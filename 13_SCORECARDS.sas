data sm_tmp.sm_scorecards_v(	drop =/*KFAMPLI KFRACGRADUAL KFRACNORMAL KFTJBNPP 
				KPREDELINQ KSAPPLE KSDENTAL KSEGMENTO KSVITALD KTJDIR
				WSTALLER*/ ZRECH__: ALERT_: RV_ALERT_: TIPOINST) / view=sm_tmp.sm_scorecards_v;
	length a_model_id a_perimeter_id ext_model_id ext_perimeter_id
           b_model_id b_perimeter_id f_model_id f_perimeter_id $16
           a_business_name ext_business_name b_business_name f_business_name
           car_type $100;
	set sm_tmp.demand_prf;

	if product_type_2 = 'Car' then
		do;
			if vendedor_cadena_name in ('HYUNDAI','JAECOO','JAGUAR','KIA','LAND ROVER','MG MOTOR','OMODA','POLESTAR','SMART','VOLVO') then car_type = 'Brands';
			else car_type = 'Green';
		end;

	if vendedor_cadena_top_name in ('Apple') then 
	do;
		if vendedor_grupo_id in (9234758, 9201807, 9234899)  then vendedor_cadena_top_name = 'Apple';
		else vendedor_cadena_top_name = 'Apple APR';
	end;
 
	IF CPRO IN ("MD","MDF","MDABS") THEN KPRODUCTO = "MD";                   
	ELSE IF CPRO IN ("DM","DMF","DMABS","DMI") THEN KPRODUCTO = "DM";     
	ELSE IF CPRO IN ("DR","DRF","DRABS") THEN KPRODUCTO = "DR";     
	ELSE IF CPRO IN ("BL","BLF") THEN KPRODUCTO = "BL";                                                                                  
	ELSE IF CPRO IN ("MC","MCF","MCI","MCG","MCM") THEN KPRODUCTO = "MC";         
	ELSE IF CPRO IN ("MM","MO","MOI","MOG","MMG","MMI","MOF","MOFG") THEN KPRODUCTO = "MM";          
 	ELSE IF CPRO IN ("PMG","PM","PMI","TFP","PM RR","F5","F10","F11","F12","F15","F20","OP12") THEN KPRODUCTO = "PM";          
    ELSE IF CPRO IN ("DP TPT","TJD","DP","TTU","TUI","TUG","XUI","XUG","TAP","XAP","G05","G10" ,"RF3","RF4","RF5","TPTG") 
					OR (FPAGO IN ("TPTI","BIC")) THEN KPRODUCTO = "DP";                                                                      
    ELSE IF CPRO IN ("XPF") THEN KPRODUCTO = "DP";
	ELSE KPRODUCTO=CPRO; 

	IF CPRO="PECG" AND  APLICA="WECOM" THEN KPOBLAC = "TUBE2";                                                              
                                            
  	IF CHAINE IN (9108994, 9111030, 9111048, 9111055, 9111063, 9111071) AND  KPRODUCTO = "PM" THEN KSAPPLE=1;
	ELSE KSAPPLE=0; 

	IF CSECTOR IN ("MED","PER","SEG") AND CAGENCE NE 144 AND CHAINE NE 9106758 AND KPRODUCTO IN ("PM","MM") THEN KSDENTAL=1;
	ELSE KSDENTAL = 0;

  	IF ((CSECTOR = "MED" AND  CAGENCE = 144) OR CHAINE = 9106758) AND  (KPRODUCTO = "PM" OR KPRODUCTO = "MM" OR KPRODUCTO = "TFP") THEN KSVITALD=1;    
	ELSE KSVITALD=0;  

  	IF KPRODUCTO = "PM" AND RED = 3 THEN WSTALLER = 1;
	ELSE WSTALLER=0; 
                                                         
	IF NUMVDR IN (2988913,2988863,2997419,2997575,2997633,2997641) AND CPRO IN ("RF" "DM") 		 THEN KPREDELINQ =1; 
	ELSE IF NUMVDR IN (2997435,2997443,2997583,2997591) AND CPRO IN ("RF","DM") 				 THEN KPREDELINQ =2;                                                             
	ELSE IF NUMVDR IN (2997450,2997468,2997476,2997492,2997609,2997625,2997617) AND CPRO = "RFI" THEN KPREDELINQ =3;                                        
	                                                                
  	IF CPRO = "RFI" AND NUMVDR IN (2997757, 2997765) AND KPREDELINQ = 0 THEN KFRACGRADUAL = 1;
	ELSE KFRACGRADUAL = 0; 
                                                                 
    IF CPRO IN ("RF","RFG") AND NUMVDR IN (1586122, 2980225, 2988269, 2980886, 2986917, 2997773, 2997807, 1396423, 2997815)                                  
    AND KPREDELINQ = 0 AND APLICA="WACC" THEN KFRACNORMAL = 1; 
  	                                                              
  	IF KFRACGRADUAL = 1 OR KFRACNORMAL = 1 THEN KSEGMENTO = "RAC";                                                                 
                                                                
	IF CPRO="DP" AND RED=2 AND APLICA="WACC" AND FPAGO="" AND KFAMPLI=0 THEN KTJDIR=1;      
    ELSE IF CPRO="DP" AND RED=2 AND APLICA="WETJO" AND FPAGO="" AND KFAMPLI=0 THEN KTJDIR=1; 
	ELSE  KTJDIR=0;  

	IF TIPOTRAN IN ("ACOM","RESA") THEN KFAMPLI=1;
	ELSE KFAMPLI = 0; 
                                                              
    IF RED=2 AND CPRO="WMC" AND APLICA="WACC" THEN KFTJBNPP = 1;
	ELSE KFTJBNPP = 0;

    if company = 'CETELEM' then
		do; 
			if zscraplica ne .  THEN
				do;
					if 		zscraplica = 48 THEN scorecard_id = zscraplica; /*'TUBE2;*/
					ELSE if zscraplica = 44 THEN scorecard_id = zscraplica; /*'SCORE DISTRIBUCION APPLE & ATIPICA';*/
					ELSE if zscraplica = 41 AND entry_Date ge '18may2022'd AND (ZRF1SCORE > 0 or zvers >= 20260219 ) THEN scorecard_id = 410; /*'SCORE DISTRIBUCION TRADICIONAL ML';*/
					ELSE if zscraplica = 41 THEN scorecard_id = zscraplica; /*'SCORE DISTRIBUCION TRADICIONAL';*/
					ELSE if zscraplica = 42 THEN scorecard_id = zscraplica; /*'SCORE DIRECT';*/
					ELSE if zscraplica = 45 THEN scorecard_id = zscraplica; /*'TARJETA DIRECT';*/
					ELSE if zscraplica = 46 THEN scorecard_id = zscraplica; /*'TARJETA';*/
					ELSE if zscraplica = 43 THEN scorecard_id = zscraplica; /*'AUTO Y MOTO';*/
					ELSE if zscraplica = 50 THEN scorecard_id = 48; 		/*'TUBE2';*/
				end;
			ELSE 
				do;
					if red=1 and entry_Date ge 20210801 and cagence in (410,411,412,413,414,415,416,428) AND KPOBLAC NE "TUBE2" 
					THEN scorecard_id = 48;	

					ELSE if KSAPPLE =1 OR KSDENTAL =1 OR KSVITALD=1 
					THEN scorecard_id = 44;

					ELSE if KSAPPLE = 0 AND  KSDENTAL = 0 AND  KSVITALD = 0 AND  
					(WSTALLER = 1 OR  ((KPRODUCTO = "PM" OR  KPRODUCTO = "MM") AND  RED = 1))                                                       
					THEN scorecard_id = 41;

		 			ELSE IF KPREDELINQ > 0 THEN scorecard_id = 42;

					ELSE IF KSEGMENTO = "RAC" THEN scorecard_id = 42;

					ELSE IF KPRODUCTO IN ('DM','DR','MD','BL') THEN scorecard_id = 42;	 

					ELSE IF KTJDIR =1 OR KFTJBNPP=1 THEN scorecard_id = 45;	 

					ELSE IF KPRODUCTO = "CP" OR  FPAGO = "RF3" OR  FPAGO = "RF4"                 
		            OR  FPAGO = "RF5" OR  KPRODUCTO = "DP"  OR  FPAGO = "G05"             
		            OR  FPAGO = "G10" OR  FPAGO = "TPTG"  OR  FPAGO = "TPTI"              
		 			THEN scorecard_id = 46;

					ELSE IF RED = 3 AND  (KPRODUCTO = "MC" OR                                     
		             CPRO = "MO" OR CPRO = "MOI" OR  CPRO = "MOG" OR  CPRO = "MOF" OR      
		             CPRO = "MOFG") THEN scorecard_id=43;                                                    
				end;

				if entry_Date le 20200401 and scorecard_id = 42 then scorecard_id = 420; /*'SCORE DIRECT old';*/
				if scorecard_id = 48 then ZXNOTA = SCRPLUST1;

		end;
	else if company = 'CMC' then 
		do;
			if red = 2 then 
				do;
					if entry_Date ge '30mar2023'd then	
						do;
							if ZXNOTA > 99999999 THEN scorecard_id = 510; /*SCORE ML DIRECT*/
							else scorecard_id = .;
						end;
					else scorecard_id = 51; /*SCORE EFX CAJAMAR*/
				end;
			else if red = 1 then
				do;
					if entry_Date ge '20oct2022'd  then 
						do;
							if ZXNOTA > 99999999 THEN scorecard_id = 410;
							else scorecard_id = .;
						end;
					else if product_type_1 in ('Distri','Distribution') then		
						do;
							if CSECTOR IN ('MED','PER','SEG') THEN scorecard_id = 41;
							ELSE IF CSECTOR NOT IN ('MED','PER','SEG') THEN scorecard_id = 44;
						end;
					else scorecard_id = 46;
				end;
		end;
	else  if company = 'XFR' then
		do;
			scorecard_id = zscraplica; 
		end;

	ENTITY_NAME = 'SPAIN';	

	/**MODELOS INTERNOS**/
	/**CETELEM**/
    if company = 'CETELEM' then
		do;
			if scorecard_id = 44 then 
				do;
					a_model_id = 'ESPA0001V00';
					a_perimeter_id = 'ESP00A0001';
					a_business_name = 'Score Distribution - Group 2 CTLM';
				end;
			else if scorecard_id = 43 then 
				do;
					a_model_id = 'ESPA0002V00';
					a_perimeter_id = 'ESP00A0002';
					a_business_name = 'Score Auto Moto CTLM';
				end;
			else if scorecard_id = 46 then 
				do;
					a_model_id = 'ESPA0003V00';
					a_perimeter_id = 'ESP00A0003';
					a_business_name = 'Score Cards Retail E-COMM CTLM';
				end;
			else if scorecard_id = 41 then 
				do;
					a_model_id = 'ESPA0004V00';
					a_perimeter_id = 'ESP00A0010';
					a_business_name = 'Score Distribution 2013 - Group 1 CTLM';
				end;
			else if scorecard_id IN (42,45,420) then 
				do;
					a_model_id = 'ESPA0008V00';
					a_perimeter_id = 'ESP00A0013';
					a_business_name = 'A-Score DIRECT';
					if zvers ge 20240430 then
						do;
							a_model_id = 'ESPA0012V00';
							a_perimeter_id = 'ESP00A0013';
							a_business_name = 'A-Score DIRECT 2024';
							scorecard_id = 421;
						end;
				end;
			else if scorecard_id = 410 then 
				do;
					a_model_id = 'ESPA0010V00';
					a_perimeter_id = 'ESP00A0011';
					a_business_name = 'A-Score DISTRIB Retail Traditional CTLM';
				end;

			if scorecard_id IN (42,45,420,421) AND SCRPLUST1 >= 0 then 
				do;
					if zvers < 20250430 AND SCRPLUST1 > 0 then 
						do;
							ext_model_id = 'ESPA0006V00';
							ext_perimeter_id = 'ESP00A0013';
							ext_business_name = 'Equifax Risk Score - Direct CTLM';
						end;
					else
						do;
							ext_model_id = 'ESPB0003V00';
							ext_perimeter_id = 'ESP00A0013';
							ext_business_name = 'Equifax Risk Score V3 - Direct CTLM';
						end;
				end;
			else if red=3 and (product_type_2 = 'Car' and vendedor_cadena_name not in ('HYUNDAI','JAECOO','JAGUAR','KIA','LAND ROVER','MG MOTOR','OMODA','POLESTAR','SMART','VOLVO')) or (product_type_2 = 'Moto' or product_type_3 = 'Microcar') AND SCRPLUST1 >= 0 then 
				do;
					if zvers < 20250516 AND SCRPLUST1 > 0 then
						do;
							ext_model_id = 'ESPA0006V00';
							ext_perimeter_id = 'ESP00A0020';
							ext_business_name = 'Equifax Risk Score Retail Auto Green';
						end;
					else
						do;
							ext_model_id = 'ESPB0003V00';
							ext_perimeter_id = 'ESP00A0020';
							ext_business_name = 'Equifax Risk Score V3 - Retail Auto Green';
						end;
				end;
			else if scorecard_id = 48  AND SCRPLUST1 >= 0 then 
				do;
					if zvers < 20250505 AND SCRPLUST1 > 0 then
						do;
							ext_model_id = 'ESPA0006V00';
							ext_perimeter_id = 'ESP00A0007';
							ext_business_name = 'Equifax Risk Score Retail E-COMM CTLM';
						end;
					else
						do;
							ext_model_id = 'ESPB0003V00';
							ext_perimeter_id = 'ESP00A0007';
							ext_business_name = 'Equifax Risk Score V3 - Retail E-COMM CTLM';
						end;
				end;
			if nota ne . then 
				do;
					b_model_id = 'ESPB0001V00';
					b_perimeter_id = 'ESP00A0018';
					b_business_name = 'SQE used for granting CTLM';
				end;
			if entry_Date ge '31jan2023'd and ZFRAUDSCR >0 then 
				do;
					f_model_id ='ESPF0001V00';
					f_perimeter_id ='ESP01F0001';
					f_business_name ='Fraud score Spain distribution Cetelem'; 
				end;
		end;

    else if company = 'CMC' then
		do;
			if scorecard_id = 44 then 
				do;
					a_model_id = 'ESPA0001V00';
					a_perimeter_id = 'ESP00A0108';
					a_business_name = 'Score Distribution - Group 2 CMC';
				end;
			else if scorecard_id = 46 then 
				do;
					a_model_id = 'ESPA0003V00';
					a_perimeter_id = 'ESP00A0109';
					a_business_name = 'Score Cards Retail E-COMM CMC';
				end;
			else if scorecard_id = 41 then 
				do;
					a_model_id = 'ESPA0004V00';
					a_perimeter_id = 'ESP00A0110';
					a_business_name = 'Score Distribution 2013 - Group 1 CMC';
				end;
			else if scorecard_id = 410 then 
				do;
					a_model_id = 'ESPA0010V00';
					a_perimeter_id = 'ESP00A0017';
					a_business_name = 'A-Score DISTRIB Retail Traditional CMC';
				end;
			else if scorecard_id = 510 then 
				do;
					a_model_id = 'ESPA0011V00';
					a_perimeter_id = 'ESP00A0012';
					a_business_name = 'A-Score DIRECT ML CMC';
				end;

			if scorecard_id IN (42,45,420,51) AND SCRPLUST1 > 0 then 
				do;
					ext_model_id = 'ESPA0006V00';
					ext_perimeter_id = 'ESP00A0012';
					ext_business_name = 'Equifax Risk Score - Direct CMC';
				end;
			else if scorecard_id = 510 AND SCRPLUST1 >= 0 and zvers >= 20250423 then 
				do;
					ext_model_id = 'ESPB0003V00';
					ext_perimeter_id = 'ESP00A0012';
					ext_business_name = 'Equifax Risk Score V3 - Direct CMC';
				end;
			else if scorecard_id = 510 AND product_type_2 = 'New/Inactive' AND SCRPLUST1 > 0 and (zvers < 20250423 or zvers = .)then 
				do;
					ext_model_id = 'ESPA0006V0';
					ext_perimeter_id = 'ESP00A0012';
					ext_business_name = 'Equifax Risk Score - Direct CMC';
				end;

			else if scorecard_id = 48 then 
				do;
					if zvers >= 20250423 and zvers ne . then 
						do;
							ext_model_id = 'ESPB0003V00';
							ext_perimeter_id = 'ESP00A0107';
							ext_business_name = 'Equifax Risk Score V3 - Retail E-COMM CMC';
						end;
					else 
						do;
							ext_model_id = 'ESPA0006V00';
							ext_perimeter_id = 'ESP00A0107';
							ext_business_name = 'Equifax Risk Score Retail E-COMM CMC';
						end;
				end;

			if nota ne . then 
				do;
					b_model_id = 'ESPB0001V00';
					b_perimeter_id = 'ESP00A0019';
					b_business_name = 'SQE used for granting CMC';
				end;
		end;
   else if company = 'XFR' then
		do;
			if scorecard_id IN (42,45,420) and product_type_1 = 'Direct' then 
				do;
					a_model_id = 'ESPA0008V00';
					a_perimeter_id = 'ESP00A0016';
					a_business_name = 'A-Score DIRECT XFR';
					if zvers ge 20240614 then
						do;
							a_model_id = 'ESPA0012V00';
							a_perimeter_id = 'ESP00A0016';
							a_business_name = 'A-Score DIRECT XFR 2024';
							scorecard_id = 421;
						end;
				end;

			if  SCRPLUST1 > 0 then
				do;
					if red=2 or (red=1 and product_type_1 = 'Cards') then 
						do;
							ext_model_id = 'ESPA0006V00';
							ext_perimeter_id = 'ESP00A0015';
							ext_business_name = 'Equifax Risk Score - Loans and Cards';
						end;
				end;
		end;
	else if company = 'OSP' then
		do;
			if scorecard_id = 17 THEN 
				DO;
					a_model_id = 'ESPA0015V00';
					a_perimeter_id = 'ESP00A0023';
					a_business_name = 'ORANGE APPLICATION PERSONAL PORTFOLIO';
				END;
			else if scorecard_id =  90 THEN
				DO;
					a_model_id = 'ESPA0013V00';
					a_perimeter_id = 'ESP00A0021';
					a_business_name = 'ORANGE APPLICATION PERSONAL JAZZTEL';					
				END;
			else if scorecard_id =  5 THEN
				DO;
					if mis_date < '01apr2025'd then 
						do;
							a_model_id = 'ESPA0017V00';
							a_perimeter_id = 'ESP00A0025';
							a_business_name = 'ORANGE APPLICATION NEW BUSINESS';
						end;
					else 
						do;
							a_model_id = 'ESPA0021V00';
							a_perimeter_id = 'ESP00A0025';
							a_business_name = 'ORANGE APPLICATION NEW BUSINESS';
						end;
						
				END;
			else if scorecard_id =  96 THEN
				DO;
					a_model_id = 'ESPA0014V00';
					a_perimeter_id = 'ESP00A0022';
					a_business_name = 'ORANGE APPLICATION PERSONAL PORTABILITY';					
				END;
			else if scorecard_id =  97 THEN
				DO;
					a_model_id = 'ESPA0016V00';
					a_perimeter_id = 'ESP00A0024';
					a_business_name = 'ORANGE APPLICATION BUSINESS';					
				END;
			else if scorecard_id =  1 THEN
				DO;
					a_model_id = 'ESPA0020V00';
					a_perimeter_id = 'ESP00A0028';
					a_business_name = 'MASMOVIL NEW CUSTOMERS';					
				END;
			else if scorecard_id =  2 THEN
				DO;
					a_model_id = 'ESPA0018V00';
					a_perimeter_id = 'ESP00A0026';
					a_business_name = 'YOIGO';					
				END;
			else if scorecard_id =  3 THEN
				DO;
					a_model_id = 'ESPA0019V00';
					a_perimeter_id = 'ESP00A0027';
					a_business_name = 'MAS MOVIL';					
				END;
		end;
run;
