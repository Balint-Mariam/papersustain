source(file.path("R", "stage2_common.R"))

read_model_index <- function() {
  if (!file.exists(stage2_model_index)) stop("Model index not found. Run scripts 07 and 08 first.", call. = FALSE)
  readr::read_csv(stage2_model_index, show_col_types = FALSE)
}

diagnose_final_chains <- function(index) {
  final <- index |> dplyr::filter(run_type == "final")
  groups <- split(final, final$variance_type)
  diagnostics <- list()
  monitored <- list()

  for (variance_type in names(groups)) {
    group <- groups[[variance_type]] |> dplyr::arrange(chain)
    mats <- lapply(group$file, function(path) extract_monitor_matrix(readRDS(path)))
    common_params <- Reduce(intersect, lapply(mats, colnames))
    if (length(common_params) == 0) next
    n_iter <- min(vapply(mats, nrow, integer(1)))
    arr <- array(
      NA_real_,
      dim = c(n_iter, length(mats), length(common_params)),
      dimnames = list(NULL, paste0("chain", group$chain), common_params)
    )
    for (i in seq_along(mats)) arr[, i, ] <- mats[[i]][seq_len(n_iter), common_params, drop = FALSE]
    draws <- posterior::as_draws_array(arr)
    summary <- posterior::summarise_draws(draws, "mean", "sd", "rhat", "ess_bulk", "ess_tail", "mcse_mean")
    summary$model_group <- paste0("BVAR-", toupper(variance_type), "-final")
    diagnostics[[length(diagnostics) + 1]] <- as.data.frame(summary)

    for (i in seq_along(mats)) {
      ess <- coda::effectiveSize(coda::mcmc(mats[[i]][, common_params, drop = FALSE]))
      monitored[[length(monitored) + 1]] <- data.frame(
        model_id = group$model_id[i],
        chain = group$chain[i],
        parameter = common_params,
        chain_effective_sample_size = as.numeric(ess[common_params]),
        stringsAsFactors = FALSE
      )
    }

    plot_params <- head(common_params, 24)
    long <- dplyr::bind_rows(lapply(seq_along(mats), function(i) {
      data.frame(draw = seq_len(n_iter), chain = paste0("chain", group$chain[i]), mats[[i]][seq_len(n_iter), plot_params, drop = FALSE]) |>
        tidyr::pivot_longer(cols = dplyr::all_of(plot_params), names_to = "parameter", values_to = "value")
    }))
    trace_plot <- ggplot2::ggplot(long, ggplot2::aes(x = draw, y = value, color = chain)) +
      ggplot2::geom_line(linewidth = 0.2, alpha = 0.75) +
      ggplot2::facet_wrap(~parameter, scales = "free_y") +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = paste("Trace plots:", variance_type), x = "Draw", y = "Value")
    ggplot2::ggsave(file.path("output", "figures", "bvar", "mcmc", paste0("trace_", variance_type, ".png")), trace_plot, width = 12, height = 9, dpi = 150)

    density_plot <- ggplot2::ggplot(long, ggplot2::aes(x = value, color = chain)) +
      ggplot2::geom_density(linewidth = 0.4) +
      ggplot2::facet_wrap(~parameter, scales = "free") +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = paste("Posterior densities:", variance_type), x = "Value", y = "Density")
    ggplot2::ggsave(file.path("output", "figures", "bvar", "mcmc", paste0("density_", variance_type, ".png")), density_plot, width = 12, height = 9, dpi = 150)

    acf_rows <- list()
    for (param in head(common_params, 12)) {
      for (i in seq_along(mats)) {
        ac <- stats::acf(mats[[i]][seq_len(n_iter), param], plot = FALSE, lag.max = 40)
        acf_rows[[length(acf_rows) + 1]] <- data.frame(
          parameter = param,
          chain = paste0("chain", group$chain[i]),
          lag = as.integer(ac$lag[, 1, 1]),
          acf = as.numeric(ac$acf[, 1, 1]),
          stringsAsFactors = FALSE
        )
      }
    }
    acf_df <- dplyr::bind_rows(acf_rows)
    acf_plot <- ggplot2::ggplot(acf_df, ggplot2::aes(x = lag, y = acf, color = chain)) +
      ggplot2::geom_hline(yintercept = 0, linewidth = 0.2) +
      ggplot2::geom_line(linewidth = 0.4) +
      ggplot2::facet_wrap(~parameter, scales = "free_y") +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = paste("MCMC autocorrelation:", variance_type), x = "Lag", y = "ACF")
    ggplot2::ggsave(file.path("output", "figures", "bvar", "mcmc", paste0("acf_", variance_type, ".png")), acf_plot, width = 12, height = 8, dpi = 150)
  }

  diag_df <- dplyr::bind_rows(diagnostics) |>
    dplyr::rename(parameter = variable) |>
    dplyr::mutate(
      rhat_pass = is.na(rhat) | rhat <= 1.01,
      bulk_ess_pass = is.na(ess_bulk) | ess_bulk >= 1000,
      tail_ess_pass = is.na(ess_tail) | ess_tail >= 500
    )
  monitored_df <- dplyr::bind_rows(monitored)
  write_csv_safe(diag_df, file.path("output", "tables", "bvar", "mcmc_diagnostics.csv"))
  write_csv_safe(monitored_df, file.path("output", "tables", "bvar", "mcmc_parameters_monitored.csv"))
  diag_df
}

run_posterior_stability <- function(index) {
  rows <- lapply(seq_len(nrow(index)), function(i) {
    file <- index$file[i]
    stable_file <- file.path("output", "models", paste0(tools::file_path_sans_ext(basename(file)), "_stable_draws.rds"))
    stability_row(index$model_id[i], file, stable_file)
  })
  result <- dplyr::bind_rows(rows)
  write_csv_safe(result, file.path("output", "tables", "bvar", "posterior_stability.csv"))
  result
}

run_residual_diagnostics <- function(index, dates) {
  lb <- list()
  lb_sq <- list()

  for (i in seq_len(nrow(index))) {
    fit <- readRDS(index$file[i])
    med_res <- median_residuals(fit)
    sd_arr <- conditional_sd_array(fit)
    med_sd <- apply(sd_arr, c(1, 2), stats::median, na.rm = TRUE)
    standardized <- med_res / med_sd
    colnames(standardized) <- colnames(fit[["Y"]])

    lb[[length(lb) + 1]] <- ljung_rows_for_matrix(index$model_id[i], standardized, squared = FALSE)
    lb_sq[[length(lb_sq) + 1]] <- ljung_rows_for_matrix(index$model_id[i], standardized, squared = TRUE)

    if (index$run_type[i] == "final" && index$chain[i] == 1) {
      eff_dates <- model_effective_dates(fit, dates)
      for (var in colnames(standardized)) {
        plot_df <- data.frame(Date = eff_dates, residual = standardized[, var])
        p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = Date, y = residual)) +
          ggplot2::geom_hline(yintercept = 0, linewidth = 0.2) +
          ggplot2::geom_line() +
          ggplot2::theme_minimal() +
          ggplot2::labs(title = paste("Standardized residual:", index$model_id[i], var), x = "Date", y = "Standardized residual")
        ggplot2::ggsave(
          file.path("output", "figures", "bvar", "residuals", paste0(gsub("[^A-Za-z0-9]+", "_", index$model_id[i]), "_", var, ".png")),
          p, width = 9, height = 5, dpi = 150
        )
      }
    }
  }

  lb_df <- dplyr::bind_rows(lb)
  lb_sq_df <- dplyr::bind_rows(lb_sq)
  write_csv_safe(lb_df, file.path("output", "tables", "bvar", "bvar_residual_ljung_box.csv"))
  write_csv_safe(lb_sq_df, file.path("output", "tables", "bvar", "bvar_squared_residual_ljung_box.csv"))
  list(level = lb_df, squared = lb_sq_df)
}

summarise_sv_final <- function(index, dates) {
  sv_final <- index |> dplyr::filter(run_type == "final", variance_type == "sv") |> dplyr::arrange(chain)
  if (nrow(sv_final) == 0) return(NULL)
  fits <- lapply(sv_final$file, readRDS)
  p <- fits[[1]][["lags"]]
  eff_dates <- dates[(p + 1):length(dates)]
  sd_arrays <- lapply(fits, conditional_sd_array)
  combined <- array(
    NA_real_,
    dim = c(dim(sd_arrays[[1]])[1], dim(sd_arrays[[1]])[2], sum(vapply(sd_arrays, function(x) dim(x)[3], integer(1))))
  )
  cursor <- 1L
  for (arr in sd_arrays) {
    draw_idx <- cursor:(cursor + dim(arr)[3] - 1L)
    combined[, , draw_idx] <- arr
    cursor <- cursor + dim(arr)[3]
  }
  vars <- colnames(fits[[1]][["Y"]])

  rows <- list()
  for (v in seq_along(vars)) {
    for (t in seq_along(eff_dates)) {
      qs <- safe_quantile(combined[t, v, ], c(0.05, 0.16, 0.5, 0.84, 0.95))
      rows[[length(rows) + 1]] <- data.frame(
        Date = eff_dates[t], variable = vars[v],
        q05 = qs[1], q16 = qs[2], median = qs[3], q84 = qs[4], q95 = qs[5],
        stringsAsFactors = FALSE
      )
    }
  }
  sv_summary <- dplyr::bind_rows(rows)
  write_csv_safe(sv_summary, file.path("output", "tables", "bvar", "stochastic_volatility_summary.csv"))

  max_rows <- sv_summary |>
    dplyr::group_by(variable) |>
    dplyr::slice_max(median, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::left_join(
      sv_summary |> dplyr::group_by(variable) |>
        dplyr::summarise(vol_p05 = stats::quantile(median, 0.05), vol_p50 = stats::median(median), vol_p95 = stats::quantile(median, 0.95), .groups = "drop"),
      by = "variable"
    )
  write_csv_safe(max_rows, file.path("output", "tables", "bvar", "stochastic_volatility_extremes.csv"))

  persistence_rows <- list()
  for (fit in fits) {
    sv_para <- fit[["sv_para"]]
    for (v in seq_along(vars)) {
      persistence_rows[[length(persistence_rows) + 1]] <- data.frame(
        variable = vars[v],
        sv_persistence_median = stats::median(sv_para[2, v, ], na.rm = TRUE),
        sv_persistence_q05 = stats::quantile(sv_para[2, v, ], 0.05, na.rm = TRUE),
        sv_persistence_q95 = stats::quantile(sv_para[2, v, ], 0.95, na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    }
  }
  persistence <- dplyr::bind_rows(persistence_rows) |>
    dplyr::group_by(variable) |>
    dplyr::summarise(dplyr::across(dplyr::starts_with("sv_persistence"), stats::median), .groups = "drop")
  write_csv_safe(persistence, file.path("output", "tables", "bvar", "stochastic_volatility_persistence.csv"))

  for (var in vars) {
    plot_df <- sv_summary |> dplyr::filter(variable == var)
    p_plot <- ggplot2::ggplot(plot_df, ggplot2::aes(x = Date)) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = q05, ymax = q95), alpha = 0.18) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = q16, ymax = q84), alpha = 0.28) +
      ggplot2::geom_line(ggplot2::aes(y = median)) +
      ggplot2::geom_vline(xintercept = as.Date(c("2020-03-31", "2022-02-28")), linewidth = 0.25, linetype = "dashed") +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = paste("Stochastic volatility:", var), subtitle = "Vertical markers are historical references, not estimated regimes.", x = "Date", y = "Conditional standard deviation")
    ggplot2::ggsave(file.path("output", "figures", "bvar", "volatility", paste0(var, "_sv.png")), p_plot, width = 9, height = 5, dpi = 150)
  }
  sv_summary
}

fit_forecast_models <- function(model_data, dates) {
  settings <- stage2_mcmc_settings()
  train <- model_data[seq_len(nrow(model_data) - 12), , drop = FALSE]
  test <- model_data[(nrow(model_data) - 11):nrow(model_data), , drop = FALSE]
  test_dates <- dates[(length(dates) - 11):length(dates)]
  rows_metrics <- list()
  rows_lpl <- list()
  rows_coverage <- list()
  run_rows <- list()

  for (variance_type in c("homoskedastic", "sv")) {
    for (p in c(1L, 2L)) {
      short <- ifelse(variance_type == "sv", "sv", "hom")
      model_id <- paste0("BVAR-", toupper(short), "-p", p, "-forecast")
      file <- file.path("output", "models", paste0("bvar_", short, "_p", p, "_forecast_train.rds"))
      log_msg("Forecast evaluation fit:", model_id)
      start <- Sys.time()
      fit <- fit_bvar_model(
        model_data = train, p = p, variance_type = variance_type,
        burnin = settings$forecast_burnin, draws = settings$forecast_draws,
        thin = settings$thin, seed = 30000 + p + ifelse(variance_type == "sv", 100, 0),
        output_path = file, quiet = TRUE
      )
      elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
      run_rows[[length(run_rows) + 1]] <- data.frame(
        model_id = model_id, lag = p, variance_type = variance_type,
        run_type = "forecast", chain = NA_integer_,
        seed = 30000 + p + ifelse(variance_type == "sv", 100, 0),
        burnin = settings$forecast_burnin, draws = settings$forecast_draws,
        thin = settings$thin, elapsed_seconds = elapsed, file = file,
        stringsAsFactors = FALSE
      )

      pred <- stats::predict(fit, ahead = 1:12, LPL = TRUE, Y_obs = test)
      pred_arr <- pred$predictions
      med <- apply(pred_arr, c(1, 2), stats::median, na.rm = TRUE)
      q16 <- apply(pred_arr, c(1, 2), stats::quantile, probs = 0.16, na.rm = TRUE)
      q84 <- apply(pred_arr, c(1, 2), stats::quantile, probs = 0.84, na.rm = TRUE)
      q05 <- apply(pred_arr, c(1, 2), stats::quantile, probs = 0.05, na.rm = TRUE)
      q95 <- apply(pred_arr, c(1, 2), stats::quantile, probs = 0.95, na.rm = TRUE)
      train_sd <- apply(train, 2, stats::sd)

      for (v in colnames(model_data)) {
        j <- match(v, colnames(model_data))
        err <- med[, j] - test[, j]
        rows_metrics[[length(rows_metrics) + 1]] <- data.frame(
          model_id = model_id, variable = v,
          rmse = sqrt(mean(err^2)),
          mae = mean(abs(err)),
          normalized_rmse = sqrt(mean(err^2)) / train_sd[j],
          stringsAsFactors = FALSE
        )
        rows_coverage[[length(rows_coverage) + 1]] <- data.frame(
          model_id = model_id, variable = v,
          coverage_68 = mean(test[, j] >= q16[, j] & test[, j] <= q84[, j]),
          coverage_90 = mean(test[, j] >= q05[, j] & test[, j] <= q95[, j]),
          stringsAsFactors = FALSE
        )
      }

      rows_lpl[[length(rows_lpl) + 1]] <- data.frame(
        model_id = model_id,
        joint_log_predictive_likelihood = ifelse(is.null(pred$LPL), NA_real_, sum(pred$LPL)),
        green_assets_log_predictive_likelihood = ifelse(
          is.null(pred$LPL_univariate),
          NA_real_,
          sum(pred$LPL_univariate[, green_vars, drop = FALSE])
        ),
        stringsAsFactors = FALSE
      )
      if (!is.null(pred$LPL_univariate)) {
        rows_lpl[[length(rows_lpl) + 1]] <- data.frame(
          model_id = paste0(model_id, "__variable__", colnames(model_data)),
          joint_log_predictive_likelihood = colSums(pred$LPL_univariate),
          green_assets_log_predictive_likelihood = NA_real_,
          stringsAsFactors = FALSE
        )
      }

      for (v in green_vars) {
        j <- match(v, colnames(model_data))
        fan <- data.frame(
          Date = test_dates, observed = test[, j], q05 = q05[, j], q16 = q16[, j],
          median = med[, j], q84 = q84[, j], q95 = q95[, j]
        )
        plot_series_with_intervals(
          fan, "Date", "median", "q05", "q95", "q16", "q84",
          paste("Forecast fan chart:", model_id, v),
          "Predictive distribution",
          file.path("output", "figures", "bvar", "forecasts", paste0(gsub("[^A-Za-z0-9]+", "_", model_id), "_", v, ".png"))
        )
      }
    }
  }

  forecast_runs <- dplyr::bind_rows(run_rows)
  append_model_index(forecast_runs)
  write_csv_safe(dplyr::bind_rows(rows_metrics), file.path("output", "tables", "bvar", "forecast_metrics.csv"))
  write_csv_safe(dplyr::bind_rows(rows_lpl), file.path("output", "tables", "bvar", "log_predictive_likelihood.csv"))
  write_csv_safe(dplyr::bind_rows(rows_coverage), file.path("output", "tables", "bvar", "forecast_interval_coverage.csv"))
  write_csv_safe(forecast_runs, file.path("output", "tables", "bvar", "forecast_estimation_runs.csv"))
}

posterior_predictive_checks <- function(index) {
  selected <- index |>
    dplyr::filter(run_type == "final", chain == 1) |>
    dplyr::arrange(variance_type)
  rows <- list()
  set.seed(40404)
  for (i in seq_len(nrow(selected))) {
    fit <- readRDS(selected$file[i])
    fitted_arr <- stats::fitted(fit)$fitted
    sd_arr <- conditional_sd_array(fit)
    y_obs <- fit[["Y"]]
    vars <- colnames(y_obs)
    draws <- dim(fitted_arr)[3]
    for (v in seq_along(vars)) {
      obs <- y_obs[, v]
      sim_stats <- matrix(NA_real_, nrow = draws, ncol = 7)
      colnames(sim_stats) <- c("mean", "sd", "skewness", "kurtosis", "minimum", "maximum", "max_abs")
      for (d in seq_len(draws)) {
        replicated <- fitted_arr[, v, d] + stats::rnorm(nrow(fitted_arr), sd = sd_arr[, v, d])
        sim_stats[d, ] <- c(
          mean(replicated), stats::sd(replicated), moments::skewness(replicated),
          moments::kurtosis(replicated), min(replicated), max(replicated), max(abs(replicated))
        )
      }
      obs_stats <- c(
        mean(obs), stats::sd(obs), moments::skewness(obs), moments::kurtosis(obs),
        min(obs), max(obs), max(abs(obs))
      )
      names(obs_stats) <- c("mean", "sd", "skewness", "kurtosis", "minimum", "maximum", "max_abs")
      for (stat_name in names(obs_stats)) {
        rows[[length(rows) + 1]] <- data.frame(
          model_id = selected$model_id[i], variable = vars[v], statistic = stat_name,
          observed = unname(obs_stats[stat_name]),
          simulated_median = stats::median(sim_stats[, stat_name], na.rm = TRUE),
          simulated_q05 = stats::quantile(sim_stats[, stat_name], 0.05, na.rm = TRUE),
          simulated_q95 = stats::quantile(sim_stats[, stat_name], 0.95, na.rm = TRUE),
          posterior_predictive_p_value = mean(sim_stats[, stat_name] >= obs_stats[stat_name], na.rm = TRUE),
          note = "Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.",
          stringsAsFactors = FALSE
        )
      }
    }
  }
  checks <- dplyr::bind_rows(rows)
  write_csv_safe(checks, file.path("output", "tables", "bvar", "posterior_predictive_checks.csv"))
  checks
}

main <- function() {
  ensure_stage2_dirs()
  load_stage2_packages()
  log_msg("BVAR diagnostics started.")
  data <- load_stage2_data()
  index <- read_model_index()
  diagnose_final_chains(index)
  run_residual_diagnostics(index, data$dates)
  summarise_sv_final(index, data$dates)
  fit_forecast_models(data$model_data, data$dates)
  run_posterior_stability(read_model_index())
  posterior_predictive_checks(read_model_index())
  log_msg("BVAR diagnostics completed.")
}

if (identical(environment(), globalenv())) {
  main()
}
