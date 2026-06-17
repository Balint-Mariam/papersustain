from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pandas as pd

from analysis_common import (
    DATA_CLEAN_RAW,
    DATA_MODEL_DIFF,
    DATA_MODEL_LEVELS,
    DATA_PROCESSED_DIR,
    DATE_COL,
    LOGS_DIR,
    OUTPUT_DIR,
    ROOT,
    TABLES_DIR,
    ensure_directories,
    format_date,
    relative_path,
)


SCRIPTS = [
    "01_data_audit.py",
    "02_data_transformations.py",
    "03_descriptive_analysis.py",
    "04_pre_model_tests.py",
]


def run_script(script_name: str) -> None:
    print(f"\n=== Running {script_name} ===")
    result = subprocess.run(
        [sys.executable, str(ROOT / script_name)],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if result.stdout:
        print(result.stdout.strip())
    if result.stderr:
        print(result.stderr.strip())
    if result.returncode != 0:
        raise RuntimeError(f"{script_name} failed with exit code {result.returncode}.")


def created_files() -> list[Path]:
    roots = [DATA_PROCESSED_DIR, OUTPUT_DIR]
    files: list[Path] = []
    for root in roots:
        if root.exists():
            files.extend(path for path in root.rglob("*") if path.is_file())
    return sorted(files)


def audit_problems() -> list[str]:
    problems: list[str] = []
    log_path = LOGS_DIR / "data_audit.log"
    if log_path.exists():
        for line in log_path.read_text(encoding="utf-8").splitlines():
            if "WARNING" in line or "ERROR" in line:
                problems.append(line)

    nonpositive_path = TABLES_DIR / "nonpositive_log_values.csv"
    if nonpositive_path.exists():
        nonpositive = pd.read_csv(nonpositive_path)
        if not nonpositive.empty:
            problems.append(f"Nonpositive log values reported in {relative_path(nonpositive_path)}")

    return problems


def print_final_summary() -> None:
    clean_df = pd.read_csv(DATA_CLEAN_RAW, parse_dates=[DATE_COL])
    diff_df = pd.read_csv(DATA_MODEL_DIFF, parse_dates=[DATE_COL])
    levels_df = pd.read_csv(DATA_MODEL_LEVELS, parse_dates=[DATE_COL])
    problems = audit_problems()

    print("\n=== Final summary ===")
    print("Created files:")
    for path in created_files():
        print(f"- {relative_path(path)}")

    print(f"\nSample period: {format_date(clean_df[DATE_COL].min())} to {format_date(clean_df[DATE_COL].max())}")
    print(f"Raw observations retained: {len(clean_df)}")
    print(f"data_model_diff observations: {len(diff_df)}")
    print(f"data_model_levels observations: {len(levels_df)}")

    print("\nProblems and warnings:")
    if problems:
        for problem in problems:
            print(f"- {problem}")
    else:
        print("- None recorded.")

    print("\nRecommendation: use data_processed/data_model_diff.csv as the main candidate set.")
    print("Keep data_processed/data_model_levels.csv for CPI/CISS stationarity comparison and robustness.")
    print("\nExact command to rerun the full analysis:")
    print("py run_analysis.py")


def main() -> None:
    ensure_directories()
    for script_name in SCRIPTS:
        run_script(script_name)
    print_final_summary()


if __name__ == "__main__":
    main()

