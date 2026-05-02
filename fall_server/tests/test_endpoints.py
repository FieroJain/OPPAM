"""
API Endpoint Integration Tests
==============================

Tests all FastAPI endpoints using TestClient.

Run::

    cd fall_server
    pytest tests/test_endpoints.py -v

Note: These tests mock Firebase and ML models to run without
external dependencies.
"""

from __future__ import annotations

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# Ensure fall_server is on path
_SERVER_DIR = Path(__file__).resolve().parent.parent
if str(_SERVER_DIR) not in sys.path:
    sys.path.insert(0, str(_SERVER_DIR))


# ── Mock heavy imports before importing server ────────────────────────

@pytest.fixture(scope="module")
def client():
    """Create a TestClient with mocked Firebase and model."""
    # Mock firebase_admin before server import
    mock_cred = MagicMock()
    mock_db = MagicMock()
    mock_db.reference.return_value.set = MagicMock()
    mock_db.reference.return_value.push = MagicMock()

    with patch.dict("sys.modules", {
        "firebase_admin": MagicMock(),
        "firebase_admin.credentials": MagicMock(Certificate=lambda x: mock_cred),
        "firebase_admin.db": mock_db,
    }):
        # Mock TF model
        import numpy as np
        mock_model = MagicMock()
        mock_model.input_shape = (None, 200, 6)
        mock_model.predict.return_value = np.array([[0.5]])

        mock_scaler = MagicMock()
        mock_scaler.transform.return_value = np.zeros((200, 6), dtype=np.float32)

        with patch("tensorflow.keras.models.load_model", return_value=mock_model):
            with patch("joblib.load", return_value=mock_scaler):
                # Force reload
                if "server" in sys.modules:
                    del sys.modules["server"]

                from fastapi.testclient import TestClient
                from server import app

                yield TestClient(app)


SAMPLE_SENSOR = {
    "ax": 0.1,
    "ay": 0.2,
    "az": 1.0,
    "gx": 15.0,
    "gy": 20.0,
    "gz": 10.0,
}

SAMPLE_FALL = {
    "ax": 1.5,
    "ay": 2.0,
    "az": 7.5,
    "gx": 350.0,
    "gy": 400.0,
    "gz": 300.0,
}


class TestPredictEndpoint:
    """Tests for the original /predict endpoint."""

    def test_predict_endpoint_returns_200(self, client) -> None:
        """POST /predict should return 200 with valid sensor data."""
        response = client.post("/predict", json=SAMPLE_SENSOR)
        assert response.status_code == 200
        data = response.json()
        # While collecting, we get status field
        assert "status" in data or "fall_detected" in data


class TestPredictRLEndpoint:
    """Tests for the /predict_rl endpoint."""

    def test_predict_rl_returns_rl_fields(self, client) -> None:
        """POST /predict_rl should return RL-specific fields."""
        # Mock RL inference
        with patch("rl_agent.inference.get_dynamic_threshold") as mock_rl:
            mock_rl.return_value = (2.5, 0, "HOLD")
            response = client.post("/predict_rl", json=SAMPLE_SENSOR)
            assert response.status_code == 200
            data = response.json()
            assert "cnn_confidence" in data
            assert "rl_threshold" in data
            assert "action_taken" in data
            assert "ensemble_decision" in data


class TestPreFallEndpoint:
    """Tests for the /pre_fall endpoint."""

    def test_pre_fall_returns_warning_field(self, client) -> None:
        """POST /pre_fall should return warning, error_score, estimated_seconds."""
        mock_detector = MagicMock()
        mock_detector.update.return_value = {
            "warning": False,
            "error_score": 0.001,
            "estimated_seconds": 0.0,
        }
        with patch("server._get_pre_fall_detector", return_value=mock_detector):
            response = client.post("/pre_fall", json=SAMPLE_SENSOR)
            assert response.status_code == 200
            data = response.json()
            assert "warning" in data
            assert "error_score" in data
            assert "estimated_seconds" in data


class TestExplainEndpoint:
    """Tests for the /explain endpoint."""

    def test_explain_returns_importance_dict(self, client) -> None:
        """POST /explain should return importance dict with all 6 features."""
        mock_result = {
            "importance": {
                "ax": 0.1, "ay": 0.05, "az": 0.5,
                "gx": 0.15, "gy": 0.1, "gz": 0.1,
            },
            "top_feature": "az",
            "top_value": 0.5,
            "interpretation": "az (vertical accel) was the strongest indicator.",
        }
        with patch("xai.explainer.explain_prediction", return_value=mock_result):
            response = client.post("/explain", json=SAMPLE_SENSOR)
            assert response.status_code == 200
            data = response.json()
            assert "importance" in data
            assert len(data["importance"]) == 6
            assert "top_feature" in data
            assert "interpretation" in data
