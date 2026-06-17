# papersustain

Prima etapa a analizei econometrice pentru seriile din `date sustain.xlsx`.

## Continut

- audit si curatare date;
- transformari ale seriilor;
- statistici descriptive si grafice;
- teste de stationaritate ADF, Phillips-Perron si KPSS;
- teste Ljung-Box, ACF/PACF;
- corelatii Pearson/Spearman, VIF si condition number;
- raport final pre-model.

Nu sunt estimate modele VAR, BVAR, BVAR-SV, BSVAR sau BSVAR-SV in aceasta etapa.

## Rulare

Instalare dependente:

```powershell
py -m pip install -r requirements.txt
```

Rulare completa:

```powershell
py run_analysis.py
```

Rulare etapa 2 reduced-form BVAR:

```powershell
Rscript R/run_stage2.R
```

## Fisiere principale

- `date sustain.xlsx`: fisierul Excel original de intrare;
- `data_processed/data_clean_raw.csv`: date curate, netransformate;
- `data_processed/data_transformed_complete.csv`: date brute si transformate;
- `data_processed/data_model_diff.csv`: setul principal candidat;
- `data_processed/data_model_levels.csv`: set alternativ pentru robustete;
- `output/pre_model_report.md`: raportul final pre-model.
- `output/reports/stage2_reduced_form_bvar_report.md`: raportul etapei BVAR reduced-form.

Log returns sunt pastrate in forma zecimala. De exemplu, `0.05` inseamna aproximativ `5%`.

`Bund 2Y` este pastrat pe scala numerica originala din Excel. Diferenta lunara
este `Bund2Y_change = Bund2Y_t - Bund2Y_t-1`, fara conversie in basis points.
De exemplu, `0.00158 -> 0.00140` produce `-0.00018`.

Obiectele RDS din `output/models` nu sunt urcate pe GitHub deoarece pot deveni mari.
Ele se regenereaza local cu `Rscript R/run_stage2.R`; codul, tabelele, graficele,
rapoartele si `renv.lock` sunt versionate.
