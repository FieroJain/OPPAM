# 📱 Flutter Setup Guide

Step-by-step guide to integrate the enhanced fall detection features
into the Flutter app.

---

## 1. API Service (New File)

**File:** `lib/services/api_service.dart`

This is a **new file** that provides static methods for all four API endpoints:

| Method               | Endpoint       | Purpose                        |
|----------------------|----------------|--------------------------------|
| `predictFall()`      | `/predict`     | Original CNN-only detection    |
| `predictRL()`        | `/predict_rl`  | CNN + RL ensemble detection    |
| `getPreFallWarning()`| `/pre_fall`    | LSTM pre-fall warning          |
| `getExplanation()`   | `/explain`     | XAI SHAP feature importance    |

### Changing the Base URL

In `lib/services/api_service.dart`, line 10:
```dart
static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
```

For **physical device** (same WiFi):
```dart
static const String baseUrl = 'http://192.168.X.X:8000'; // Your PC's local IP
```

For **production**:
```dart
static const String baseUrl = 'https://your-server.com'; // HTTPS recommended
```

---

## 2. Dashboard Screen Modifications

**File:** `lib/features/dashboard/screens/dashboard_screen.dart`

### New Imports (Lines 1–14)
```dart
import 'dart:async';                         // ADDED — for Timer
import 'package:fl_chart/fl_chart.dart';     // ADDED — for XAI bar chart
import '../../../services/api_service.dart'; // ADDED — API calls
```

### New State Variables (after line 31)
- `_rlThreshold` — current adaptive threshold from RL agent
- `_preFallWarning` — whether instability is detected
- `_preFallTimer` — Timer.periodic for 500ms pre-fall polling
- `_lastSensorData` — most recent sensor reading for API calls

### New Widgets
1. **Pre-fall warning banner** — yellow Container shown when `_preFallWarning == true`
2. **`_buildRLThresholdCard()`** — shows current RL threshold with color coding
3. **"Why?" button** — triggers `_showExplanationDialog()` which calls `/explain`
   and renders a `BarChart` with SHAP feature importances

### New Methods
- `_pollPreFall()` — called every 500ms to check instability
- `_showExplanationDialog()` — shows XAI bar chart dialog

---

## 3. Threshold History Screen (New File)

**File:** `lib/screens/threshold_history.dart`

A full-screen `LineChart` showing RL threshold values over the last 5 minutes.

Features:
- Polls `/predict_rl` every 1 second
- Stores up to 300 data points
- X-axis: time (MM:SS), Y-axis: threshold (1.5 to 5.0)
- Reference line at 2.5g (default threshold)
- Touch interactions for tooltip values

---

## 4. Route Registration

**File:** `lib/core/router/app_router.dart`

Added after the `/hospitals` route:
```dart
// ADDED — RL Threshold History
GoRoute(
  path: '/threshold-history',
  builder: (context, state) => const ThresholdHistoryScreen(),
),
```

Import added:
```dart
import 'package:fall_detection_app/screens/threshold_history.dart';
```

---

## 5. pubspec.yaml

The following dependencies are already present in puspec.yaml:
```yaml
fl_chart: ^0.70.2    # Charts (bar chart for XAI, line chart for threshold)
http: ^1.2.0         # HTTP client for API calls
```

If they're missing for any reason, add them under `dependencies:` and run:
```bash
flutter pub get
```

---

## 6. Firebase Firestore Fields

When a fall is detected via `/predict_rl`, the Firebase document now includes:

| Field               | Type   | Description                              |
|---------------------|--------|------------------------------------------|
| `fall_detected`     | bool   | Whether fall was detected                |
| `confidence`        | double | CNN model confidence                     |
| `rl_threshold`      | double | Current RL adaptive threshold            |
| `ensemble_decision` | string | "CNN_TRIGGERED" / "RL_TRIGGERED" / "BOTH"|
| `timestamp`         | string | ISO 8601 timestamp                       |
| `ax`, `ay`, `az`    | double | Accelerometer readings at detection time |

These are **additions** — all existing fields are preserved.

---

## 7. Build & Run

```bash
# Terminal 1: Start the Python backend
cd fall_server
pip install -r requirements.txt
python rl_agent/train.py           # Train RL agent (once)
python pre_fall/lstm_autoencoder.py # Train LSTM (once)
uvicorn server:app --host 0.0.0.0 --port 8000 --reload

# Terminal 2: Run the Flutter app
cd fall_detection_app
flutter pub get
flutter run
```

---

## Common Issues

| Issue | Solution |
|-------|---------|
| `Connection refused` | Check `baseUrl` matches your server IP |
| SHAP takes too long | First call loads background data; subsequent calls are fast |
| Pre-fall timer drain | Timer is cancelled in `dispose()` — verifiable in logs |
| RL model not found | Run `python rl_agent/train.py` first |
| LSTM model not found | Run `python pre_fall/lstm_autoencoder.py` first |
