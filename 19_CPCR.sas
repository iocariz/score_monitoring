%sm_require(data=sm_tmp.cpcr_base);
/***CETELEM***/

data direct(keep=authorization_id risk_level politica_seg_bcc company nature_holder score_model fraud_flag mis_date outstanding product_type_1-product_type_3 red score_band score_rf se_decision_id segment_1-segment_4 status_name todu_30ever_h6 todu_amt_pile_h6 valid_call valid_score_rf vendedor_cadena_top_name acct_booked_H0);
	set sm_tmp.cpcr_base (keep=authorization_id a_business_name nature_holder zxnota company acct_booked_H0 todu_30ever_h6 zxscore todu_amt_pile_h6 CLASIFICACION_DATE mis_date oa_amt_cma mdeccent product_type_1-product_type_3 red rf_business_name score_rf se_decision_id segment_1-segment_4 status_name valid_call vendedor_cadena_top_name);
	where mis_date ge '01JAN2021'd and company = 'CETELEM' and product_type_2 ne 'Panda' and rf_business_name = 'A-Score DIRECT 2024';

	if product_type_1 = 'Cards' then outstanding = mdeccent/100;
	else outstanding = oa_amt_cma;

	if CLASIFICACION_DATE ne . then fraud_flag = 'Y'; 
	else fraud_flag = 'N';

	if score_rf le 364 then score_band = 0;
	else if score_rf le 370 then score_band = 1;
	else if score_rf le 379 then score_band = 2;
	else if score_rf le 382 then score_band = 3;
	else if score_rf le 389 then score_band = 4;
	else if score_rf le 397 then score_band = 5;
	else if score_rf le 404 then score_band = 6;
	else if score_rf le 416 then score_band = 7;
	else if score_rf le 431 then score_band = 8;
	else score_band=9;

	length risk_level $ 50.;
	if score_band le 3 then risk_level = 'Higher Band';
	else if score_band le 7 then risk_level = 'Medium Band';
	else risk_level = 'Lower Band';

	score_model = rf_business_name;

	if score_RF = . then valid_score_RF=0;
	else valid_score_RF=1;

	length politica_seg_bcc $35.;
	politica_seg_bcc='Otros';
run;

data disttrib_trad(keep=authorization_id risk_level politica_seg_bcc zxscore company nature_holder score_model fraud_flag mis_date outstanding product_type_1-product_type_3 red score_band score_rf se_decision_id segment_1-segment_4 status_name todu_30ever_h6 todu_amt_pile_h6 valid_call valid_score_rf vendedor_cadena_top_name acct_booked_H0);
	set sm_tmp.cpcr_base (keep=authorization_id nature_holder company CLASIFICACION_DATE acct_booked_H0 todu_30ever_h6 zxscore todu_amt_pile_h6 mis_date oa_amt_cma mdeccent product_type_1-product_type_3 red rf_business_name score_rf se_decision_id segment_1-segment_4 status_name valid_call vendedor_cadena_top_name);
	where mis_date ge '01JAN2021'd and rf_business_name = 'A-Score DISTRIB Retail Traditional CTLM' and company = 'CETELEM';

	if product_type_1 = 'Cards' then outstanding = mdeccent/100;
	else outstanding = oa_amt_cma;

	if CLASIFICACION_DATE ne . then fraud_flag = 'Y'; 
	else fraud_flag = 'N';

	if score_RF = . or score_RF > 1 then valid_score_RF=0;
	else valid_score_RF=1;

	if 		round(score_RF,0.0000001) le 0.8894938 then score_band = 1;
	else if round(score_RF,0.0000001) le 0.9136649 then score_band = 2;
	else if round(score_RF,0.0000001) le 0.9470597 then score_band = 3;
	else if round(score_RF,0.0000001) le 0.9654058 then score_band = 4;
	else if round(score_RF,0.0000001) le 0.9703869 then score_band = 5;
	else if round(score_RF,0.0000001) le 0.9744170 then score_band = 6;
	else if round(score_RF,0.0000001) le 0.9777791 then score_band = 7;
	else if round(score_RF,0.0000001) le 0.9806289 then score_band = 8;
	else if round(score_RF,0.0000001) le 0.9830639 then score_band = 9;
	else if round(score_RF,0.0000001) le 0.9851669 then score_band = 10;
	else if round(score_RF,0.0000001) le 0.9870236 then score_band = 11;
	else if round(score_RF,0.0000001) le 0.9886948 then score_band = 12;
	else if round(score_RF,0.0000001) le 0.9902284 then score_band = 13;
	else if round(score_RF,0.0000001) le 0.9916906 then score_band = 14;
	else if round(score_RF,0.0000001) le 0.9930733 then score_band = 15;
	else if round(score_RF,0.0000001) le 0.9943728 then score_band = 16;
	else if round(score_RF,0.0000001) le 0.9956056 then score_band = 17;
	else if round(score_RF,0.0000001) le 0.9967630 then score_band = 18;
	else if round(score_RF,0.0000001) le 0.9977915 then score_band = 19;
	else if round(score_RF,0.0000001) 			   then score_band = 20;

	score_model = rf_business_name;

	length risk_level $ 50.;
	if score_band le 5 then risk_level = 'Higher Band';
	else if score_band le 10 then risk_level = 'Medium Band';
	else risk_level = 'Lower Band';

	length politica_seg_bcc $35.;
	politica_seg_bcc='Otros';
run;

proc freq data=disttrib_trad;
tables score_band*zxscore /nocol nocum norow;
/*where status_name = 'Booked';*/
run;

data distrib_ecom(keep=authorization_id risk_level politica_seg_bcc company nature_holder score_model fraud_flag mis_date zxnota ZRF1SCORE outstanding product_type_1-product_type_3 red score_band score_rf se_decision_id segment_1-segment_4 status_name todu_30ever_h6 todu_amt_pile_h6 valid_call valid_score_rf vendedor_cadena_top_name acct_booked_H0);
	set sm_tmp.cpcr_base (keep=authorization_id nature_holder company CLASIFICACION_DATE acct_booked_H0 todu_30ever_h6 zxscore zxnota ZRF1SCORE todu_amt_pile_h6 mis_date oa_amt_cma mdeccent product_type_1-product_type_3 red rf_business_name score_rf se_decision_id segment_1-segment_4 status_name valid_call vendedor_cadena_top_name);
	where mis_date ge '01JAN2021'd and rf_business_name = "Equifax Risk Score V3 - Retail E-COMM CTLM" and company = 'CETELEM' and score_RF > 0 and score_RF <= 99;

	if product_type_1 = 'Cards' then outstanding = mdeccent/100;
	else outstanding = oa_amt_cma;

	if CLASIFICACION_DATE ne . then fraud_flag = 'Y'; 
	else fraud_flag = 'N';

	if score_RF = . and score_RF <1 then valid_score_RF=0;
	else valid_score_RF=1;

	score_band = int(score_rf);

	if 		score_rf lt 0  then score_band = .;
	else if score_rf le 2  then score_band=1;
	else if score_rf le 7  then score_band=2;
	else if score_rf le 11 then score_band=3;
	else if score_rf le 16 then score_band=4;
	else if score_rf le 22 then score_band=5;
	else if score_rf le 27 then score_band=6;
	else if score_rf le 33 then score_band=7;
	else if score_rf le 38 then score_band=8;
	else if score_rf le 43 then score_band=9;
	else if score_rf le 47 then score_band=10;
	else if score_rf le 51 then score_band=11;
	else if score_rf le 56 then score_band=12;
	else if score_rf le 62 then score_band=13;
	else if score_rf le 68 then score_band=14;
	else if score_rf le 73 then score_band=15;
	else if score_rf le 78 then score_band=16;
	else if score_rf le 83 then score_band=17;
	else if score_rf le 89 then score_band=18;
	else if score_rf le 94 then score_band=19;
	else if score_rf le 99 then score_band=20;

	score_model = rf_business_name;

	length risk_level $ 50.;
	if score_band le 4 then risk_level = 'Higher Band';
	else if score_band le 14 then risk_level = 'Medium Band';
	else risk_level = 'Lower Band';

	length politica_seg_bcc $35.;
	politica_seg_bcc='Otros';

run;


proc freq data=distrib_ecom;
tables score_RF;
run;

data auto(keep=authorization_id risk_level politica_seg_bcc company nature_holder score_model fraud_flag mis_date outstanding product_type_1-product_type_3 red score_band score_rf se_decision_id segment_1-segment_4 status_name todu_30ever_h6 todu_amt_pile_h6 valid_call valid_score_rf vendedor_cadena_top_name acct_booked_H0);
	set sm_tmp.cpcr_base (keep=authorization_id nature_holder company CLASIFICACION_DATE acct_booked_H0 todu_30ever_h6 zxscore todu_amt_pile_h6 mis_date oa_amt_cma mdeccent product_type_1-product_type_3 red rf_business_name score_rf se_decision_id segment_1-segment_4 status_name valid_call vendedor_cadena_top_name);
	where mis_date ge '01JAN2021'd and rf_business_name = "Score Auto Moto CTLM" and company = 'CETELEM' and score_RF > 0;

	if product_type_1 = 'Cards' then outstanding = mdeccent/100;
	else outstanding = oa_amt_cma;

	if CLASIFICACION_DATE ne . then fraud_flag = 'Y'; 
	else fraud_flag = 'N';

	if score_RF = .  then valid_score_RF=0;
	else valid_score_RF=1;

	score_band = input(zxscore,2.);

	score_model = rf_business_name;

	length risk_level $ 50.;
	if score_band le 2 then risk_level = 'Higher Band';
	else if score_band le 5 then risk_level = 'Medium Band';
	else risk_level = 'Lower Band';

	length politica_seg_bcc $35.;
	politica_seg_bcc='Otros';
run;

/**CAJAMAR**/
data direct_cmc(keep=authorization_id risk_level politica_seg_bcc company nature_holder score_model fraud_flag mis_date outstanding product_type_1-product_type_3 red score_band score_rf se_decision_id segment_1-segment_4 status_name todu_30ever_h6 todu_amt_pile_h6 valid_call valid_score_rf vendedor_cadena_top_name acct_booked_H0);
	set sm_tmp.cpcr_base (keep=authorization_id a_business_name pltbc1 nature_holder ML_SCORE_P0 company CLASIFICACION_DATE acct_booked_H0 todu_30ever_h6 zxscore todu_amt_pile_h6 mis_date oa_amt_cma mdeccent product_type_1-product_type_3 red rf_business_name score_rf se_decision_id segment_1-segment_4 status_name valid_call vendedor_cadena_top_name);
	where mis_date ge '01JAN2021'd and (rf_business_name = 'A-Score DIRECT ML CMC' or a_business_name = 'A-Score DIRECT ML CMC') and company = 'CMC';

	if a_business_name in  ('A-Score DIRECT ML CMC') then 
							do;
								score_RF = ML_SCORE_P0;
								rf_business_name =  a_business_name;
							end;

	if product_type_1 = 'Cards' then outstanding = mdeccent/100;
	else outstanding = oa_amt_cma;

	if CLASIFICACION_DATE ne . then fraud_flag = 'Y'; 
	else fraud_flag = 'N';

	if score_RF = . or score_RF > 1 then valid_score_RF=0;
	else valid_score_RF=1;

	if 		score_RF = . then score_band = .;
	else if round(score_RF,0.0000001) le 0.727075 	then score_band = 1;
	else if round(score_RF,0.0000001) le 0.7677014	then score_band = 2;
	else if round(score_RF,0.0000001) le 0.7969099 	then score_band = 3;
	else if round(score_RF,0.0000001) le 0.8198714 	then score_band = 4;
	else if round(score_RF,0.0000001) le 0.8391541 	then score_band = 5;
	else if round(score_RF,0.0000001) le 0.8549067 	then score_band = 6;
	else if round(score_RF,0.0000001) le 0.867447 	then score_band = 7;
	else if round(score_RF,0.0000001) le 0.8786486 	then score_band = 8;
	else if round(score_RF,0.0000001) le 0.8885892 	then score_band = 9;
	else if round(score_RF,0.0000001) le 0.897551 	then score_band = 10;
	else if round(score_RF,0.0000001) le 0.920042 	then score_band = 11;
	else if round(score_RF,0.0000001) le 0.9390011 	then score_band = 12;
	else if round(score_RF,0.0000001) le 0.9542669 	then score_band = 13;
	else if round(score_RF,0.0000001) le 0.9670261 	then score_band = 14;
	else if round(score_RF,0.0000001) le 0.977677 	then score_band = 15;
	else if round(score_RF,0.0000001) le 0.9855601 	then score_band = 16;
	else if round(score_RF,0.0000001) le 0.9913119 	then score_band = 17;
	else if round(score_RF,0.0000001) le 0.9952319 	then score_band = 18;
	else if round(score_RF,0.0000001) le 0.9978755 	then score_band = 19;
	else if round(score_RF,0.0000001) le 1 			then score_band = 20;

	score_model = rf_business_name;

	length risk_level $ 50.;
	if score_band le 6 then risk_level = 'Higher Band';
	else if score_band le 11 then risk_level = 'Medium Band';
	else risk_level = 'Lower Band';

	length politica_seg_bcc $35.;
	if pltbc1<=0 then politica_seg_bcc='Sin definir';
	else if pltbc1=1 then politica_seg_bcc='Favorable';
	else if pltbc1=2 then politica_seg_bcc='Neutral';
	else if pltbc1=3 then politica_seg_bcc='Neutral por no vinculacion con BCC';
	else if pltbc1=4 then politica_seg_bcc='Restrictiva';
	else politica_seg_bcc='Otros';
run;
data disttrib_trad_cmc(keep=authorization_id risk_level politica_seg_bcc rf_business_name a_business_name company nature_holder score_model fraud_flag mis_date outstanding product_type_1-product_type_3 red score_band score_rf se_decision_id segment_1-segment_4 status_name todu_30ever_h6 todu_amt_pile_h6 valid_call valid_score_rf vendedor_cadena_top_name acct_booked_H0);
	set sm_tmp.cpcr_base (keep=authorization_id nature_holder pltbc1 a_business_name company CLASIFICACION_DATE acct_booked_H0 todu_30ever_h6 zxscore todu_amt_pile_h6 mis_date oa_amt_cma mdeccent product_type_1-product_type_3 red rf_business_name score_rf se_decision_id segment_1-segment_4 status_name valid_call vendedor_cadena_top_name);
	where mis_date ge '01JAN2021'd and /*rf_business_name = 'A-Score DISTRIB Retail Traditional CMC'*/ red=1 and company = 'CMC';

	if product_type_1 = 'Cards' then outstanding = mdeccent/100;
	else outstanding = oa_amt_cma;

	if CLASIFICACION_DATE ne . then fraud_flag = 'Y'; 
	else fraud_flag = 'N';

	if score_RF = . or score_RF > 1 then valid_score_RF=0;
	else valid_score_RF=1;

	if 		round(score_RF,0.0000001) le  0.9378750 then score_band = 1;
	else if round(score_RF,0.0000001) le  0.9493545 then score_band = 2;
	else if round(score_RF,0.0000001) le  0.9566220 then score_band = 3;
	else if round(score_RF,0.0000001) le  0.9627754 then score_band = 4;
	else if round(score_RF,0.0000001) le  0.9680681 then score_band = 5;
	else if round(score_RF,0.0000001) le  0.9723781 then score_band = 6;
	else if round(score_RF,0.0000001) le  0.9761699 then score_band = 7;
	else if round(score_RF,0.0000001) le  0.9791811 then score_band = 8;
	else if round(score_RF,0.0000001) le  0.9816718 then score_band = 9;
	else if round(score_RF,0.0000001) le  0.9837332 then score_band = 10;
	else if round(score_RF,0.0000001) le  0.9856528 then score_band = 11;
	else if round(score_RF,0.0000001) le  0.9873823 then score_band = 12;
	else if round(score_RF,0.0000001) le  0.9889979 then score_band = 13;
	else if round(score_RF,0.0000001) le  0.9906464 then score_band = 14;
	else if round(score_RF,0.0000001) le  0.9921266 then score_band = 15;
	else if round(score_RF,0.0000001) le  0.9936769 then score_band = 16;
	else if round(score_RF,0.0000001) le  0.9950488 then score_band = 17;
	else if round(score_RF,0.0000001) le  0.9964995 then score_band = 18;
	else if round(score_RF,0.0000001) le  0.9976920 then score_band = 19;
	else if round(score_RF,0.0000001) 			    then score_band = 20;

	score_model = rf_business_name;

	length risk_level $ 50.;
	if score_band le 5 then risk_level = 'Higher Band';
	else if score_band le 12 then risk_level = 'Medium Band';
	else risk_level = 'Lower Band';

	length politica_seg_bcc $35.;
	if pltbc1<=0 then politica_seg_bcc='Sin definir';
	else if pltbc1=1 then politica_seg_bcc='Favorable';
	else if pltbc1=2 then politica_seg_bcc='Neutral';
	else if pltbc1=3 then politica_seg_bcc='Neutral por no vinculacion con BCC';
	else if pltbc1=4 then politica_seg_bcc='Restrictiva';
	else politica_seg_bcc='Otros';

run;

/*XFERA DIRECT LOANS*/
data direct_xfr(keep=authorization_id risk_level politica_seg_bcc company nature_holder score_model fraud_flag mis_date outstanding product_type_1-product_type_3 red score_band score_rf se_decision_id segment_1-segment_4 status_name todu_30ever_h6 todu_amt_pile_h6 valid_call valid_score_rf vendedor_cadena_top_name acct_booked_H0);
	set sm_tmp.cpcr_base (keep=authorization_id a_business_name nature_holder zxnota company acct_booked_H0 todu_30ever_h6 zxscore todu_amt_pile_h6 CLASIFICACION_DATE mis_date oa_amt_cma mdeccent product_type_1-product_type_3 red rf_business_name score_rf se_decision_id segment_1-segment_4 status_name valid_call vendedor_cadena_top_name);
	where mis_date ge '01JAN2021'd and company = 'XFR' and product_type_2 ne 'Panda' and rf_business_name =  'A-Score DIRECT XFR 2024';

	if product_type_1 = 'Cards' then outstanding = mdeccent/100;
	else outstanding = oa_amt_cma;

	if CLASIFICACION_DATE ne . then fraud_flag = 'Y'; 
	else fraud_flag = 'N';

	if score_rf le 364 then score_band = 0;
	else if score_rf le 379 then score_band = 1;
	else if score_rf le 383 then score_band = 2;
	else if score_rf le 389 then score_band = 3;
	else if score_rf le 398 then score_band = 4;
	else if score_rf le 404 then score_band = 5;
	else if score_rf le 419 then score_band = 6;
	else score_band=7;

	score_model = rf_business_name;

	if score_RF = . then valid_score_RF=0;
	else valid_score_RF=1;

	length risk_level $ 50.;
	if score_band le 2 then risk_level = 'Higher Band';
	else if score_band le 4 then risk_level = 'Medium Band';
	else risk_level = 'Lower Band';

	length politica_seg_bcc $35.;
	politica_seg_bcc='Otros';

run;

/*XFERA CARDS DISTRIB*/
data distrib_xfr(keep=authorization_id risk_level politica_seg_bcc company nature_holder score_model fraud_flag mis_date outstanding product_type_1-product_type_3 red score_band score_rf se_decision_id segment_1-segment_4 status_name todu_30ever_h6 todu_amt_pile_h6 valid_call valid_score_rf vendedor_cadena_top_name acct_booked_H0);
	set sm_tmp.cpcr_base (keep=authorization_id ext_business_name a_business_name nature_holder scrplust1 zxnota company acct_booked_H0 todu_30ever_h6 zxscore todu_amt_pile_h6 CLASIFICACION_DATE mis_date oa_amt_cma mdeccent product_type_1-product_type_3 red rf_business_name score_rf se_decision_id segment_1-segment_4 status_name valid_call vendedor_cadena_top_name);
	where mis_date ge '01JAN2021'd and company = 'XFR' and product_type_2 ne 'Panda' and ext_business_name = 'Equifax Risk Score - Loans and Cards';;

	if product_type_1 = 'Cards' then outstanding = mdeccent/100;
	else outstanding = oa_amt_cma;

	if CLASIFICACION_DATE ne . then fraud_flag = 'Y'; 
	else fraud_flag = 'N';

	score_rf = scrplust1;
	score_band = scrplust1;

	score_model = ext_business_name;

	if scrplust1 lt 1 or scrplust1 gt 20 or scrplust1=. then valid_score_RF=0;
	else valid_score_RF=1;

	length risk_level $ 50.;
	if score_band le 6 then risk_level = 'Lower Band';
	else if score_band le 10 then risk_level = 'Medium Band';
	else risk_level = 'Higher Band';

	length politica_seg_bcc $35.;
	politica_seg_bcc='Otros';
run;


data sm_tmp.score_models;
	set auto
		distrib_ecom
		disttrib_trad
		direct
		direct_cmc
		disttrib_trad_cmc
		direct_xfr
		distrib_xfr
;
run;
proc sql;
create table sm_tmp.CET_SCORES_SUM as
	select 	segment_1,
			segment_2,
			segment_3,
			segment_4,
			product_type_1,
			product_type_2,
			product_type_3,
			vendedor_cadena_top_name,
			red,
			se_decision_id,
			status_name,
			score_model,
			put(mis_date, yymmd7.) as mis_date,
			year(mis_date) as year,
			valid_call,
			fraud_flag,
			score_band,
			nature_holder,
			company,
			risk_level,
			politica_seg_bcc,
			sum(acct_booked_H0) as acct_booked_H0,
			sum(score_rf) as score_rf,
			sum(valid_score_rf) as valid_score_rf,
			sum(todu_30ever_h6) as todu_30ever_h6,
			sum(todu_amt_pile_h6) as todu_amt_pile_h6,
			sum(outstanding) as outstanding
	from 	sm_tmp.score_models
	group by segment_1,
			segment_2,
			segment_3,
			segment_4,
			product_type_1,
			product_type_2,
			product_type_3,
			vendedor_cadena_top_name,
			red,
			se_decision_id,
			status_name,
			score_model,
			calculated mis_date,
			calculated year,
			valid_call,
			fraud_flag,
			score_band,
			nature_holder,
			company,
			risk_level,
			politica_seg_bcc
;
quit;
