"""
RL Agent Training Script
========================

Trains a PPO agent on the FallDetectionEnv for 50,000 timesteps,
saves the model and plots the reward curve.

Usage::

    python -m rl_agent.train          # from fall_server/
    python rl_agent/train.py          # alternative

Outputs:
    - models/rl_fall_agent.zip          — trained PPO model
    - models/rl_training_curve.png      — reward-per-episode plot
"""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import List

import matplotlib
matplotlib.use("Agg")  # headless backend — no GUI needed
import matplotlib.pyplot as plt
import numpy as np
from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import BaseCallback

# Ensure fall_server is on the path when running as a script
_SCRIPT_DIR = Path(__file__).resolve().parent
_SERVER_DIR = _SCRIPT_DIR.parent
if str(_SERVER_DIR) not in sys.path:
    sys.path.insert(0, str(_SERVER_DIR))

from rl_agent.environment import FallDetectionEnv  # noqa: E402


# ── Callback to log reward every 1,000 steps ──────────────────────────
class RewardLoggerCallback(BaseCallback):
    """Logs cumulative episode reward at configurable step intervals."""

    def __init__(self, log_interval: int = 1_000, verbose: int = 0) -> None:
        super().__init__(verbose)
        self.log_interval = log_interval
        self.episode_rewards: List[float] = []
        self._current_episode_reward: float = 0.0

    def _on_step(self) -> bool:
        """Called after every environment step."""
        # Accumulate reward
        reward = self.locals.get("rewards", [0.0])
        if isinstance(reward, np.ndarray):
            self._current_episode_reward += float(reward[0])
        else:
            self._current_episode_reward += float(reward)

        # Check for episode end
        dones = self.locals.get("dones", [False])
        if isinstance(dones, np.ndarray):
            done = bool(dones[0])
        else:
            done = bool(dones)

        if done:
            self.episode_rewards.append(self._current_episode_reward)
            self._current_episode_reward = 0.0

        # Periodic log
        if self.num_timesteps % self.log_interval == 0:
            avg = (
                np.mean(self.episode_rewards[-10:])
                if self.episode_rewards
                else 0.0
            )
            print(
                f"  Step {self.num_timesteps:>6,d} | "
                f"Episodes: {len(self.episode_rewards):>4d} | "
                f"Avg reward (last 10): {avg:>8.2f}"
            )
        return True


def train() -> None:
    """Train PPO on FallDetectionEnv and save artefacts."""
    # Ensure output directory exists
    models_dir = _SERVER_DIR / "models"
    models_dir.mkdir(parents=True, exist_ok=True)

    print("╔══════════════════════════════════════════════╗")
    print("║  RL Fall Detection Agent — PPO Training     ║")
    print("╚══════════════════════════════════════════════╝")

    env = FallDetectionEnv()

    model = PPO(
        "MlpPolicy",
        env,
        verbose=0,
        learning_rate=3e-4,
        n_steps=256,
        batch_size=64,
        n_epochs=10,
        gamma=0.99,
        gae_lambda=0.95,
        clip_range=0.2,
        seed=42,
    )

    callback = RewardLoggerCallback(log_interval=1_000)

    print("Training for 50,000 timesteps …")
    model.learn(total_timesteps=50_000, callback=callback)

    # ── Save model ────────────────────────────────────────────────────
    model_path = models_dir / "rl_fall_agent"
    model.save(str(model_path))
    print(f"✅ Model saved → {model_path}.zip")

    # ── Plot reward curve ─────────────────────────────────────────────
    rewards = callback.episode_rewards
    if rewards:
        fig, ax = plt.subplots(figsize=(10, 5))
        ax.plot(rewards, linewidth=0.8, alpha=0.4, label="Episode reward")
        # Smoothed
        window = min(20, max(1, len(rewards) // 10))
        if len(rewards) >= window:
            smoothed = np.convolve(
                rewards, np.ones(window) / window, mode="valid"
            )
            ax.plot(
                range(window - 1, len(rewards)),
                smoothed,
                linewidth=2,
                color="crimson",
                label=f"Moving avg (w={window})",
            )
        ax.set_xlabel("Episode")
        ax.set_ylabel("Total Reward")
        ax.set_title("RL Fall Detection Agent — Training Reward Curve")
        ax.legend()
        ax.grid(True, alpha=0.3)
        fig.tight_layout()
        curve_path = models_dir / "rl_training_curve.png"
        fig.savefig(str(curve_path), dpi=150)
        plt.close(fig)
        print(f"📈 Reward curve saved → {curve_path}")
    else:
        print("⚠️  No episodes completed — reward curve not saved.")

    print("Training complete. Model saved.")


if __name__ == "__main__":
    train()
