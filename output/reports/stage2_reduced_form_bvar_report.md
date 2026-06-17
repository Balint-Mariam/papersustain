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

## MCMC Diagnostics

```csv
parameter,mean,sd,rhat,ess_bulk,ess_tail,mcse_mean,model_group,rhat_pass,bulk_ess_pass,tail_ess_pass
own_lag1__EUA_ret,-0.03700481432932528,0.07672012733142518,1.0000389603391004,29382.800267948744,27980.55300214042,4.4760614319954415e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__TTF_ret,-0.0243170561547621,0.07546103458883324,0.999955813502992,28742.30221686207,27930.47189301294,4.451050262815726e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__Brent_ret,0.08749050685333593,0.08269508105023182,1.0000837154454985,23483.60178777233,28391.87516269321,5.39444381269058e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__Power_ret,0.32866934400774356,0.08478249828964426,1.0001597456677604,11380.161498092662,12437.966304056734,8.002070076043497e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__CPI_yoy_change,0.13506717048325734,0.15834324624786378,0.9999814356397334,18228.394603975892,22056.05755562637,0.0011890921910997,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__IP_growth,0.0294985544344597,0.0760363816105594,1.0000686822504332,24224.07855684297,26405.31440370714,4.890802052137202e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__Bund2Y_change,3.689620730426016e-4,0.17429051592459271,1.0001711865549163,29985.620226564,24973.714740675747,0.00101069465660326,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__CISS_change,-0.15291073420756776,0.08054593412918688,1.000029227328398,20235.15484206132,25855.740357681927,5.660810956535466e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__GreenEquity_relative,0.02866533617716599,0.07729147579861127,1.00005812424172,29464.173108948467,29222.020800232058,4.502213815589709e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
own_lag1__GreenBond_relative,0.06559191430063921,0.16454689627929622,1.00017540144923,25177.630301088775,22622.619171727903,0.00105536334853927,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__EUA_ret__to__GreenEquity_relative,-0.0112989295500569,0.02991559450952868,1.0001683100974168,27778.23672272989,27319.608983744623,1.7942631884987405e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__TTF_ret__to__GreenEquity_relative,-0.00305049443674299,0.01795932777537314,1.0000522131762466,30412.261290189745,28601.81832489771,1.0297503577775796e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__Brent_ret__to__GreenEquity_relative,-0.0043314900215405,0.02838219778359737,1.0000387354863245,29743.007360995896,24254.369339581444,1.6460416943652695e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__Power_ret__to__GreenEquity_relative,0.00504461771989938,0.06528931587415535,1.000032147307548,29690.40237884365,27401.425742246985,3.78933202894112e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__CPI_yoy_change__to__GreenEquity_relative,-0.08029620949432896,0.9168688607736222,1.000010505660551,29819.02309369958,27820.64197693276,0.00531128329504273,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__IP_growth__to__GreenEquity_relative,0.03675025942580658,0.13313572529435844,0.9999824424726356,29475.318944051676,26926.054879411895,7.763829315452441e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__Bund2Y_change__to__GreenEquity_relative,-0.6528239145663575,1.7826696267560709,1.0001316914886298,28021.77373752659,26479.22134278152,0.01065328772346925,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__CISS_change__to__GreenEquity_relative,-0.00977405973424237,0.03746563224037665,1.0000768707928185,28666.92840163495,25739.0863505119,2.215176893549728e-4,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
intercept__GreenEquity_relative,0.0022693896781528,0.00516762089279085,0.9999826079867384,29185.55370874851,29050.38640101859,3.0256838326242128e-5,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
lag1__EUA_ret__to__GreenBond_relative,-5.420863509079167e-5,0.00173081324451369,1.0002751597075594,28487.460349843135,25500.10038520737,1.0252240882764132e-5,BVAR-HOMOSKEDASTIC-final,TRUE,TRUE,TRUE
```

## Posterior Stability

```csv
model_id,total_draws,stable_draws,unstable_draws,unstable_pct,warning,original_file,stable_file
BVAR-HOM-p1-pilot,2000,2000,0,0,NA,output/models/bvar_hom_p1_pilot.rds,output/models/bvar_hom_p1_pilot_stable_draws.rds
BVAR-HOM-p2-pilot,2000,1995,5,0.25,NA,output/models/bvar_hom_p2_pilot.rds,output/models/bvar_hom_p2_pilot_stable_draws.rds
BVAR-HOM-final-chain1,10000,10000,0,0,NA,output/models/bvar_hom_final_chain1.rds,output/models/bvar_hom_final_chain1_stable_draws.rds
BVAR-HOM-final-chain2,10000,9998,2,0.02,NA,output/models/bvar_hom_final_chain2.rds,output/models/bvar_hom_final_chain2_stable_draws.rds
BVAR-HOM-final-chain3,10000,9999,1,0.01,NA,output/models/bvar_hom_final_chain3.rds,output/models/bvar_hom_final_chain3_stable_draws.rds
BVAR-SV-p1-pilot,2000,2000,0,0,NA,output/models/bvar_sv_p1_pilot.rds,output/models/bvar_sv_p1_pilot_stable_draws.rds
BVAR-SV-p2-pilot,2000,2000,0,0,NA,output/models/bvar_sv_p2_pilot.rds,output/models/bvar_sv_p2_pilot_stable_draws.rds
BVAR-SV-final-chain1,10000,10000,0,0,NA,output/models/bvar_sv_final_chain1.rds,output/models/bvar_sv_final_chain1_stable_draws.rds
BVAR-SV-final-chain2,10000,10000,0,0,NA,output/models/bvar_sv_final_chain2.rds,output/models/bvar_sv_final_chain2_stable_draws.rds
BVAR-SV-final-chain3,10000,10000,0,0,NA,output/models/bvar_sv_final_chain3.rds,output/models/bvar_sv_final_chain3_stable_draws.rds
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
2020-03-31,Brent_ret,0.21429734034100772,0.24464641835600637,0.3086169522807697,0.4069035648089865,0.4997110093256457,0.05848543214142712,0.08244349215681221,0.14495362437090825
2022-08-31,Bund2Y_change,0.00331786348320351,0.00385076984571384,0.00495680504459214,0.00661085013347042,0.00823003837687083,3.5656566011782237e-4,8.704949042619583e-4,0.00370257559339835
2020-03-31,CISS_change,0.18159158612594872,0.21549279557907244,0.2910573147938239,0.4147281360384004,0.5499015727685276,0.0076155900181717,0.04276643539293039,0.16356378598069238
2023-03-31,CPI_yoy_change,0.0048455976448908,0.00548244091828772,0.00675022779769039,0.00855370678278805,0.0102539939126344,0.0018890736576366,0.00240004002633774,0.00571290262711045
2016-12-31,EUA_ret,0.1253433844569137,0.1451131165361384,0.18528056575094665,0.2487289686498405,0.30879418706254946,0.05717705467627924,0.09625860540283536,0.15275587420805006
2015-01-31,GreenBond_relative,0.00481407695533147,0.00560948138345641,0.0072389779918927,0.00963370198359712,0.01189239958276609,5.450373340663516e-4,0.00138100477400259,0.00617643558570271
2026-03-31,GreenEquity_relative,0.0652483239840437,0.07414883547690455,0.0930668795345604,0.12317936812262471,0.15188943031168675,0.03377066502748625,0.05406623282155992,0.07579729770892513
2020-04-30,IP_growth,0.07188053673876349,0.0831237460680274,0.10733303703097824,0.14525458575256076,0.18199963641801475,0.00521632421494102,0.0091626457590873,0.02798463072123431
2024-04-30,Power_ret,0.08103772399062682,0.09417784462469152,0.12143674772450253,0.162644937180496,0.20324559285087215,0.01880909701936606,0.03739906005060217,0.08525962989819397
2021-10-31,TTF_ret,0.23587135195517211,0.2682043004171005,0.3316788442235355,0.4216390909244844,0.5029134317239718,0.0784401432529596,0.13308276007723757,0.3026989890438629
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
BVAR-HOM-final-chain1,EUA_ret,mean,0.01803712067175318,0.01794849931902223,-0.00413428928755472,0.04038148686901582,0.4979,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,sd,0.1129269603411588,0.11522226691282678,0.10035346643362954,0.13214758109465372,0.5989,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,skewness,-0.3505267463149478,0.00135889889962998,-0.3333355309443731,0.3277181924020614,0.9578,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,kurtosis,3.9714158425924206,2.9171301463266435,2.445557014490972,3.6934255060054646,0.02,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,minimum,-0.3101549283038394,-0.28189713313835707,-0.3803831101647046,-0.21177759394076845,0.701,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,maximum,0.357766051521067,0.318810750520853,0.24727442381211776,0.4186411106061945,0.2333,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,EUA_ret,max_abs,0.357766051521067,0.33212463723358043,0.266124769719753,0.4272754254689337,0.3045,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,mean,0.0058856742155128,0.00599252794410723,-0.03030134985642611,0.04207478317557677,0.5022,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,sd,0.19081683396910917,0.19202643060176605,0.1681211559675048,0.22064727330272124,0.5316,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,skewness,0.19326181324543804,-0.0078098358145179,-0.3464642328990122,0.3130598878182975,0.1503,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,kurtosis,4.592058517224699,2.924649346575794,2.453274711722968,3.7251526954405887,0.0043,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,minimum,-0.6514525981468875,-0.49966658335407466,-0.6717192905145705,-0.3810809324813268,0.9307,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,maximum,0.6638984339451812,0.5056926932539862,0.3893937911182791,0.6722887585252202,0.0579,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,TTF_ret,max_abs,0.6638984339451812,0.5491120296217564,0.4379179495434168,0.712342673662093,0.1089,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,mean,3.71576378684402e-4,5.671805613275945e-4,-0.02332536778126176,0.02421250827190627,0.5047,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,sd,0.12098690483484108,0.12428942158474612,0.1082740314964723,0.14248952984590335,0.6284,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,skewness,-1.4702329189713137,-9.433584190137508e-4,-0.3290338343200856,0.33315349270460837,1,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,kurtosis,16.55613647235671,2.9200084599456817,2.453902738977957,3.702079219280456,0,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,minimum,-0.7982438091599007,-0.3236117118742755,-0.4322126107532119,-0.24907410632661023,1,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
BVAR-HOM-final-chain1,Brent_ret,maximum,0.49033567422526847,0.32556225654117493,0.24847217001635205,0.4337495275970449,0.012,Replicated data are generated from fitted reduced-form predictions and posterior residual volatility.
```

## Model Comparison

```csv
model,lag,variance_type,prior,stable_draws,unstable_pct,max_rhat,min_bulk_ess,residual_autocorrelation_rejections,squared_residual_autocorrelation_rejections,joint_log_predictive_likelihood,green_assets_log_predictive_likelihood,green_rmse_mean,green_mae_mean,green_coverage_68_mean,green_coverage_90_mean,estimation_time_seconds,warning
BVAR-HOM-p1,1,homoskedastic,"HMP coefficients, HMP Cholesky covariance",2000,0,1.030420788305147,1016.6810971330924,12,12,220.18889721391668,52.252499296914536,0.04454843256132973,0.034271235733246946,0.7916666666666667,0.9583333333333333,3.935216903686523,NA
BVAR-HOM-p2,2,homoskedastic,"HMP coefficients, HMP Cholesky covariance",1995,0.25,NA,NA,5,12,217.99315334831655,52.37653519103803,0.044648286444303846,0.034263189334072165,0.75,0.9583333333333333,9.80267882347107,NA
BVAR-SV-p1,1,sv,"HMP coefficients, HMP Cholesky covariance",2000,0,1.037699459200929,539.830840100328,3,4,302.9184408647801,78.4439491357211,0.043280107113507306,0.03321590952093421,0.7083333333333333,0.9166666666666667,8.654885053634644,NA
BVAR-SV-p2,2,sv,"HMP coefficients, HMP Cholesky covariance",2000,0,NA,NA,2,2,301.2823581687019,77.98962302548442,0.043722055292804714,0.03354443222408287,0.7083333333333333,0.9166666666666667,14.709797859191896,NA
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

`csv
time,script,warning
2026-06-17T13:04:25Z,package_check,package 'readr' was built under R version 4.4.3
2026-06-17T13:04:25Z,package_check,package 'dplyr' was built under R version 4.4.3
2026-06-17T13:04:25Z,package_check,package 'tidyr' was built under R version 4.4.3
2026-06-17T13:04:25Z,package_check,package 'ggplot2' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'vars' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'strucchange' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'zoo' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'sandwich' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'urca' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'lmtest' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'bayesianVARs' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'posterior' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'coda' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'forecast' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'tseries' was built under R version 4.4.3
2026-06-17T13:04:26Z,package_check,package 'patchwork' was built under R version 4.4.3
2026-06-17T13:04:27Z,06_lag_selection_var.R,NaNs produced
2026-06-17T13:08:29Z,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17T13:08:29Z,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17T13:08:30Z,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17T13:08:35Z,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17T13:08:38Z,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17T13:11:42Z,09_bvar_diagnostics.R,"Setting 'error_term=FALSE'! To calculate predicted historical
    values including the error term, the full path of logvariances is needed,
    i.e. set 'sv_keep='all'' when calling bvar()!"
2026-06-17T13:12:04Z,renv_snapshot,"packages argument is set; type argument ""explicit"" will be ignored"
`
