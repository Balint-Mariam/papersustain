source(file.path("R", "stage2_common.R"))

lag_parameter_table <- function(n_obs, n_vars, max_lag = 4) {
  data.frame(
    lag = seq_len(max_lag),
    regressors_per_equation = seq_len(max_lag) * n_vars + 1,
    effective_observations = n_obs - seq_len(max_lag),
    observation_to_regressor_ratio = (n_obs - seq_len(max_lag)) / (seq_len(max_lag) * n_vars + 1),
    stringsAsFactors = FALSE
  )
}

run_lag_selection <- function(model_data) {
  selection <- vars::VARselect(model_data, lag.max = 4, type = "const")
  criteria <- as.data.frame(t(selection$criteria))
  criteria$lag <- as.integer(gsub("[^0-9]", "", rownames(criteria)))
  criteria <- criteria[, c("lag", setdiff(names(criteria), "lag"))]
  params <- lag_parameter_table(nrow(model_data), ncol(model_data), max_lag = 4)
  criteria <- dplyr::left_join(criteria, params, by = "lag")

  recommended <- data.frame(
    criterion = names(selection$selection),
    recommended_lag = as.integer(selection$selection),
    stringsAsFactors = FALSE
  )
  bic_lag <- recommended$recommended_lag[recommended$criterion %in% c("SC(n)", "SC")]
  hq_lag <- recommended$recommended_lag[recommended$criterion %in% c("HQ(n)", "HQ")]
  candidate <- if (length(bic_lag) && !is.na(bic_lag[1])) bic_lag[1] else if (length(hq_lag)) hq_lag[1] else 1L
  candidate <- min(max(candidate, 1L), 2L)
  recommended$p_candidate_for_bvar <- candidate
  recommended$selection_note <- paste(
    "BVAR estimation is restricted to p=1 and p=2. Candidate lag prioritizes parsimony, SC/BIC, HQ, stability, residual diagnostics, and predictive evaluation."
  )

  write_csv_safe(criteria, file.path("output", "tables", "bvar", "lag_selection_criteria.csv"))
  write_csv_safe(recommended, file.path("output", "tables", "bvar", "lag_selection_recommendations.csv"))
  list(selection = selection, criteria = criteria, recommended = recommended, p_candidate = candidate)
}

var_stability_rows <- function(var_fit, p) {
  roots <- vars::roots(var_fit, modulus = TRUE)
  data.frame(
    model = paste0("VAR(", p, ")"),
    lag = p,
    root_index = seq_along(roots),
    modulus = as.numeric(roots),
    max_modulus = max(as.numeric(roots), na.rm = TRUE),
    stable = max(as.numeric(roots), na.rm = TRUE) < 1,
    stringsAsFactors = FALSE
  )
}

safe_var_test <- function(expr, model, p, lag) {
  result <- try(expr, silent = TRUE)
  if (inherits(result, "try-error")) {
    return(data.frame(
      model = model, lag_order = p, test_lag = lag, statistic = NA_real_,
      parameter = NA_real_, p_value = NA_real_, warning = as.character(result),
      stringsAsFactors = FALSE
    ))
  }
  test <- if (!is.null(result$serial)) result$serial else if (!is.null(result$arch.mul)) result$arch.mul else result$jb.mul
  scalar <- function(x) {
    if (is.null(x) || length(x) == 0) return(NA_real_)
    as.numeric(x[1])
  }
  data.frame(
    model = model,
    lag_order = p,
    test_lag = lag,
    statistic = scalar(test$statistic),
    parameter = scalar(test$parameter),
    p_value = scalar(test$p.value),
    warning = "",
    stringsAsFactors = FALSE
  )
}

run_var_benchmarks <- function(model_data) {
  stability <- list()
  serial <- list()
  arch <- list()
  normality <- list()

  for (p in c(1L, 2L)) {
    model_name <- paste0("VAR(", p, ")")
    fit <- vars::VAR(model_data, p = p, type = "const")
    save_rds_safe(fit, file.path("output", "models", paste0("var_p", p, ".rds")))

    stability[[length(stability) + 1]] <- var_stability_rows(fit, p)
    for (test_lag in c(6L, 12L)) {
      serial[[length(serial) + 1]] <- safe_var_test(
        vars::serial.test(fit, lags.pt = test_lag, type = "PT.adjusted"),
        model_name, p, test_lag
      ) |>
        dplyr::mutate(test = "Portmanteau adjusted")
      serial[[length(serial) + 1]] <- safe_var_test(
        vars::serial.test(fit, lags.bg = test_lag, type = "BG"),
        model_name, p, test_lag
      ) |>
        dplyr::mutate(test = "Breusch-Godfrey LM")
    }

    arch[[length(arch) + 1]] <- safe_var_test(
      vars::arch.test(fit, lags.multi = 6, multivariate.only = TRUE),
      model_name, p, 6
    ) |>
      dplyr::mutate(test = "Multivariate ARCH")

    normality[[length(normality) + 1]] <- safe_var_test(
      vars::normality.test(fit, multivariate.only = TRUE),
      model_name, p, NA_integer_
    ) |>
      dplyr::mutate(test = "Multivariate normality")
  }

  write_csv_safe(dplyr::bind_rows(stability), file.path("output", "tables", "bvar", "var_stability.csv"))
  write_csv_safe(dplyr::bind_rows(serial), file.path("output", "tables", "bvar", "var_serial_correlation.csv"))
  write_csv_safe(dplyr::bind_rows(arch), file.path("output", "tables", "bvar", "var_arch_tests.csv"))
  write_csv_safe(dplyr::bind_rows(normality), file.path("output", "tables", "bvar", "var_normality_tests.csv"))
}

main <- function() {
  ensure_stage2_dirs()
  load_stage2_packages()
  log_msg("Lag selection and VAR benchmark diagnostics started.")
  data <- load_stage2_data()
  run_lag_selection(data$model_data)
  run_var_benchmarks(data$model_data)
  log_msg("Lag selection and VAR benchmark diagnostics completed.")
}

if (identical(environment(), globalenv())) {
  main()
}
