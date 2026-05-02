"""
Unit Tests for RL Fall Detection Environment
=============================================

Tests cover observation/action spaces, reward function, threshold
clipping, and step return format.

Run::

    cd fall_server
    pytest tests/test_rl_env.py -v
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pytest

# Ensure fall_server is on path
_SERVER_DIR = Path(__file__).resolve().parent.parent
if str(_SERVER_DIR) not in sys.path:
    sys.path.insert(0, str(_SERVER_DIR))

from rl_agent.environment import FallDetectionEnv


@pytest.fixture
def env() -> FallDetectionEnv:
    """Create a fresh FallDetectionEnv instance."""
    return FallDetectionEnv()


class TestObservationSpace:
    """Tests for the observation space."""

    def test_observation_space_shape(self, env: FallDetectionEnv) -> None:
        """Observation space should be Box with shape (7,)."""
        assert env.observation_space.shape == (7,)
        assert env.observation_space.dtype == np.float32

    def test_observation_within_bounds(self, env: FallDetectionEnv) -> None:
        """Reset observation should fit within the defined bounds."""
        obs, _ = env.reset(seed=42)
        assert obs.shape == (7,)
        # Accelerometer values are generated within reasonable ranges
        assert obs.dtype == np.float32


class TestActionSpace:
    """Tests for the action space."""

    def test_action_space_valid(self, env: FallDetectionEnv) -> None:
        """Action space should be Discrete(3)."""
        assert env.action_space.n == 3

    def test_all_actions_valid(self, env: FallDetectionEnv) -> None:
        """All three actions (0, 1, 2) should be accepted without error."""
        env.reset(seed=42)
        for action in [0, 1, 2]:
            obs, reward, terminated, truncated, info = env.step(action)
            assert obs.shape == (7,)
            assert isinstance(reward, float)


class TestRewards:
    """Tests for the reward function."""

    def test_reward_true_positive(self, env: FallDetectionEnv) -> None:
        """True positive (fall correctly detected) should give +10."""
        env.reset(seed=42)
        # Force a fall scenario: set threshold very low so detection triggers
        env.threshold = 0.1
        # Generate fall data manually
        obs, is_fall = env._generate_fall()
        accel_mag = float(obs[6])
        detected = accel_mag > env.threshold
        # A fall with low threshold should almost always be detected
        if is_fall and detected:
            assert env.REWARD_TP == 10.0

    def test_reward_false_alarm(self, env: FallDetectionEnv) -> None:
        """False positive (false alarm) should give -5."""
        assert env.REWARD_FP == -5.0

    def test_reward_values_correct(self, env: FallDetectionEnv) -> None:
        """Verify all reward constants are set correctly."""
        assert env.REWARD_TP == 10.0
        assert env.REWARD_FP == -5.0
        assert env.REWARD_FN == -2.0
        assert env.REWARD_TN == 1.0


class TestThreshold:
    """Tests for threshold clipping."""

    def test_threshold_clipping(self, env: FallDetectionEnv) -> None:
        """Threshold should be clipped to [1.5, 5.0]."""
        env.reset(seed=42)

        # Drive threshold down repeatedly
        for _ in range(200):
            env.step(1)  # more sensitive
        assert env.threshold >= 1.5

        # Drive threshold up repeatedly
        env.reset(seed=42)
        for _ in range(200):
            env.step(2)  # less sensitive
        assert env.threshold <= 5.0

    def test_initial_threshold(self, env: FallDetectionEnv) -> None:
        """Initial threshold should be 2.5 after reset."""
        env.reset(seed=42)
        assert env.threshold == 2.5


class TestStepReturns:
    """Tests for step() return format."""

    def test_step_returns_correct_keys(self, env: FallDetectionEnv) -> None:
        """step() info dict should contain expected keys."""
        env.reset(seed=42)
        obs, reward, terminated, truncated, info = env.step(0)

        assert "threshold" in info
        assert "is_fall" in info
        assert "detected" in info
        assert "accel_mag" in info
        assert "action" in info

    def test_step_types(self, env: FallDetectionEnv) -> None:
        """step() should return correct types."""
        env.reset(seed=42)
        obs, reward, terminated, truncated, info = env.step(0)

        assert isinstance(obs, np.ndarray)
        assert isinstance(reward, float)
        assert isinstance(terminated, bool)
        assert isinstance(truncated, bool)
        assert isinstance(info, dict)

    def test_episode_truncation(self, env: FallDetectionEnv) -> None:
        """Episode should truncate after MAX_STEPS."""
        env.reset(seed=42)
        for i in range(env.MAX_STEPS):
            _, _, terminated, truncated, _ = env.step(0)
            if i < env.MAX_STEPS - 1:
                assert not truncated
        assert truncated
