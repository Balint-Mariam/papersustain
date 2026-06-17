from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy import stats

from analysis_common import (
    DATA_CLEAN_RAW,
    DATA_TRANSFORMED_COMPLETE,
    DATE_COL,
    NUMERIC_COLUMNS,
    RAW_FIGURES_DIR,
    RAW_UNITS,
    TABLES_DIR,
    TRANSFORMED_COLUMNS,
    TRANSFORMED_FIGURES_DIR,
    TRANSFORMED_UNITS,
    ensure_directories,
    read_csv_with_date,
    relative_path,
    safe_filename,
    save_csv,
)


DESCRIPTIVE_TABLE = TABLES_DIR / "descriptive_statistics.csv"
EXTREME_TABLE = TABLES_DIR / "extreme_observations.csv"


def jarque_bera(series: pd.Series) -> tuple[float, float]:
    clean = series.dropna()
    if len(clean) < 2:
        return np.nan, np.nan
    result = stats.jarque_bera(clean)
    statistic = getattr(result, "statistic", result[0])
    pvalue = getattr(result, "pvalue", result[1])
    return float(statistic), float(pvalue)


def descriptive_statistics(df: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for column in [name for name in TRANSFORMED_COLUMNS if name in df.columns]:
        series = pd.to_numeric(df[column], errors="coerce")
        clean = series.dropna()
        jb_stat, jb_pvalue = jarque_bera(clean)

        rows.append(
            {
                "variable": column,
                "unit": TRANSFORMED_UNITS.get(column, ""),
                "observations": int(clean.count()),
                "mean": clean.mean(),
                "median": clean.median(),
                "standard_deviation": clean.std(ddof=1),
                "minimum": clean.min(),
                "maximum": clean.max(),
                "p01": clean.quantile(0.01),
                "p05": clean.quantile(0.05),
                "p25": clean.quantile(0.25),
                "p75": clean.quantile(0.75),
                "p95": clean.quantile(0.95),
                "p99": clean.quantile(0.99),
                "skewness": clean.skew(),
                "excess_kurtosis": clean.kurt(),
                "jarque_bera_statistic": jb_stat,
                "jarque_bera_p_value": jb_pvalue,
                "note": "Log returns are stored in decimal form where applicable.",
            }
        )
    return pd.DataFrame(rows)


def plot_series(
    df: pd.DataFrame,
    column: str,
    unit: str,
    output_dir,
    zero_line: bool,
) -> None:
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(df[DATE_COL], df[column])
    ax.set_title(f"{column} ({unit})")
    ax.set_xlabel("Date")
    ax.set_ylabel(unit)
    if zero_line:
        ax.axhline(0, linewidth=0.8)
    fig.autofmt_xdate()
    fig.tight_layout()
    fig.savefig(output_dir / f"{safe_filename(column)}.png", dpi=150)
    plt.close(fig)


def create_raw_plots(df: pd.DataFrame) -> None:
    for column in NUMERIC_COLUMNS:
        series = pd.to_numeric(df[column], errors="coerce")
        zero_line = bool(series.min(skipna=True) <= 0 <= series.max(skipna=True))
        plot_series(df, column, RAW_UNITS.get(column, "Value"), RAW_FIGURES_DIR, zero_line)


def create_transformed_plots(df: pd.DataFrame) -> None:
    for column in [name for name in TRANSFORMED_COLUMNS if name in df.columns]:
        series = pd.to_numeric(df[column], errors="coerce")
        unit = TRANSFORMED_UNITS.get(column, "Value")
        zero_line = (
            "return" in unit.lower()
            or "growth" in unit.lower()
            or "change" in unit.lower()
            or "basis points" in unit.lower()
            or bool(series.min(skipna=True) <= 0 <= series.max(skipna=True))
        )
        plot_series(df, column, unit, TRANSFORMED_FIGURES_DIR, zero_line)


def extreme_observations(df: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for column in [name for name in TRANSFORMED_COLUMNS if name in df.columns]:
        series = pd.to_numeric(df[column], errors="coerce")
        clean = series.dropna()
        if clean.empty:
            continue

        mean = clean.mean()
        std = clean.std(ddof=1)
        median = clean.median()
        mad = (clean - median).abs().median()

        z_scores = (series - mean) / std if std and not np.isnan(std) else pd.Series(np.nan, index=series.index)
        modified_z_scores = (
            0.6745 * (series - median) / mad if mad and not np.isnan(mad) else pd.Series(np.nan, index=series.index)
        )

        z_mask = z_scores.abs() > 3
        modified_mask = modified_z_scores.abs() > 3.5
        flagged = z_mask | modified_mask

        for index in df.index[flagged.fillna(False)]:
            criteria = []
            if bool(z_mask.loc[index]):
                criteria.append("abs_z_score_gt_3")
            if bool(modified_mask.loc[index]):
                criteria.append("abs_modified_z_score_gt_3_5")
            rows.append(
                {
                    "variable": column,
                    "date": df.loc[index, DATE_COL].strftime("%Y-%m-%d"),
                    "value": series.loc[index],
                    "z_score": z_scores.loc[index],
                    "modified_z_score": modified_z_scores.loc[index],
                    "criterion": ";".join(criteria),
                }
            )

    return pd.DataFrame(
        rows,
        columns=["variable", "date", "value", "z_score", "modified_z_score", "criterion"],
    )


def main() -> None:
    ensure_directories()
    raw_df = read_csv_with_date(DATA_CLEAN_RAW)
    transformed_df = read_csv_with_date(DATA_TRANSFORMED_COMPLETE)

    descriptive_df = descriptive_statistics(transformed_df)
    extremes_df = extreme_observations(transformed_df)

    save_csv(descriptive_df, DESCRIPTIVE_TABLE)
    save_csv(extremes_df, EXTREME_TABLE)
    create_raw_plots(raw_df)
    create_transformed_plots(transformed_df)

    print("Descriptive analysis completed.")
    print("Log returns remain in decimal form in all model files.")
    print(f"Saved {relative_path(DESCRIPTIVE_TABLE)}")
    print(f"Saved {relative_path(EXTREME_TABLE)}")
    print(f"Saved raw figures in {relative_path(RAW_FIGURES_DIR)}")
    print(f"Saved transformed figures in {relative_path(TRANSFORMED_FIGURES_DIR)}")


if __name__ == "__main__":
    main()

