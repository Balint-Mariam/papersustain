# Pre-Model Econometric Analysis Report

## Sample and Data Checks

- Raw sample period: 2014-03-31 to 2026-04-30
- Raw observations: 146
- Observations after transformations in `data_model_diff.csv`: 145
- Observations after transformations in `data_model_levels.csv`: 145
- Missing months inside the retained monthly sample: None
- Missing numeric values reported in the raw audit: 0

Zero and negative value checks:

```csv
variable,observations,first_observation,last_observation,missing_values,zero_values,negative_values,minimum,minimum_date,maximum,maximum_date,mean,median,standard_deviation
Bund 2Y,146,2014-03-31,2026-04-30,0,0,92,-0.00933,2019-08-31,0.03198,2023-09-30,0.0038775342465753,-0.00487,0.0138929510562206
CPI EU,146,2014-03-31,2026-04-30,0,1,7,-0.005,2015-01-31,0.115,2022-10-31,0.0254383561643835,0.0175,0.0273450424436438
```

Audit warnings:

- WARNING: Zero values exist in the raw data.
- WARNING: Negative values exist in the raw data.

## Transformations and Units

- Log returns are stored in decimal form. A value of `0.05` means approximately `5%`.
- `EUA_ret`, `TTF_ret`, `Brent_ret`, and `Power_ret`: monthly log returns in decimal form.
- `IP_growth`: approximate monthly industrial production growth in decimal form.
- `Bund 2Y` is kept on the original numeric scale from Excel, for example `0.03198`.
- `Bund2Y_change`: signed raw first difference. For example, `0.00158` to `0.00140` gives `-0.00018`.
- `CPI_yoy_level`: annual inflation rate; `CPI_yoy_change`: monthly change in that annual inflation rate, in percentage points.
- `CISS_level`: systemic stress index level; `CISS_change`: monthly change in systemic stress.
- `GreenEquity_relative`: relative performance proxy versus the European broad equity market.
- `GreenBond_relative`: relative performance proxy versus the euro corporate bond market.
- The two relative returns are not pure green premia, pure green-screening effects, or causal estimates of a green label.

Transformation identity checks are saved in `output/tables/transformation_checks.csv`.

Bund 2Y scale diagnostic:

```csv
Date,Bund 2Y,Bund2Y_source_scale,Bund2Y_change,diagnostic_note
2014-03-31,0.00158,decimal_fraction,,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2014-04-30,0.0014,decimal_fraction,-0.00018,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2014-05-31,0.00061,decimal_fraction,-0.00079,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2014-06-30,0.00025,decimal_fraction,-0.0003599999999999,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2014-07-31,0.0002199999999999,decimal_fraction,-3.000000000010001e-05,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2014-08-31,-0.00033,decimal_fraction,-0.0005499999999999,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2014-09-30,-0.00083,decimal_fraction,-0.0005,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2014-10-31,-0.00058,decimal_fraction,0.00025,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2014-11-30,-0.00034,decimal_fraction,0.0002399999999999,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2014-12-31,-0.0011,decimal_fraction,-0.00076,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2015-01-31,-0.00187,decimal_fraction,-0.0007699999999999,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
2015-02-28,-0.00229,decimal_fraction,-0.00042,Values are kept on the original decimal-fraction scale; monthly changes are raw first differences.
```

## Descriptive Statistics

Detailed descriptive statistics are saved in `output/tables/descriptive_statistics.csv`.

```csv
variable,unit,observations,mean,median,standard_deviation,minimum,maximum,p01,p05,p25,p75,p95,p99,skewness,excess_kurtosis,jarque_bera_statistic,jarque_bera_p_value,note
EUA_ret,"Log return, decimal form",145,0.0189843229375575,0.0214773356105568,0.1131107077805288,-0.3101549283038394,0.357766051521067,-0.3010285505248271,-0.187793304923914,-0.0383161024039946,0.0879005482136623,0.1911627485726593,0.2634629534070019,-0.3628898133301151,1.0208922920108616,8.51136916759308,0.0141833777107029,Log returns are stored in decimal form where applicable.
TTF_ret,"Log return, decimal form",145,0.0053508147619274,0.0074815131436705,0.1902621621239927,-0.6514525981468875,0.6638984339451812,-0.4189228762445325,-0.2728740360506044,-0.0986907915926891,0.1045991017340224,0.3228271296278538,0.5528725747306898,0.2037026193301158,1.715458053572684,16.75527903465185,0.0002299521032823,Log returns are stored in decimal form where applicable.
Brent_ret,"Log return, decimal form",145,0.000388825046507,0.012323128173624,0.1205662584484731,-0.7982438091599007,0.4903356742252684,-0.2295462802326778,-0.1665901942857977,-0.0580802466763827,0.0588516259067457,0.1579224623219771,0.2929776839552463,-1.4912241119171734,14.197830329071714,1181.9378369133244,2.215438700511247e-257,Log returns are stored in decimal form where applicable.
Power_ret,"Log return, decimal form",145,0.0058609108524385,0.0045493396631539,0.0568807963859778,-0.2791247722440557,0.1792624535833837,-0.1724248626563859,-0.0727408546296061,-0.0216591625114146,0.0305274010677187,0.0930485151643018,0.1480535682054258,-0.7550340733709373,5.204375606091542,163.6619405733727,2.892418666975334e-36,Log returns are stored in decimal form where applicable.
IP_growth,"Log growth, decimal form",145,0.0006931235975888,0.0010085729548849,0.0257534063625594,-0.2042244496781755,0.1235163743644847,-0.0766774792897743,-0.0180005578201608,-0.0042780813910781,0.008080852053939,0.0217211626640636,0.0691207654861026,-3.112719981734122,33.79258513578501,6649.144975240552,0.0,Log returns are stored in decimal form where applicable.
Bund2Y_change,Raw first difference,145,0.0001711724137931,1.9999999999999185e-05,0.0018562538826926,-0.00455,0.0092,-0.0039711999999999,-0.0025179999999999,-0.0006799999999998,0.0007000000000001,0.0043399999999998,0.0062248,1.4312849475258724,5.523795135672273,217.81516699072975,5.0354402906198516e-48,Log returns are stored in decimal form where applicable.
CPI_yoy_level,Percentage points,146,0.0254383561643835,0.0175,0.0273450424436438,-0.005,0.115,-0.00255,0.00025,0.0069999999999999,0.027,0.0975,0.1101,1.7584499529078492,2.455082238848806,106.75358746101998,6.587991363346598e-24,Log returns are stored in decimal form where applicable.
CPI_yoy_change,Percentage points,145,0.0001793103448275,0.0,0.0039750418682582,-0.016,0.016,-0.01224,-0.005,-0.0019999999999999,0.002,0.0069999999999998,0.00912,-0.2319343827138114,3.833363729945385,82.26477064183604,1.3690900922934693e-18,Log returns are stored in decimal form where applicable.
CISS_level,Index level,146,0.1079869863013698,0.0572,0.133156761783944,0.0013,0.696,0.0013,0.002875,0.014475,0.1431,0.377425,0.6339950000000008,2.093706952677506,5.006586776643157,244.40452052436723,8.476814744552348e-54,Log returns are stored in decimal form where applicable.
CISS_change,Index change,145,8.275862068970731e-06,-0.0034999999999999,0.0925542937531565,-0.2859999999999999,0.4964999999999999,-0.240944,-0.1145599999999999,-0.0333,0.0181999999999999,0.1298199999999999,0.3458440000000001,1.5154212147583426,8.314769911415699,440.026050435868,2.815510822188703e-96,Log returns are stored in decimal form where applicable.
GE_return,"Log return, decimal form",145,0.007997919367327,0.0073350605383026,0.0695408680148368,-0.1701888463451162,0.2048396266377379,-0.1398279215201142,-0.1164142330668505,-0.0382964738195834,0.049507759701374,0.1235493580727088,0.1566091821741759,0.032216083936448,0.0291450759247733,0.0255768700634634,0.9872929895363618,Log returns are stored in decimal form where applicable.
Stoxx600_return,"Log return, decimal form",145,0.0063589166743148,0.0139068466956189,0.0392642574959625,-0.1568174055556275,0.129630457340756,-0.0865548417953754,-0.0567280091763977,-0.0135907396586549,0.0301042649056197,0.063914376471287,0.076317530820298,-0.5920840438920035,1.8124532463740683,25.95234589307015,2.3148331498206976e-06,Log returns are stored in decimal form where applicable.
GreenEquity_relative,"Relative log return, decimal form",145,0.0016390026930122,0.0063537294452595,0.0587585603177175,-0.1387098558751409,0.2253493254113481,-0.1274893049122083,-0.1022439248203186,-0.0334535220583855,0.0327911649693932,0.0907285117926297,0.165104503704467,0.324018783976687,1.4704729279855169,13.976559873503769,0.000922632153252,Log returns are stored in decimal form where applicable.
GreenEquity_relative_check,"Relative log return, decimal form",145,0.0016390026930122,0.0063537294452597,0.0587585603177175,-0.1387098558751409,0.2253493254113475,-0.127489304912208,-0.1022439248203178,-0.0334535220583853,0.0327911649693939,0.0907285117926304,0.1651045037044673,0.3240187839766884,1.4704729279855018,13.976559873503524,0.0009226321532521,Log returns are stored in decimal form where applicable.
GreenBond_return,"Log return, decimal form",145,0.0017143139925626,0.0021599799220917,0.0138820300597503,-0.067524955349433,0.0456393238662373,-0.0396946475447063,-0.0202316991467682,-0.0034132137332942,0.0095062066384912,0.0221530888797845,0.0342726684494807,-1.0485931448737569,5.07700439558621,168.8737601451785,2.13564427261412e-37,Log returns are stored in decimal form where applicable.
CorpBond_return,"Log return, decimal form",145,0.0013433090811379,0.0021028885540328,0.0131711596858838,-0.0709568525860548,0.045933770967208,-0.0398087545663053,-0.0195047396515844,-0.0030746305912598,0.0075610135506396,0.0164519558161186,0.032707719672129,-1.331428387492318,7.568794216018478,361.20646685746107,3.672927095205304e-79,Log returns are stored in decimal form where applicable.
GreenBond_relative,"Relative log return, decimal form",145,0.0003710049114247,4.687771163514043e-05,0.0029611083827213,-0.0080943988830952,0.0132349337233046,-0.0070537773439599,-0.0041954082576727,-0.0007776801125931,0.0011855678366607,0.0053346780722563,0.0108639677580352,0.9437102016630808,4.5965040925279865,137.96156236831322,1.1016087436899698e-30,Log returns are stored in decimal form where applicable.
GreenBond_relative_check,"Relative log return, decimal form",145,0.0003710049114247,4.687771163514043e-05,0.0029611083827213,-0.0080943988830956,0.0132349337233043,-0.0070537773439605,-0.0041954082576727,-0.0007776801125937,0.0011855678366604,0.0053346780722562,0.0108639677580355,0.9437102016629508,4.596504092527946,137.9615623683055,1.1016087436942423e-30,Log returns are stored in decimal form where applicable.
```

## Extreme Observations

Extreme observations are identified but not removed, modified, winsorized, or smoothed.

```csv
variable,date,value,z_score,modified_z_score,criterion
EUA_ret,2016-12-31,0.357766051521067,2.9951340172042333,3.54074034636252,abs_modified_z_score_gt_3_5
TTF_ret,2020-08-31,0.6238043984745463,3.2505337730240678,4.070165864501408,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
TTF_ret,2021-09-30,0.6638984339451812,3.461264246298653,4.334944892551094,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
TTF_ret,2022-12-31,-0.6514525981468875,-3.452096862437525,-4.351568294094049,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
Brent_ret,2020-03-31,-0.7982438091599007,-6.624014417331549,-9.840744853653812,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
Brent_ret,2020-05-31,0.335114539970951,2.776280190095614,3.9188718144583694,abs_modified_z_score_gt_3_5
Brent_ret,2026-03-31,0.4903356742252684,4.063714471061171,5.803344900809984,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
Power_ret,2022-02-28,0.1456355980589814,2.4573264807698787,3.630985115216811,abs_modified_z_score_gt_3_5
Power_ret,2022-07-31,0.1499534018919179,2.5332361745026635,3.742107783193681,abs_modified_z_score_gt_3_5
Power_ret,2022-08-31,0.1792624535833837,3.048507646663188,4.4964032875387,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
Power_ret,2024-03-31,-0.1544943814975949,-2.8191463998131367,-4.093136998382902,abs_modified_z_score_gt_3_5
Power_ret,2024-04-30,-0.2791247722440557,-5.010226670573632,-7.300615167053632,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
Power_ret,2024-07-31,-0.186513097852579,-3.3820554726347214,-4.917168224493684,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
IP_growth,2020-03-31,-0.1151189046800702,-4.496959611759464,-12.44380338086325,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
IP_growth,2020-04-30,-0.2042244496781755,-7.956911423324392,-21.99203352142152,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
IP_growth,2020-05-31,0.1235163743644847,4.769204082666809,13.127495958837812,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
IP_growth,2020-06-30,0.0886581455791519,3.4156655140365237,9.392213370737734,abs_z_score_gt_3;abs_modified_z_score_gt_3_5
IP_growth,2020-07-31,0.0442550090040398,1.691499943470844,4.634132748585365,abs_modified_z_score_gt_3_5
Bund2Y_change,2022-03-31,0.0045899999999999,2.3805081984782155,4.403521428572596,abs_modified_z_score_gt_3_5
Bund2Y_change,2022-07-31,-0.00368,-2.0747013378400183,-3.5652142857153075,abs_modified_z_score_gt_3_5
```
... 102 additional rows in the CSV file.

## Stationarity Tests

Detailed ADF, Phillips-Perron, and KPSS results are saved in `output/tables/stationarity_tests_detailed.csv`.

Stationarity summary:

```csv
dataset,variable,adf_result,pp_result,kpss_result,joint_evaluation,recommendation
data_model_diff,EUA_ret,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
data_model_diff,TTF_ret,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
data_model_diff,Brent_ret,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
data_model_diff,Power_ret,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
data_model_diff,CPI_yoy_change,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
data_model_diff,IP_growth,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
data_model_diff,Bund2Y_change,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
data_model_diff,CISS_change,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
data_model_diff,GreenEquity_relative,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
data_model_diff,GreenBond_relative,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
level_change_checks,CPI_yoy_level,Fail to reject unit root at 5%,Fail to reject unit root at 5%,Reject stationarity at 5%,CLEARLY_NONSTATIONARY,Treat as nonstationary evidence and use only with an explicit robustness rationale.
level_change_checks,CPI_yoy_change,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
level_change_checks,CISS_level,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
level_change_checks,CISS_change,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
```

CPI and CISS level-versus-difference comparison:

```csv
dataset,variable,adf_result,pp_result,kpss_result,joint_evaluation,recommendation
data_model_diff,CPI_yoy_change,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
data_model_diff,CISS_change,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
level_change_checks,CPI_yoy_level,Fail to reject unit root at 5%,Fail to reject unit root at 5%,Reject stationarity at 5%,CLEARLY_NONSTATIONARY,Treat as nonstationary evidence and use only with an explicit robustness rationale.
level_change_checks,CPI_yoy_change,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
level_change_checks,CISS_level,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
level_change_checks,CISS_change,Reject unit root; stationary at 5%,Reject unit root; stationary at 5%,Fail to reject stationarity at 5%,CLEARLY_STATIONARY,Retain in the candidate set.
```

ADF, Phillips-Perron, and KPSS detailed rows:

```csv
dataset,variable,test,null_hypothesis,statistic,p_value,lag_or_bandwidth,observations_used,conclusion_5pct,warning,critical_1pct,critical_5pct,critical_10pct
data_model_diff,EUA_ret,ADF,unit root,-12.685002406554592,1.1647943814111809e-23,0,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,EUA_ret,Phillips-Perron,unit root,-12.720208539237031,9.864656319264255e-24,14,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,EUA_ret,KPSS,stationarity around a constant,0.1617033834401209,0.1,5,145,Fail to reject stationarity at 5%,"The test statistic is outside of the range of p-values available in the
look-up table. The actual p-value is greater than the p-value returned.
",0.739,0.463,0.347
data_model_diff,TTF_ret,ADF,unit root,-6.269966964859556,4.02672840230321e-08,1,143,Reject unit root; stationary at 5%,,-3.4769274060112707,-2.8819726324025625,-2.577665408088415
data_model_diff,TTF_ret,Phillips-Perron,unit root,-12.011205441100818,3.1778122753783135e-22,14,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,TTF_ret,KPSS,stationarity around a constant,0.0622078780848524,0.1,4,145,Fail to reject stationarity at 5%,"The test statistic is outside of the range of p-values available in the
look-up table. The actual p-value is greater than the p-value returned.
",0.739,0.463,0.347
data_model_diff,Brent_ret,ADF,unit root,-10.547955467550986,8.318234016834374e-19,0,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,Brent_ret,Phillips-Perron,unit root,-10.468047235477062,1.306058850463491e-18,14,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,Brent_ret,KPSS,stationarity around a constant,0.17667973241429,0.1,5,145,Fail to reject stationarity at 5%,"The test statistic is outside of the range of p-values available in the
look-up table. The actual p-value is greater than the p-value returned.
",0.739,0.463,0.347
data_model_diff,Power_ret,ADF,unit root,-3.1835067525422813,0.0209594435635984,2,142,Reject unit root; stationary at 5%,,-3.477261624048995,-2.8821181874544237,-2.577743110493949
data_model_diff,Power_ret,Phillips-Perron,unit root,-9.14132402907952,2.844172483362225e-15,14,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,Power_ret,KPSS,stationarity around a constant,0.1265035560290104,0.1,7,145,Fail to reject stationarity at 5%,"The test statistic is outside of the range of p-values available in the
look-up table. The actual p-value is greater than the p-value returned.
",0.739,0.463,0.347
data_model_diff,CPI_yoy_change,ADF,unit root,-7.28332706967996,1.4807484218289026e-10,0,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,CPI_yoy_change,Phillips-Perron,unit root,-8.56430564290691,8.528312910961852e-14,14,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,CPI_yoy_change,KPSS,stationarity around a constant,0.0805719875848533,0.1,7,145,Fail to reject stationarity at 5%,"The test statistic is outside of the range of p-values available in the
look-up table. The actual p-value is greater than the p-value returned.
",0.739,0.463,0.347
data_model_diff,IP_growth,ADF,unit root,-10.93997485707546,9.349585145901496e-20,1,143,Reject unit root; stationary at 5%,,-3.4769274060112707,-2.8819726324025625,-2.577665408088415
data_model_diff,IP_growth,Phillips-Perron,unit root,-12.104048465731427,1.987793740972464e-22,14,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,IP_growth,KPSS,stationarity around a constant,0.0906778634441104,0.1,24,145,Fail to reject stationarity at 5%,"The test statistic is outside of the range of p-values available in the
look-up table. The actual p-value is greater than the p-value returned.
",0.739,0.463,0.347
data_model_diff,Bund2Y_change,ADF,unit root,-11.809357276158362,8.93692842830442e-22,0,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,Bund2Y_change,Phillips-Perron,unit root,-12.679238279967176,1.196997253550642e-23,14,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,Bund2Y_change,KPSS,stationarity around a constant,0.3157299150108221,0.1,4,145,Fail to reject stationarity at 5%,"The test statistic is outside of the range of p-values available in the
look-up table. The actual p-value is greater than the p-value returned.
",0.739,0.463,0.347
data_model_diff,CISS_change,ADF,unit root,-11.29205172500748,1.3721355447529522e-20,1,143,Reject unit root; stationary at 5%,,-3.4769274060112707,-2.8819726324025625,-2.577665408088415
data_model_diff,CISS_change,Phillips-Perron,unit root,-16.617940572947184,1.7080653613457684e-29,14,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,CISS_change,KPSS,stationarity around a constant,0.0558084661369423,0.1,9,145,Fail to reject stationarity at 5%,"The test statistic is outside of the range of p-values available in the
look-up table. The actual p-value is greater than the p-value returned.
",0.739,0.463,0.347
data_model_diff,GreenEquity_relative,ADF,unit root,-11.490133469577238,4.758562675772021e-21,0,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,GreenEquity_relative,Phillips-Perron,unit root,-12.21614749569524,1.134438532910593e-22,14,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,GreenEquity_relative,KPSS,stationarity around a constant,0.1918981684282968,0.1,5,145,Fail to reject stationarity at 5%,"The test statistic is outside of the range of p-values available in the
look-up table. The actual p-value is greater than the p-value returned.
",0.739,0.463,0.347
data_model_diff,GreenBond_relative,ADF,unit root,-8.639539024736457,5.473448074033267e-14,0,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,GreenBond_relative,Phillips-Perron,unit root,-8.64027881052893,5.4496274075620437e-14,14,144,Reject unit root; stationary at 5%,,-3.476597917537401,-2.8818291230495543,-2.5775887982253085
data_model_diff,GreenBond_relative,KPSS,stationarity around a constant,0.3618782905828845,0.0935869437142739,5,145,Fail to reject stationarity at 5%,,0.739,0.463,0.347
```
... 12 additional rows in the CSV file.

## Autocorrelation

ACF/PACF figures are saved in `output/figures/acf_pacf`. Ljung-Box tests use the null hypothesis of no autocorrelation up to the tested lag.

Significant Ljung-Box results at 5%:

```csv
dataset,variable,lag,lb_statistic,p_value,null_hypothesis,conclusion_5pct
data_model_diff,TTF_ret,6,12.73077987772403,0.0475160637591555,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,TTF_ret,12,22.67745375789876,0.030592458114425,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,Power_ret,6,135.0454779835064,1.111677895272482e-26,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,Power_ret,12,164.65673679013503,5.89749328750011e-29,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,CPI_yoy_change,6,99.32499421500296,3.4702751325276804e-19,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,CPI_yoy_change,12,128.4599382902375,1.2571446269600148e-21,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,IP_growth,6,21.254016198416014,0.0016514129762086,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,IP_growth,12,23.906066443149232,0.0209476808226593,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,Bund2Y_change,12,29.264368307893097,0.0035989001458133,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,CISS_change,6,16.026691108341048,0.0136114205462476,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,CISS_change,12,24.397733289792505,0.0179493078105154,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,GreenEquity_relative,6,14.328395839026449,0.0261753609549642,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,GreenBond_relative,6,26.24628924941449,0.0002003066639052,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_diff,GreenBond_relative,12,29.30027982799589,0.0035548114963245,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_levels,TTF_ret,6,12.73077987772403,0.0475160637591555,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_levels,TTF_ret,12,22.67745375789876,0.030592458114425,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_levels,Power_ret,6,135.0454779835064,1.111677895272482e-26,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_levels,Power_ret,12,164.65673679013503,5.89749328750011e-29,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_levels,CPI_yoy_level,6,751.8657562034354,3.8541319284501315e-159,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
data_model_levels,CPI_yoy_level,12,1101.8279611715702,2.3511929349730947e-228,no autocorrelation up to tested lag,Reject no-autocorrelation at 5%
```
... 8 additional rows in the CSV file.

## Correlations and Collinearity

Pearson and Spearman matrices are saved as CSV files in `output/tables`, with heatmaps in `output/figures/correlations`.

High absolute correlations:

No rows.

Requested relationship checks:

```csv
dataset,method,relationship,variable_1,variable_2,correlation,abs_correlation
data_model_diff,pearson,TTF - Power,TTF_ret,Power_ret,0.2716458038487437,0.2716458038487437
data_model_diff,pearson,TTF - Brent,TTF_ret,Brent_ret,0.164125323977503,0.164125323977503
data_model_diff,pearson,Power - CPI,Power_ret,CPI_yoy_change,0.2879659399383766,0.2879659399383766
data_model_diff,pearson,CPI - Bund 2Y,CPI_yoy_change,Bund2Y_change,0.1988549363456886,0.1988549363456886
data_model_diff,pearson,Green equity - green bond,GreenEquity_relative,GreenBond_relative,-0.0665937686561339,0.0665937686561339
data_model_diff,spearman,TTF - Power,TTF_ret,Power_ret,0.2608290033065659,0.2608290033065659
data_model_diff,spearman,TTF - Brent,TTF_ret,Brent_ret,0.1302432687765706,0.1302432687765706
data_model_diff,spearman,Power - CPI,Power_ret,CPI_yoy_change,0.2772987178422206,0.2772987178422206
data_model_diff,spearman,CPI - Bund 2Y,CPI_yoy_change,Bund2Y_change,0.1094427364587921,0.1094427364587921
data_model_diff,spearman,Green equity - green bond,GreenEquity_relative,GreenBond_relative,-0.1340497559439458,0.1340497559439458
data_model_levels,pearson,TTF - Power,TTF_ret,Power_ret,0.2716458038487437,0.2716458038487437
data_model_levels,pearson,TTF - Brent,TTF_ret,Brent_ret,0.164125323977503,0.164125323977503
data_model_levels,pearson,Power - CPI,Power_ret,CPI_yoy_level,0.3316762435493738,0.3316762435493738
data_model_levels,pearson,CPI - Bund 2Y,CPI_yoy_level,Bund2Y_change,0.381483009378104,0.381483009378104
data_model_levels,pearson,Green equity - green bond,GreenEquity_relative,GreenBond_relative,-0.0665937686561339,0.0665937686561339
data_model_levels,spearman,TTF - Power,TTF_ret,Power_ret,0.2608290033065659,0.2608290033065659
data_model_levels,spearman,TTF - Brent,TTF_ret,Brent_ret,0.1302432687765706,0.1302432687765706
data_model_levels,spearman,Power - CPI,Power_ret,CPI_yoy_level,0.2430748284399493,0.2430748284399493
data_model_levels,spearman,CPI - Bund 2Y,CPI_yoy_level,Bund2Y_change,0.2210665265868467,0.2210665265868467
data_model_levels,spearman,Green equity - green bond,GreenEquity_relative,GreenBond_relative,-0.1340497559439458,0.1340497559439458
```

VIF is a static diagnostic and is not a definitive exclusion criterion for a BVAR with shrinkage. No variable is removed based on VIF.

High VIF rows:

No rows.

Condition number diagnostics:

```csv
dataset,condition_number,singular_values,note
data_model_diff,2.2526062333051358,17.44668346;14.54578517;12.59874787;12.30903402;11.87725349;11.47519337;10.48447248;9.799821908;9.224748563;7.745110175,Variables were standardized temporarily only for this diagnostic.
data_model_levels,2.194284276897809,16.8006725;16.35975102;12.89766199;12.54130921;11.71559703;11.40336777;9.824074379;9.339322809;8.173829964;7.656561494,Variables were standardized temporarily only for this diagnostic.
```

## Recommendation for the BVAR Stage

The recommended main candidate set is `data_processed/data_model_diff.csv`. It uses log returns and first differences while preserving the numeric scale of each transformed series. `data_processed/data_model_levels.csv` should be kept for stationarity comparison and robustness checks involving CPI and CISS levels.

No VAR, BVAR, BVAR-SV, BSVAR, or BSVAR-SV model is estimated in this stage. No structural-break tests are run.
