# Stage 2 Reduced-Form BVAR Report

## Data

- Input file: `data_processed/data_model_diff.csv`
- Observations: 145
- Variables: EUA_ret, TTF_ret, Brent_ret, Power_ret, CPI_yoy_change, IP_growth, Bund2Y_change, CISS_change, GreenEquity_relative, GreenBond_relative
- Bund 2Y is kept on its raw numeric first-difference scale. It is not multiplied by 100 or 10000.
- No standardization, normalization, rescaling, outlier removal, dummy variables, IRF, FEVD, or structural restrictions are used.

Data checks:

```csv
check,status,detail,value
file_exists,PASS,data_processed/data_model_diff.csv,NA
model_variable_order,PASS,EUA_ret | TTF_ret | Brent_ret | Power_ret | CPI_yoy_change | IP_growth | Bund2Y_change | CISS_change | GreenEquity_relative | GreenBond_relative,NA
duplicate_dates,PASS,No duplicate dates,NA
chronological_order,PASS,Dates sorted ascending,NA
numeric_columns,PASS,All model columns are numeric,NA
missing_values,PASS,No NA values,0
finite_values,PASS,No infinite values,0
observations,PASS,145,NA
rank,PASS,10,columns=10
zero_variance,PASS,NA,NA
bund_scale,PASS,Bund 2Y first difference kept on raw numeric scale,Bund2Y_change
```

Variable units:

```csv
variable,unit,transformed_again_in_stage2
EUA_ret,"Log return, decimal form",FALSE
TTF_ret,"Log return, decimal form",FALSE
Brent_ret,"Log return, decimal form",FALSE
Power_ret,"Log return, decimal form",FALSE
CPI_yoy_change,Percentage-point first difference,FALSE
IP_growth,"Log growth, decimal form",FALSE
Bund2Y_change,"Raw first difference, original Bund 2Y scale",FALSE
CISS_change,Index first difference,FALSE
GreenEquity_relative,"Relative log return, decimal form",FALSE
GreenBond_relative,"Relative log return, decimal form",FALSE
```

## Lag Selection

```csv
lag,AIC(n),HQ(n),SC(n),FPE(n),regressors_per_equation,effective_observations,observation_to_regressor_ratio
1,-71.90499839877803,-70.97017468275422,-69.60454742046883,5.935205146425551e-32,11,144,13.090909090909092
2,-71.73849656053854,-69.95383310267486,-67.34672651103914,7.145972673160634e-32,21,143,6.809523809523809
3,-71.46672573478621,-68.83222253508269,-64.98363661409661,9.86482333118782e-32,31,142,4.580645161290323
4,-71.3522442645501,-67.86790132300675,-62.77783607267032,1.2222040073489003e-31,41,141,3.4390243902439024
```

## VAR Benchmarks

Classical VAR(1) and VAR(2) are estimated only as reduced-form benchmarks.

```csv
model,lag,root_index,modulus,max_modulus,stable
VAR(1),1,1,0.6015888511169928,0.6015888511169928,TRUE
VAR(1),1,2,0.3084597012394008,0.6015888511169928,TRUE
VAR(1),1,3,0.3084597012394008,0.6015888511169928,TRUE
VAR(1),1,4,0.2935178897748295,0.6015888511169928,TRUE
VAR(1),1,5,0.2935178897748295,0.6015888511169928,TRUE
VAR(1),1,6,0.26795493141730103,0.6015888511169928,TRUE
VAR(1),1,7,0.1750616274184748,0.6015888511169928,TRUE
VAR(1),1,8,0.16543475607898542,0.6015888511169928,TRUE
VAR(1),1,9,0.16543475607898542,0.6015888511169928,TRUE
VAR(1),1,10,0.04081815047242422,0.6015888511169928,TRUE
VAR(2),2,1,0.7212397120133043,0.7212397120133043,TRUE
VAR(2),2,2,0.7212397120133043,0.7212397120133043,TRUE
VAR(2),2,3,0.6125736981000357,0.7212397120133043,TRUE
VAR(2),2,4,0.5930799942650626,0.7212397120133043,TRUE
VAR(2),2,5,0.5930799942650626,0.7212397120133043,TRUE
VAR(2),2,6,0.5417879806288134,0.7212397120133043,TRUE
VAR(2),2,7,0.5417879806288134,0.7212397120133043,TRUE
VAR(2),2,8,0.53300227760271,0.7212397120133043,TRUE
VAR(2),2,9,0.53300227760271,0.7212397120133043,TRUE
VAR(2),2,10,0.5208301404899675,0.7212397120133043,TRUE
```

## Priors and MCMC Settings

```csv
model_id,lag,coefficient_prior_function,coefficient_prior,coefficient_priormean,intercept_prior_sd,sigma_prior_function,sigma_type,cholesky_U_prior,cholesky_heteroscedastic,sv_keep,variance_type
BVAR-HOM-p1-pilot,1,specify_prior_phi,HMP,0,10,specify_prior_sigma,cholesky,HMP,FALSE,last,homoskedastic
BVAR-HOM-p2-pilot,2,specify_prior_phi,HMP,0,10,specify_prior_sigma,cholesky,HMP,FALSE,last,homoskedastic
BVAR-HOM-final-chain1,1,specify_prior_phi,HMP,0,10,specify_prior_sigma,cholesky,HMP,FALSE,last,homoskedastic
BVAR-HOM-final-chain2,1,specify_prior_phi,HMP,0,10,specify_prior_sigma,cholesky,HMP,FALSE,last,homoskedastic
BVAR-HOM-final-chain3,1,specify_prior_phi,HMP,0,10,specify_prior_sigma,cholesky,HMP,FALSE,last,homoskedastic
BVAR-SV-p1-pilot,1,specify_prior_phi,HMP,0,10,specify_prior_sigma,cholesky,HMP,TRUE,all,sv
BVAR-SV-p2-pilot,2,specify_prior_phi,HMP,0,10,specify_prior_sigma,cholesky,HMP,TRUE,all,sv
BVAR-SV-final-chain1,1,specify_prior_phi,HMP,0,10,specify_prior_sigma,cholesky,HMP,TRUE,all,sv
BVAR-SV-final-chain2,1,specify_prior_phi,HMP,0,10,specify_prior_sigma,cholesky,HMP,TRUE,all,sv
BVAR-SV-final-chain3,1,specify_prior_phi,HMP,0,10,specify_prior_sigma,cholesky,HMP,TRUE,all,sv
```

MCMC extension decision:

```csv
initial_final_burnin,initial_final_draws,extended_final_burnin,extended_final_draws,reason
10000,10000,20000,20000,"The initial full run produced max R-hat 1.0377 and minimum bulk ESS 539.8, so final chains were extended according to the stage-2 diagnostic rule."
```

## MCMC Diagnostics

```csv
parameter,mean,sd,rhat,ess_bulk,ess_tail,mcse_mean,model_group,rhat_pass,bulk_ess_pass,tail_ess_pass
own_lag1__EUA_ret,-0.03642030707378812,0.07669166166309689,0.9999721619115222,55962.82301338947,55453.37868902379,3.2418255339660784e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__TTF_ret,-0.02433289187489171,0.07533369237375158,1.0000019208746953,53864.20747348549,56989.131653201555,3.2451637145573364e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__Brent_ret,0.08777376929261826,0.08170572418133407,1.000055374849327,49452.350935295945,56573.28460743426,3.674229280317407e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__Power_ret,0.32800383563727403,0.08582596573693833,1.0000671655005406,19054.840557604428,18226.654871172508,6.395740973064432e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__CPI_yoy_change,0.1347144545253731,0.15877023044775482,1.000007008625707,37097.78847952541,42786.88280860291,8.406006865011522e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__IP_growth,0.02914039192125684,0.075577442364042,0.9999654361977298,45440.641796675896,51572.95524989388,3.548194393413566e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__Bund2Y_change,-1.4411046086119014e-4,0.17481797927163562,1.0000061028110163,59852.73354021113,50137.39580449291,7.150667530006409e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__CISS_change,-0.15290971155454738,0.08037144057065355,1.0000085296034984,38484.19709714641,41979.03987110581,4.092446880928605e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__GreenEquity_relative,0.02864840144771616,0.07633308529028873,1.0000225037726935,59594.59454857497,58640.890786373704,3.127405192018663e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__GreenBond_relative,0.06692129290301652,0.16419526272995136,1.000046429686224,49789.360820244925,47452.94790338198,7.442506374200103e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__EUA_ret__to__GreenEquity_relative,-0.01123360041204136,0.02978863161672161,1.0001452971580616,55552.56960272928,49326.073584871214,1.2662622898288584e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__TTF_ret__to__GreenEquity_relative,-0.00321092711425746,0.01773147295959747,0.9999901090653752,60378.03699475188,52308.97562343341,7.215968201548835e-5,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__Brent_ret__to__GreenEquity_relative,-0.00413074260668799,0.02836253821123272,1.0000454115120363,60248.54421799819,53662.41335809747,1.1554741850038749e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__Power_ret__to__GreenEquity_relative,0.00518105039237613,0.06464590628721742,0.9999988134602572,60086.58339276163,54415.098754202074,2.6371142555764985e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__CPI_yoy_change__to__GreenEquity_relative,-0.07977968302217013,0.9132622328691614,1.0000979732241626,59401.12166642715,54281.28696975437,0.00374919277461031,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__IP_growth__to__GreenEquity_relative,0.03769365321564634,0.132726220988728,1.000006442424553,58305.31138423448,57526.509162508555,5.497444747116109e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__Bund2Y_change__to__GreenEquity_relative,-0.6543823502008791,1.7870657068511284,1.0000274664275342,57730.6540899837,51552.73283404517,0.00744463446444357,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__CISS_change__to__GreenEquity_relative,-0.00975058828509681,0.03721615584615292,1.000011174023605,57004.65045525003,51414.76211682537,1.56031853277576e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
intercept__GreenEquity_relative,0.0022552796975546,0.00518368517777142,1.000036361818567,59822.47419374582,59302.85922765728,2.11973354867598e-5,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__EUA_ret__to__GreenBond_relative,-4.9880142648432776e-5,0.00172592287574601,0.999992849836344,59529.54907163418,49817.132109902224,7.075067071093088e-6,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
```

## Posterior Stability

```csv
model_id,total_draws,stable_draws,unstable_draws,unstable_pct,warning,original_file,stable_file
BVAR-HOM-p1-pilot,2000,2000,0,0,NA,output/models/bvar_hom_p1_pilot.rds,output/models/bvar_hom_p1_pilot_stable_draws.rds
BVAR-HOM-p2-pilot,2000,1995,5,0.25,NA,output/models/bvar_hom_p2_pilot.rds,output/models/bvar_hom_p2_pilot_stable_draws.rds
BVAR-HOM-final-chain1,20000,19996,4,0.02,NA,output/models/bvar_hom_final_chain1.rds,output/models/bvar_hom_final_chain1_stable_draws.rds
BVAR-HOM-final-chain2,20000,19998,2,0.01,NA,output/models/bvar_hom_final_chain2.rds,output/models/bvar_hom_final_chain2_stable_draws.rds
BVAR-HOM-final-chain3,20000,19997,3,0.015,NA,output/models/bvar_hom_final_chain3.rds,output/models/bvar_hom_final_chain3_stable_draws.rds
BVAR-SV-p1-pilot,2000,2000,0,0,NA,output/models/bvar_sv_p1_pilot.rds,output/models/bvar_sv_p1_pilot_stable_draws.rds
BVAR-SV-p2-pilot,2000,2000,0,0,NA,output/models/bvar_sv_p2_pilot.rds,output/models/bvar_sv_p2_pilot_stable_draws.rds
BVAR-SV-final-chain1,20000,20000,0,0,NA,output/models/bvar_sv_final_chain1.rds,output/models/bvar_sv_final_chain1_stable_draws.rds
BVAR-SV-final-chain2,20000,20000,0,0,NA,output/models/bvar_sv_final_chain2.rds,output/models/bvar_sv_final_chain2_stable_draws.rds
BVAR-SV-final-chain3,20000,20000,0,0,NA,output/models/bvar_sv_final_chain3.rds,output/models/bvar_sv_final_chain3_stable_draws.rds
BVAR-HOM-p1-forecast,5000,4999,1,0.02,NA,output/models/bvar_hom_p1_forecast_train.rds,output/models/bvar_hom_p1_forecast_train_stable_draws.rds
BVAR-HOM-p2-forecast,5000,4993,7,0.14,NA,output/models/bvar_hom_p2_forecast_train.rds,output/models/bvar_hom_p2_forecast_train_stable_draws.rds
BVAR-SV-p1-forecast,5000,5000,0,0,NA,output/models/bvar_sv_p1_forecast_train.rds,output/models/bvar_sv_p1_forecast_train_stable_draws.rds
BVAR-SV-p2-forecast,5000,5000,0,0,NA,output/models/bvar_sv_p2_forecast_train.rds,output/models/bvar_sv_p2_forecast_train_stable_draws.rds
```

## Residual Diagnostics

```csv
model_id,variable,lag,statistic,p_value,squared_residual,warning
BVAR-HOM-p1-pilot,EUA_ret,6,7.935754761826665,0.24284797469101416,FALSE,NA
BVAR-HOM-p1-pilot,EUA_ret,12,10.941150879097176,0.5339687069139577,FALSE,NA
BVAR-HOM-p1-pilot,TTF_ret,6,13.000692089509338,0.04302495778103799,FALSE,NA
BVAR-HOM-p1-pilot,TTF_ret,12,23.847497743892312,0.02133441333234742,FALSE,NA
BVAR-HOM-p1-pilot,Brent_ret,6,6.57412652844801,0.36203115418088383,FALSE,NA
BVAR-HOM-p1-pilot,Brent_ret,12,10.58355583587843,0.5649039959997859,FALSE,NA
BVAR-HOM-p1-pilot,Power_ret,6,25.61243867977171,2.628582534351942e-4,FALSE,NA
BVAR-HOM-p1-pilot,Power_ret,12,44.579624509153696,1.2161368328489353e-5,FALSE,NA
BVAR-HOM-p1-pilot,CPI_yoy_change,6,56.863155830102066,1.9472456980196284e-10,FALSE,NA
BVAR-HOM-p1-pilot,CPI_yoy_change,12,87.61236117868366,1.4288570326925765e-13,FALSE,NA
BVAR-HOM-p1-pilot,IP_growth,6,21.6115032276198,0.00142358649952767,FALSE,NA
BVAR-HOM-p1-pilot,IP_growth,12,28.100403681517424,0.00534794614985578,FALSE,NA
BVAR-HOM-p1-pilot,Bund2Y_change,6,8.248304202408065,0.2204705161674141,FALSE,NA
BVAR-HOM-p1-pilot,Bund2Y_change,12,28.261531176823596,0.00506466705432717,FALSE,NA
BVAR-HOM-p1-pilot,CISS_change,6,10.499673543744954,0.10512615775774314,FALSE,NA
BVAR-HOM-p1-pilot,CISS_change,12,18.085864110738843,0.11310815547288078,FALSE,NA
BVAR-HOM-p1-pilot,GreenEquity_relative,6,13.622245624815584,0.034152631503786,FALSE,NA
BVAR-HOM-p1-pilot,GreenEquity_relative,12,17.354318406407753,0.1367480798865347,FALSE,NA
BVAR-HOM-p1-pilot,GreenBond_relative,6,16.59511958596097,0.01089227652581026,FALSE,NA
BVAR-HOM-p1-pilot,GreenBond_relative,12,22.323964146611832,0.03404533982453217,FALSE,NA
```

## Stochastic Volatility

Stochastic volatility is residual covariance variation through time, not time variation in VAR coefficients.

```csv
Date,variable,q05,q16,median,q84,q95,vol_p05,vol_p50,vol_p95
2020-03-31,Brent_ret,0.21404100785696412,0.24454246070787328,0.30681930604990015,0.4038104851274984,0.4953673023992759,0.05872953883075586,0.08259239149353148,0.14548623269462962
2022-08-31,Bund2Y_change,0.00331894319939766,0.0038681539924771,0.00498771183835589,0.00667844155664985,0.00829493791756999,3.5753767247194407e-4,8.678138275429301e-4,0.00370170636017369
2020-03-31,CISS_change,0.18077973692900087,0.2158114522374336,0.2909887956250271,0.41600573797858414,0.5436146039233947,0.00757520870637528,0.04297992733086001,0.16339200031474718
2023-03-31,CPI_yoy_change,0.0048558071325253,0.00549966201384483,0.00677286076093825,0.00862252797107711,0.01029617702826006,0.00188726427674351,0.00239709571536362,0.00571348035670851
2016-12-31,EUA_ret,0.1257493601820467,0.14479734295631522,0.18538861259615289,0.2482217023220747,0.3091111809311049,0.05723727086923883,0.09535418719327574,0.1525446652746531
2015-01-31,GreenBond_relative,0.00481587319016601,0.00561547386373941,0.00727086178479937,0.00970759210804837,0.01202247190342153,5.414074692322345e-4,0.00137612138269406,0.00617755941413459
2026-03-31,GreenEquity_relative,0.06535209045911941,0.07444828077433728,0.09361037525127693,0.12338063043740452,0.15266759770700225,0.03361803058165317,0.05402274515626431,0.07554551523430529
2020-04-30,IP_growth,0.07203173235052646,0.08310611410596956,0.1072496198548482,0.14424773540541316,0.17967822498152597,0.00517665365957847,0.00919707598138095,0.02802708166576537
2024-04-30,Power_ret,0.08100625803606469,0.09372426820391172,0.12099581823307408,0.1633842254758507,0.20458558848805616,0.0189769499526192,0.03763163056856699,0.08506737062617672
2021-10-31,TTF_ret,0.23604319136162824,0.2677604653154917,0.3308217926256043,0.42055402420712673,0.5042693471962333,0.07804138430094648,0.1336755157371401,0.3011892559975058
```

## Predictive Evaluation

Forecast evaluation uses the last 12 observations as test set and prioritizes density forecasts over RMSE alone.

```csv
model_id,joint_log_predictive_likelihood,green_assets_log_predictive_likelihood
BVAR-HOM-p1-forecast,220.18889721391668,52.252499296914536
BVAR-HOM-p1-forecast__variable__EUA_ret,11.850619847493778,NA
BVAR-HOM-p1-forecast__variable__TTF_ret,2.9688861543734246,NA
BVAR-HOM-p1-forecast__variable__Brent_ret,6.053456185267859,NA
BVAR-HOM-p1-forecast__variable__Power_ret,19.649427375033415,NA
BVAR-HOM-p1-forecast__variable__CPI_yoy_change,40.27199286914335,NA
BVAR-HOM-p1-forecast__variable__IP_growth,30.193294545016492,NA
BVAR-HOM-p1-forecast__variable__Bund2Y_change,41.058626815707214,NA
BVAR-HOM-p1-forecast__variable__CISS_change,14.19700480915112,NA
BVAR-HOM-p1-forecast__variable__GreenEquity_relative,11.388838825260285,NA
BVAR-HOM-p1-forecast__variable__GreenBond_relative,40.86366047165425,NA
BVAR-HOM-p2-forecast,217.99315334831655,52.37653519103803
BVAR-HOM-p2-forecast__variable__EUA_ret,11.485025175978809,NA
BVAR-HOM-p2-forecast__variable__TTF_ret,2.9413276486254114,NA
BVAR-HOM-p2-forecast__variable__Brent_ret,6.16498136330375,NA
BVAR-HOM-p2-forecast__variable__Power_ret,19.298353485007137,NA
BVAR-HOM-p2-forecast__variable__CPI_yoy_change,39.96186013695979,NA
BVAR-HOM-p2-forecast__variable__IP_growth,29.663268722594648,NA
BVAR-HOM-p2-forecast__variable__Bund2Y_change,40.805737199588386,NA
BVAR-HOM-p2-forecast__variable__CISS_change,13.64563500154647,NA
```

```csv
model_id,variable,rmse,mae,normalized_rmse
BVAR-HOM-p1-forecast,EUA_ret,0.05919164361398803,0.04034911693332618,0.5069336125675196
BVAR-HOM-p1-forecast,TTF_ret,0.18560837382243597,0.1287082373177253,0.97231684350408
BVAR-HOM-p1-forecast,Brent_ret,0.15436136217939758,0.0866176264072804,1.3178773685668237
BVAR-HOM-p1-forecast,Power_ret,0.0347467441173246,0.03046365717314149,0.5941740184621401
BVAR-HOM-p1-forecast,CPI_yoy_change,0.00264252898852835,0.00193940412626677,0.6488255040367347
BVAR-HOM-p1-forecast,IP_growth,0.00751977329371131,0.00479764366193614,0.2800193530423364
BVAR-HOM-p1-forecast,Bund2Y_change,0.00191897060783908,0.00115433267708873,1.0339552370285996
BVAR-HOM-p1-forecast,CISS_change,0.03006280520071098,0.02412043734852676,0.3133484700479312
BVAR-HOM-p1-forecast,GreenEquity_relative,0.08829021362179693,0.06785443050408092,1.5930306987057432
BVAR-HOM-p1-forecast,GreenBond_relative,8.066515008625341e-4,6.880409624129709e-4,0.26148741813803
BVAR-HOM-p2-forecast,EUA_ret,0.05886871607879828,0.04009670752048838,0.504167971811219
BVAR-HOM-p2-forecast,TTF_ret,0.18510009324089527,0.12667013063055813,0.969654195475436
BVAR-HOM-p2-forecast,Brent_ret,0.15534095384393137,0.08606636311736733,1.3262407418028368
BVAR-HOM-p2-forecast,Power_ret,0.03602780130406657,0.03124919468937759,0.6160802694178021
BVAR-HOM-p2-forecast,CPI_yoy_change,0.00270183157066955,0.00207665354138067,0.663386187350136
BVAR-HOM-p2-forecast,IP_growth,0.00899539846099673,0.00574236909677633,0.33496829745024936
BVAR-HOM-p2-forecast,Bund2Y_change,0.00177383000577356,0.00103728608165735,0.9557524313169896
BVAR-HOM-p2-forecast,CISS_change,0.02995323822364454,0.02411721855537979,0.3122064394089962
BVAR-HOM-p2-forecast,GreenEquity_relative,0.08853309960665003,0.06787809033693304,1.5974131190701768
BVAR-HOM-p2-forecast,GreenBond_relative,7.6347328195766e-4,6.482883312112906e-4,0.2474905917896485
```

## Posterior Predictive Checks

```csv
model_id,variable,statistic,observed,simulated_median,simulated_q05,simulated_q95,posterior_predictive_p_value,note
BVAR-HOM-final-chain1,EUA_ret,mean,0.01803712067175318,0.01795701725279744,-0.00404132732337474,0.04013854101253823,0.4973,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,sd,0.1129269603411588,0.1150338038752578,0.10002802225233828,0.13208044671342825,0.5889,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,skewness,-0.3505267463149478,9.088764000238158e-5,-0.3274401884736529,0.3302765734974568,0.9596,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,kurtosis,3.9714158425924206,2.9142432412396024,2.444458691620119,3.678409908245802,0.0197,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,minimum,-0.3101549283038394,-0.2814312471594219,-0.3807375239621964,-0.21074115715128044,0.7026,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,maximum,0.357766051521067,0.31720057001454327,0.2477670613310323,0.4180138864380007,0.2321,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,max_abs,0.357766051521067,0.33107689225580356,0.2651306624905507,0.4271024223581691,0.30085,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,mean,0.0058856742155128,0.00586761100521573,-0.03080192022170341,0.04206238424194572,0.49945,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,sd,0.19081683396910917,0.1924794996530015,0.1679010029675164,0.2205345487630948,0.54075,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,skewness,0.19326181324543804,-0.01200147496103857,-0.3443069910408697,0.3178019247588278,0.149,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,kurtosis,4.592058517224699,2.9208926442591503,2.4489175082664265,3.704598509965757,0.0033,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,minimum,-0.6514525981468875,-0.49963505590280344,-0.6709997782703662,-0.38151615762771024,0.93115,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,maximum,0.6638984339451812,0.5048928418647687,0.38959041227117885,0.6705581565529352,0.0554,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,max_abs,0.6638984339451812,0.549414190894272,0.4390382209152999,0.7102521512907586,0.1075,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,mean,3.71576378684402e-4,4.452355351128183e-4,-0.02322602506935093,0.02408227324064196,0.5019,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,sd,0.12098690483484108,0.12393747813144146,0.10796231947245916,0.14253154204005944,0.6133,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,skewness,-1.4702329189713137,5.13127300556884e-4,-0.3318596577083251,0.33143145304095756,1,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,kurtosis,16.55613647235671,2.9069152356022308,2.4494787109360447,3.7036557637981864,0,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,minimum,-0.7982438091599007,-0.32262758256085056,-0.43020063170953865,-0.2473255407445184,1,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,maximum,0.49033567422526847,0.3229787370225833,0.24785806935889565,0.4330232409715816,0.01025,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
```

## Model Comparison

```csv
model,lag,variance_type,prior,stable_draws,unstable_pct,max_rhat,min_bulk_ess,residual_autocorrelation_rejections,squared_residual_autocorrelation_rejections,joint_log_predictive_likelihood,green_assets_log_predictive_likelihood,green_rmse_mean,green_mae_mean,green_coverage_68_mean,green_coverage_90_mean,estimation_time_seconds,warning
BVAR-HOM-p1,1,homoskedastic,"HMP coefficients, HMP Cholesky covariance",2000,0,1.010398341616695,2378.316842778751,12,12,220.18889721391668,52.252499296914536,0.04454843256132973,0.034271235733246946,0.7916666666666667,0.9583333333333333,4.073092937469482,NA
BVAR-HOM-p2,2,homoskedastic,"HMP coefficients, HMP Cholesky covariance",1995,0.25,NA,NA,5,12,217.99315334831655,52.37653519103803,0.044648286444303846,0.034263189334072165,0.75,0.9583333333333333,10.719236850738524,NA
BVAR-SV-p1,1,sv,"HMP coefficients, HMP Cholesky covariance",2000,0,1.0127192526358066,1044.0896210724854,4,4,302.9184408647801,78.4439491357211,0.043280107113507306,0.03321590952093421,0.7083333333333333,0.9166666666666667,8.369157075881958,NA
BVAR-SV-p2,2,sv,"HMP coefficients, HMP Cholesky covariance",2000,0,NA,NA,4,2,301.2823581687019,77.98962302548442,0.043722055292804714,0.03354443222408287,0.7083333333333333,0.9166666666666667,15.716938018798828,NA
```

## Warnings

- No major warnings recorded.

## Recommendation

```csv
p_candidate_from_lag_selection,p_recommended_for_next_stage,homoskedastic_preferred,sv_preferred,variance_recommendation,sv_green_lpl_gap_vs_best_hom,recommendation
1,1,BVAR-HOM-p2,BVAR-SV-p1,BVAR-SV,26.067413944683068,"Use BVAR-SV with p = 1 as the reduced-form candidate for the structural stage, subject to reviewing diagnostics."
```

No structural shocks, sign restrictions, zero restrictions, narrative restrictions, impulse responses, FEVD, historical decomposition, or counterfactual analysis are computed in this stage.


## Execution Warnings

```csv
time,script,warning
2026-06-17 13:16:08,package_check,package 'readr' was built under R version 4.4.3
2026-06-17 13:16:08,package_check,package 'dplyr' was built under R version 4.4.3
2026-06-17 13:16:08,package_check,package 'tidyr' was built under R version 4.4.3
2026-06-17 13:16:08,package_check,package 'ggplot2' was built under R version 4.4.3
2026-06-17 13:16:08,package_check,package 'vars' was built under R version 4.4.3
2026-06-17 13:16:08,package_check,package 'strucchange' was built under R version 4.4.3
2026-06-17 13:16:08,package_check,package 'zoo' was built under R version 4.4.3
2026-06-17 13:16:08,package_check,package 'sandwich' was built under R version 4.4.3
2026-06-17 13:16:08,package_check,package 'urca' was built under R version 4.4.3
2026-06-17 13:16:08,package_check,package 'lmtest' was built under R version 4.4.3
2026-06-17 13:16:08,package_check,package 'bayesianVARs' was built under R version 4.4.3
2026-06-17 13:16:09,package_check,package 'posterior' was built under R version 4.4.3
2026-06-17 13:16:09,package_check,package 'coda' was built under R version 4.4.3
2026-06-17 13:16:09,package_check,package 'forecast' was built under R version 4.4.3
2026-06-17 13:16:09,package_check,package 'tseries' was built under R version 4.4.3
2026-06-17 13:16:09,package_check,package 'patchwork' was built under R version 4.4.3
2026-06-17 13:16:10,06_lag_selection_var.R,NaNs produced
2026-06-17 13:23:45,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17 13:23:46,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17 13:23:48,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17 13:23:58,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17 13:24:05,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17 13:28:02,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17 13:28:44,renv_snapshot,"packages argument is set; type argument ""explicit"" will be ignored"
```
