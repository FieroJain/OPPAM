from __future__ import annotations
import math
from typing import Any, Dict, Optional, Tuple
import gymnasium as gym
import numpy as np
from gymnasium import spaces

class FallDetectionEnv(gym.Env):
    metadata: Dict[str, Any] = {"render_modes": ["human"]}
    THRESHOLD_MIN: float = 1.8
    THRESHOLD_MAX: float = 3.5
    THRESHOLD_INIT: float = 2.5
    REWARD_TP: float = 10.0
    REWARD_FP: float = -5.0
    REWARD_FN: float = -8.0
    REWARD_TN: float = 2.0
    REWARD_RELAX_BONUS: float = 3.0
    MAX_STEPS: int = 500

    def __init__(self, render_mode=None):
        super().__init__()
        self.render_mode = render_mode
        self.observation_space = spaces.Box(low=-500.0, high=500.0, shape=(7,), dtype=np.float32)
        self.action_space = spaces.Discrete(3)
        self.threshold = self.THRESHOLD_INIT
        self.step_count = 0
        self._rng = np.random.default_rng()
        self._calm_streak = 0

    def _generate_normal(self):
        ax = self._rng.uniform(-5.0, 5.0)
        ay = self._rng.uniform(-5.0, 5.0)
        az = self._rng.uniform(95.0, 105.0)
        gx = self._rng.uniform(-15.0, 15.0)
        gy = self._rng.uniform(-15.0, 15.0)
        gz = self._rng.uniform(-15.0, 15.0)
        accel_mag = math.sqrt((ax/100)**2 + (ay/100)**2 + (az/100)**2)
        return np.array([ax, ay, az, gx, gy, gz, accel_mag], dtype=np.float32), False

    def _generate_calm(self):
        ax = self._rng.uniform(-2.0, 2.0)
        ay = self._rng.uniform(-2.0, 2.0)
        az = self._rng.uniform(98.0, 102.0)
        gx = self._rng.uniform(-5.0, 5.0)
        gy = self._rng.uniform(-5.0, 5.0)
        gz = self._rng.uniform(-5.0, 5.0)
        accel_mag = math.sqrt((ax/100)**2 + (ay/100)**2 + (az/100)**2)
        return np.array([ax, ay, az, gx, gy, gz, accel_mag], dtype=np.float32), False

    def _generate_fall(self):
        ax = self._rng.uniform(-200.0, 200.0)
        ay = self._rng.uniform(-200.0, 200.0)
        az = self._rng.uniform(300.0, 800.0)
        gx = self._rng.uniform(200.0, 500.0)
        gy = self._rng.uniform(200.0, 500.0)
        gz = self._rng.uniform(200.0, 500.0)
        accel_mag = math.sqrt((ax/100)**2 + (ay/100)**2 + (az/100)**2)
        return np.array([ax, ay, az, gx, gy, gz, accel_mag], dtype=np.float32), True

    def reset(self, *, seed=None, options=None):
        super().reset(seed=seed)
        if seed is not None:
            self._rng = np.random.default_rng(seed)
        self.threshold = self.THRESHOLD_INIT
        self.step_count = 0
        self._calm_streak = 0
        obs, _ = self._generate_normal()
        return obs, {"threshold": self.threshold}

    def step(self, action):
        if action == 1:
            self.threshold = max(self.THRESHOLD_MIN, self.threshold - 0.15)
        elif action == 2:
            self.threshold = min(self.THRESHOLD_MAX, self.threshold + 0.15)
        self.threshold = float(np.clip(self.threshold, self.THRESHOLD_MIN, self.THRESHOLD_MAX))

        rand = self._rng.random()
        if rand < 0.15:
            obs, is_fall = self._generate_fall()
            self._calm_streak = 0
        elif rand < 0.40:
            obs, is_fall = self._generate_calm()
            self._calm_streak += 1
        else:
            obs, is_fall = self._generate_normal()
            self._calm_streak = max(0, self._calm_streak - 1)

        accel_mag = float(obs[6])
        detected = accel_mag > self.threshold

        if is_fall and detected:
            reward = self.REWARD_TP
        elif not is_fall and detected:
            reward = self.REWARD_FP
        elif is_fall and not detected:
            reward = self.REWARD_FN
        else:
            reward = self.REWARD_TN
            if self._calm_streak > 5 and action == 2:
                reward += self.REWARD_RELAX_BONUS

        self.step_count += 1
        info = {"threshold": self.threshold, "is_fall": is_fall,
                "detected": detected, "accel_mag": accel_mag,
                "action": action, "calm_streak": self._calm_streak}
        return obs, reward, False, self.step_count >= self.MAX_STEPS, info

    def render(self):
        print(f"Step {self.step_count:>4d} | Threshold: {self.threshold:.3f}g")