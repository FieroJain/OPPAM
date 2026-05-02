from __future__ import annotations
import sys
from pathlib import Path
from typing import Optional
import numpy as np
from stable_baselines3 import PPO

_SCRIPT_DIR = Path(__file__).resolve().parent
_SERVER_DIR = _SCRIPT_DIR.parent
if str(_SERVER_DIR) not in sys.path:
    sys.path.insert(0, str(_SERVER_DIR))

_model: Optional[PPO] = None
_current_threshold: float = 2.5

_ACTION_LABELS = {0: "HOLD", 1: "MORE_SENSITIVE", 2: "RELAX"}

def _load_model() -> PPO:
    global _model
    if _model is None:
        model_path = _SERVER_DIR / "models" / "rl_fall_agent.zip"
        if not model_path.exists():
            raise FileNotFoundError(f"RL model not found at {model_path}.")
        _model = PPO.load(str(model_path))
        print(f"✅ RL model loaded from {model_path}")
    return _model

def get_dynamic_threshold(features: np.ndarray) -> tuple[float, int, str]:
    global _current_threshold
    model = _load_model()
    obs = np.asarray(features, dtype=np.float32).reshape(1, -1)
    action, _ = model.predict(obs, deterministic=True)
    action = int(action)
    if action == 1:
        _current_threshold = max(1.8, _current_threshold - 0.15)
    elif action == 2:
        _current_threshold = min(3.5, _current_threshold + 0.15)
    label = _ACTION_LABELS.get(action, "HOLD")
    return _current_threshold, action, label

def get_action_label(action: int) -> str:
    return _ACTION_LABELS.get(action, "UNKNOWN")