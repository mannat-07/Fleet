import json
from pathlib import Path
from typing import Dict, List, Tuple

import joblib
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler, StandardScaler

from firebase_client import get_firestore_client


FEATURES = [
    "safety_score",
    "fuel_efficiency",
    "on_time_delivery_rate",
    "alert_count",
    "experience_years",
    "trips_completed",
]
MODEL_PATH = Path(__file__).resolve().parent / "driver_model.pkl"


def fetch_driver_data() -> pd.DataFrame:
    """Fetch driver data from Firestore and return as a DataFrame."""
    db = get_firestore_client()
    docs = db.collection("drivers").stream()
    rows = []
    for doc in docs:
        data = doc.to_dict()
        rows.append({
            "driver_id": data.get("driver_id") or data.get("id") or doc.id,
            **data,
        })

    if not rows:
        raise ValueError("No driver records found in Firestore.")

    df = pd.DataFrame(rows)
    return df


def clean_and_prepare(
    df: pd.DataFrame,
) -> Tuple[pd.DataFrame, Dict[str, float], MinMaxScaler]:
    """Clean data, compute driver_score if missing, normalize to 0-100."""
    if df.empty:
        raise ValueError("No driver rows returned from Firestore.")

    for feature in FEATURES:
        if feature not in df.columns:
            df[feature] = np.nan
        df[feature] = pd.to_numeric(df[feature], errors="coerce")

    missing_counts = df[FEATURES].isna().sum().to_dict()
    total_rows = len(df)
    if any(count > 0 for count in missing_counts.values()):
        print("Missing feature values detected (rows with nulls will be dropped):")
        for name, count in missing_counts.items():
            if count:
                print(f"- {name}: {count}/{total_rows} rows missing")

    required = df.dropna(subset=FEATURES).copy()
    if required.empty:
        raise ValueError(
            "No valid driver rows after cleaning. Ensure drivers have numeric "
            "values for safety_score, fuel_efficiency, on_time_delivery_rate, "
            "alert_count, experience_years, trips_completed."
        )

    if "driver_score" not in required.columns:
        required["driver_score"] = np.nan

    mask_missing = required["driver_score"].isna()
    computed_scores = (
        0.3 * required["safety_score"]
        + 0.25 * required["on_time_delivery_rate"]
        + 0.2 * required["fuel_efficiency"]
        - 2 * required["alert_count"]
        + 1.5 * required["experience_years"]
    )
    required.loc[mask_missing, "driver_score"] = computed_scores[mask_missing]

    score_scaler = MinMaxScaler(feature_range=(0, 100))
    required["driver_score_norm"] = score_scaler.fit_transform(
        required[["driver_score"]]
    )

    stats = {
        "safety_score": required["safety_score"].mean(),
        "fuel_efficiency": required["fuel_efficiency"].mean(),
        "on_time_delivery_rate": required["on_time_delivery_rate"].mean(),
        "alert_count": required["alert_count"].mean(),
        "experience_years": required["experience_years"].mean(),
        "trips_completed": required["trips_completed"].mean(),
    }
    return required, stats, score_scaler


def build_reason(row: pd.Series, stats: Dict[str, float]) -> str:
    reasons: List[str] = []
    if row["safety_score"] >= stats["safety_score"]:
        reasons.append("High safety score")
    if row["alert_count"] <= stats["alert_count"]:
        reasons.append("low alerts")
    if row["on_time_delivery_rate"] >= stats["on_time_delivery_rate"]:
        reasons.append("good on-time delivery")
    if row["fuel_efficiency"] >= stats["fuel_efficiency"]:
        reasons.append("efficient fuel usage")
    if row["experience_years"] >= stats["experience_years"]:
        reasons.append("experienced driver")
    if not reasons:
        reasons.append("balanced overall performance")
    return ", ".join(reasons[:3])


def train_model(df: pd.DataFrame) -> Dict[str, object]:
    feature_scaler = StandardScaler()
    X = df[FEATURES].values
    y = df["driver_score_norm"].values

    X_scaled = feature_scaler.fit_transform(X)

    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y, test_size=0.2, random_state=42
    )

    model = LinearRegression()
    model.fit(X_train, y_train)
    preds = model.predict(X_test)
    mae = mean_absolute_error(y_test, preds)

    return {
        "model": model,
        "feature_scaler": feature_scaler,
        "mae": mae,
    }


def rank_drivers(
    df: pd.DataFrame,
    model: LinearRegression,
    feature_scaler: StandardScaler,
    stats: Dict[str, float],
) -> List[Dict[str, object]]:
    X_scaled = feature_scaler.transform(df[FEATURES].values)
    preds = model.predict(X_scaled)

    df = df.copy()
    df["predicted_score"] = preds
    df["predicted_score"] = df["predicted_score"].clip(0, 100)

    top = df.sort_values("predicted_score", ascending=False).head(3)
    output = []
    for _, row in top.iterrows():
        output.append(
            {
                "driver_id": row["driver_id"],
                "predicted_score": round(float(row["predicted_score"]), 2),
                "reason": build_reason(row, stats),
            }
        )
    return output


def save_model(model: LinearRegression, feature_scaler: StandardScaler, score_scaler: MinMaxScaler, stats: Dict[str, float]):
    artifact = {
        "model": model,
        "feature_scaler": feature_scaler,
        "score_scaler": score_scaler,
        "feature_names": FEATURES,
        "stats": stats,
    }
    joblib.dump(artifact, MODEL_PATH)


def main():
    df_raw = fetch_driver_data()
    df, stats, score_scaler = clean_and_prepare(df_raw)
    result = train_model(df)

    save_model(result["model"], result["feature_scaler"], score_scaler, stats)
    recommendations = rank_drivers(
        df,
        result["model"],
        result["feature_scaler"],
        stats,
    )

    print(f"MAE: {result['mae']:.4f}")
    print(json.dumps({"recommended_drivers": recommendations}, indent=2))


if __name__ == "__main__":
    main()
