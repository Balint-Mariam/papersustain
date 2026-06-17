source(file.path("R", "stage2_common.R"))

main <- function() {
  ensure_stage2_dirs()
  load_stage2_packages()
  log_msg("Stage 2 data preparation started.")

  prepared <- prepare_stage2_data(file.path("data_processed", "data_model_diff.csv"))
  model_data <- prepared$model_data

  units <- data.frame(
    variable = prepared$variable_order,
    unit = c(
      "Log return, decimal form",
      "Log return, decimal form",
      "Log return, decimal form",
      "Log return, decimal form",
      "Percentage-point first difference",
      "Log growth, decimal form",
      "Raw first difference, original Bund 2Y scale",
      "Index first difference",
      "Relative log return, decimal form",
      "Relative log return, decimal form"
    ),
    transformed_again_in_stage2 = FALSE,
    stringsAsFactors = FALSE
  )
  write_csv_safe(units, file.path("output", "tables", "bvar", "stage2_variable_units.csv"))

  log_msg("Rows:", nrow(model_data))
  log_msg("Variables:", paste(prepared$variable_order, collapse = ", "))
  log_msg("Bund 2Y is kept on raw numeric scale; no multiplication by 100 or 10000.")
  log_msg("Stage 2 data preparation completed.")
}

if (identical(environment(), globalenv())) {
  main()
}

