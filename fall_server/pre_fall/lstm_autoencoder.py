"""
LSTM Autoencoder for Pre-Fall Detection
========================================

Builds and trains an LSTM autoencoder on *normal* gait data only.
At inference time, abnormally-high reconstruction error signals
pre-fall instability 2-3 seconds before an actual fall.

Architecture:
    Encoder: LSTM(64, return_sequences=True) → LSTM(32)
    Decoder: RepeatVector(10) → LSTM(32, return_sequences=True)
             → LSTM(64, return_sequences=True) → TimeDistributed(Dense(6))

Outputs:
    - models/pre_fall_model.h5       — trained autoencoder
    - models/threshold.json          — {"warning_threshold": <95th-percentile>}
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers  # type: ignore[attr-defined]

# Paths
_SCRIPT_DIR = Path(__file__).resolve().parent
_SERVER_DIR = _SCRIPT_DIR.parent
_MODELS_DIR = _SERVER_DIR / "models"


def _generate_normal_sequences(
    n_sequences: int = 2_000,
    timesteps: int = 10,
    features: int = 6,
    seed: int = 42,
) -> np.ndarray:
    """Generate synthetic *normal* walking sequences.

    Each sequence has shape ``(timesteps, features)`` where features are
    ``[ax, ay, az, gx, gy, gz]``.

    Args:
        n_sequences: Number of sequences to generate.
        timesteps: Number of time steps per sequence.
        features: Number of sensor axes.
        seed: Random seed for reproducibility.

    Returns:
        Array of shape ``(n_sequences, timesteps, features)``.
    """
    rng = np.random.default_rng(seed)
    data = np.zeros((n_sequences, timesteps, features), dtype=np.float32)
    for i in range(n_sequences):
        # Simulate a smooth walking pattern with slight variation per step
        base_accel = rng.uniform(0.8, 1.2, size=(features,))
        for t in range(timesteps):
            noise = rng.normal(0, 0.05, size=(features,))
            # TODO: replace with real CSV — using synthetic walking data
            data[i, t, 0] = base_accel[0] + noise[0]        # ax  # TODO: replace with real CSV
            data[i, t, 1] = base_accel[1] + noise[1]        # ay  # TODO: replace with real CSV
            data[i, t, 2] = base_accel[2] + noise[2] + 0.98 # az (gravity) # TODO: replace with real CSV
            data[i, t, 3] = rng.uniform(5, 30) + noise[3]   # gx  # TODO: replace with real CSV
            data[i, t, 4] = rng.uniform(5, 30) + noise[4]   # gy  # TODO: replace with real CSV
            data[i, t, 5] = rng.uniform(5, 30) + noise[5]   # gz  # TODO: replace with real CSV
    return data


def build_model(timesteps: int = 10, features: int = 6) -> keras.Model:
    """Build the LSTM Autoencoder architecture.

    Args:
        timesteps: Sequence length.
        features: Number of sensor axes.

    Returns:
        Compiled Keras model.
    """
    inputs = keras.Input(shape=(timesteps, features), name="sensor_input")

    # Encoder
    x = layers.LSTM(64, return_sequences=True, name="enc_lstm1")(inputs)
    x = layers.LSTM(32, return_sequences=False, name="enc_lstm2")(x)

    # Decoder
    x = layers.RepeatVector(timesteps, name="repeat")(x)
    x = layers.LSTM(32, return_sequences=True, name="dec_lstm1")(x)
    x = layers.LSTM(64, return_sequences=True, name="dec_lstm2")(x)
    outputs = layers.TimeDistributed(
        layers.Dense(features), name="output_dense"
    )(x)

    model = keras.Model(inputs, outputs, name="lstm_autoencoder")
    model.compile(optimizer="adam", loss="mae")
    return model


def train_and_save() -> None:
    """Train the autoencoder on normal data and persist artefacts."""
    _MODELS_DIR.mkdir(parents=True, exist_ok=True)

    print("╔══════════════════════════════════════════════╗")
    print("║  LSTM Autoencoder — Pre-Fall Detection      ║")
    print("╚══════════════════════════════════════════════╝")

    # 1. Generate data
    print("Generating synthetic normal sequences …")
    X_train = _generate_normal_sequences(n_sequences=2_000)
    print(f"  Training data shape: {X_train.shape}")

    # 2. Build model
    model = build_model()
    model.summary()

    # 3. Train
    print("\nTraining for 30 epochs …")
    model.fit(
        X_train, X_train,
        epochs=30,
        batch_size=64,
        validation_split=0.1,
        verbose=1,
    )

    # 4. Save model
    model_path = _MODELS_DIR / "pre_fall_model.h5"
    model.save(str(model_path))
    print(f"✅ Model saved → {model_path}")

    # 5. Compute warning threshold (95th percentile of reconstruction error)
    print("Computing warning threshold …")
    reconstructed = model.predict(X_train, verbose=0)
    errors = np.mean(np.abs(reconstructed - X_train), axis=(1, 2))
    threshold = float(np.percentile(errors, 95))

    threshold_path = _MODELS_DIR / "threshold.json"
    with open(threshold_path, "w") as f:
        json.dump({"warning_threshold": round(threshold, 6)}, f, indent=2)
    print(f"📊 Warning threshold ({threshold:.6f}) saved → {threshold_path}")

    print("Training complete.")


if __name__ == "__main__":
    train_and_save()
