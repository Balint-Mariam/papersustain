source(file.path("R", "stage2_common.R"))

read_csv_optional <- function(path) {
  if (!file.exists(path)) return(data.frame())
  readr::read_csv(path, show_col_types = FALSE)
}

base_model_id <- function(variance_type, p) {
  paste0("BVAR-", ifelse(variance_type == "sv", "SV", "HOM"), "-p", p)
}

build_model_comparison <- function() {
  index <- read_csv_optional(stage2_model_index)
  stability <- read_csv_optional(file.path("output", "tables", "bvar", "posterior_stability.csv"))
  mcmc <- read_csv_optional(file.path("output", "tables", "bvar", "mcmc_diagnostics.csv"))
  residual <- read_csv_optional(file.path("output", "tables", "bvar", "bvar_residual_ljung_box.csv"))
  residual_sq <- read_csv_optional(file.path("output", "tables", "bvar", "bvar_squared_residual_ljung_box.csv"))
  lpl <- read_csv_optional(file.path("output", "tables", "bvar", "log_predictive_likelihood.csv"))
  metrics <- read_csv_optional(file.path("output", "tables", "bvar", "forecast_metrics.csv"))
  coverage <- read_csv_optional(file.path("output", "tables", "bvar", "forecast_interval_coverage.csv"))

  rows <- list()
  for (variance_type in c("homoskedastic", "sv")) {
    for (p in c(1L, 2L)) {
      base <- base_model_id(variance_type, p)
      pilot_id <- paste0(base, "-pilot")
      forecast_id <- paste0(base, "-forecast")
      pilot_run <- index |> dplyr::filter(model_id == pilot_id)
      stability_row_df <- stability |> dplyr::filter(model_id == pilot_id)
      forecast_lpl <- lpl |> dplyr::filter(model_id == forecast_id)
      green_metrics <- metrics |> dplyr::filter(model_id == forecast_id, variable %in% green_vars)
      green_cov <- coverage |> dplyr::filter(model_id == forecast_id, variable %in% green_vars)
      residual_auto <- residual |> dplyr::filter(model_id == pilot_id, p_value < 0.05)
      residual_sq_auto <- residual_sq |> dplyr::filter(model_id == pilot_id, p_value < 0.05)

      final_lags <- index |>
        dplyr::filter(run_type == "final", variance_type == .env$variance_type) |>
        dplyr::pull(lag) |>
        unique()
      final_group <- paste0("BVAR-", toupper(variance_type), "-final")
      mcmc_group <- if (p %in% final_lags) {
        mcmc |> dplyr::filter(model_group == final_group)
      } else {
        data.frame()
      }

      rows[[length(rows) + 1]] <- data.frame(
        model = base,
        lag = p,
        variance_type = variance_type,
        prior = "HMP coefficients, HMP Cholesky covariance",
        stable_draws = ifelse(nrow(stability_row_df), stability_row_df$stable_draws[1], NA_real_),
        unstable_pct = ifelse(nrow(stability_row_df), stability_row_df$unstable_pct[1], NA_real_),
        max_rhat = if (nrow(mcmc_group)) max(mcmc_group$rhat, na.rm = TRUE) else NA_real_,
        min_bulk_ess = if (nrow(mcmc_group)) min(mcmc_group$ess_bulk, na.rm = TRUE) else NA_real_,
        residual_autocorrelation_rejections = nrow(residual_auto),
        squared_residual_autocorrelation_rejections = nrow(residual_sq_auto),
        joint_log_predictive_likelihood = ifelse(nrow(forecast_lpl), forecast_lpl$joint_log_predictive_likelihood[1], NA_real_),
        green_assets_log_predictive_likelihood = ifelse(nrow(forecast_lpl), forecast_lpl$green_assets_log_predictive_likelihood[1], NA_real_),
        green_rmse_mean = ifelse(nrow(green_metrics), mean(green_metrics$rmse, na.rm = TRUE), NA_real_),
        green_mae_mean = ifelse(nrow(green_metrics), mean(green_metrics$mae, na.rm = TRUE), NA_real_),
        green_coverage_68_mean = ifelse(nrow(green_cov), mean(green_cov$coverage_68, na.rm = TRUE), NA_real_),
        green_coverage_90_mean = ifelse(nrow(green_cov), mean(green_cov$coverage_90, na.rm = TRUE), NA_real_),
        estimation_time_seconds = ifelse(nrow(pilot_run), pilot_run$elapsed_seconds[1], NA_real_),
        warning = ifelse(nrow(stability_row_df), stability_row_df$warning[1], ""),
        stringsAsFactors = FALSE
      )
    }
  }
  comparison <- dplyr::bind_rows(rows)
  write_csv_safe(comparison, file.path("output", "tables", "bvar", "reduced_form_model_comparison.csv"))
  comparison
}

recommend_models <- function(comparison) {
  lag_rec <- read_csv_optional(file.path("output", "tables", "bvar", "lag_selection_recommendations.csv"))
  candidate <- if ("p_candidate_for_bvar" %in% names(lag_rec)) unique(stats::na.omit(lag_rec$p_candidate_for_bvar))[1] else 1L

  hom <- comparison |> dplyr::filter(variance_type == "homoskedastic")
  sv <- comparison |> dplyr::filter(variance_type == "sv")
  hom_pref <- hom$model[which.max(hom$green_assets_log_predictive_likelihood)]
  sv_pref <- sv$model[which.max(sv$green_assets_log_predictive_likelihood)]

  p2_gain <- comparison$green_assets_log_predictive_likelihood[comparison$model == "BVAR-SV-p2"] -
    comparison$green_assets_log_predictive_likelihood[comparison$model == "BVAR-SV-p1"]
  lag_choice <- ifelse(!is.na(p2_gain) && p2_gain > 2, 2L, as.integer(candidate))

  best_hom <- hom |> dplyr::slice_max(green_assets_log_predictive_likelihood, n = 1, with_ties = FALSE)
  best_sv <- sv |> dplyr::slice_max(green_assets_log_predictive_likelihood, n = 1, with_ties = FALSE)
  sv_lpl_gap <- best_sv$green_assets_log_predictive_likelihood - best_hom$green_assets_log_predictive_likelihood
  sv_ok <- is.na(best_sv$unstable_pct) || best_sv$unstable_pct <= 10
  variance_choice <- ifelse(!is.na(sv_lpl_gap) && sv_lpl_gap >= -2 && sv_ok, "BVAR-SV", "BVAR-HOM")

  data.frame(
    p_candidate_from_lag_selection = candidate,
    p_recommended_for_next_stage = lag_choice,
    homoskedastic_preferred = hom_pref,
    sv_preferred = sv_pref,
    variance_recommendation = variance_choice,
    sv_green_lpl_gap_vs_best_hom = sv_lpl_gap,
    recommendation = paste(
      "Use", variance_choice, "with p =", lag_choice,
      "as the reduced-form candidate for the structural stage, subject to reviewing diagnostics."
    ),
    stringsAsFactors = FALSE
  )
}

csv_block <- function(df, n = 20) {
  if (nrow(df) == 0) return("No rows.\n")
  paste0("```csv\n", paste(capture.output(readr::write_csv(head(df, n), stdout())), collapse = "\n"), "\n```")
}

write_stage2_report <- function(comparison, recommendation) {
  data <- load_stage2_data()
  checks <- read_csv_optional(file.path("output", "tables", "stage2_data_check.csv"))
  units <- read_csv_optional(file.path("output", "tables", "bvar", "stage2_variable_units.csv"))
  lag_criteria <- read_csv_optional(file.path("output", "tables", "bvar", "lag_selection_criteria.csv"))
  var_stability <- read_csv_optional(file.path("output", "tables", "bvar", "var_stability.csv"))
  prior <- read_csv_optional(file.path("output", "tables", "bvar", "prior_specifications.csv"))
  extension <- read_csv_optional(file.path("output", "tables", "bvar", "mcmc_extension_decision.csv"))
  mcmc <- read_csv_optional(file.path("output", "tables", "bvar", "mcmc_diagnostics.csv"))
  stability <- read_csv_optional(file.path("output", "tables", "bvar", "posterior_stability.csv"))
  residual <- read_csv_optional(file.path("output", "tables", "bvar", "bvar_residual_ljung_box.csv"))
  sv_extremes <- read_csv_optional(file.path("output", "tables", "bvar", "stochastic_volatility_extremes.csv"))
  forecast <- read_csv_optional(file.path("output", "tables", "bvar", "forecast_metrics.csv"))
  lpl <- read_csv_optional(file.path("output", "tables", "bvar", "log_predictive_likelihood.csv"))
  ppc <- read_csv_optional(file.path("output", "tables", "bvar", "posterior_predictive_checks.csv"))

  warnings <- c(
    stability$warning[!is.na(stability$warning) & stability$warning != ""],
    comparison$warning[!is.na(comparison$warning) & comparison$warning != ""]
  )
  warnings_text <- if (length(warnings)) paste("- ", unique(warnings), collapse = "\n") else "- No major warnings recorded."

  report <- paste0(
    "# Stage 2 Reduced-Form BVAR Report\n\n",
    "## Data\n\n",
    "- Input file: `data_processed/data_model_diff.csv`\n",
    "- Observations: ", nrow(data$model_data), "\n",
    "- Variables: ", paste(data$variable_order, collapse = ", "), "\n",
    "- Bund 2Y is kept on its raw numeric first-difference scale. It is not multiplied by 100 or 10000.\n",
    "- No standardization, normalization, rescaling, outlier removal, dummy variables, IRF, FEVD, or structural restrictions are used.\n\n",
    "Data checks:\n\n", csv_block(checks), "\n\n",
    "Variable units:\n\n", csv_block(units), "\n\n",
    "## Lag Selection\n\n", csv_block(lag_criteria), "\n\n",
    "## VAR Benchmarks\n\n",
    "Classical VAR(1) and VAR(2) are estimated only as reduced-form benchmarks.\n\n",
    csv_block(var_stability), "\n\n",
    "## Priors and MCMC Settings\n\n", csv_block(prior), "\n\n",
    "MCMC extension decision:\n\n", csv_block(extension), "\n\n",
    "## MCMC Diagnostics\n\n", csv_block(mcmc), "\n\n",
    "## Posterior Stability\n\n", csv_block(stability), "\n\n",
    "## Residual Diagnostics\n\n", csv_block(residual), "\n\n",
    "## Stochastic Volatility\n\n",
    "Stochastic volatility is residual covariance variation through time, not time variation in VAR coefficients.\n\n",
    csv_block(sv_extremes), "\n\n",
    "## Predictive Evaluation\n\n",
    "Forecast evaluation uses the last 12 observations as test set and prioritizes density forecasts over RMSE alone.\n\n",
    csv_block(lpl), "\n\n", csv_block(forecast), "\n\n",
    "## Posterior Predictive Checks\n\n", csv_block(ppc), "\n\n",
    "## Model Comparison\n\n", csv_block(comparison), "\n\n",
    "## Warnings\n\n", warnings_text, "\n\n",
    "## Recommendation\n\n", csv_block(recommendation), "\n\n",
    "No structural shocks, sign restrictions, zero restrictions, narrative restrictions, impulse responses, FEVD, historical decomposition, or counterfactual analysis are computed in this stage.\n"
  )
  writeLines(report, file.path("output", "reports", "stage2_reduced_form_bvar_report.md"), useBytes = TRUE)
}

main <- function() {
  ensure_stage2_dirs()
  load_stage2_packages()
  log_msg("BVAR model comparison started.")
  comparison <- build_model_comparison()
  recommendation <- recommend_models(comparison)
  write_csv_safe(recommendation, file.path("output", "tables", "bvar", "stage2_model_recommendation.csv"))
  write_stage2_report(comparison, recommendation)
  writeLines(capture.output(sessionInfo()), file.path("output", "reports", "sessionInfo_stage2.txt"), useBytes = TRUE)
  log_msg("BVAR model comparison completed.")
}

if (identical(environment(), globalenv())) {
  main()
}
