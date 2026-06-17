suppressPackageStartupMessages({
  library(utils)
})

required_stage2_packages <- c(
  "readr", "dplyr", "tidyr", "ggplot2", "vars", "bayesianVARs",
  "posterior", "coda", "forecast", "tseries", "moments", "patchwork"
)

stage2_dirs <- c(
  "R",
  "output/models",
  "output/tables/bvar",
  "output/figures/bvar",
  "output/figures/bvar/mcmc",
  "output/figures/bvar/residuals",
  "output/figures/bvar/volatility",
  "output/figures/bvar/forecasts",
  "output/logs",
  "output/reports"
)

base_model_vars <- c(
  "EUA_ret",
  "TTF_ret",
  "Brent_ret",
  "Power_ret",
  "CPI_yoy_change",
  "IP_growth",
  "Bund2Y_change",
  "CISS_change",
  "GreenEquity_relative",
  "GreenBond_relative"
)

green_vars <- c("GreenEquity_relative", "GreenBond_relative")

stage2_model_index <- file.path("output", "tables", "bvar", "estimated_models.csv")

ensure_stage2_dirs <- function() {
  invisible(lapply(stage2_dirs, dir.create, recursive = TRUE, showWarnings = FALSE))
}

log_msg <- function(...) {
  cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "-", ..., "\n")
}

check_stage2_packages <- function(stop_on_missing = TRUE) {
  installed <- rownames(installed.packages())
  result <- data.frame(
    package = required_stage2_packages,
    installed = required_stage2_packages %in% installed,
    version = vapply(required_stage2_packages, function(pkg) {
      if (pkg %in% installed) as.character(packageVersion(pkg)) else NA_character_
    }, character(1)),
    stringsAsFactors = FALSE
  )
  readr::write_csv(result, file.path("output", "tables", "bvar", "stage2_package_check.csv"))
  missing <- result$package[!result$installed]
  if (length(missing) > 0) {
    msg <- paste("Missing R packages:", paste(missing, collapse = ", "))
    message(msg)
    if (stop_on_missing) stop(msg, call. = FALSE)
  }
  invisible(result)
}

load_stage2_packages <- function() {
  check_stage2_packages(stop_on_missing = TRUE)
  suppressPackageStartupMessages({
    library(readr)
    library(dplyr)
    library(tidyr)
    library(ggplot2)
    library(vars)
    library(bayesianVARs)
    library(posterior)
    library(coda)
    library(forecast)
    library(tseries)
    library(moments)
    library(patchwork)
  })
}

write_csv_safe <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(x, path)
}

save_rds_safe <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(x, path)
}

find_bund_column <- function(columns) {
  if ("Bund2Y_change" %in% columns) return("Bund2Y_change")
  candidates <- grep("bund.*(change|diff)|bund2y.*(change|diff)", columns, ignore.case = TRUE, value = TRUE)
  candidates <- candidates[!grepl("bps", candidates, ignore.case = TRUE)]
  if (length(candidates) == 0) {
    candidates <- grep("bund.*(change|diff)|bund2y.*(change|diff)", columns, ignore.case = TRUE, value = TRUE)
  }
  if (length(candidates) != 1) {
    stop("Could not uniquely identify the Bund 2Y first-difference column.", call. = FALSE)
  }
  candidates
}

stage2_variable_order <- function(columns) {
  vars <- base_model_vars
  bund_col <- find_bund_column(columns)
  vars[vars == "Bund2Y_change"] <- bund_col
  vars
}

prepare_stage2_data <- function(input_path = file.path("data_processed", "data_model_diff.csv")) {
  ensure_stage2_dirs()
  if (!file.exists(input_path)) stop("Input file not found: ", input_path, call. = FALSE)

  raw <- readr::read_csv(input_path, show_col_types = FALSE)
  checks <- list()
  add_check <- function(check, status, detail = "", value = NA_character_) {
    checks[[length(checks) + 1]] <<- data.frame(
      check = check, status = status, detail = as.character(detail), value = as.character(value),
      stringsAsFactors = FALSE
    )
  }

  add_check("file_exists", "PASS", input_path)
  if (!"Date" %in% names(raw)) stop("Date column is missing.", call. = FALSE)
  raw$Date <- as.Date(raw$Date)
  if (any(is.na(raw$Date))) stop("Date conversion produced NA values.", call. = FALSE)

  vars <- stage2_variable_order(names(raw))
  missing_vars <- setdiff(vars, names(raw))
  if (length(missing_vars) > 0) stop("Missing model columns: ", paste(missing_vars, collapse = ", "), call. = FALSE)
  add_check("model_variable_order", "PASS", paste(vars, collapse = " | "))

  raw <- raw[order(raw$Date), ]
  duplicate_dates <- raw$Date[duplicated(raw$Date)]
  if (length(duplicate_dates) > 0) stop("Duplicate dates found: ", paste(duplicate_dates, collapse = ", "), call. = FALSE)
  add_check("duplicate_dates", "PASS", "No duplicate dates")

  if (is.unsorted(raw$Date)) stop("Dates are not chronologically ordered after sorting.", call. = FALSE)
  add_check("chronological_order", "PASS", "Dates sorted ascending")

  model_df <- raw[, vars, drop = FALSE]
  numeric_flags <- vapply(model_df, is.numeric, logical(1))
  if (!all(numeric_flags)) {
    stop("Non-numeric model columns: ", paste(names(model_df)[!numeric_flags], collapse = ", "), call. = FALSE)
  }
  add_check("numeric_columns", "PASS", "All model columns are numeric")

  na_count <- sum(is.na(model_df))
  finite_count <- sum(!is.finite(as.matrix(model_df)))
  if (na_count > 0) stop("NA values found in model data: ", na_count, call. = FALSE)
  if (finite_count > 0) stop("Infinite or non-finite values found in model data: ", finite_count, call. = FALSE)
  add_check("missing_values", "PASS", "No NA values", na_count)
  add_check("finite_values", "PASS", "No infinite values", finite_count)

  model_matrix <- as.matrix(model_df)
  storage.mode(model_matrix) <- "double"
  rank_value <- qr(model_matrix)$rank
  zero_variance <- names(model_df)[vapply(model_df, function(x) stats::var(x) == 0, logical(1))]
  max_abs <- apply(abs(model_matrix), 2, max)
  min_abs_nonzero <- apply(abs(model_matrix), 2, function(x) min(x[x > 0], na.rm = TRUE))

  add_check("observations", "PASS", nrow(model_matrix))
  add_check("rank", ifelse(rank_value == ncol(model_matrix), "PASS", "WARN"), rank_value, paste0("columns=", ncol(model_matrix)))
  add_check("zero_variance", ifelse(length(zero_variance) == 0, "PASS", "FAIL"), paste(zero_variance, collapse = ", "))
  add_check("bund_scale", "PASS", "Bund 2Y first difference kept on raw numeric scale", vars[vars == find_bund_column(names(raw))])

  magnitude <- data.frame(
    variable = names(model_df),
    max_abs = as.numeric(max_abs),
    min_abs_nonzero = as.numeric(min_abs_nonzero),
    flagged_large = as.numeric(max_abs) > 100,
    flagged_tiny = as.numeric(max_abs) < 1e-8,
    stringsAsFactors = FALSE
  )
  write_csv_safe(magnitude, file.path("output", "tables", "bvar", "stage2_numeric_magnitudes.csv"))
  if (length(zero_variance) > 0) stop("Zero-variance model columns found.", call. = FALSE)

  checks_df <- dplyr::bind_rows(checks)
  write_csv_safe(checks_df, file.path("output", "tables", "stage2_data_check.csv"))
  write_csv_safe(cbind(Date = raw$Date, as.data.frame(model_matrix)), file.path("output", "tables", "bvar", "model_data_used.csv"))
  save_rds_safe(list(dates = raw$Date, model_data = model_matrix, variable_order = vars), file.path("output", "models", "stage2_model_data.rds"))
  list(dates = raw$Date, model_data = model_matrix, variable_order = vars, checks = checks_df)
}

load_stage2_data <- function() {
  path <- file.path("output", "models", "stage2_model_data.rds")
  if (!file.exists(path)) return(prepare_stage2_data())
  readRDS(path)
}

stage2_mcmc_settings <- function() {
  profile <- Sys.getenv("STAGE2_MCMC_PROFILE", unset = "full")
  if (tolower(profile) == "smoke") {
    return(list(
      profile = "smoke",
      pilot_burnin = 50L, pilot_draws = 50L,
      final_burnin = 100L, final_draws = 100L,
      forecast_burnin = 50L, forecast_draws = 50L,
      thin = 1L
    ))
  }
  list(
    profile = "full",
    pilot_burnin = 2000L, pilot_draws = 2000L,
    final_burnin = 10000L, final_draws = 10000L,
    forecast_burnin = 5000L, forecast_draws = 5000L,
    thin = 1L
  )
}

prior_spec_row <- function(model_id, p, variance_type, sv_enabled) {
  data.frame(
    model_id = model_id,
    lag = p,
    coefficient_prior_function = "specify_prior_phi",
    coefficient_prior = "HMP",
    coefficient_priormean = 0,
    intercept_prior_sd = 10,
    sigma_prior_function = "specify_prior_sigma",
    sigma_type = "cholesky",
    cholesky_U_prior = "HMP",
    cholesky_heteroscedastic = sv_enabled,
    sv_keep = ifelse(sv_enabled, "all", "last"),
    variance_type = variance_type,
    stringsAsFactors = FALSE
  )
}

fit_bvar_model <- function(model_data, p, variance_type, burnin, draws, thin, seed, output_path, quiet = FALSE) {
  if (!variance_type %in% c("homoskedastic", "sv")) stop("Unknown variance_type.", call. = FALSE)
  sv_enabled <- variance_type == "sv"
  set.seed(seed)
  prior_phi <- bayesianVARs::specify_prior_phi(
    data = model_data,
    lags = p,
    prior = "HMP",
    priormean = 0
  )
  prior_sigma <- bayesianVARs::specify_prior_sigma(
    data = model_data,
    type = "cholesky",
    cholesky_U_prior = "HMP",
    cholesky_heteroscedastic = sv_enabled,
    quiet = TRUE
  )
  start <- Sys.time()
  fit <- bayesianVARs::bvar(
    data = model_data,
    lags = p,
    draws = draws,
    burnin = burnin,
    thin = thin,
    prior_intercept = 10,
    prior_phi = prior_phi,
    prior_sigma = prior_sigma,
    sv_keep = ifelse(sv_enabled, "all", "last"),
    quiet = quiet
  )
  elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
  save_rds_safe(fit, output_path)
  attr(fit, "elapsed_seconds") <- elapsed
  fit
}

append_model_index <- function(rows) {
  existing <- if (file.exists(stage2_model_index)) readr::read_csv(stage2_model_index, show_col_types = FALSE) else NULL
  combined <- dplyr::bind_rows(existing, rows) |>
    dplyr::distinct(model_id, file, .keep_all = TRUE)
  write_csv_safe(combined, stage2_model_index)
}

draw_count <- function(fit) {
  dim(fit[["PHI"]])[3]
}

stability_row <- function(model_id, file, stable_file = NULL) {
  fit <- readRDS(file)
  total <- draw_count(fit)
  stable <- bayesianVARs::stable_bvar(fit, quiet = TRUE)
  stable_n <- draw_count(stable)
  if (!is.null(stable_file)) save_rds_safe(stable, stable_file)
  unstable_pct <- 100 * (total - stable_n) / total
  data.frame(
    model_id = model_id,
    total_draws = total,
    stable_draws = stable_n,
    unstable_draws = total - stable_n,
    unstable_pct = unstable_pct,
    warning = dplyr::case_when(
      unstable_pct > 10 ~ "IMPORTANT: more than 10% unstable posterior draws",
      unstable_pct > 5 ~ "WARNING: more than 5% unstable posterior draws",
      TRUE ~ ""
    ),
    original_file = file,
    stable_file = ifelse(is.null(stable_file), "", stable_file),
    stringsAsFactors = FALSE
  )
}

extract_monitor_matrix <- function(fit) {
  phi <- fit[["PHI"]]
  row_names <- dimnames(phi)[[1]]
  eq_names <- dimnames(phi)[[2]]
  draws <- dim(phi)[3]
  out <- list()

  add_phi <- function(row, eq, label) {
    if (row %in% row_names && eq %in% eq_names) {
      out[[label]] <<- phi[row, eq, ]
    }
  }

  for (v in eq_names) {
    add_phi(paste0(v, ".l1"), v, paste0("own_lag1__", v))
  }

  lagged_drivers <- c("EUA_ret", "TTF_ret", "Brent_ret", "Power_ret", "CPI_yoy_change", "IP_growth", "Bund2Y_change", "CISS_change")
  for (eq in intersect(green_vars, eq_names)) {
    for (driver in lagged_drivers) {
      for (lag in seq_len(fit[["lags"]])) {
        add_phi(paste0(driver, ".l", lag), eq, paste0("lag", lag, "__", driver, "__to__", eq))
      }
    }
    add_phi("intercept", eq, paste0("intercept__", eq))
  }

  sv_para <- fit[["sv_para"]]
  if (length(dim(sv_para)) == 3 && dim(sv_para)[3] == draws) {
    sv_labels <- c("sv_mu", "sv_phi", "sv_sigma2")
    sv_vars <- dimnames(sv_para)[[2]]
    if (is.null(sv_vars)) sv_vars <- eq_names
    for (i in seq_len(dim(sv_para)[1])) {
      for (j in seq_len(dim(sv_para)[2])) {
        label <- paste0(sv_labels[pmin(i, length(sv_labels))], "__", sv_vars[j])
        out[[label]] <- sv_para[i, j, ]
      }
    }
  }

  u <- fit[["U"]]
  if (length(dim(u)) == 2 && dim(u)[2] == draws) {
    max_u <- min(10, dim(u)[1])
    for (i in seq_len(max_u)) out[[paste0("cholesky_U_", i)]] <- u[i, ]
  }

  if (length(out) == 0) return(matrix(numeric(0), nrow = draws, ncol = 0))
  mat <- do.call(cbind, out)
  mat <- as.matrix(mat)
  storage.mode(mat) <- "double"
  mat
}

model_effective_dates <- function(fit, all_dates) {
  all_dates[(fit[["lags"]] + 1):length(all_dates)]
}

residual_array <- function(fit) {
  stats::residuals(fit)[["resids"]]
}

median_residuals <- function(fit) {
  apply(residual_array(fit), c(1, 2), stats::median, na.rm = TRUE)
}

conditional_sd_array <- function(fit) {
  logvar <- fit[["logvar"]]
  if (length(dim(logvar)) == 3 && dim(logvar)[1] > 1) {
    return(exp(0.5 * logvar))
  }
  vc <- stats::vcov(fit)
  if (length(dim(vc)) == 4) {
    draws <- dim(vc)[4]
    m <- dim(vc)[2]
    sd_draws <- matrix(NA_real_, nrow = m, ncol = draws)
    for (d in seq_len(draws)) {
      sd_draws[, d] <- sqrt(diag(vc[1, , , d]))
    }
    t_eff <- nrow(fit[["Y"]])
    arr <- array(NA_real_, dim = c(t_eff, m, draws))
    for (d in seq_len(draws)) arr[, , d] <- matrix(sd_draws[, d], nrow = t_eff, ncol = m, byrow = TRUE)
    dimnames(arr) <- list(NULL, colnames(fit[["Y"]]), NULL)
    return(arr)
  }
  stop("Could not extract conditional standard deviations.", call. = FALSE)
}

ljung_rows_for_matrix <- function(model_id, matrix_values, squared = FALSE, lags = c(6, 12)) {
  values <- as.matrix(matrix_values)
  rows <- list()
  for (var in colnames(values)) {
    series <- values[, var]
    if (squared) series <- series^2
    for (lag in lags) {
      test <- try(stats::Box.test(series, lag = lag, type = "Ljung-Box"), silent = TRUE)
      rows[[length(rows) + 1]] <- data.frame(
        model_id = model_id,
        variable = var,
        lag = lag,
        statistic = if (inherits(test, "try-error")) NA_real_ else unname(test$statistic),
        p_value = if (inherits(test, "try-error")) NA_real_ else test$p.value,
        squared_residual = squared,
        warning = if (inherits(test, "try-error")) as.character(test) else "",
        stringsAsFactors = FALSE
      )
    }
  }
  dplyr::bind_rows(rows)
}

safe_quantile <- function(x, probs) {
  as.numeric(stats::quantile(x, probs = probs, na.rm = TRUE, names = FALSE))
}

plot_series_with_intervals <- function(df, x, y, ymin90, ymax90, ymin68, ymax68, title, ylab, output_path) {
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[[x]])) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data[[ymin90]], ymax = .data[[ymax90]]), alpha = 0.18) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data[[ymin68]], ymax = .data[[ymax68]]), alpha = 0.28) +
    ggplot2::geom_line(ggplot2::aes(y = .data[[y]])) +
    ggplot2::labs(title = title, x = "Date", y = ylab) +
    ggplot2::theme_minimal()
  ggplot2::ggsave(output_path, p, width = 9, height = 5, dpi = 150)
}
