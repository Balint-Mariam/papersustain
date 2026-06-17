from __future__ import annotations

import warnings

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import statsmodels.api as sm
from arch.unitroot import PhillipsPerron
from statsmodels.stats.diagnostic import acorr_ljungbox
from statsmodels.tsa.stattools import adfuller, kpss
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf

from analysis_common import (
    ACF_PACF_FIGURES_DIR,
    CORRELATION_FIGURES_DIR,
    DATA_CLEAN_RAW,
    DATA_MODEL_DIFF,
    DATA_MODEL_LEVELS,
    DATA_TRANSFORMED_COMPLETE,
    DATE_COL,
    LOGS_DIR,
    OUTPUT_DIR,
    TABLES_DIR,
    ensure_directories,
    format_date,
    missing_months,
    read_csv_with_date,
    relative_path,
    safe_filename,
    save_csv,
)


STATIONARITY_DETAILED = TABLES_DIR / "stationarity_tests_detailed.csv"
STATIONARITY_SUMMARY = TABLES_DIR / "stationarity_summary.csv"
LJUNG_BOX_TABLE = TABLES_DIR / "ljung_box_tests.csv"
HIGH_CORRELATIONS_TABLE = TABLES_DIR / "high_correlations.csv"
SPECIAL_CORRELATIONS_TABLE = TABLES_DIR / "special_correlations.csv"
VIF_DIFF_TABLE = TABLES_DIR / "vif_diff.csv"
VIF_LEVELS_TABLE = TABLES_DIR / "vif_levels.csv"
CONDITION_NUMBER_TABLE = TABLES_DIR / "condition_number.csv"
REPORT_FILE = OUTPUT_DIR / "pre_model_report.md"


def clean_series(series: pd.Series) -> pd.Series:
    return pd.to_numeric(series, errors="coerce").replace([np.inf, -np.inf], np.nan).dropna()


def add_critical_values(row: dict[str, object], critical_values: dict[str, float]) -> dict[str, object]:
    for key, output_key in [("1%", "critical_1pct"), ("5%", "critical_5pct"), ("10%", "critical_10pct")]:
        row[output_key] = critical_values.get(key, np.nan)
    return row


def run_adf(dataset: str, variable: str, series: pd.Series) -> dict[str, object]:
    clean = clean_series(series)
    row: dict[str, object] = {
        "dataset": dataset,
        "variable": variable,
        "test": "ADF",
        "null_hypothesis": "unit root",
    }
    try:
        max_lag = min(12, max(0, len(clean) // 2 - 2))
        result = adfuller(clean, maxlag=max_lag, regression="c", autolag="BIC")
        statistic, p_value, selected_lag, nobs, critical_values = result[:5]
        row.update(
            {
                "statistic": statistic,
                "p_value": p_value,
                "lag_or_bandwidth": selected_lag,
                "observations_used": nobs,
                "conclusion_5pct": (
                    "Reject unit root; stationary at 5%"
                    if p_value < 0.05
                    else "Fail to reject unit root at 5%"
                ),
                "warning": "",
            }
        )
        return add_critical_values(row, critical_values)
    except Exception as exc:
        row.update(
            {
                "statistic": np.nan,
                "p_value": np.nan,
                "lag_or_bandwidth": np.nan,
                "observations_used": len(clean),
                "critical_1pct": np.nan,
                "critical_5pct": np.nan,
                "critical_10pct": np.nan,
                "conclusion_5pct": "ERROR",
                "warning": str(exc),
            }
        )
        return row


def run_pp(dataset: str, variable: str, series: pd.Series) -> dict[str, object]:
    clean = clean_series(series)
    row: dict[str, object] = {
        "dataset": dataset,
        "variable": variable,
        "test": "Phillips-Perron",
        "null_hypothesis": "unit root",
    }
    try:
        pp_test = PhillipsPerron(clean, trend="c")
        row.update(
            {
                "statistic": pp_test.stat,
                "p_value": pp_test.pvalue,
                "lag_or_bandwidth": getattr(pp_test, "lags", np.nan),
                "observations_used": getattr(pp_test, "nobs", len(clean)),
                "conclusion_5pct": (
                    "Reject unit root; stationary at 5%"
                    if pp_test.pvalue < 0.05
                    else "Fail to reject unit root at 5%"
                ),
                "warning": "",
            }
        )
        return add_critical_values(row, pp_test.critical_values)
    except Exception as exc:
        row.update(
            {
                "statistic": np.nan,
                "p_value": np.nan,
                "lag_or_bandwidth": np.nan,
                "observations_used": len(clean),
                "critical_1pct": np.nan,
                "critical_5pct": np.nan,
                "critical_10pct": np.nan,
                "conclusion_5pct": "ERROR",
                "warning": str(exc),
            }
        )
        return row


def run_kpss(dataset: str, variable: str, series: pd.Series) -> dict[str, object]:
    clean = clean_series(series)
    row: dict[str, object] = {
        "dataset": dataset,
        "variable": variable,
        "test": "KPSS",
        "null_hypothesis": "stationarity around a constant",
    }
    try:
        with warnings.catch_warnings(record=True) as captured:
            warnings.simplefilter("always")
            statistic, p_value, lags, critical_values = kpss(clean, regression="c", nlags="auto")
        warning_text = "; ".join(str(item.message) for item in captured)
        row.update(
            {
                "statistic": statistic,
                "p_value": p_value,
                "lag_or_bandwidth": lags,
                "observations_used": len(clean),
                "conclusion_5pct": (
                    "Reject stationarity at 5%"
                    if p_value < 0.05
                    else "Fail to reject stationarity at 5%"
                ),
                "warning": warning_text,
            }
        )
        return add_critical_values(row, critical_values)
    except Exception as exc:
        row.update(
            {
                "statistic": np.nan,
                "p_value": np.nan,
                "lag_or_bandwidth": np.nan,
                "observations_used": len(clean),
                "critical_1pct": np.nan,
                "critical_5pct": np.nan,
                "critical_10pct": np.nan,
                "conclusion_5pct": "ERROR",
                "warning": str(exc),
            }
        )
        return row


def stationarity_rows() -> list[dict[str, object]]:
    diff_df = read_csv_with_date(DATA_MODEL_DIFF)
    complete_df = read_csv_with_date(DATA_TRANSFORMED_COMPLETE)

    specs: list[tuple[str, str, pd.Series]] = []
    for variable in [column for column in diff_df.columns if column != DATE_COL]:
        specs.append(("data_model_diff", variable, diff_df[variable]))
    for variable in ["CPI_yoy_level", "CPI_yoy_change", "CISS_level", "CISS_change"]:
        specs.append(("level_change_checks", variable, complete_df[variable]))

    rows: list[dict[str, object]] = []
    for dataset, variable, series in specs:
        rows.append(run_adf(dataset, variable, series))
        rows.append(run_pp(dataset, variable, series))
        rows.append(run_kpss(dataset, variable, series))
    return rows


def is_stationary_result(row: pd.Series) -> bool | None:
    if pd.isna(row["p_value"]) or row["conclusion_5pct"] == "ERROR":
        return None
    if row["test"] == "KPSS":
        return bool(row["p_value"] >= 0.05)
    return bool(row["p_value"] < 0.05)


def evaluate_stationarity(adf: bool | None, pp: bool | None, kpss_result: bool | None) -> str:
    results = [adf, pp, kpss_result]
    if any(result is None for result in results):
        return "MIXED_EVIDENCE"
    if adf != pp:
        return "MIXED_EVIDENCE"
    votes = sum(bool(result) for result in results)
    if votes == 3:
        return "CLEARLY_STATIONARY"
    if votes == 2:
        return "LIKELY_STATIONARY"
    if votes == 1:
        return "LIKELY_NONSTATIONARY"
    return "CLEARLY_NONSTATIONARY"


def stationarity_recommendation(evaluation: str) -> str:
    recommendations = {
        "CLEARLY_STATIONARY": "Retain in the candidate set.",
        "LIKELY_STATIONARY": "Retain; document the conflicting stationarity evidence.",
        "MIXED_EVIDENCE": "Retain for now; do not apply automatic extra differencing.",
        "LIKELY_NONSTATIONARY": "Use caution; assess robustness rather than differencing automatically.",
        "CLEARLY_NONSTATIONARY": "Treat as nonstationary evidence and use only with an explicit robustness rationale.",
    }
    return recommendations[evaluation]


def stationarity_summary(detailed: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for (dataset, variable), group in detailed.groupby(["dataset", "variable"], sort=False):
        tests = {row["test"]: row for _, row in group.iterrows()}
        adf_stationary = is_stationary_result(tests["ADF"])
        pp_stationary = is_stationary_result(tests["Phillips-Perron"])
        kpss_stationary = is_stationary_result(tests["KPSS"])
        evaluation = evaluate_stationarity(adf_stationary, pp_stationary, kpss_stationary)
        rows.append(
            {
                "dataset": dataset,
                "variable": variable,
                "adf_result": tests["ADF"]["conclusion_5pct"],
                "pp_result": tests["Phillips-Perron"]["conclusion_5pct"],
                "kpss_result": tests["KPSS"]["conclusion_5pct"],
                "joint_evaluation": evaluation,
                "recommendation": stationarity_recommendation(evaluation),
            }
        )
    return pd.DataFrame(rows)


def run_stationarity_tests() -> tuple[pd.DataFrame, pd.DataFrame]:
    detailed = pd.DataFrame(stationarity_rows())
    summary = stationarity_summary(detailed)
    save_csv(detailed, STATIONARITY_DETAILED)
    save_csv(summary, STATIONARITY_SUMMARY)
    return detailed, summary


def model_datasets() -> list[tuple[str, pd.DataFrame]]:
    return [
        ("data_model_diff", read_csv_with_date(DATA_MODEL_DIFF)),
        ("data_model_levels", read_csv_with_date(DATA_MODEL_LEVELS)),
    ]


def create_acf_pacf_plot(dataset: str, variable: str, series: pd.Series) -> None:
    clean = clean_series(series)
    if len(clean) < 5:
        return
    max_lag = min(24, max(1, len(clean) // 2 - 1))
    fig, axes = plt.subplots(2, 1, figsize=(10, 7))
    plot_acf(clean, lags=max_lag, ax=axes[0])
    axes[0].set_title(f"ACF: {variable} ({dataset})")
    plot_pacf(clean, lags=max_lag, ax=axes[1], method="ywm")
    axes[1].set_title(f"PACF: {variable} ({dataset})")
    fig.tight_layout()
    output_path = ACF_PACF_FIGURES_DIR / f"{dataset}_{safe_filename(variable)}_acf_pacf.png"
    fig.savefig(output_path, dpi=150)
    plt.close(fig)


def run_autocorrelation_tests() -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for dataset, df in model_datasets():
        for variable in [column for column in df.columns if column != DATE_COL]:
            series = clean_series(df[variable])
            create_acf_pacf_plot(dataset, variable, series)
            if len(series) <= 12:
                continue
            ljung = acorr_ljungbox(series, lags=[6, 12], return_df=True)
            for lag, result in ljung.iterrows():
                rows.append(
                    {
                        "dataset": dataset,
                        "variable": variable,
                        "lag": int(lag),
                        "lb_statistic": result["lb_stat"],
                        "p_value": result["lb_pvalue"],
                        "null_hypothesis": "no autocorrelation up to tested lag",
                        "conclusion_5pct": (
                            "Reject no-autocorrelation at 5%"
                            if result["lb_pvalue"] < 0.05
                            else "Fail to reject no-autocorrelation at 5%"
                        ),
                    }
                )
    results = pd.DataFrame(rows)
    save_csv(results, LJUNG_BOX_TABLE)
    return results


def save_correlation_heatmap(correlation: pd.DataFrame, dataset: str, method: str) -> None:
    fig_width = max(8, 0.65 * len(correlation.columns))
    fig_height = max(7, 0.65 * len(correlation.columns))
    fig, ax = plt.subplots(figsize=(fig_width, fig_height))
    image = ax.imshow(correlation.values, vmin=-1, vmax=1)
    fig.colorbar(image, ax=ax, fraction=0.046, pad=0.04)
    ax.set_xticks(range(len(correlation.columns)))
    ax.set_yticks(range(len(correlation.index)))
    ax.set_xticklabels(correlation.columns, rotation=90)
    ax.set_yticklabels(correlation.index)
    ax.set_title(f"{method.capitalize()} correlations: {dataset}")
    fig.tight_layout()
    output_path = CORRELATION_FIGURES_DIR / f"{dataset}_{method}_correlation_heatmap.png"
    fig.savefig(output_path, dpi=150)
    plt.close(fig)


def high_correlation_pairs(correlation: pd.DataFrame, dataset: str, method: str) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    columns = list(correlation.columns)
    for i, left in enumerate(columns):
        for right in columns[i + 1 :]:
            value = correlation.loc[left, right]
            abs_value = abs(value)
            if abs_value >= 0.70:
                if abs_value >= 0.90:
                    bucket = ">=0.90"
                elif abs_value >= 0.80:
                    bucket = ">=0.80"
                else:
                    bucket = ">=0.70"
                rows.append(
                    {
                        "dataset": dataset,
                        "method": method,
                        "variable_1": left,
                        "variable_2": right,
                        "correlation": value,
                        "abs_correlation": abs_value,
                        "threshold_bucket": bucket,
                    }
                )
    return rows


def special_correlation_pairs(correlation: pd.DataFrame, dataset: str, method: str) -> list[dict[str, object]]:
    pairs = [
        ("TTF - Power", "TTF_ret", "Power_ret"),
        ("TTF - Brent", "TTF_ret", "Brent_ret"),
        ("Power - CPI", "Power_ret", "CPI_yoy_change"),
        ("Power - CPI", "Power_ret", "CPI_yoy_level"),
        ("CPI - Bund 2Y", "CPI_yoy_change", "Bund2Y_change_bps"),
        ("CPI - Bund 2Y", "CPI_yoy_level", "Bund2Y_change_bps"),
        ("Green equity - green bond", "GreenEquity_relative", "GreenBond_relative"),
    ]
    rows: list[dict[str, object]] = []
    for label, left, right in pairs:
        if left in correlation.index and right in correlation.columns:
            value = correlation.loc[left, right]
            rows.append(
                {
                    "dataset": dataset,
                    "method": method,
                    "relationship": label,
                    "variable_1": left,
                    "variable_2": right,
                    "correlation": value,
                    "abs_correlation": abs(value),
                }
            )
    return rows


def run_correlation_analysis() -> tuple[pd.DataFrame, pd.DataFrame]:
    high_rows: list[dict[str, object]] = []
    special_rows: list[dict[str, object]] = []
    for dataset, df in model_datasets():
        numeric = df.drop(columns=[DATE_COL])
        for method in ["pearson", "spearman"]:
            correlation = numeric.corr(method=method)
            output_path = TABLES_DIR / f"correlation_{method}_{dataset.replace('data_model_', '')}.csv"
            save_csv(correlation.reset_index().rename(columns={"index": "variable"}), output_path)
            save_correlation_heatmap(correlation, dataset, method)
            high_rows.extend(high_correlation_pairs(correlation, dataset, method))
            special_rows.extend(special_correlation_pairs(correlation, dataset, method))

    high_df = pd.DataFrame(
        high_rows,
        columns=[
            "dataset",
            "method",
            "variable_1",
            "variable_2",
            "correlation",
            "abs_correlation",
            "threshold_bucket",
        ],
    )
    special_df = pd.DataFrame(
        special_rows,
        columns=[
            "dataset",
            "method",
            "relationship",
            "variable_1",
            "variable_2",
            "correlation",
            "abs_correlation",
        ],
    )
    save_csv(high_df, HIGH_CORRELATIONS_TABLE)
    save_csv(special_df, SPECIAL_CORRELATIONS_TABLE)
    return high_df, special_df


def calculate_vif(df: pd.DataFrame, dataset: str) -> pd.DataFrame:
    numeric = df.drop(columns=[DATE_COL]).dropna().astype(float)
    rows: list[dict[str, object]] = []
    for variable in numeric.columns:
        y = numeric[variable]
        x = numeric.drop(columns=[variable])
        x = sm.add_constant(x, has_constant="add")
        try:
            model = sm.OLS(y, x).fit()
            r_squared = float(model.rsquared)
            tolerance = 1 - r_squared
            vif = np.inf if tolerance <= 0 else 1 / tolerance
        except Exception:
            r_squared = np.nan
            tolerance = np.nan
            vif = np.nan

        if pd.isna(vif):
            classification = "not_available"
        elif vif < 5:
            classification = "low"
        elif vif < 10:
            classification = "moderate"
        else:
            classification = "high"

        rows.append(
            {
                "dataset": dataset,
                "variable": variable,
                "r_squared": r_squared,
                "tolerance": tolerance,
                "vif": vif,
                "classification": classification,
                "note": (
                    "VIF is a static diagnostic and is not a definitive exclusion "
                    "criterion for a shrinkage BVAR."
                ),
            }
        )
    return pd.DataFrame(rows)


def run_vif_analysis() -> tuple[pd.DataFrame, pd.DataFrame]:
    diff_df = calculate_vif(read_csv_with_date(DATA_MODEL_DIFF), "data_model_diff")
    levels_df = calculate_vif(read_csv_with_date(DATA_MODEL_LEVELS), "data_model_levels")
    save_csv(diff_df, VIF_DIFF_TABLE)
    save_csv(levels_df, VIF_LEVELS_TABLE)
    return diff_df, levels_df


def condition_number(df: pd.DataFrame, dataset: str) -> dict[str, object]:
    numeric = df.drop(columns=[DATE_COL]).dropna().astype(float)
    std = numeric.std(ddof=0)
    if (std == 0).any():
        zero_variance = std[std == 0].index.tolist()
        return {
            "dataset": dataset,
            "condition_number": np.inf,
            "singular_values": "",
            "note": f"Zero variance variables prevent standardization: {zero_variance}",
        }

    standardized = (numeric - numeric.mean()) / std
    singular_values = np.linalg.svd(standardized.to_numpy(), compute_uv=False)
    smallest = singular_values.min()
    condition = np.inf if smallest == 0 else singular_values.max() / smallest
    return {
        "dataset": dataset,
        "condition_number": condition,
        "singular_values": ";".join(f"{value:.10g}" for value in singular_values),
        "note": "Variables were standardized temporarily only for this diagnostic.",
    }


def run_condition_number_analysis() -> pd.DataFrame:
    rows = [condition_number(df, dataset) for dataset, df in model_datasets()]
    results = pd.DataFrame(rows)
    save_csv(results, CONDITION_NUMBER_TABLE)
    return results


def read_optional_csv(path) -> pd.DataFrame:
    if not path.exists():
        return pd.DataFrame()
    return pd.read_csv(path)


def csv_preview(df: pd.DataFrame, max_rows: int = 20) -> str:
    if df.empty:
        return "No rows."
    preview = df.head(max_rows)
    suffix = "" if len(df) <= max_rows else f"\n... {len(df) - max_rows} additional rows in the CSV file."
    return "```csv\n" + preview.to_csv(index=False).strip() + "\n```" + suffix


def audit_warnings() -> list[str]:
    log_path = LOGS_DIR / "data_audit.log"
    if not log_path.exists():
        return []
    lines = log_path.read_text(encoding="utf-8").splitlines()
    return [line for line in lines if "WARNING" in line or "ERROR" in line]


def generate_report() -> None:
    raw_df = read_csv_with_date(DATA_CLEAN_RAW)
    diff_df = read_csv_with_date(DATA_MODEL_DIFF)
    levels_df = read_csv_with_date(DATA_MODEL_LEVELS)

    audit_df = read_optional_csv(TABLES_DIR / "data_audit.csv")
    missing_df = read_optional_csv(TABLES_DIR / "missing_values.csv")
    descriptive_df = read_optional_csv(TABLES_DIR / "descriptive_statistics.csv")
    extremes_df = read_optional_csv(TABLES_DIR / "extreme_observations.csv")
    stationarity_detailed = read_optional_csv(STATIONARITY_DETAILED)
    stationarity_summary_df = read_optional_csv(STATIONARITY_SUMMARY)
    ljung_df = read_optional_csv(LJUNG_BOX_TABLE)
    high_corr_df = read_optional_csv(HIGH_CORRELATIONS_TABLE)
    special_corr_df = read_optional_csv(SPECIAL_CORRELATIONS_TABLE)
    vif_diff_df = read_optional_csv(VIF_DIFF_TABLE)
    vif_levels_df = read_optional_csv(VIF_LEVELS_TABLE)
    condition_df = read_optional_csv(CONDITION_NUMBER_TABLE)

    missing_month_values = missing_months(raw_df[DATE_COL])
    missing_month_text = "None" if not missing_month_values else ", ".join(format_date(value) for value in missing_month_values)
    missing_total = int(missing_df["missing_values"].sum()) if "missing_values" in missing_df else 0

    if not audit_df.empty and {"zero_values", "negative_values"}.issubset(audit_df.columns):
        zero_negative = audit_df[(audit_df["zero_values"] > 0) | (audit_df["negative_values"] > 0)]
    else:
        zero_negative = pd.DataFrame()

    if not ljung_df.empty and "p_value" in ljung_df.columns:
        significant_ljung = ljung_df[ljung_df["p_value"] < 0.05]
    else:
        significant_ljung = pd.DataFrame()

    high_vif = pd.concat([vif_diff_df, vif_levels_df], ignore_index=True)
    if not high_vif.empty and "classification" in high_vif.columns:
        high_vif = high_vif[high_vif["classification"] == "high"]
    else:
        high_vif = pd.DataFrame()

    if not stationarity_summary_df.empty and "variable" in stationarity_summary_df.columns:
        cpi_ciss_summary = stationarity_summary_df[
            stationarity_summary_df["variable"].isin(
                ["CPI_yoy_level", "CPI_yoy_change", "CISS_level", "CISS_change"]
            )
        ]
    else:
        cpi_ciss_summary = pd.DataFrame()

    warnings_found = audit_warnings()
    warning_text = "\n".join(f"- {item}" for item in warnings_found) if warnings_found else "- No audit warnings or errors recorded."

    report = f"""# Pre-Model Econometric Analysis Report

## Sample and Data Checks

- Raw sample period: {format_date(raw_df[DATE_COL].min())} to {format_date(raw_df[DATE_COL].max())}
- Raw observations: {len(raw_df)}
- Observations after transformations in `data_model_diff.csv`: {len(diff_df)}
- Observations after transformations in `data_model_levels.csv`: {len(levels_df)}
- Missing months inside the retained monthly sample: {missing_month_text}
- Missing numeric values reported in the raw audit: {missing_total}

Zero and negative value checks:

{csv_preview(zero_negative)}

Audit warnings:

{warning_text}

## Transformations and Units

- Log returns are stored in decimal form. A value of `0.05` means approximately `5%`.
- `EUA_ret`, `TTF_ret`, `Brent_ret`, and `Power_ret`: monthly log returns in decimal form.
- `IP_growth`: approximate monthly industrial production growth in decimal form.
- `Bund2Y_change_bps`: monthly change in basis points.
- `CPI_yoy_level`: annual inflation rate; `CPI_yoy_change`: monthly change in that annual inflation rate, in percentage points.
- `CISS_level`: systemic stress index level; `CISS_change`: monthly change in systemic stress.
- `GreenEquity_relative`: relative performance proxy versus the European broad equity market.
- `GreenBond_relative`: relative performance proxy versus the euro corporate bond market.
- The two relative returns are not pure green premia, pure green-screening effects, or causal estimates of a green label.

Transformation identity checks are saved in `output/tables/transformation_checks.csv`.

## Descriptive Statistics

Detailed descriptive statistics are saved in `output/tables/descriptive_statistics.csv`.

{csv_preview(descriptive_df)}

## Extreme Observations

Extreme observations are identified but not removed, modified, winsorized, or smoothed.

{csv_preview(extremes_df)}

## Stationarity Tests

Detailed ADF, Phillips-Perron, and KPSS results are saved in `output/tables/stationarity_tests_detailed.csv`.

Stationarity summary:

{csv_preview(stationarity_summary_df, max_rows=30)}

CPI and CISS level-versus-difference comparison:

{csv_preview(cpi_ciss_summary)}

ADF, Phillips-Perron, and KPSS detailed rows:

{csv_preview(stationarity_detailed, max_rows=30)}

## Autocorrelation

ACF/PACF figures are saved in `output/figures/acf_pacf`. Ljung-Box tests use the null hypothesis of no autocorrelation up to the tested lag.

Significant Ljung-Box results at 5%:

{csv_preview(significant_ljung)}

## Correlations and Collinearity

Pearson and Spearman matrices are saved as CSV files in `output/tables`, with heatmaps in `output/figures/correlations`.

High absolute correlations:

{csv_preview(high_corr_df)}

Requested relationship checks:

{csv_preview(special_corr_df)}

VIF is a static diagnostic and is not a definitive exclusion criterion for a BVAR with shrinkage. No variable is removed based on VIF.

High VIF rows:

{csv_preview(high_vif)}

Condition number diagnostics:

{csv_preview(condition_df)}

## Recommendation for the BVAR Stage

The recommended main candidate set is `data_processed/data_model_diff.csv`. It uses log returns, first differences, and basis-point changes as requested, while preserving decimal log-return units. `data_processed/data_model_levels.csv` should be kept for stationarity comparison and robustness checks involving CPI and CISS levels.

No VAR, BVAR, BVAR-SV, BSVAR, or BSVAR-SV model is estimated in this stage. No structural-break tests are run.
"""

    REPORT_FILE.write_text(report, encoding="utf-8")


def main() -> None:
    ensure_directories()
    run_stationarity_tests()
    run_autocorrelation_tests()
    run_correlation_analysis()
    run_vif_analysis()
    run_condition_number_analysis()
    generate_report()

    print("Pre-model tests completed.")
    print(f"Saved {relative_path(STATIONARITY_DETAILED)}")
    print(f"Saved {relative_path(STATIONARITY_SUMMARY)}")
    print(f"Saved {relative_path(LJUNG_BOX_TABLE)}")
    print(f"Saved {relative_path(HIGH_CORRELATIONS_TABLE)}")
    print(f"Saved {relative_path(VIF_DIFF_TABLE)}")
    print(f"Saved {relative_path(VIF_LEVELS_TABLE)}")
    print(f"Saved {relative_path(CONDITION_NUMBER_TABLE)}")
    print(f"Saved {relative_path(REPORT_FILE)}")


if __name__ == "__main__":
    main()
