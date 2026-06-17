source(file.path("R", "stage2_common.R"))

read_candidate_lag <- function() {
  path <- file.path("output", "tables", "bvar", "lag_selection_recommendations.csv")
  if (!file.exists(path)) return(1L)
  rec <- readr::read_csv(path, show_col_types = FALSE)
  candidate <- unique(stats::na.omit(rec$p_candidate_for_bvar))
  if (length(candidate) == 0) 1L else as.integer(candidate[1])
}

fit_sv_models <- function(model_data) {
  settings <- stage2_mcmc_settings()
  rows <- list()
  prior_rows <- list()

  for (p in c(1L, 2L)) {
    model_id <- paste0("BVAR-SV-p", p, "-pilot")
    file <- file.path("output", "models", paste0("bvar_sv_p", p, "_pilot.rds"))
    log_msg("Estimating", model_id, "burnin=", settings$pilot_burnin, "draws=", settings$pilot_draws, "sv_keep=all")
    start <- Sys.time()
    fit_bvar_model(
      model_data = model_data,
      p = p,
      variance_type = "sv",
      burnin = settings$pilot_burnin,
      draws = settings$pilot_draws,
      thin = settings$thin,
      seed = 20360 + p,
      output_path = file,
      quiet = TRUE
    )
    elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
    rows[[length(rows) + 1]] <- data.frame(
      model_id = model_id, lag = p, variance_type = "sv",
      run_type = "pilot", chain = NA_integer_, seed = 20360 + p,
      burnin = settings$pilot_burnin, draws = settings$pilot_draws,
      thin = settings$thin, elapsed_seconds = elapsed, file = file,
      stringsAsFactors = FALSE
    )
    prior_rows[[length(prior_rows) + 1]] <- prior_spec_row(model_id, p, "sv", TRUE)
  }

  p_selected <- read_candidate_lag()
  for (chain in seq_along(c(20261L, 20262L, 20263L))) {
    seed <- c(20261L, 20262L, 20263L)[chain] + 100L
    model_id <- paste0("BVAR-SV-final-chain", chain)
    file <- file.path("output", "models", paste0("bvar_sv_final_chain", chain, ".rds"))
    log_msg("Estimating", model_id, "p=", p_selected, "burnin=", settings$final_burnin, "draws=", settings$final_draws, "sv_keep=all")
    start <- Sys.time()
    fit_bvar_model(
      model_data = model_data,
      p = p_selected,
      variance_type = "sv",
      burnin = settings$final_burnin,
      draws = settings$final_draws,
      thin = settings$thin,
      seed = seed,
      output_path = file,
      quiet = TRUE
    )
    elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
    rows[[length(rows) + 1]] <- data.frame(
      model_id = model_id, lag = p_selected, variance_type = "sv",
      run_type = "final", chain = chain, seed = seed,
      burnin = settings$final_burnin, draws = settings$final_draws,
      thin = settings$thin, elapsed_seconds = elapsed, file = file,
      stringsAsFactors = FALSE
    )
    prior_rows[[length(prior_rows) + 1]] <- prior_spec_row(model_id, p_selected, "sv", TRUE)
  }

  model_rows <- dplyr::bind_rows(rows)
  prior_df <- dplyr::bind_rows(prior_rows)
  append_model_index(model_rows)

  existing_prior <- if (file.exists(file.path("output", "tables", "bvar", "prior_specifications.csv"))) {
    readr::read_csv(file.path("output", "tables", "bvar", "prior_specifications.csv"), show_col_types = FALSE)
  } else {
    NULL
  }
  write_csv_safe(
    dplyr::bind_rows(existing_prior, prior_df) |> dplyr::distinct(model_id, .keep_all = TRUE),
    file.path("output", "tables", "bvar", "prior_specifications.csv")
  )
  write_csv_safe(model_rows, file.path("output", "tables", "bvar", "bvar_sv_estimation_runs.csv"))
  invisible(model_rows)
}

main <- function() {
  ensure_stage2_dirs()
  load_stage2_packages()
  log_msg("BVAR-SV estimation started.")
  data <- load_stage2_data()
  fit_sv_models(data$model_data)
  log_msg("BVAR-SV estimation completed.")
}

if (identical(environment(), globalenv())) {
  main()
}

