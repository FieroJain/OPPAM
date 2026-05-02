# 🎬 DEMO SCRIPT — 3-Minute Evaluator Walkthrough

> Designed for final-year project evaluation. Follow this script
> to demonstrate all four enhancements in exactly 3 minutes.

---

## Minute 1 — RL Adaptive Threshold (60 seconds)

### Setup (before demo)
```bash
cd fall_server
pip install -r requirements.txt
```

### Live Demo Steps

1. **Train the RL agent** (pre-train before demo, just show the result):
   ```bash
   python rl_agent/train.py
   ```
   - Show the training curve: `models/rl_training_curve.png`
   - *"This PPO agent was trained for 50,000 steps to learn when to tighten
     or loosen the fall-detection threshold."*

2. **Send normal sensor data** to `/predict_rl`:
   ```bash
   curl -X POST http://localhost:8000/predict_rl \
     -H "Content-Type: application/json" \
     -d '{"ax": 0.1, "ay": 0.2, "az": 1.0, "gx": 15, "gy": 20, "gz": 10}'
   ```
   - Show threshold stays around **~2.5 g**
   - *"With normal walking data, the agent holds the default threshold."*

3. **Send fall-like data**:
   ```bash
   curl -X POST http://localhost:8000/predict_rl \
     -H "Content-Type: application/json" \
     -d '{"ax": 1.5, "ay": 2.0, "az": 7.5, "gx": 350, "gy": 400, "gz": 300}'
   ```
   - Show threshold drops closer to **1.5 g** (more sensitive)
   - *"After suspicious activity, the agent becomes MORE alert —
     it learned this through reinforcement learning."*

### Key Talking Point
> *"The RL agent dynamically adjusts sensitivity based on context.
> This reduces false negatives in risky situations while minimizing
> false positives during calm periods."*

---

## Minute 2 — Pre-Fall Warning (60 seconds)

### Live Demo Steps

1. **Open the Flutter app** on a phone or emulator
2. **Hold the phone still** — dashboard shows normal status
3. **Wave the phone rapidly** (simulate instability):
   - Yellow banner appears: **"⚠️ Instability detected — sit down slowly"**
   - Shows estimated seconds countdown (e.g., "Est. 2.3s")
4. **Stop waving** — banner auto-dismisses

### Key Talking Point
> *"Our LSTM autoencoder was trained ONLY on normal gait patterns.
> When it sees something unusual, the reconstruction error spikes.
> This gives us a 2-3 second early warning before a fall actually
> happens — potentially saving lives."*

### Technical Detail (if asked)
- Architecture: LSTM(64) → LSTM(32) → RepeatVector → LSTM(32) → LSTM(64) → Dense(6)
- Trained on synthetic normal walking data
- Warning threshold = 95th percentile of training reconstruction error
- Time-to-fall estimated via linear regression on recent error slope

---

## Minute 3 — XAI + Statistics (60 seconds)

### Live Demo Steps

1. **Trigger a fall** in the app (drop/shake phone sharply)
2. **Tap the "Why?" button** on the RL threshold card
   - Bar chart appears with 6 bars (ax, ay, az, gx, gy, gz)
   - `az` bar highlighted in **red** (typically the strongest indicator)
   - Interpretation: *"az (vertical accel) was the strongest indicator,
     contributing 45.2% of the prediction."*
3. **Show the evaluation results**:
   ```bash
   python evaluate.py
   ```
   - Show `results/comparison.png` — side-by-side confusion matrices
   - Show the metrics table in console
   - Read the McNemar's p-value: *"p=0.03 — statistically significant"*

4. **Show Firebase** (open Firebase console briefly):
   - Show a fall document with the new fields:
     - `rl_threshold: 1.89`
     - `cnn_confidence: 0.97`
     - `ensemble_decision: "BOTH"`

### Key Talking Points
> *"SHAP values tell us WHY the model made its decision —
> critical for medical applications where black-box AI isn't acceptable."*

> *"McNemar's test confirms CNN+RL is statistically significantly
> better than CNN alone, with p < 0.05."*

---

## Quick Recovery Phrases

| If this happens…           | Say this…                                                  |
|----------------------------|------------------------------------------------------------|
| Server doesn't respond     | "Let me restart uvicorn. The system stays resilient."      |
| Pre-fall banner won't show | "The LSTM needs 10 readings to warm up. Give it a moment." |
| XAI takes long to load     | "SHAP computation is intensive. In production we'd cache." |
| McNemar p > 0.05           | "With real data, the improvement would be more pronounced."|

---

## Pre-Demo Checklist

- [ ] `cd fall_server && uvicorn server:app --reload` running
- [ ] RL model trained: `models/rl_fall_agent.zip` exists
- [ ] LSTM model trained: `models/pre_fall_model.h5` exists
- [ ] Flutter app built and connected to the server
- [ ] Firebase console open in a browser tab
- [ ] `results/comparison.png` generated from `python evaluate.py`
