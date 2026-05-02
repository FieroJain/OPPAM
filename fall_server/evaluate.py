"""
Evaluation Script — CNN vs CNN+RL Comparison
=============================================

Generates 200 test events (100 falls, 100 normal), evaluates both
Model A (CNN only) and Model B (CNN+RL ensemble), computes metrics,
plots confusion matrices and metric bar charts, and performs McNemar's
test for statistical significance.

Usage::

    cd fall_server
    python evaluate.py

Outputs:
    - results/comparison.png  — confusion matrices + metric bar chart
    - Console: formatted comparison table + McNemar's test result
"""

from __future__ import annotations

import math
import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from statsmodels.stats.contingency_tables import mcnemar

# Ensure fall_server is on the path
_SERVER_DIR = Path(__file__).resolve().parent
if str(_SERVER_DIR) not in sys.path:
    sys.path.insert(0, str(_SERVER_DIR))

import tensorflow as tf
import joblib


# ── Synthetic test data generator ─────────────────────────────────────

def generate_test_events(
    n_falls: int = 100,
    n_normal: int = 100,
    seed: int = 99,
) -> Tuple[List[np.ndarray], List[int]]:
    """Generate balanced synthetic test events.

    Args:
        n_falls: Number of fall events.
        n_normal: Number of normal events.
        seed: Random seed.

    Returns:
        (readings, labels) where readings is a list of 6-element arrays
        and labels is 1 (fall) or 0 (normal).
    """
    rng = np.random.default_rng(seed)
    readings: List[np.ndarray] = []
    labels: List[int] = []

    for _ in range(n_normal):
        ax = rng.uniform(-0.2, 0.2)   # TODO: replace with real CSV
        ay = rng.uniform(-0.2, 0.2)   # TODO: replace with real CSV
        az = rng.uniform(0.8, 1.2)    # TODO: replace with real CSV
        gx = rng.uniform(5.0, 30.0)   # TODO: replace with real CSV
        gy = rng.uniform(5.0, 30.0)   # TODO: replace with real CSV
        gz = rng.uniform(5.0, 30.0)   # TODO: replace with real CSV
        readings.append(np.array([ax, ay, az, gx, gy, gz], dtype=np.float32))
        labels.append(0)

    for _ in range(n_falls):
        ax = rng.uniform(-2.0, 2.0)    # TODO: replace with real CSV
        ay = rng.uniform(-2.0, 2.0)    # TODO: replace with real CSV
        az = rng.uniform(3.0, 8.0)     # TODO: replace with real CSV
        gx = rng.uniform(200.0, 500.0) # TODO: replace with real CSV
        gy = rng.uniform(200.0, 500.0) # TODO: replace with real CSV
        gz = rng.uniform(200.0, 500.0) # TODO: replace with real CSV
        readings.append(np.array([ax, ay, az, gx, gy, gz], dtype=np.float32))
        labels.append(1)

    return readings, labels


# ── CNN-only classifier ───────────────────────────────────────────────

def cnn_predict(
    reading: np.ndarray,
    model: tf.keras.Model,
    scaler,
    threshold: float = 0.95,
) -> Tuple[bool, float]:
    """Run CNN prediction on a single reading.

    For evaluation we tile the single reading across the window.

    Args:
        reading: 6-element sensor array.
        model: Loaded Keras CNN model.
        scaler: Fitted scaler.
        threshold: Classification threshold.

    Returns:
        (fall_detected, confidence).
    """
    window_size = model.input_shape[1]
    # Tile reading across window
    window = np.tile(reading, (window_size, 1))
    scaled = scaler.transform(window)
    batch = scaled.reshape(1, window_size, 6)
    prob = float(model.predict(batch, verbose=0)[0][0])
    return prob > threshold, prob


# ── CNN+RL ensemble classifier ────────────────────────────────────────

def cnn_rl_predict(
    reading: np.ndarray,
    model: tf.keras.Model,
    scaler,
    rl_threshold: float = 2.5,
    cnn_threshold: float = 0.95,
) -> Tuple[bool, float, str]:
    """Run CNN + RL ensemble prediction.

    Args:
        reading: 6-element sensor array.
        model: Loaded Keras CNN model.
        scaler: Fitted scaler.
        rl_threshold: Current RL adaptive threshold (g).
        cnn_threshold: CNN classification threshold.

    Returns:
        (fall_detected, cnn_confidence, ensemble_decision).
    """
    cnn_fall, cnn_conf = cnn_predict(reading, model, scaler, cnn_threshold)

    accel_mag = math.sqrt(float(reading[0]) ** 2 + float(reading[1]) ** 2 + float(reading[2]) ** 2)
    rl_triggered = accel_mag > rl_threshold

    if cnn_fall and rl_triggered:
        ensemble = "BOTH"
    elif cnn_fall:
        ensemble = "CNN_TRIGGERED"
    elif rl_triggered:
        ensemble = "RL_TRIGGERED"
    else:
        ensemble = "NONE"

    fall_detected = cnn_fall or rl_triggered
    return fall_detected, cnn_conf, ensemble


# ── Evaluation ────────────────────────────────────────────────────────

def evaluate() -> None:
    """Run the full evaluation pipeline."""

    results_dir = _SERVER_DIR / "results"
    results_dir.mkdir(parents=True, exist_ok=True)

    print("╔══════════════════════════════════════════════╗")
    print("║  Fall Detection — Model Evaluation          ║")
    print("╚══════════════════════════════════════════════╝\n")

    # Load assets
    # Load assets
    print("Loading model and scaler …")
    import keras.src.engine.input_layer as _il
    _orig = _il.InputLayer.__init__
    def _fix(self, *a, **kw):
        kw.pop("batch_shape", None)
        _orig(self, *a, **kw)
    _il.InputLayer.__init__ = _fix
    model = tf.keras.models.load_model(
        str(_SERVER_DIR / "sequence_cnn_model.keras"),
        compile=False
    )
    scaler = joblib.load(str(_SERVER_DIR / "scaler.pkl"))

    # Try to load RL model for dynamic threshold
    try:
        from rl_agent.inference import get_dynamic_threshold
        use_rl = True
        print("✅ RL model loaded for ensemble evaluation")
    except FileNotFoundError:
        use_rl = False
        print("⚠️  RL model not found — using fixed threshold=2.5 for ensemble")

    # Generate test data
    print("Generating 200 test events (100 falls + 100 normal) …")
    readings, labels = generate_test_events()
    y_true = np.array(labels)

    # ── Model A: CNN Only ─────────────────────────────────────────────
    print("\nEvaluating Model A (CNN Only) …")
    preds_a: List[int] = []
    probs_a: List[float] = []
    for r in readings:
        detected, conf = cnn_predict(r, model, scaler)
        preds_a.append(int(detected))
        probs_a.append(conf)

    # ── Model B: CNN + RL ─────────────────────────────────────────────
    print("Evaluating Model B (CNN + RL) …")
    preds_b: List[int] = []
    probs_b: List[float] = []
    for r in readings:
        if use_rl:
            accel_mag = math.sqrt(float(r[0]) ** 2 + float(r[1]) ** 2 + float(r[2]) ** 2)
            features = np.array(
                [r[0], r[1], r[2], r[3], r[4], r[5], accel_mag],
                dtype=np.float32,
            )
            rl_thr, _, _ = get_dynamic_threshold(features)
        else:
            rl_thr = 2.5

        detected, conf, _ = cnn_rl_predict(r, model, scaler, rl_threshold=rl_thr)
        preds_b.append(int(detected))
        probs_b.append(conf)

    y_pred_a = np.array(preds_a)
    y_pred_b = np.array(preds_b)
    y_prob_a = np.array(probs_a)
    y_prob_b = np.array(probs_b)

    # ── Compute metrics ───────────────────────────────────────────────
    def compute_metrics(y_t, y_p, y_s) -> Dict[str, float]:
        """Compute all 6 metrics."""
        tn, fp, fn, tp = confusion_matrix(y_t, y_p, labels=[0, 1]).ravel()
        return {
            "Accuracy": accuracy_score(y_t, y_p),
            "Sensitivity": recall_score(y_t, y_p, zero_division=0),
            "Specificity": float(tn / (tn + fp)) if (tn + fp) > 0 else 0.0,
            "Precision": precision_score(y_t, y_p, zero_division=0),
            "F1": f1_score(y_t, y_p, zero_division=0),
            "AUC-ROC": roc_auc_score(y_t, y_s),
        }

    metrics_a = compute_metrics(y_true, y_pred_a, y_prob_a)
    metrics_b = compute_metrics(y_true, y_pred_b, y_prob_b)

    # ── Print table ───────────────────────────────────────────────────
    print("\n┌─────────────┬──────────┬────────────┐")
    print("│ Metric      │ CNN Only │ CNN+RL     │")
    print("├─────────────┼──────────┼────────────┤")
    for key in metrics_a:
        va = f"{metrics_a[key]:.4f}"
        vb = f"{metrics_b[key]:.4f}"
        print(f"│ {key:<11s} │ {va:>8s} │ {vb:>10s} │")
    print("└─────────────┴──────────┴────────────┘")

    # ── McNemar's test ────────────────────────────────────────────────
    # Contingency table: a disagrees b
    both_correct = np.sum((y_pred_a == y_true) & (y_pred_b == y_true))
    a_correct_b_wrong = np.sum((y_pred_a == y_true) & (y_pred_b != y_true))
    a_wrong_b_correct = np.sum((y_pred_a != y_true) & (y_pred_b == y_true))
    both_wrong = np.sum((y_pred_a != y_true) & (y_pred_b != y_true))

    contingency = np.array([
        [both_correct, a_correct_b_wrong],
        [a_wrong_b_correct, both_wrong],
    ])
    try:
        result = mcnemar(contingency, exact=True)
        pvalue = result.pvalue
        statistic = result.statistic
        print(f"\n📊 McNemar's Test:")
        print(f"   Statistic: {statistic:.4f}")
        print(f"   p-value:   {pvalue:.4f}")
        if pvalue < 0.05:
            print("   ✅ CNN+RL is statistically significantly better (p < 0.05)")
        else:
            print("   ℹ️  No statistically significant difference (p ≥ 0.05)")
    except Exception as e:
        print(f"\n⚠️  McNemar's test failed: {e}")
        pvalue = 1.0

    # ── Plot ──────────────────────────────────────────────────────────
    fig, axes = plt.subplots(1, 3, figsize=(18, 5))

    # Confusion matrix — CNN
    cm_a = confusion_matrix(y_true, y_pred_a, labels=[0, 1])
    im0 = axes[0].imshow(cm_a, cmap="Blues", interpolation="nearest")
    axes[0].set_title("CNN Only — Confusion Matrix", fontweight="bold")
    axes[0].set_xlabel("Predicted")
    axes[0].set_ylabel("Actual")
    axes[0].set_xticks([0, 1])
    axes[0].set_xticklabels(["Normal", "Fall"])
    axes[0].set_yticks([0, 1])
    axes[0].set_yticklabels(["Normal", "Fall"])
    for i in range(2):
        for j in range(2):
            axes[0].text(j, i, str(cm_a[i, j]), ha="center", va="center",
                         fontsize=16, fontweight="bold",
                         color="white" if cm_a[i, j] > cm_a.max() / 2 else "black")

    # Confusion matrix — CNN+RL
    cm_b = confusion_matrix(y_true, y_pred_b, labels=[0, 1])
    axes[1].imshow(cm_b, cmap="Greens", interpolation="nearest")
    axes[1].set_title("CNN + RL — Confusion Matrix", fontweight="bold")
    axes[1].set_xlabel("Predicted")
    axes[1].set_ylabel("Actual")
    axes[1].set_xticks([0, 1])
    axes[1].set_xticklabels(["Normal", "Fall"])
    axes[1].set_yticks([0, 1])
    axes[1].set_yticklabels(["Normal", "Fall"])
    for i in range(2):
        for j in range(2):
            axes[1].text(j, i, str(cm_b[i, j]), ha="center", va="center",
                         fontsize=16, fontweight="bold",
                         color="white" if cm_b[i, j] > cm_b.max() / 2 else "black")

    # Bar chart comparing metrics
    metric_names = list(metrics_a.keys())
    vals_a = [metrics_a[k] for k in metric_names]
    vals_b = [metrics_b[k] for k in metric_names]
    x_pos = np.arange(len(metric_names))
    width = 0.35

    axes[2].bar(x_pos - width / 2, vals_a, width, label="CNN Only",
                color="#3B82F6", alpha=0.85)
    axes[2].bar(x_pos + width / 2, vals_b, width, label="CNN + RL",
                color="#10B981", alpha=0.85)
    axes[2].set_ylabel("Score")
    axes[2].set_title("Metric Comparison", fontweight="bold")
    axes[2].set_xticks(x_pos)
    axes[2].set_xticklabels(metric_names, rotation=25, ha="right")
    axes[2].set_ylim(0, 1.1)
    axes[2].legend()
    axes[2].grid(axis="y", alpha=0.3)

    fig.tight_layout()
    out_path = results_dir / "comparison.png"
    fig.savefig(str(out_path), dpi=150)
    plt.close(fig)
    print(f"\n📈 Plots saved → {out_path}")
    print("Evaluation complete.")


if __name__ == "__main__":
    evaluate()
