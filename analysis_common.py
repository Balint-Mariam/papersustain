from __future__ import annotations

import re
from pathlib import Path

import numpy as np
import pandas as pd


ROOT = Path(__file__).resolve().parent
INPUT_FILE = ROOT / "date sustain.xlsx"
SHEET_NAME = "value"
DATE_COL = "Date"

EXPECTED_COLUMNS = [
    "Date",
    "GB Corp Index",
    "Corp Bond Index",
    "GE Index TR",
    "Stoxx600 TR",
    "Power Energy Price",
    "Brent",
    "TTF",
    "EUA",
    "Bund 2Y",
    "CPI EU",
    "Industrial Production",
    "CISS",
]

NUMERIC_COLUMNS = [column for column in EXPECTED_COLUMNS if column != DATE_COL]

STRICTLY_POSITIVE_COLUMNS = [
    "GB Corp Index",
    "Corp Bond Index",
    "GE Index TR",
    "Stoxx600 TR",
    "Power Energy Price",
    "Brent",
    "TTF",
    "EUA",
    "Industrial Production",
]

DATA_PROCESSED_DIR = ROOT / "data_processed"
OUTPUT_DIR = ROOT / "output"
TABLES_DIR = OUTPUT_DIR / "tables"
LOGS_DIR = OUTPUT_DIR / "logs"
RAW_FIGURES_DIR = OUTPUT_DIR / "figures" / "raw_series"
TRANSFORMED_FIGURES_DIR = OUTPUT_DIR / "figures" / "transformed_series"
ACF_PACF_FIGURES_DIR = OUTPUT_DIR / "figures" / "acf_pacf"
CORRELATION_FIGURES_DIR = OUTPUT_DIR / "figures" / "correlations"

DATA_CLEAN_RAW = DATA_PROCESSED_DIR / "data_clean_raw.csv"
DATA_TRANSFORMED_COMPLETE = DATA_PROCESSED_DIR / "data_transformed_complete.csv"
DATA_MODEL_DIFF = DATA_PROCESSED_DIR / "data_model_diff.csv"
DATA_MODEL_LEVELS = DATA_PROCESSED_DIR / "data_model_levels.csv"

MODEL_DIFF_COLUMNS = [
    "Date",
    "EUA_ret",
    "TTF_ret",
    "Brent_ret",
    "Power_ret",
    "CPI_yoy_change",
    "IP_growth",
    "Bund2Y_change_bps",
    "CISS_change",
    "GreenEquity_relative",
    "GreenBond_relative",
]

MODEL_LEVEL_COLUMNS = [
    "Date",
    "EUA_ret",
    "TTF_ret",
    "Brent_ret",
    "Power_ret",
    "CPI_yoy_level",
    "IP_growth",
    "Bund2Y_change_bps",
    "CISS_level",
    "GreenEquity_relative",
    "GreenBond_relative",
]

TRANSFORMED_COLUMNS = [
    "EUA_ret",
    "TTF_ret",
    "Brent_ret",
    "Power_ret",
    "IP_growth",
    "Bund2Y_change_bps",
    "CPI_yoy_level",
    "CPI_yoy_change",
    "CISS_level",
    "CISS_change",
    "GE_return",
    "Stoxx600_return",
    "GreenEquity_relative",
    "GreenEquity_relative_check",
    "GreenBond_return",
    "CorpBond_return",
    "GreenBond_relative",
    "GreenBond_relative_check",
]

RAW_UNITS = {
    "GB Corp Index": "Index level",
    "Corp Bond Index": "Index level",
    "GE Index TR": "Index level",
    "Stoxx600 TR": "Index level",
    "Power Energy Price": "Price level",
    "Brent": "Price level",
    "TTF": "Price level",
    "EUA": "Price level",
    "Bund 2Y": "Yield level, decimal fraction",
    "CPI EU": "Percentage points",
    "Industrial Production": "Index level",
    "CISS": "Index level",
}

TRANSFORMED_UNITS = {
    "EUA_ret": "Log return, decimal form",
    "TTF_ret": "Log return, decimal form",
    "Brent_ret": "Log return, decimal form",
    "Power_ret": "Log return, decimal form",
    "IP_growth": "Log growth, decimal form",
    "Bund2Y_change_bps": "Basis points",
    "CPI_yoy_level": "Percentage points",
    "CPI_yoy_change": "Percentage points",
    "CISS_level": "Index level",
    "CISS_change": "Index change",
    "GE_return": "Log return, decimal form",
    "Stoxx600_return": "Log return, decimal form",
    "GreenEquity_relative": "Relative log return, decimal form",
    "GreenEquity_relative_check": "Relative log return, decimal form",
    "GreenBond_return": "Log return, decimal form",
    "CorpBond_return": "Log return, decimal form",
    "GreenBond_relative": "Relative log return, decimal form",
    "GreenBond_relative_check": "Relative log return, decimal form",
}

OUTPUT_DIRS = [
    DATA_PROCESSED_DIR,
    TABLES_DIR,
    RAW_FIGURES_DIR,
    TRANSFORMED_FIGURES_DIR,
    ACF_PACF_FIGURES_DIR,
    CORRELATION_FIGURES_DIR,
    LOGS_DIR,
]


def ensure_directories() -> None:
    for directory in OUTPUT_DIRS:
        directory.mkdir(parents=True, exist_ok=True)


def save_csv(df: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False, date_format="%Y-%m-%d")


def read_csv_with_date(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"Required file not found: {relative_path(path)}")
    return pd.read_csv(path, parse_dates=[DATE_COL])


def relative_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def safe_filename(name: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9]+", "_", name).strip("_")
    return cleaned or "series"


def to_month_end(values: pd.Series) -> pd.Series:
    return pd.to_datetime(values).dt.to_period("M").dt.to_timestamp("M")


def expected_month_ends(start: pd.Timestamp, end: pd.Timestamp) -> pd.DatetimeIndex:
    return pd.date_range(start=start, end=end, freq="ME")


def missing_months(dates: pd.Series) -> list[pd.Timestamp]:
    clean_dates = pd.DatetimeIndex(pd.to_datetime(dates).dropna().sort_values().unique())
    if clean_dates.empty:
        return []
    expected = expected_month_ends(clean_dates.min(), clean_dates.max())
    missing = expected.difference(clean_dates)
    return [pd.Timestamp(value) for value in missing]


def is_consecutive_monthly(dates: pd.Series) -> bool:
    return len(missing_months(dates)) == 0


def finite_numeric_frame(df: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    return df[columns].replace([np.inf, -np.inf], np.nan)


def format_date(value: object) -> str:
    if pd.isna(value):
        return ""
    return pd.Timestamp(value).strftime("%Y-%m-%d")
