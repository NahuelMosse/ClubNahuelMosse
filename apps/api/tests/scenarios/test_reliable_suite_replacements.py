"""Replacements of frozen tests of test_reliable_suite.py (see `replaces:` in the Log of the card)."""

import os
import subprocess
import sys
from pathlib import Path

API_ROOT = Path(__file__).resolve().parents[2]
SCENARIO = "tests/scenarios/test_error_log.py"


def _run(*arguments: str, env: dict[str, str]) -> "subprocess.CompletedProcess[str]":
    return subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider", *arguments],
        cwd=API_ROOT, env=env, capture_output=True, text=True, timeout=300, check=False,
    )  # fmt: skip


def _env(remove: tuple[str, ...] = (), add: dict[str, str] | None = None) -> dict[str, str]:
    return {k: v for k, v in os.environ.items() if k not in remove} | (add or {})


def _fails_for_lack_of_emulator(run: "subprocess.CompletedProcess[str]") -> None:
    output = run.stdout + run.stderr
    assert run.returncode != 0
    assert "the Firebase Auth emulator is required" in output
    assert "error" in output.lower()


def test_with_the_emulator_variable_missing_the_run_fails_with_the_emulator_message() -> None:
    """with the emulator variable missing the run exits non-zero and says the emulator is required
    @REV-08-S5 @assumption:REV-08-ASM-10
    """
    run = _run(SCENARIO, env=_env(remove=("FIREBASE_AUTH_EMULATOR_HOST",)))

    _fails_for_lack_of_emulator(run)


def test_with_the_emulator_off_the_run_fails_with_the_emulator_message() -> None:
    """with the emulator off the run exits non-zero and says the emulator is required
    @REV-08-S5 @assumption:REV-08-ASM-10
    """
    run = _run(SCENARIO, env=_env(add={"FIREBASE_AUTH_EMULATOR_HOST": "127.0.0.1:9"}))

    _fails_for_lack_of_emulator(run)
