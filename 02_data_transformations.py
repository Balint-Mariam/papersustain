from __future__ import annotations

import numpy as np
import pandas as pd

from analysis_common import (
    DATA_CLEAN_RAW,
    DATA_MODEL_DIFF,
    DATA_MODEL_LEVELS,
    DATA_TRANSFORMED_COMPLETE,
    DATE_COL,
    MODEL_DIFF_COLUMNS,
    MODEL_LEVEL_COLUMNS,
    STRICTLY_POSITIVE_COLUMNS,
    TABLES_DIR,
    ensure_directories,
    format_date,
    read_csv_with_date,
    relative_path,
    save_csv,
)


NONPOSITIVE_TABLE = TABLES_DIR / "nonpositive_log_values.csv"
TRANSFORMATION_CHECKS = TABLES_DIR / "transformation_checks.csv"


def report_nonpositive_values(df: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for column in STRICTLY_POSITIVE_COLUMNS:
        bad_mask = df[column] <= 0
        for _, row in df.loc[bad_mask, [DATE_COL, column]].iterrows():
            rows.append(
                {
                    "variable": column,
                    "date": format_date(row[DATE_COL]),
                    "value": row[column],
                }
            )
    return pd.DataFrame(rows, columns=["variable", "date", "value"])


def check_log_requirements(df: pd.DataFrame) -> None:
    nonpositive_df = report_nonpositive_values(df)
    if nonpositive_df.empty:
        if NONPOSITIVE_TABLE.exists():
            NONPOSITIVE_TABLE.unlink()
        return

    save_csv(nonpositive_df, NONPOSITIVE_TABLE)
    print("Transformation stopped: log variables contain values <= 0.")
    print(nonpositive_df.to_string(index=False))
    raise ValueError(
        "Natural logs were not applied because at least one required series "
        f"contains nonpositive values. See {relative_path(NONPOSITIVE_TABLE)}."
    )


def add_transformations(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    complete = df.copy()

    complete["EUA_ret"] = np.log(df["EUA"]).diff()
    complete["TTF_ret"] = np.log(df["TTF"]).diff()
    complete["Brent_ret"] = np.log(df["Brent"]).diff()
    complete["Power_ret"] = np.log(df["Power Energy Price"]).diff()
    complete["IP_growth"] = np.log(df["Industrial Production"]).diff()
    complete["Bund2Y_change_bps"] = df["Bund 2Y"].diff() * 100

    complete["CPI_yoy_level"] = df["CPI EU"]
    complete["CPI_yoy_change"] = df["CPI EU"].diff()

    complete["CISS_level"] = df["CISS"]
    complete["CISS_change"] = df["CISS"].diff()

    complete["GE_return"] = np.log(df["GE Index TR"]).diff()
    complete["Stoxx600_return"] = np.log(df["Stoxx600 TR"]).diff()
    complete["GreenEquity_relative"] = complete["GE_return"] - complete["Stoxx600_return"]
    complete["GreenEquity_relative_check"] = np.log(df["GE Index TR"] / df["Stoxx600 TR"]).diff()

    complete["GreenBond_return"] = np.log(df["GB Corp Index"]).diff()
    complete["CorpBond_return"] = np.log(df["Corp Bond Index"]).diff()
    complete["GreenBond_relative"] = complete["GreenBond_return"] - complete["CorpBond_return"]
    complete["GreenBond_relative_check"] = np.log(df["GB Corp Index"] / df["Corp Bond Index"]).diff()

    checks = pd.DataFrame(
        [
            {
                "check": "GreenEquity_relative_identity",
                "max_abs_difference": (
                    complete["GreenEquity_relative"] - complete["GreenEquity_relative_check"]
                )
                .abs()
                .max(),
            },
            {
                "check": "GreenBond_relative_identity",
                "max_abs_difference": (
                    complete["GreenBond_relative"] - complete["GreenBond_relative_check"]
                )
                .abs()
                .max(),
            },
        ]
    )

    return complete, checks


def create_model_dataset(complete: pd.DataFrame, columns: list[str], output_path) -> pd.DataFrame:
    model_df = complete[columns].copy()

    if len(model_df) < 2:
        raise ValueError("Not enough observations to remove the first mechanically differenced row.")

    first_data_row_has_nan = model_df.iloc[0, 1:].isna().any()
    later_nan_mask = model_df.iloc[1:, 1:].isna().any(axis=1)
    if not first_data_row_has_nan:
        raise ValueError("The first transformed row does not contain the expected mechanical NaN.")
    if later_nan_mask.any():
        bad_dates = model_df.iloc[1:].loc[later_nan_mask, DATE_COL].dt.strftime("%Y-%m-%d").tolist()
        raise ValueError(
            "Additional missing transformed observations were found after the first row. "
            f"No extra rows were dropped. Dates affected: {bad_dates}"
        )

    model_df = model_df.iloc[1:].reset_index(drop=True)
    save_csv(model_df, output_path)
    return model_df


def main() -> None:
    ensure_directories()

    df = read_csv_with_date(DATA_CLEAN_RAW)
    check_log_requirements(df)

    complete, checks = add_transformations(df)
    save_csv(complete, DATA_TRANSFORMED_COMPLETE)
    save_csv(checks, TRANSFORMATION_CHECKS)

    diff_df = create_model_dataset(complete, MODEL_DIFF_COLUMNS, DATA_MODEL_DIFF)
    levels_df = create_model_dataset(complete, MODEL_LEVEL_COLUMNS, DATA_MODEL_LEVELS)

    print("Data transformations completed.")
    print("Log returns are stored in decimal form; they were not multiplied by 100.")
    print(f"Saved {relative_path(DATA_TRANSFORMED_COMPLETE)}")
    print(f"Saved {relative_path(DATA_MODEL_DIFF)} with {len(diff_df)} observations")
    print(f"Saved {relative_path(DATA_MODEL_LEVELS)} with {len(levels_df)} observations")
    print(f"Saved {relative_path(TRANSFORMATION_CHECKS)}")


if __name__ == "__main__":
    main()

