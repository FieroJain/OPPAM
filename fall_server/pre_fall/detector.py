"""
Pre-Fall Detector
=================

Maintains a rolling window of the last 10 sensor readings and uses
the LSTM autoencoder to compute reconstruction error.  If the error
exceeds the saved threshold, a pre-fall warning is issued together
with an estimated time-to-fall based on the slope of recent errors.

Usage::

    detector = PreFallDetector()
    result   = detector.update([ax, ay, az, gx, gy, gz])
    # result = {"warning": bool, "error_score": float,
    #           "estimated_seconds": float}
"""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np
import tensorflow as tf
from tensorflow import keras

_SERVER_DIR = Path(__file__).resolve().parent.parent
_MODELS_DIR = _SERVER_DIR / "models"


class PreFallDetector:
    """Streaming pre-fall detector backed by an LSTM autoencoder.

    Keeps a deque of the last 10 readings (each of length 6) and
    evaluates the autoencoder reconstruction error on every update.

    Attributes:
        buffer: Rolling window of sensor readings.
        warning_threshold: 95th-percentile error from training.
    """

    WINDOW_SIZE: int = 10
    FEATURES: int = 6

    def __init__(self) -> None:
        """Load the LSTM autoencoder model and threshold."""
        model_path = _MODELS_DIR / "pre_fall_model.h5"
        threshold_path = _MODELS_DIR / "threshold.json"

        if not model_path.exists():
            raise FileNotFoundError(
                f"Pre-fall model not found at {model_path}. "
                "Run `python pre_fall/lstm_autoencoder.py` first."
            )
        if not threshold_path.exists():
            raise FileNotFoundError(
                f"Threshold file not found at {threshold_path}."
            )

        self._model: keras.Model = keras.models.load_model(str(model_path))
        with open(threshold_path, "r") as f:
            self.warning_threshold: float = json.load(f)["warning_threshold"]

        self.buffer: deque[List[float]] = deque(maxlen=self.WINDOW_SIZE)
        self._error_history: deque[float] = deque(maxlen=30)

        print(
            f"✅ PreFallDetector ready | threshold={self.warning_threshold:.6f}"
        )

    def update(self, reading: List[float]) -> Dict[str, object]:
        """Ingest a new sensor reading and evaluate pre-fall status.

        Args:
            reading: List of 6 floats ``[ax, ay, az, gx, gy, gz]``.

        Returns:
            Dictionary with keys:
            - ``warning`` (bool): ``True`` if instability detected.
            - ``error_score`` (float): Reconstruction error.
            - ``estimated_seconds`` (float): Estimated seconds until fall
              (``0.0`` when no warning).
        """
        self.buffer.append(reading[: self.FEATURES])

        # Not enough data yet
        if len(self.buffer) < self.WINDOW_SIZE:
            return {
                "warning": False,
                "error_score": 0.0,
                "estimated_seconds": 0.0,
            }

        # Prepare input
        window = np.array(list(self.buffer), dtype=np.float32)
        window = window.reshape(1, self.WINDOW_SIZE, self.FEATURES)

        # Reconstruct and compute error
        reconstructed = self._model.predict(window, verbose=0)
        error: float = float(np.mean(np.abs(reconstructed - window)))
        self._error_history.append(error)

        warning = error > self.warning_threshold

        estimated_seconds: float = 0.0
        if warning and len(self._error_history) >= 5:
            recent = list(self._error_history)[-5:]
            x = np.arange(len(recent), dtype=np.float64)
            coeffs = np.polyfit(x, recent, 1)
            slope = float(coeffs[0])
            if slope > 0:
                estimated_seconds = max(
                    0.0,
                    (2 * self.warning_threshold - error) / slope,
                )
            else:
                estimated_seconds = 3.0

        return {
            "warning": warning,
            "error_score": round(error, 6),
            "estimated_seconds": round(estimated_seconds, 2),
        }
