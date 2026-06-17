source(file.path("R", "stage2_common.R"))

stage2_warning_log <- list()

record_stage2_warning <- function(script, warning) {
  stage2_warning_log[[length(stage2_warning_log) + 1]] <<- data.frame(
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    script = script,
    warning = conditionMessage(warning),
    stringsAsFactors = FALSE
  )
  log_msg("WARNING in", script, ":", conditionMessage(warning))
}

with_warning_capture <- function(script, expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      record_stage2_warning(script, w)
      invokeRestart("muffleWarning")
    }
  )
}

run_stage2_script <- function(script) {
  log_msg("Running", script)
  env <- new.env(parent = globalenv())
  sys.source(file.path("R", script), envir = env)
  with_warning_capture(script, env$main())
}

reset_stage2_outputs <- function() {
  if (tolower(Sys.getenv("STAGE2_SKIP_CLEAN", unset = "false")) == "true") {
    log_msg("Skipping Stage 2 output cleanup because STAGE2_SKIP_CLEAN=true.")
    return(invisible(FALSE))
  }
  log_msg("Cleaning Stage 2 outputs before rerun.")
  paths <- c(
    file.path("output", "tables", "bvar"),
    file.path("output", "figures", "bvar"),
    file.path("output", "reports", "stage2_reduced_form_bvar_report.md"),
    file.path("output", "reports", "sessionInfo_stage2.txt"),
    file.path("output", "logs", "stage2_bvar.log")
  )
  for (path in paths) {
    if (dir.exists(path)) unlink(path, recursive = TRUE, force = TRUE)
    if (file.exists(path)) unlink(path, force = TRUE)
  }
  model_files <- list.files(file.path("output", "models"), pattern = "\\.rds$", full.names = TRUE)
  if (length(model_files)) unlink(model_files, force = TRUE)
  ensure_stage2_dirs()
  invisible(TRUE)
}

write_renv_lock <- function() {
  if (!requireNamespace("renv", quietly = TRUE)) {
    log_msg("Package 'renv' is not installed; renv.lock was not updated.")
    return(invisible(FALSE))
  }
  log_msg("Updating renv.lock with installed package versions.")
  renv::snapshot(
    lockfile = "renv.lock",
    prompt = FALSE,
    type = "explicit",
    packages = c(required_stage2_packages, "renv"),
    force = TRUE
  )
  invisible(TRUE)
}

append_warning_section_to_report <- function(warnings_df) {
  report_path <- file.path("output", "reports", "stage2_reduced_form_bvar_report.md")
  if (!file.exists(report_path)) return(invisible(FALSE))
  warning_text <- if (nrow(warnings_df) == 0) {
    "No execution warnings were captured.\n"
  } else {
    paste0(
      "```csv\n",
      paste(capture.output(readr::write_csv(warnings_df, stdout())), collapse = "\n"),
      "\n```\n"
    )
  }
  cat(
    "\n## Execution Warnings\n\n",
    warning_text,
    file = report_path,
    append = TRUE,
    sep = ""
  )
  invisible(TRUE)
}

print_final_summary <- function() {
  index <- if (file.exists(stage2_model_index)) readr::read_csv(stage2_model_index, show_col_types = FALSE) else data.frame()
  recommendation <- if (file.exists(file.path("output", "tables", "bvar", "stage2_model_recommendation.csv"))) {
    readr::read_csv(file.path("output", "tables", "bvar", "stage2_model_recommendation.csv"), show_col_types = FALSE)
  } else {
    data.frame()
  }
  stability <- if (file.exists(file.path("output", "tables", "bvar", "posterior_stability.csv"))) {
    readr::read_csv(file.path("output", "tables", "bvar", "posterior_stability.csv"), show_col_types = FALSE)
  } else {
    data.frame()
  }
  mcmc <- if (file.exists(file.path("output", "tables", "bvar", "mcmc_diagnostics.csv"))) {
    readr::read_csv(file.path("output", "tables", "bvar", "mcmc_diagnostics.csv"), show_col_types = FALSE)
  } else {
    data.frame()
  }
  lpl <- if (file.exists(file.path("output", "tables", "bvar", "log_predictive_likelihood.csv"))) {
    readr::read_csv(file.path("output", "tables", "bvar", "log_predictive_likelihood.csv"), show_col_types = FALSE)
  } else {
    data.frame()
  }
  execution_warnings <- if (file.exists(file.path("output", "tables", "bvar", "stage2_warnings.csv"))) {
    readr::read_csv(file.path("output", "tables", "bvar", "stage2_warnings.csv"), show_col_types = FALSE)
  } else {
    data.frame()
  }

  cat("\n=== Stage 2 summary ===\n")
  if (nrow(index)) {
    cat("Models estimated:\n")
    cat(paste0("- ", index$model_id, " (", index$file, ")"), sep = "\n")
    cat("\n")
  }
  if (nrow(recommendation)) {
    cat("Recommended lag:", recommendation$p_recommended_for_next_stage[1], "\n")
    cat("Preferred homoskedastic model:", recommendation$homoskedastic_preferred[1], "\n")
    cat("Preferred SV model:", recommendation$sv_preferred[1], "\n")
    cat("Variance recommendation:", recommendation$variance_recommendation[1], "\n")
  }
  if (nrow(stability)) {
    cat("Stable draw percentages:\n")
    stable_pct <- 100 - stability$unstable_pct
    cat(paste0("- ", stability$model_id, ": ", round(stable_pct, 2), "%"), sep = "\n")
    cat("\n")
  }
  if (nrow(mcmc)) {
    cat("Max R-hat:", suppressWarnings(max(mcmc$rhat, na.rm = TRUE)), "\n")
    cat("Min bulk ESS:", suppressWarnings(min(mcmc$ess_bulk, na.rm = TRUE)), "\n")
  }
  if (nrow(lpl)) {
    green <- lpl[!grepl("__variable__", lpl$model_id), c("model_id", "green_assets_log_predictive_likelihood")]
    cat("Green-assets predictive log likelihood:\n")
    cat(paste0("- ", green$model_id, ": ", round(green$green_assets_log_predictive_likelihood, 3)), sep = "\n")
    cat("\n")
  }
  warnings <- unique(c(
    stability$warning[!is.na(stability$warning) & stability$warning != ""],
    execution_warnings$warning[!is.na(execution_warnings$warning) & execution_warnings$warning != ""]
  ))
  cat("Warnings:\n")
  if (length(warnings)) cat(paste0("- ", warnings), sep = "\n") else cat("- None recorded.\n")
  cat("Reproduction command: Rscript R/run_stage2.R\n")
}

main <- function() {
  ensure_stage2_dirs()
  reset_stage2_outputs()
  log_path <- file.path("output", "logs", "stage2_bvar.log")
  log_con <- file(log_path, open = "wt")
  sink(log_con, split = TRUE)
  sink(log_con, type = "message")
  on.exit({
    sink(type = "message")
    sink()
    close(log_con)
  }, add = TRUE)

  with_warning_capture("package_check", load_stage2_packages())
  log_msg("Stage 2 started.")
  log_msg("MCMC profile:", stage2_mcmc_settings()$profile)

  scripts <- c(
    "05_prepare_bvar_data.R",
    "06_lag_selection_var.R",
    "07_bvar_homoskedastic.R",
    "08_bvar_sv.R",
    "09_bvar_diagnostics.R",
    "10_bvar_model_comparison.R"
  )
  for (script in scripts) run_stage2_script(script)

  writeLines(capture.output(sessionInfo()), file.path("output", "reports", "sessionInfo_stage2.txt"), useBytes = TRUE)
  with_warning_capture("renv_snapshot", write_renv_lock())
  warnings_df <- if (length(stage2_warning_log)) dplyr::bind_rows(stage2_warning_log) else data.frame(
    time = character(), script = character(), warning = character()
  )
  write_csv_safe(warnings_df, file.path("output", "tables", "bvar", "stage2_warnings.csv"))
  append_warning_section_to_report(warnings_df)
  log_msg("Stage 2 completed.")
  print_final_summary()
}

if (identical(environment(), globalenv())) {
  main()
}
