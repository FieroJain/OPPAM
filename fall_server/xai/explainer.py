"""
XAI (Explainable AI) Module
============================

Uses SHAP to explain CNN fall-detection predictions.  Tries
``shap.DeepExplainer`` first; falls back to ``shap.KernelExplainer``
if DeepExplainer fails (e.g., unsupported layer types).

Example usage::

    from xai.explainer import explain_prediction

    result = explain_prediction({
        "ax": 0.1, "ay": 0.2, "az": 8.5,
        "gx": 250.0, "gy": 300.0, "gz": 280.0,
    })
    print(result)
    # {
    #     "importance": {"ax": 0.02, "ay": 0.03, "az": 0.45, ...},
    #     "top_feature": "az",
    #     "top_value": 0.45,
    #     "interpretation": "az (vertical accel) was the strongest indicator …"
    # }
"""

from __future__ import annotations

import pickle
import warnings
from pathlib import Path
from typing import Any, Dict, Optional

import numpy as np
import shap
import tensorflow as tf
from tensorflow import keras

warnings.filterwarnings("ignore", category=FutureWarning)

_SERVER_DIR = Path(__file__).resolve().parent.parent

# ── Feature metadata ──────────────────────────────────────────────────
_FEATURE_NAMES = ["ax", "ay", "az", "gx", "gy", "gz"]
_FEATURE_DESCRIPTIONS: Dict[str, str] = {
    "ax": "lateral acceleration",
    "ay": "forward acceleration",
    "az": "vertical acceleration",
    "gx": "roll angular velocity",
    "gy": "pitch angular velocity",
    "gz": "yaw angular velocity",
}

# ── Lazy-loaded singletons ────────────────────────────────────────────
_model: Optional[keras.Model] = None
_scaler: Optional[Any] = None
_explainer: Optional[Any] = None
_background: Optional[np.ndarray] = None


def _load_assets() -> None:
    """Load CNN model and scaler once."""
    global _model, _scaler

    if _model is None:
        model_path = _SERVER_DIR / "sequence_cnn_model.keras"
        _model = keras.models.load_model(str(model_path))
        print(f"✅ XAI: CNN model loaded from {model_path}")

    if _scaler is None:
        scaler_path = _SERVER_DIR / "scaler.pkl"
        with open(scaler_path, "rb") as f:
            _scaler = pickle.load(f)
        print(f"✅ XAI: Scaler loaded from {scaler_path}")


def _get_explainer() -> Any:
    """Create SHAP explainer (DeepExplainer → KernelExplainer fallback).

    Returns:
        A SHAP explainer instance.
    """
    global _explainer, _background
    if _explainer is not None:
        return _explainer

    _load_assets()
    assert _model is not None and _scaler is not None

    # Build a small background dataset (100 synthetic normal samples)
    rng = np.random.default_rng(0)
    bg_raw = np.column_stack([
        rng.uniform(-0.2, 0.2, (100,)),   # ax
        rng.uniform(-0.2, 0.2, (100,)),   # ay
        rng.uniform(0.8, 1.2, (100,)),    # az
        rng.uniform(5.0, 30.0, (100,)),   # gx
        rng.uniform(5.0, 30.0, (100,)),   # gy
        rng.uniform(5.0, 30.0, (100,)),   # gz
    ]).astype(np.float32)
    bg_scaled = _scaler.transform(bg_raw)

    # Determine the model input shape
    input_shape = _model.input_shape  # e.g. (None, 200, 6)
    if len(input_shape) == 3:
        window = input_shape[1]
        # Tile single reading across the window
        _background = np.tile(
            bg_scaled[:, np.newaxis, :], (1, window, 1)
        ).astype(np.float32)
    else:
        _background = bg_scaled

    # Try DeepExplainer first
    try:
        _explainer = shap.DeepExplainer(_model, _background)
        print("✅ XAI: Using shap.DeepExplainer")
    except Exception as e:
        print(f"⚠️  DeepExplainer failed ({e}); falling back to KernelExplainer")

        def _predict_fn(x: np.ndarray) -> np.ndarray:
            """Wrapper for KernelExplainer."""
            return _model.predict(x, verbose=0)  # type: ignore[union-attr]

        # KernelExplainer needs fewer background samples
        _explainer = shap.KernelExplainer(_predict_fn, _background[:20])
        print("✅ XAI: Using shap.KernelExplainer")

    return _explainer


def explain_prediction(sensor_input: Dict[str, float]) -> Dict[str, Any]:
    """Explain a single fall-detection prediction using SHAP.

    Args:
        sensor_input: Dictionary with keys
            ``{ax, ay, az, gx, gy, gz}`` — raw sensor values.

    Returns:
        Dictionary with:
        - ``importance``: per-feature SHAP importance (abs mean across window).
        - ``top_feature``: name of the most important feature.
        - ``top_value``: importance value of the top feature.
        - ``interpretation``: human-readable explanation string.

    Example::

        result = explain_prediction({"ax": 0.1, "ay": 0.2, "az": 8.5,
                                     "gx": 250, "gy": 300, "gz": 280})
    """
    _load_assets()
    assert _model is not None and _scaler is not None

    explainer = _get_explainer()

    # Prepare input
    raw = np.array(
        [[sensor_input[k] for k in _FEATURE_NAMES]], dtype=np.float32
    )
    scaled = _scaler.transform(raw)

    input_shape = _model.input_shape
    if len(input_shape) == 3:
        window = input_shape[1]
        sample = np.tile(scaled[:, np.newaxis, :], (1, window, 1)).astype(
            np.float32
        )
    else:
        sample = scaled

    # Compute SHAP values
    shap_values = explainer.shap_values(sample)

    # Handle different SHAP output formats
    if isinstance(shap_values, list):
        sv = shap_values[0]
    else:
        sv = shap_values

    # Average absolute SHAP across window dimension if present
    if sv.ndim == 3:
        # shape: (1, window, features) → mean across window → (features,)
        feature_importance = np.mean(np.abs(sv[0]), axis=0)
    else:
        feature_importance = np.abs(sv[0])

    # Normalise to sum to 1
    total = float(np.sum(feature_importance))
    if total > 0:
        feature_importance = feature_importance / total

    importance: Dict[str, float] = {
        name: round(float(feature_importance[i]), 4)
        for i, name in enumerate(_FEATURE_NAMES)
    }

    top_feature = max(importance, key=lambda k: importance[k])
    top_value = importance[top_feature]

    desc = _FEATURE_DESCRIPTIONS.get(top_feature, top_feature)
    interpretation = (
        f"{top_feature} ({desc}) was the strongest indicator of a fall, "
        f"contributing {top_value:.1%} of the prediction."
    )

    return {
        "importance": importance,
        "top_feature": top_feature,
        "top_value": top_value,
        "interpretation": interpretation,
    }
