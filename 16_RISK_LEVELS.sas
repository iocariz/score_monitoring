/* Prepare all retrofit inputs from the narrow sidecar emitted by step 15. */
%sm_require(data=sm_tmp.sm_score_lookup_input);
%sm_require(data=sm_bk.ml_rf_mi, vars=company authorization_id ML_SCORE_P0_RF);
%sm_assert_unique(data=sm_bk.ml_rf_mi, keys=company authorization_id,
                  out=sm_tmp.qa_ml_lookup_duplicates);
%sm_assert_unique(data=sm_tmp.RETROFIT_DIRECT_CMC_SCORED, keys=authorization_id,
                  out=sm_tmp.qa_cmc_lookup_duplicates);
%sm_assert_unique(data=sm_bk.new_efx_base, keys=company authorization_id,
                  out=sm_tmp.qa_efx_lookup_duplicates);

proc sql;
    create table work.ml_rf_cmc as
    select a.authorization_id, a.company, a.ML_SCORE_P0, b.score_RF
    from sm_tmp.sm_score_lookup_input as a
    left join sm_tmp.RETROFIT_DIRECT_CMC_SCORED as b
      on a.authorization_id=b.authorization_id
    where a.ext_business_name='Equifax Risk Score - Direct CMC';
quit;
proc stdize data=work.ml_rf_cmc out=work.ml_rf_mi_cmc reponly method=mean;
    var score_RF;
run;
data work.ml_rf_mi_cmc(keep=authorization_id company ML_SCORE_P0_RF_CMC);
    set work.ml_rf_mi_cmc;
    if ML_SCORE_P0 in (.,0) then ML_SCORE_P0_RF_CMC=1-score_RF;
    else ML_SCORE_P0_RF_CMC=ML_SCORE_P0;
run;
proc sql;
    create table work.efx_v3 as
    select a.authorization_id, a.ext_business_name, a.mis_date, a.company,
           a.product_type_1, a.product_type_2, a.product_type_3,
           b.riskv3
    from sm_tmp.sm_score_lookup_input as a
    left join sm_bk.new_efx_base as b
      on a.authorization_id=b.authorization_id and a.company=b.company
    where a.mis_date ge '01JAN2021'd and a.ext_business_name in (
        'Equifax Risk Score - Direct CMC', 'Equifax Risk Score - Direct CTLM',
        'Equifax Risk Score Retail Auto Green', 'Equifax Risk Score Retail E-COMM CTLM');
quit;
proc sort data=work.efx_v3;
    by mis_date company product_type_1 product_type_2 product_type_3;
run;
proc stdize data=work.efx_v3 out=work.efx_v3_imputed reponly method=median;
    var riskv3;
    by mis_date company product_type_1 product_type_2 product_type_3;
run;
data work.efx_v3_mi(keep=authorization_id company risk_score_rf);
    set work.efx_v3_imputed;
	array bins(101) _temporary_ (-9999999,1,3,5,8,12,61,80,91,103,115,127,140,151,161,171,179,189,199,208,217,227,237,249,261,271,283,295,305,315,325,337,350,363,379,396,414,
                    429,443,453,466,478,487,497,506,516,524,532,540,548,555,563,571,577,584,589,597,604,610,616,622,628,635,640,647,651,657,661,666,672,677,
                    681,685,690,695,700,704,709,714,719,726,730,736,743,749,754,760,766,772,778,785,789,796,802,810,817,827,837,850,869,999999);
 
 
	risk_score_rf = 0;
 
	if missing(riskv3) then risk_score_rf = .;
	else do i = 2 to 101;
		if riskv3 > bins[i-1] and riskv3 <= bins[i] then do;
			risk_score_rf = i-2;
			leave;
		end;
	end;
	drop i;
run;
%sm_check_step(Retrofit imputation);
%sm_assert_unique(data=work.ml_rf_mi_cmc, keys=company authorization_id,
                  out=sm_tmp.qa_cmc_imputed_duplicates);
%sm_assert_unique(data=work.efx_v3_mi, keys=company authorization_id,
                  out=sm_tmp.qa_efx_imputed_duplicates);

%include "&sm_code_dir./macros/retrofit_lookup.sas";
%sm_retrofit_prepare;

/* One full-population read/write. Private hash fields cannot inherit stale
   values from an input column or an unsuccessful lookup. */
data sm_tmp.demand_prf_char_RF(compress=&sm_compress drop=_sm_:);
    length company $20 rf_ext_business_name $50 rf_business_name $100
           risk_level risk_level_v1 customer_type $50;
    length _sm_ml _sm_cmc _sm_efx _sm_rc 8;
    %sm_retrofit_init;
    set sm_tmp.demand_prf_char(rename=(SCORE=SCORE_CALC));
    call missing(_sm_ml,_sm_cmc,_sm_efx);
    %sm_retrofit_find;
    ML_SCORE_P0_RF=_sm_ml;
    ML_SCORE_P0_RF_CMC=_sm_cmc;
    risk_score_rf=_sm_efx;
	if a_business_name in	  ( 'A-Score DIRECT',
								'A-Score DIRECT 2024',
								'A-Score DIRECT XFR',
								'A-Score DIRECT XFR 2024',
								'Score Auto Moto CTLM',
								'Score Cards Retail E-COMM CMC',
								'Score Cards Retail E-COMM CTLM',
								'Score Distribution - Group 2 CMC',
								'Score Distribution - Group 2 CTLM',
								'Score Distribution 2013 - Group 1 CMC',
								'Score Distribution 2013 - Group 1 CTLM'
								'ORANGE APPLICATION PERSONAL PORTFOLIO'
								'ORANGE APPLICATION PERSONAL JAZZTEL'
								'ORANGE APPLICATION NEW BUSINESS'
								'ORANGE APPLICATION PERSONAL PORTABILITY'
								'ORANGE APPLICATION BUSINESS'
								) then score_real = ZXNOTA;

	else if a_business_name in ('A-Score DIRECT ML CMC',
								'A-Score DISTRIB Retail Traditional CMC',
								'A-Score DISTRIB Retail Traditional CTLM'
								) then score_real = ML_SCORE_P0;

	else if ext_business_name in (	'Equifax Risk Score - Direct CMC',
									'Equifax Risk Score - Direct CTLM',
									'Equifax Risk Score - Loans and Cards',
									'Equifax Risk Score Retail Auto Green',
									'Equifax Risk Score Retail E-COMM CTLM',
									'Equifax Risk Score V3 - Direct CMC',
									'Equifax Risk Score V3 - Direct CTLM',
									'Equifax Risk Score V3 - Retail Auto Green',
									'Equifax Risk Score V3 - Retail E-COMM CTLM'
								) then score_real = SCRPLUST1;
	;  
	if ext_business_name in (	'Equifax Risk Score V3 - Direct CMC',
								'Equifax Risk Score V3 - Direct CTLM',
								'Equifax Risk Score V3 - Retail Auto Green',
								'Equifax Risk Score V3 - Retail E-COMM CTLM') then risk_score_rf =scrplust1;

	if 		ext_business_name in ('Equifax Risk Score - Direct CMC', 'Equifax Risk Score V3 - Direct CMC') 					then rf_ext_business_name = 'Equifax Risk Score V3 - Direct CMC';
	else if ext_business_name in ('Equifax Risk Score - Direct CTLM', 'Equifax Risk Score V3 - Direct CTLM') 				then rf_ext_business_name = 'Equifax Risk Score V3 - Direct CTLM';
	else if ext_business_name in ('Equifax Risk Score Retail Auto Green', 'Equifax Risk Score V3 - Retail Auto Green') 		then rf_ext_business_name = 'Equifax Risk Score V3 - Retail Auto Green';
	else if ext_business_name in ('Equifax Risk Score Retail E-COMM CTLM', 'Equifax Risk Score V3 - Retail E-COMM CTLM') 	then rf_ext_business_name = 'Equifax Risk Score V3 - Retail E-COMM CTLM';

	if a_business_name in ('Score Distribution - Group 2 CTLM',
							'Score Cards Retail E-COMM CTLM',
							'Score Distribution 2013 - Group 1 CTLM'
						  )  and product_type_3 not in ('E-Commerce','TJ Ecommerce') then 
							do;
								score_RF = ML_SCORE_P0_RF;
								rf_business_name =  'A-Score DISTRIB Retail Traditional CTLM';
							end;
	else if a_business_name in ('Score Distribution - Group 2 CMC',
								'Score Cards Retail E-COMM CMC',
								'Score Distribution 2013 - Group 1 CMC'
						  )  then 
								do;
									score_RF = ML_SCORE_P0_RF;
									rf_business_name =  'A-Score DISTRIB Retail Traditional CMC';
								end;
	else if a_business_name in ('Score Distribution - Group 2 CTLM',
							'Score Cards Retail E-COMM CTLM',
							'Score Distribution 2013 - Group 1 CTLM'
						  )  and product_type_3 in ('E-Commerce','TJ Ecommerce') then 
							 do;
								score_RF = risk_score_rf; /*Falta datos RF Equifax*/
								rf_business_name =  'Equifax Risk Score V3 - Retail E-COMM CTLM';
							 end;
	else if a_business_name in ('Score Auto Moto CTLM') then
							do;
								score_RF = SCORE_REAL;
								rf_business_name =  a_business_name;
							end;
	else if a_business_name in ('ORANGE APPLICATION PERSONAL PORTFOLIO',
								'ORANGE APPLICATION PERSONAL JAZZTEL',
								'ORANGE APPLICATION NEW BUSINESS',
								'ORANGE APPLICATION PERSONAL PORTABILITY',
								'ORANGE APPLICATION BUSINESS') then
							do;
								score_RF = SCORE_REAL;
								rf_business_name =  a_business_name;
							end;
	else if a_business_name in ('A-Score DIRECT', 'A-Score DIRECT 2024') then
							do;
								if a_business_name = 'A-Score DIRECT' then score_RF = SCORE_CALC;
								else score_RF = SCORE_REAL;
								rf_business_name =  'A-Score DIRECT 2024';
							end;
	else if a_business_name in ('A-Score DIRECT XFR', 'A-Score DIRECT XFR 2024') then
							do;
								if a_business_name = 'A-Score DIRECT XFR' then score_RF = SCORE_CALC;
								else score_RF = SCORE_REAL;
								rf_business_name =  'A-Score DIRECT XFR 2024';
							end;
	else if a_business_name in  ('A-Score DISTRIB Retail Traditional CTLM') then 
							do;
								score_RF = ML_SCORE_P0;
								rf_business_name =  a_business_name;
							end;
	else if a_business_name in  ('A-Score DISTRIB Retail Traditional CMC') then 
							do;
								score_RF = ML_SCORE_P0;
								rf_business_name =  a_business_name;
							end;
	else if a_business_name in  ('A-Score DIRECT ML CMC') then 
							do;
								score_RF = ML_SCORE_P0;
								rf_business_name =  a_business_name;
							end;

	if ext_business_name in  ('Equifax Risk Score Retail E-COMM CTLM','Equifax Risk Score V3 - Retail E-COMM CTLM') then 
							do;
								score_RF = risk_score_rf;
								rf_business_name =  'Equifax Risk Score V3 - Retail E-COMM CTLM';
							end;
	else if ext_business_name in ('Equifax Risk Score - Direct CMC','Equifax Risk Score V3 - Direct CMC') then
							do;
								score_RF = ML_SCORE_P0_RF_CMC;
								rf_business_name =  'A-Score DIRECT ML CMC';;
							end;
	else if ext_business_name in ('Equifax Risk Score - Direct XFR') then
							do;
								if RED_NAME NE 'DIRECT' then 
									do;
										score_RF = SCRPLUST1;
										rf_business_name =  ext_business_name;
									end;
								else 
									do;
										if product_type_1 = 'Cards' then 
											do;
												score_RF = SCRPLUST1;
												rf_business_name =  ext_business_name;
											end;
										else 
											do;
												score_RF = SCORE_REAL;
												rf_business_name =  a_business_name;
											end;
									end;
							end;
/*risk level*/

	if SCRV_customer_Group_init in ('Inactive','New','') then	
		do;
			customer_type = 'New';
			ind_known = 0;
		end;
	else
		do;
			customer_type = 'Known';
			ind_known = 1;
		end;

	if SCRV_customer_Group_init in ('SCRV >=F','Singular') then	ind_known_Fmas = 1;
	else ind_known_Fmas = 0;

	risk_level = 'Not defined';

	If customer_type = 'Known' then		
		do;
			If SCRV_customer_Group_init in ('SCRV >=F','Singular') then risk_level = 'High';
			else if SCRV_customer_Group_init in ('SCRV D-E') then risk_level = 'Medium';
			else risk_level = 'Low';
		end;
	else if customer_type = 'New' then
		do;
			if rf_business_name in  ('Score Auto Moto CTLM') then 
				do;
					if		ZXSCORE IN ('3','2','1','0') then risk_level = 'High';
					else if	ZXSCORE IN ('4','5','6') then risk_level = 'Medium';
					else if ZXSCORE IN ('7','8') then risk_level = 'Low';
					else risk_level = 'Not defined';
				end;
			else if rf_business_name = 'A-Score DIRECT XFR 2024' then /*MIXED*/
				do; 
					*zxnota = score_RF; 
					if score_real <=383 then rl1 = 3;
					else if score_real <=405 then rl1 = 2;
					else if score_real <=10000 then rl1 = 1;

					if  	       	SCRPLUST1 <=    8 then rl2 = 1;
					else if    8 <  SCRPLUST1 <=    12 then rl2 = 2;
					else if    12 <  SCRPLUST1         then rl2 = 3;

					if max(rl1,rl2) = 1 then risk_level = 'Low';
					else if max(rl1,rl2) = 2 then risk_level = 'Medium';
					else if max(rl1,rl2) = 3 then risk_level = 'High';
				end;
			else if rf_business_name = 'A-Score DIRECT 2024' then /*MIXED*/
				do; 
					*zxnota = score_RF; 
					if score_RF <=376 then rl1 = 3;
					else if score_RF <=397 then rl1 = 2;
					else if score_RF <=10000 then rl1 = 1;

					if  	       	 risk_score_rf <=    12 then rl2 = 3;
					else if    12 <  risk_score_rf <=    66 then rl2 = 2;
					else if    66 <  risk_score_rf         then rl2 = 1;

					if max(rl1,rl2) = 1 then risk_level = 'Low';
					else if max(rl1,rl2) = 2 then risk_level = 'Medium';
					else if max(rl1,rl2) = 3 then risk_level = 'High';
				end;
			else if rf_business_name  = 'A-Score DISTRIB Retail Traditional CTLM' then
				do; 
					if       round(score_RF,0.0000001) le 0.9654058  then risk_level = 'High';
					else if  round(score_RF,0.0000001) le 0.9871413  then risk_level = 'Medium';
					else if  round(score_RF,0.0000001) le 1  		then risk_level = 'Low';
					else 												risk_level = 'Not defined';
				end;
			else if rf_business_name  = 'A-Score DIRECT ML CMC' then
				do; 
					if       round(score_RF,0.0000001) le 0.8273836  then	risk_level = 'High';
					else if  round(score_RF,0.0000001) le 0.9460228  then	risk_level = 'Medium';
					else if  round(score_RF,0.0000001) le 1  		 then	risk_level = 'Low';
					else 													risk_level = 'Not defined';
				end;
			else if rf_business_name in ('Equifax Risk Score - Direct XFR','Equifax Risk Score - Direct CMC','Equifax Risk Score V3 - Retail E-COMM CTLM') and red_name in ('DISTRI', 'DISTRIBUTION') then
				do; 
					if  				score_RF <=  12 		then risk_level = 'High';
					else if    12 <  	score_RF <=  66 		then risk_level = 'Medium';
					else if    66 <  	score_RF         		then risk_level = 'Low';
					else 										 	 risk_level = 'Not defined';
				end;
			else if rf_business_name in (	'ORANGE APPLICATION PERSONAL PORTFOLIO',
											'ORANGE APPLICATION PERSONAL JAZZTEL',
											'ORANGE APPLICATION NEW BUSINESS',
											'ORANGE APPLICATION PERSONAL PORTABILITY',
											'ORANGE APPLICATION BUSINESS') then
				do; 
					if  				F_DECILE_DEMAND <=  3 	then risk_level = 'Low';
					else if   3   <  	F_DECILE_DEMAND <=  7 	then risk_level = 'Medium';
					else if   7   <  	F_DECILE_DEMAND         then risk_level = 'High';
					else 											 risk_level = 'Not defined';
				end;
		end; 

	if risk_level = 'High' then ind_rl_high =1;
	else ind_rl_high =0;

run;
%sm_check_step(Retrofit and risk levels);
%sm_assert_rows(base=sm_tmp.sm_app_index, candidate=sm_tmp.demand_prf_char_RF);
