import os
import json
from pathlib import Path
from typing import Optional

import firebase_admin
from firebase_admin import credentials, firestore


DEFAULT_KEY_PATH = Path(__file__).resolve().parents[1] / "serviceAccountKey.json"


def get_firestore_client() -> firestore.Client:
    """Return an initialized Firestore client using service account credentials."""
    if firebase_admin._apps:
        return firestore.client()

    cred_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
    key_path = Path(cred_path) if cred_path else DEFAULT_KEY_PATH

    if not key_path.exists():
        raise FileNotFoundError(
            "Firestore credentials not found. Set FIREBASE_SERVICE_ACCOUNT_PATH "
            "or place serviceAccountKey.json in fleet-backend/."
        )

    with key_path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    cred = credentials.Certificate(data)
    firebase_admin.initialize_app(cred)
    return firestore.client()
