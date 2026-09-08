/* DATA-step statements: shared by finalization and fixture tests. */
	early_bad = 0;
	basel_bad = 0;

	if status_name = 'Booked' then 
		do;

			/*Early Risk Criteria*/
			if acct_booked_H6=1 then early_bad=ind_30ever_h6;
                else early_bad=.;
		
			/*Basel Criteria*/
			if acct_booked_H12=1 then basel_bad=basel_default_H12;
                else basel_bad=.;

			if f_model_id ='ESPF0001V00' then	
				do;

					MESES_FRAUDE = intck('month', mis_date, CLASIFICACION_DATE); 

					if PAGADO_EVITADO='PAGADO' and not missing(MESES_FRAUDE)
                        and 0 <= MESES_FRAUDE and MESES_FRAUDE <= 6 then fraude_pagado = 1;
					else fraude_pagado 	 = 0;

					fraude_pagado_ns 	 = max(fraude_pagado, ind_60ever_H3);

					control_group_flag = "N";
					if mod(fnact1,100) in (1,2,3,4,5,6,8,25,31)
					and DTRT ge '20230131'
					and status_name = 'Booked'
					and (
							(vendedor_cadena_top_name = 'PC Componentes' 	and ZFRAUDSCR ge 642747000000000) 
						or  (vendedor_cadena_top_name = 'Conforama' 		and ZFRAUDSCR ge 205399000000000)  
						or  (vendedor_cadena_top_name = 'Apple' 			and ZFRAUDSCR ge 1461354000000000)
						or  (vendedor_cadena_top_name = 'Apple APR' 		and ZFRAUDSCR ge 686977000000000) 
						)	then control_group_flag = "Y";

					red_zone="N";
					if 	(  
							(vendedor_cadena_top_name = 'PC Componentes' and ZFRAUDSCR ge 642747000000000) 
						or  (vendedor_cadena_top_name = 'Conforama' 	 and ZFRAUDSCR ge 205399000000000)  
						or  (vendedor_cadena_top_name = 'Apple' 		 and ZFRAUDSCR ge 1461354000000000)
						or  (vendedor_cadena_top_name = 'Apple APR' 	 and ZFRAUDSCR ge 686977000000000) 
						)	then red_zone = "Y";
				end;
		end;
	else 
		do;
			early_bad = 0;
			basel_bad = 0;
		end;

/* Explicit denominators: unbooked and unknown outcomes are not good accounts. */
    early_observed=(status_name='Booked' and not missing(early_bad));
    basel_observed=(status_name='Booked' and not missing(basel_bad));

/* Segment and materiality rules, preserving their original ordering. */
	if company = 'CMC' then vendedor_cadena_top_name ='Other';
	else if vendedor_cadena_top_name ='Others' then vendedor_cadena_top_name = 'Other';
	if company = 'CETELEM' then	do;

			segment_4 = product_type_3;
			segment_1 = product_type_1;

			if product_type_1 = 'Direct' then 
				do;
					if product_type_2 in ('Known', 'New/Inactive') then 
							do;
								segment_2 = 'Loan';
								if product_type_2 = 'New/Inactive' then segment_3 = 'Acquisition';
								else segment_3 = 'Known';

								if product_type_3 in ('Premium', 'Gold') then segment_4 = 'Premium/Gold';
								else segment_4 = product_type_3;
							end;
					else do;
							segment_2 = 'Consolidation';
							if product_type_3 in ('Premium','No Premium') then segment_3 = 'Known';
							else segment_3 = 'Acquisition';
							
							segment_4 = product_type_3;
						end;
				end;
			else if product_type_1 = 'Distribution' then 
				do;
					segment_2 = product_type_2;
					if product_type_3 = 'E-Commerce' then segment_3 = 'Digital';
					else segment_3 = 'No Digital';
				end;
			else if product_type_1 = 'Auto' then 
				do;
					segment_2 = product_type_2;
					if product_type_2 = 'Car' then 
						do;
							if product_type_3 in ('VO','VS') then segment_3 = 'VOVS';
							else segment_3 = product_type_3;
						end;
					else segment_3 = product_type_3;
				end;
	end;
	else do;
			segment_1 = product_type_1;
			segment_2 = product_type_2;
			segment_3 = product_type_3;
			segment_4 = '';
	end;

	if SE_Decision_id = 'KO' then 
		do; 
			if reject_reason = '09-SCORE' then materiality_cat = "Rules OK - Score KO";
			else if ko_score = 1 then materiality_cat = "Rules KO - Score KO";
			else if ko_score ne 1 then materiality_cat = "Rules KO - Score OK";		 
		end;
	else materiality_cat = "Rules OK - Score OK";

	if score_RF = . or (rf_business_name = ("Equifax Risk Score Retail E-COMM CTLM") and score_RF <1) then valid_score_RF=0;
	else valid_score_RF=1;

	if scrplust1 >0 then valid_efx = 1;
	else valid_efx=0;

	quarter = put(mis_date,yyq10.);
