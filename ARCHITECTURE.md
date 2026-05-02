# 🏗️ System Architecture

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                      FALL DETECTION SYSTEM                          │
│                CNN + RL + LSTM + XAI + Flutter                      │
└──────────────────────────────────────────────────────────────────────┘

  ┌─────────┐         ┌──────────────┐         ┌─────────────────────┐
  │  ESP32  │ ──BLE──▶│  Flutter App │ ──HTTP──▶│  FastAPI Server     │
  │ IMU 6DOF│         │  (Dart)      │         │  (Python)           │
  │ ax,ay,az│         │              │         │                     │
  │ gx,gy,gz│         │  ┌────────┐  │         │  ┌───────────────┐  │
  └─────────┘         │  │Dashboard│  │         │  │ POST /predict │  │
                      │  │  Screen │◀─┼─────────┼──│  (CNN Only)   │  │
                      │  └────────┘  │         │  └───────────────┘  │
                      │              │         │                     │
                      │  ┌────────┐  │         │  ┌───────────────┐  │
                      │  │Threshld│  │         │  │POST/predict_rl│  │
                      │  │History │◀─┼─────────┼──│ (CNN + RL)    │  │
                      │  └────────┘  │         │  └───────┬───────┘  │
                      │              │         │          │          │
                      │  ┌────────┐  │         │  ┌───────▼───────┐  │
                      │  │Pre-Fall│  │         │  │  RL Agent     │  │
                      │  │Warning │◀─┼─────────┼──│  (PPO/SB3)    │  │
                      │  │ Banner │  │         │  └───────────────┘  │
                      │  └────────┘  │         │                     │
                      │              │         │  ┌───────────────┐  │
                      │  ┌────────┐  │         │  │POST /pre_fall │  │
                      │  │  XAI   │  │         │  │ (LSTM AutoEnc)│  │
                      │  │  Why?  │◀─┼─────────┼──└───────────────┘  │
                      │  │ Dialog │  │         │                     │
                      │  └────────┘  │         │  ┌───────────────┐  │
                      │              │         │  │ POST /explain │  │
                      │              │◀────────┼──│ (SHAP Values) │  │
                      │              │         │  └───────────────┘  │
                      └──────┬───────┘         └──────────┬──────────┘
                             │                            │
                             ▼                            ▼
                      ┌──────────────┐         ┌──────────────────┐
                      │   Firebase   │         │  Trained Models  │
                      │  Realtime DB │         │                  │
                      │              │         │  • CNN (.keras)  │
                      │  • /falls    │         │  • RL  (.zip)    │
                      │  • /live     │         │  • LSTM (.h5)    │
                      │  • /sos      │         │  • Scaler (.pkl) │
                      │              │         │  • Threshold     │
                      └──────┬───────┘         │    (.json)       │
                             │                 └──────────────────┘
                             ▼
                      ┌──────────────┐
                      │    Push      │
                      │ Notification │
                      │  (FCM)       │
                      └──────────────┘
```

---

## Data Flow

### 1. Sensor Reading Flow
```
ESP32 IMU → BLE → Flutter App → HTTP POST → FastAPI → CNN Model
                                                     → RL Agent
                                                     → Response to Flutter
```

### 2. Pre-Fall Detection Flow
```
Flutter Timer(500ms) → POST /pre_fall → LSTM Autoencoder
                                      → Reconstruction Error
                                      → Compare with Threshold
                                      → Warning + Time Estimate
                                      → Yellow Banner in Flutter
```

### 3. Fall Detection Flow (Ensemble)
```
POST /predict_rl → Scale with scaler.pkl
                 → CNN: cnn_confidence (> 0.95 = fall)
                 → RL Agent: adaptive threshold + action
                 → Ensemble: CNN OR accel_mag > rl_threshold
                 → Firebase: store fall with metadata
                 → Response: fall_detected + decision reason
```

### 4. XAI Explanation Flow
```
User taps "Why?" → POST /explain → SHAP DeepExplainer
                                  → Feature importance scores
                                  → Top feature identification
                                  → Human-readable interpretation
                                  → BarChart in Flutter dialog
```

---

## Component Details

### CNN Model (sequence_cnn_model.keras)
- **Input:** (batch, 200, 6) — 200 timesteps × 6 sensor axes
- **Output:** Single probability [0, 1]
- **Threshold:** > 0.95 = fall detected
- **Preprocessing:** StandardScaler from `scaler.pkl`

### RL Agent (rl_fall_agent.zip)
- **Algorithm:** PPO (Proximal Policy Optimization)
- **Framework:** Stable-Baselines3
- **Observation:** [ax, ay, az, gx, gy, gz, accel_mag] — shape (7,)
- **Actions:** HOLD (0), MORE_SENSITIVE (1), LESS_SENSITIVE (2)
- **Threshold range:** [1.5, 5.0] g
- **Reward:** TP=+10, FP=-5, FN=-2, TN=+1

### LSTM Autoencoder (pre_fall_model.h5)
- **Input:** (batch, 10, 6) — 10 timesteps × 6 axes
- **Architecture:** Encoder LSTM(64)→LSTM(32), Decoder LSTM(32)→LSTM(64)→Dense(6)
- **Training:** Normal gait data only
- **Warning:** Reconstruction error > 95th percentile of normal

### SHAP Explainer
- **Primary:** shap.DeepExplainer
- **Fallback:** shap.KernelExplainer
- **Output:** Per-feature importance scores (sum = 1.0)

---

## File Structure (Final)

```
OPPAM/
├── fall_detection_app/               ← Flutter frontend
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/
│   │   │   ├── router/app_router.dart      (modified — added /threshold-history)
│   │   │   ├── services/firebase_service.dart
│   │   │   └── theme/app_colors.dart
│   │   ├── features/
│   │   │   ├── dashboard/screens/
│   │   │   │   └── dashboard_screen.dart   (modified — RL card, pre-fall, XAI)
│   │   │   ├── alert/
│   │   │   ├── auth/
│   │   │   └── ...
│   │   ├── screens/
│   │   │   └── threshold_history.dart      ← NEW
│   │   ├── services/
│   │   │   └── api_service.dart            ← NEW
│   │   └── shared/
│   └── pubspec.yaml
│
├── fall_server/                      ← Python FastAPI backend
│   ├── server.py                     (modified — added 3 endpoints)
│   ├── sequence_cnn_model.keras
│   ├── scaler.pkl
│   ├── firebase_key.json
│   ├── requirements.txt              ← NEW
│   ├── Dockerfile                    ← NEW
│   ├── evaluate.py                   ← NEW
│   ├── rl_agent/                     ← NEW package
│   │   ├── __init__.py
│   │   ├── environment.py
│   │   ├── train.py
│   │   └── inference.py
│   ├── pre_fall/                     ← NEW package
│   │   ├── __init__.py
│   │   ├── lstm_autoencoder.py
│   │   └── detector.py
│   ├── xai/                          ← NEW package
│   │   ├── __init__.py
│   │   └── explainer.py
│   ├── models/                       ← Created by training scripts
│   │   ├── rl_fall_agent.zip
│   │   ├── rl_training_curve.png
│   │   ├── pre_fall_model.h5
│   │   └── threshold.json
│   ├── results/                      ← Created by evaluate.py
│   │   └── comparison.png
│   └── tests/                        ← NEW
│       ├── __init__.py
│       ├── test_rl_env.py
│       └── test_endpoints.py
│
├── docker-compose.yml                ← NEW
├── .env.example                      ← NEW
├── DEMO_SCRIPT.md                    ← NEW
├── FLUTTER_SETUP.md                  ← NEW
└── ARCHITECTURE.md                   ← NEW (this file)
```

---

## API Endpoints Summary

| Method | Endpoint       | Description                        | Added |
|--------|----------------|------------------------------------|-------|
| POST   | `/predict`     | CNN-only fall detection             | ✕     |
| POST   | `/predict_rl`  | CNN + RL ensemble fall detection    | ✓     |
| POST   | `/pre_fall`    | LSTM pre-fall instability warning   | ✓     |
| POST   | `/explain`     | SHAP XAI feature explanation        | ✓     |
| POST   | `/sos`         | SOS alert relay to Firebase         | ✕     |

---

## Evaluation Methodology

1. **Test Set:** 200 events (100 falls + 100 normal) — synthetic data
2. **Models Compared:**
   - **Model A:** CNN alone (sequence_cnn_model.keras)
   - **Model B:** CNN + RL ensemble (threshold-aware detection)
3. **Metrics:** Accuracy, Sensitivity, Specificity, Precision, F1, AUC-ROC
4. **Statistical Test:** McNemar's test (p < 0.05 = significant difference)
5. **Visualizations:** Confusion matrices + metric bar chart (comparison.png)
