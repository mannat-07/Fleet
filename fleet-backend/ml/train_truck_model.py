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
    "maintenance_score",
    "fuel_efficiency",
    "breakdown_count",
    "age_years",
    "total_trips",
    "avg_load_capacity_used",
]
MODEL_PATH = Path(__file__).resolve().parent / "truck_model.pkl"


def fetch_truck_data() -> pd.DataFrame:
    """Fetch truck data from Firestore and return as a DataFrame."""
    db = get_firestore_client()
    docs = db.collection("trucks").stream()
    rows = []
    for doc in docs:
        data = doc.to_dict()
        rows.append({
            "truck_id": data.get("truck_id") or data.get("truckId") or doc.id,
            **data,
        })

    if not rows:
        raise ValueError("No truck records found in Firestore.")

    df = pd.DataFrame(rows)
    return df


def clean_and_prepare(
    df: pd.DataFrame,
) -> Tuple[pd.DataFrame, Dict[str, float], MinMaxScaler]:
    """Clean data, compute truck_score if missing, normalize to 0-100."""
    if df.empty:
        raise ValueError("No truck rows returned from Firestore.")

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
            "No valid truck rows after cleaning. Ensure trucks have numeric "
            "values for maintenance_score, fuel_efficiency, breakdown_count, "
            "age_years, total_trips, avg_load_capacity_used."
        )

    if "truck_score" not in required.columns:
        required["truck_score"] = np.nan

    mask_missing = required["truck_score"].isna()
    # Truck scoring formula
    computed_scores = (
        0.35 * required["maintenance_score"]
        + 0.25 * required["fuel_efficiency"] * 10  # Scale to 0-100
        + 0.20 * required["avg_load_capacity_used"]
        - 3.0 * required["breakdown_count"]
        - 1.5 * required["age_years"]
    )
    required.loc[mask_missing, "truck_score"] = computed_scores[mask_missing]

    score_scaler = MinMaxScaler(feature_range=(0, 100))
    required["truck_score_norm"] = score_scaler.fit_transform(
        required[["truck_score"]]
    )

    stats = {
        "maintenance_score": required["maintenance_score"].mean(),
        "fuel_efficiency": required["fuel_efficiency"].mean(),
        "breakdown_count": required["breakdown_count"].mean(),
        "age_years": required["age_years"].mean(),
        "total_trips": required["total_trips"].mean(),
        "avg_load_capacity_used": required["avg_load_capacity_used"].mean(),
    }
    return required, stats, score_scaler


def build_reason(row: pd.Series, stats: Dict[str, float]) -> str:
    reasons: List[str] = []
    if row["maintenance_score"] >= stats["maintenance_score"]:
        reasons.append("High maintenance score")
    if row["breakdown_count"] <= stats["breakdown_count"]:
        reasons.append("low breakdowns")
    if row["fuel_efficiency"] >= stats["fuel_efficiency"]:
        reasons.append("efficient fuel usage")
    if row["avg_load_capacity_used"] >= stats["avg_load_capacity_used"]:
        reasons.append("good capacity utilization")
    if row["age_years"] <= stats["age_years"]:
        reasons.append("newer vehicle")
    if not reasons:
        reasons.append("balanced overall performance")
    return ", ".join(reasons[:3])


def train_model(df: pd.DataFrame) -> Dict[str, object]:
    feature_scaler = StandardScaler()
    X = df[FEATURES].values
    y = df["truck_score_norm"].values

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


def rank_trucks(
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
                "truck_id": row["truck_id"],
                "plate": row.get("plate", "N/A"),
                "model": row.get("model", "N/A"),
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
    df_raw = fetch_truck_data()
    df, stats, score_scaler = clean_and_prepare(df_raw)
    result = train_model(df)

    save_model(result["model"], result["feature_scaler"], score_scaler, stats)
    recommendations = rank_trucks(
        df,
        result["model"],
        result["feature_scaler"],
        stats,
    )

    print(f"MAE: {result['mae']:.4f}")
    print(json.dumps({"recommended_trucks": recommendations}, indent=2))


if __name__ == "__main__":
    main()
