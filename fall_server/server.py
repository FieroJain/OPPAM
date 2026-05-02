"""
Fall Detection Server
"""
from __future__ import annotations
import math
import traceback
from collections import deque
from datetime import datetime
from typing import Any, Dict
import joblib
import numpy as np
import tensorflow as tf
import firebase_admin
from firebase_admin import credentials, db
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pydantic import BaseModel

import requests as _requests
from google.oauth2 import service_account
import google.auth.transport.requests as _google_auth_transport

def _get_fcm_token():
    try:
        creds = service_account.Credentials.from_service_account_file(
            'fcm_service_account.json',
            scopes=['https://www.googleapis.com/auth/firebase.messaging']
        )
        creds.refresh(_google_auth_transport.Request())
        return creds.token
    except Exception as e:
        print(f"FCM token error: {e}")
        return None

def send_fcm_notification(title: str, body: str):
    try:
        token = _get_fcm_token()
        if not token:
            return
        _requests.post(
            "https://fcm.googleapis.com/v1/projects/fallproject01/messages:send",
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            json={
                "message": {
                    "topic": "fall_alerts",
                    "notification": {"title": title, "body": body},
                    "android": {"priority": "high"},
                }
            },
            timeout=5,
        )
        print("FCM sent!")
    except Exception as e:
        print(f"FCM error: {e}")

app = FastAPI(title="Fall Detection API", version="2.0.0",
              description="CNN + RL + LSTM + XAI fall detection system")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

model = tf.keras.models.load_model("sequence_cnn_model.h5", compile=False)
scaler = joblib.load("scaler.pkl")
print("Model loaded! Input shape:", model.input_shape)

cred = credentials.Certificate("firebase_key.json")
firebase_admin.initialize_app(cred, {"databaseURL": "https://fallproject01-default-rtdb.asia-southeast1.firebasedatabase.app"})
print("Firebase connected!")

WINDOW_SIZE = 200
FEATURES = 6
buffer: list = []
_lstm_buffer: deque = deque(maxlen=10)
_lstm_model = None
_lstm_threshold = 3.5

class SensorData(BaseModel):
    ax: float
    ay: float
    az: float
    gx: float
    gy: float
    gz: float

def get_rl_threshold_fn():
    try:
        from rl_agent.inference import get_dynamic_threshold
        return get_dynamic_threshold
    except Exception as e:
        print(f"RL not loaded: {e}")
        return None

def get_lstm():
    global _lstm_model, _lstm_threshold
    if _lstm_model is None:
        try:
            from pathlib import Path
            import json
            lstm_path = Path(__file__).parent / "models" / "pre_fall_model.h5"
            _lstm_model = tf.keras.models.load_model(str(lstm_path), compile=False)
            thr_path = Path(__file__).parent / "models" / "threshold.json"
            if thr_path.exists():
                with open(thr_path) as f:
                    _lstm_threshold = json.load(f).get("threshold", 3.5)
            print(f"LSTM loaded, threshold={_lstm_threshold:.3f}")
        except Exception as e:
            print(f"LSTM not loaded: {e}")
    return _lstm_model

def _compute_rl_and_lstm(data: SensorData) -> dict:
    reading = [data.ax, data.ay, data.az, data.gx, data.gy, data.gz]
    a_mag = math.sqrt(data.ax**2 + data.ay**2 + data.az**2)
    rl_thr = 2.5
    action = "HOLD"
    get_threshold = get_rl_threshold_fn()
    if get_threshold is not None:
        try:
            ax_n = data.ax / 100.0
            ay_n = data.ay / 100.0
            az_n = data.az / 100.0
            gx_n = data.gx / 5.0
            gy_n = data.gy / 5.0
            gz_n = data.gz / 5.0
            a_mag_n = math.sqrt(ax_n**2 + ay_n**2 + az_n**2)
            features = np.array([ax_n, ay_n, az_n, gx_n, gy_n, gz_n, a_mag_n], dtype=np.float32)
            rl_thr, _, action = get_threshold(features)
        except Exception:
            pass
    _lstm_buffer.append(np.array(reading, dtype=np.float32))
    lstm = get_lstm()
    pre_fall_warning = False
    error_score = 0.0
    if lstm is not None:
        try:
            if len(_lstm_buffer) < 10:
                window = np.tile(_lstm_buffer[0] if _lstm_buffer else reading, (10, 1))
            else:
                window = np.array(list(_lstm_buffer))
            window = window.reshape(1, 10, 6)
            reconstructed = lstm.predict(window, verbose=0)
            error_score = float(np.mean(np.abs(window - reconstructed)))
            pre_fall_warning = bool(error_score > _lstm_threshold)
        except Exception:
            pass
    return {"rl_threshold": round(rl_thr, 3), "rl_action": action,
            "pre_fall_warning": pre_fall_warning, "pre_fall_error": round(error_score, 4),
            "a_mag": round(a_mag, 4)}

def _write_live_to_firebase(data: SensorData, confidence: float, extras: dict):
    try:
        db.reference("/live").set({
            "confidence": round(confidence, 3),
            "rl_threshold": extras.get("rl_threshold", 2.5),
            "rl_action": extras.get("rl_action", "HOLD"),
            "pre_fall_warning": extras.get("pre_fall_warning", False),
            "pre_fall_error": extras.get("pre_fall_error", 0.0),
            "ax": round(data.ax, 4), "ay": round(data.ay, 4), "az": round(data.az, 4),
            "gx": round(data.gx, 4), "gy": round(data.gy, 4), "gz": round(data.gz, 4),
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        })
    except Exception as e:
        print(f"Firebase /live write error: {e}")

@app.post("/predict")
def predict(data: SensorData):
    global buffer
    reading = [data.ax, data.ay, data.az, data.gx, data.gy, data.gz]
    buffer.append(reading)
    if len(buffer) > WINDOW_SIZE:
        buffer.pop(0)
    extras = _compute_rl_and_lstm(data)
    a_mag = extras["a_mag"]
    if len(buffer) < WINDOW_SIZE:
        if a_mag > 80.0:

            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            try:
                db.reference("/falls").push({"fall_detected": True, "confidence": 0.85,
                    "timestamp": timestamp, "ax": round(data.ax, 2), "ay": round(data.ay, 2),
                    "az": round(data.az, 2), "detection_method": "impact_during_collection"})
                buffer.clear()
                print(f"IMPACT FALL during collection! a_mag={a_mag:.2f}")
            except Exception as e:
                print(f"Firebase error: {e}")
            _write_live_to_firebase(data, 0.85, extras)
            return {"fall_detected": True, "confidence": 0.85, "reason": "impact_detected"}
        _write_live_to_firebase(data, 0.0, extras)
        return {"status": "collecting", "samples": len(buffer)}
    if a_mag < 30.0:
        _write_live_to_firebase(data, 0.0, extras)
        return {"fall_detected": False, "confidence": 0.0, "reason": "no_significant_movement"}
    input_data = np.array(buffer, dtype=np.float32).reshape(-1, FEATURES)
    input_data = scaler.transform(input_data).reshape(1, WINDOW_SIZE, FEATURES)
    prob = float(model.predict(input_data, verbose=0)[0][0])
    fall_detected = prob > 0.7
    if fall_detected:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        if prob > 0.95 and a_mag > 200:
            severity = "Severe"
        elif prob > 0.85 or a_mag > 150:
            severity = "Moderate"
        else:
            severity = "Mild"
        try:
            db.reference("/falls").push({
                "fall_detected": True,
                "confidence": round(prob, 3),
                "severity": severity,
                "timestamp": timestamp,
                "ax": round(data.ax, 2),
                "ay": round(data.ay, 2),
                "az": round(data.az, 2),
            })
            buffer.clear()
            print(f"FALL DETECTED! conf={prob:.3f} at {timestamp}")
            send_fcm_notification(
                "Fall Detected!",
                f"Patient may have fallen! Confidence: {round(prob*100)}% Severity: {severity}"
            )
        except Exception as e:
            print(f"Firebase error: {e}")
    _write_live_to_firebase(data, prob, extras)
    return {"fall_detected": fall_detected, "confidence": round(prob, 3)}

@app.post("/sos")
def sos_alert(payload: dict = None):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        db.reference("/sos").push({"sos": True, "timestamp": timestamp,
                                   "message": "SOS button pressed by patient!"})
        print(f"SOS ALERT! at {timestamp}")
    except Exception as e:
        print(f"Firebase SOS error: {e}")
    return {"sos_received": True, "timestamp": timestamp}

@app.post("/predict_rl")
async def predict_rl(data: SensorData) -> Dict[str, Any]:
    try:
        reading = [data.ax, data.ay, data.az, data.gx, data.gy, data.gz]
        accel_mag = math.sqrt(data.ax**2 + data.ay**2 + data.az**2)
        global buffer
        buffer.append(reading)
        if len(buffer) > WINDOW_SIZE:
            buffer.pop(0)
        cnn_confidence = 0.0
        cnn_fall = False
        if len(buffer) >= WINDOW_SIZE:
            inp = np.array(buffer, dtype=np.float32).reshape(-1, FEATURES)
            inp = scaler.transform(inp).reshape(1, WINDOW_SIZE, FEATURES)
            cnn_confidence = float(model.predict(inp, verbose=0)[0][0])
            cnn_fall = cnn_confidence > 0.95
        rl_threshold = 2.5
        action_label = "HOLD"
        get_threshold = get_rl_threshold_fn()
        if get_threshold is not None:
            try:
                ax_n = data.ax/100.0; ay_n = data.ay/100.0; az_n = data.az/100.0
                gx_n = data.gx/5.0; gy_n = data.gy/5.0; gz_n = data.gz/5.0
                a_mag_n = math.sqrt(ax_n**2+ay_n**2+az_n**2)
                features = np.array([ax_n,ay_n,az_n,gx_n,gy_n,gz_n,a_mag_n], dtype=np.float32)
                rl_threshold, _, action_label = get_threshold(features)
            except Exception as e:
                print(f"RL inference error: {e}")
        rl_triggered = accel_mag > (rl_threshold * 100)
        fall_detected = cnn_fall or rl_triggered
        if cnn_fall and rl_triggered: ensemble = "BOTH"
        elif cnn_fall: ensemble = "CNN_TRIGGERED"
        elif rl_triggered: ensemble = "RL_TRIGGERED"
        else: ensemble = "NONE"
        if fall_detected:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            try:
                db.reference("/falls").push({"fall_detected": True,
                    "confidence": round(cnn_confidence, 3), "rl_threshold": round(rl_threshold, 3),
                    "ensemble_decision": ensemble, "timestamp": timestamp})
            except Exception: pass
        return {"fall_detected": fall_detected, "cnn_confidence": round(cnn_confidence, 4),
                "rl_threshold": round(rl_threshold, 4), "action_taken": action_label,
                "ensemble_decision": ensemble}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"RL prediction error: {e}")

@app.post("/pre_fall")
async def pre_fall(data: SensorData) -> Dict[str, Any]:
    try:
        reading = np.array([data.ax, data.ay, data.az, data.gx, data.gy, data.gz], dtype=np.float32)
        _lstm_buffer.append(reading)
        lstm = get_lstm()
        if lstm is None:
            return {"warning": False, "error_score": 0.0, "estimated_seconds": None}
        if len(_lstm_buffer) < 10:
            window = np.tile(reading, (10, 1))
        else:
            window = np.array(list(_lstm_buffer))
        window = window.reshape(1, 10, 6)
        reconstructed = lstm.predict(window, verbose=0)
        error_score = float(np.mean(np.abs(window - reconstructed)))
        warning = bool(error_score > _lstm_threshold)
        estimated_seconds = round(5.0-(error_score/_lstm_threshold)*3, 1) if warning else None
        return {"warning": warning, "error_score": round(error_score, 4), "estimated_seconds": estimated_seconds}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Pre-fall error: {e}")

@app.post("/explain")
async def explain(data: SensorData) -> Dict[str, Any]:
    try:
        reading = np.array([data.ax, data.ay, data.az, data.gx, data.gy, data.gz], dtype=np.float32)
        feature_names = ["ax", "ay", "az", "gx", "gy", "gz"]
        if len(buffer) >= WINDOW_SIZE:
            inp = np.array(buffer, dtype=np.float32).reshape(-1, FEATURES)
            inp = scaler.transform(inp).reshape(1, WINDOW_SIZE, FEATURES)
            base_conf = float(model.predict(inp, verbose=0)[0][0])
        else:
            window = np.tile(reading, (WINDOW_SIZE, 1))
            scaled = scaler.transform(window).reshape(1, WINDOW_SIZE, FEATURES)
            base_conf = float(model.predict(scaled, verbose=0)[0][0])
        importances = {}
        for i, name in enumerate(feature_names):
            perturbed = reading.copy(); perturbed[i] = 0.0
            window = np.tile(perturbed, (WINDOW_SIZE, 1))
            scaled = scaler.transform(window).reshape(1, WINDOW_SIZE, FEATURES)
            conf = float(model.predict(scaled, verbose=0)[0][0])
            importances[name] = round(abs(base_conf - conf), 4)
        total = sum(importances.values()) or 1.0
        importances = {k: round(v/total, 4) for k, v in importances.items()}
        top_feature = max(importances, key=importances.get)
        labels = {"ax": "X-axis acceleration", "ay": "Y-axis acceleration",
                  "az": "Z-axis acceleration (vertical)", "gx": "X-axis rotation",
                  "gy": "Y-axis rotation", "gz": "Z-axis rotation"}
        return {"importance": importances, "top_feature": top_feature,
                "top_value": importances[top_feature],
                "interpretation": f"Fall detected primarily due to {labels[top_feature]}",
                "cnn_confidence": round(base_conf, 4)}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Explanation error: {e}")
