data sm_tmp.sm_characteristics_v / view=sm_tmp.sm_characteristics_v;
	length CHAR_1-CHAR_9 B_CHAR_1-B_CHAR_9 $64
           DES_CHAR_1-DES_CHAR_9 B_DES_CHAR_1-B_DES_CHAR_9 $160 KSAUTO $16;
	format CHAR_1-CHAR_9 B_CHAR_1-B_CHAR_9 $64.
           DES_CHAR_1-DES_CHAR_9 B_DES_CHAR_1-B_DES_CHAR_9 $160. KSAUTO $16.;
	format DTRT_date FCHTEMP_DATE yymmddn8.;
	FORMAT DATE_PSENIO DDMMYY10.;
	LENGTH channel_type $11.; 
	set sm_tmp.sm_scorecards_v;

	DTRT_date = input(put(DTRT, 8.), yymmdd8.);
	DATE_PSENIO = MDY(MENTPRFT,1,ANCPROF);
	FCHTEMP_DATE = input(put(FCHTEMP, 8.), yymmdd8.);
	

	/*KFCARTE*/
	IF KPRODUCTO IN ("CP","DP","XP","MP","WMC") THEN KFCARTE=1; 
	ELSE KFCARTE=0;

	/*WDURDEG*/
	IF DAY(DTRT_date) <=22 AND KFCARTE=0 THEN WDURDEG=DURDEG;
	ELSE IF DAY(DTRT_date) >22 AND KFCARTE=0 THEN WDURDEG=DURDEG+1;
	ELSE WDURDEG=0;

	/*KFFINCRE*/
	format KFFINCRE yymmddn8.;
	KFFINCRE = INTNX('month', DTRT_date,WDURDEG);

	/*KEDADFCRE1*/

	format FNACT1_date yymmddn8.;
	FNACT1_date = input(put(FNACT1, 8.), yymmdd8.);

	IF KFFINCRE NE . AND FNACT1_date NE . THEN age = INTCK('YEAR',FNACT1_date,KFFINCRE,'c');
	ELSE KEDADFCRE1=0;

	/*KEDAD1*/

	IF KFFINCRE NE . AND FNACT1_date NE . and DTRT_date ne . THEN KEDAD1 = INTCK('YEAR',FNACT1_date,DTRT_date,'c');
	ELSE KEDAD1=0;

	/*KEDADFCRE2*/

	format FNACT2_date yymmddn8.;
	FNACT2_date = input(put(FNACT2, 8.), yymmdd8.);

	IF KFFINCRE NE . AND FNACT2_date NE . THEN KEDADFCRE2 = INTCK('YEAR',KFFINCRE,FNACT2_date,'c');
	ELSE KEDADFCRE2=0;

	/*KPENS*/
	                                                              
 	IF CSP IN ("90","91","95")  THEN KPENS1   = 1;
	ELSE KPENS1 =0;

	IF CSP2 IN ("90","91","95")  THEN KPENS2   = 1;
	ELSE KPENS2 =0;

	/*KMSAL1CL*/
	IF KPENS1 = 0 AND KEDADFCRE1 >=66 THEN KMSAL1CL=INT(MSAL1*90/100);
	ELSE KMSAL1CL=MSAL1;

	/*KMSAL2CL*/
	IF KPENS2 = 0 AND KEDADFCRE2 >=66 THEN KMSAL2CL=INT(MSAL2*90/100);
	ELSE KMSAL2CL=MSAL2;

	IF CSP IN ('82','83','84') or SITFAM IN (2,7) or scorecard_id = 43 THEN WINGRES = SUM(KMSAL1CL,KMSAL2CL,0);
	ELSE WINGRES = KMSAL1CL;

	/*KANTPF1*/
	IF ANCPROF = 9999 THEN KANTPF1 = 0;
	ELSE IF ANCPROF = 0 THEN KANTPF1 = 0;
	ELSE IF SUBSTR(DTRT,1,4)*1 >= ANCPROF*1 THEN KANTPF1 = (SUBSTR(DTRT,1,4)*1-ANCPROF*1);
	ELSE KANTPF1=0;

	IF ANCBQ = 9999 THEN KANTBCO = 0;
	ELSE IF ANCBQ = 0 THEN KANTBCO = 0;
	ELSE IF SUBSTR(DTRT,1,4)*1 >= ANCBQ*1 THEN KANTBCO = (SUBSTR(DTRT,1,4)*1-ANCBQ*1);
	ELSE KANTBCO=0;

	IF ANCHAB = 9999 THEN KANTRESI1 = 0;
	ELSE IF ANCHAB = 0 THEN KANTRESI1 = 0;
	ELSE IF SUBSTR(DTRT,1,4)*1 >= ANCHAB*1 THEN KANTRESI1 = (SUBSTR(DTRT,1,4)*1-ANCHAB*1);
	ELSE KANTRESI1=0;

	/*KMSAL1TJ*/
	IF KPENS1 = 0 AND KEDAD1 >=60 THEN KMSAL1TJ=INT(MSAL1*90/100);
	ELSE KMSAL1TJ=MSAL1;

	IF KFCARTE = 1 THEN KMENSCENT = MENSTJ;
	ELSE IF KFCARTE = 0 THEN KMENSCENT = MENSCENT;
                        
	if scorecard_id in (42,45,420,421) then 
	do;
		IF RVIVOACT IN ("A","B","C","D","E","F","G","H","I","J","K","R","X","W","4","Q") THEN customer_type='Known';
		ELSE IF RVIVOACT IN ("Y","Z","5","7") THEN customer_type='Inactive';
		ELSE IF RVIVOACT IN (" ","","1","2","6","8")then customer_type='New';
		else customer_type='ERROR';

		if company ne 'XFR' then 
			do;
				/*IF (CHAINE IN (9102179) OR NUMVDR in (1984590,2986420,2996999) OR CAGENCE in (425,486)) AND (CHAINE NOT IN (9103888,9102153)) 
				THEN channel_type = 'On-Line';
				ELSE channel_type = 'Off-Line';*/
				%score_direct_2024;
			end;
		else if company = 'XFR'	then
			do;
				/*IF CHAINE = 9110727 THEN channel_type = 'On-Line';
				ELSE channel_type = 'Off-Line';*/
				%score_direct_XFR_2024;
			end;
		*decile = input(put(zxnota, decile_score_42_.), best.);
	end;

	else if scorecard_id = 43 then 
	do;

		KIMPCONT = MOPCENT;
		KIMPFIN  = MDECCENT;
		KIMPENT = INT(100*(KIMPCONT-KIMPFIN)/KIMPCONT);

		IF RED=3 AND CMAT IN ("501","502","507","514","518","544") then KSAUTO='COCHE_NUEVO';
		ELSE IF RED=3 AND CMAT IN ("510","516","519","531","611","503") then KSAUTO='COCHE_SEMINUEVO';
		ELSE IF RED=3 AND CMAT IN ("511" "512" "513" "517" "525" "550") then KSAUTO='COCHE_OCASION';
		ELSE IF RED=3 AND CMAT IN ("451" "453" "500" "530" "452" "535" "515" "541" "509" "465" "560" "520") then KSAUTO='MOTO';
		ELSE IF RED=3 AND CMAT IN ("504" "505" "546" "542" "543" "545" "506" "540" "547" "521" "522" "523") then KSAUTO='OTROS';
		ELSE KSAUTO='NO AUTO';

		%score_automoto;
		*decile = input(put(zxnota, decile_score_43_.), best.);
	end;
	else if scorecard_id = 44 then
	do;
		KIMPCONT = MOPCENT;
		KIMPFIN  = MDECCENT;
		KIMPENT = INT(1000*(KIMPCONT-KIMPFIN)/KIMPCONT);

		IF ANCBQ = 9999 THEN KANTBCO = 0;
		ELSE IF ANCBQ = 0 THEN KANTBCO = 0;
		ELSE IF SUBSTR(DTRT,1,4)*1 >= ANCBQ*1 THEN KANTBCO = (SUBSTR(DTRT,1,4)*1-ANCBQ*1);
		ELSE KANTBCO=0;

		WDECREV = 0;
		IF WINGRES <= 0 THEN WDECREV=9999;
		ELSE WDECREV = 1000*MDECCENT/WINGRES;

		%score_distrib2;
		*decile = input(put(zxnota, decile_score_44_.), best.);

	end;
	else if scorecard_id = 41 then
	do;
		IF CMAT IN ("461","462","463","464","469","460") THEN WGRCMAT = 1;
		ELSE IF CMAT IN ("300","342","343","344","345","349","340","351","353","354","355","359","350" ,"330") THEN WGRCMAT = 2;
		ELSE IF CMAT IN ("390","450","470","492","491","494","499","710") THEN WGRCMAT = 2;
		ELSE WGRCMAT = 3;
	
		IF KMSAL1CL > 0 THEN WRIMPREV = int((100*MDECCENT / KMSAL1CL));
		ELSE WRIMPREV = 9999;

		KIMPENT = int(100*(KIMPCONT-KIMPFIN+(KIMPCONT/200)) / KIMPCONT);

		%score_distrib1;
		*decile = input(put(zxnota, decile_score_41_.), best.);
	end;
	else if scorecard_id = 46 then
	do;
		KCODPT1 = INT(CPTLT1/1000);
		%score_cards;
		*decile = input(put(zxnota, decile_score_46_.), best.);
	end;
	else if scorecard_id = 48 then
	do;
		ZXNOTA = SCRPLUST1;
	end;
	else if scorecard_id = 410 then
	do;
			/*AGE*/
			FNACT1_date = input(put(FNACT1, 8.), yymmdd8.);
			V410_AGE = INTCK('YEAR',FNACT1_date,DECISION_DATE,'c');

			/*PRO_SENIO*/
			PRO_SENIO = ROUND((ENTRY_DATE-DATE_PSENIO)/(365.25/12));
			IF DATE_PSENIO IN (.,0) OR MENTPRFT IN (.,0) THEN V410_PRO_SENIO = 78;
			ELSE IF (PRO_SENIO/12) > V410_AGE THEN V410_PRO_SENIO = 78;
			ELSE V410_PRO_SENIO = PRO_SENIO;

			/*HAB_SENIO*/
			HAB_SENIO = YEAR(DECISION_DATE) - ANCHAB;
			IF HAB_SENIO > V410_AGE OR HAB_SENIO = . THEN V410_HAB_SENIO = 13;
			ELSE V410_HAB_SENIO = HAB_SENIO;

			/*TIME_CONTRACT*/
			TIME_CONTRACT = INTCK('MONTH',ENTRY_DATE, FCHTEMP_DATE,'C');
			IF TIME_CONTRACT/12 > 80 OR TIME_CONTRACT = . OR TIME_CONTRACT <0 THEN TIME_CONTRACT = 9;

			IF TEMPORAL = 'E' THEN  V410_TIME_CONTRACT = TIME_CONTRACT;
			ELSE IF TEMPORAL = 'F' THEN V410_TIME_CONTRACT = 999999999;
			ELSE IF TEMPORAL = 'X' THEN V410_TIME_CONTRACT = 9999;
			ELSE IF TEMPORAL ='' THEN V410_TIME_CONTRACT = -1;

			/*SALARY*/
			IF MSAL1/100 = . THEN V410_SALARY = 1313.77;
			ELSE V410_SALARY = MSAL1/100;

			/*NBENF*/
			IF NBENF = . OR NBENF < 0 THEN V410_NBENF = 0;
			ELSE V410_NBENF = NBENF;

			/*TOT_OUST*/
			V410_TOT_OUST = MAX(0,TODUMR1/100);

			/*NB_L*/
			V410_NB_L = MAX(0,NDOSCLMR);

			/*NB_C*/
			V410_NB_C = MAX(0,NDOSCAMR);

			/*nb_appro30_l*/
			V410_nb_appro30_l = MAX(0,NOP30CL1);

			/*nb_appro30_c*/
			V410_nb_appro30_c = MAX(0,NOP30TJ1);

			/*SITHAB*/
			LENGTH V410_SITHAB $ 10.;
			V410_SITHAB = put(sithab, $1.);
			if SITHAB = .  THEN V410_SITHAB = 'MISSING';

			/*SITFAM*/
			LENGTH V410_SITFAM $ 10.;
			V410_SITFAM = put(SITFAM, $1.);
			if SITFAM = . or sitfam not in (1,2,3,4,7) THEN V410_SITFAM = 'MISSING';

			/*CSP*/	
			LENGTH V410_CSP $ 10.;
			IF compress(CSP) IN ('92','40','01','91','61','15','74') then V410_CSP = 'rare+';
			else if compress(CSP) IN ('84', '83', '82', '81', '73', '25', '') then V410_CSP = 'rare-';
			else V410_CSP = compress(CSP);

			/*CODRAMA*/	
			LENGTH V410_CODRAMA $ 10.;
			IF CSP IN ('90','95') THEN  V410_CODRAMA = '0';
			ELSE IF compress(CODRAMA) IN (19, 38, 30, 40, 39, 22, 31) then V410_CODRAMA = 'rare+';
			else if compress(CODRAMA) IN (26,41,34,37,25,17,16,11,14,23,32,33,35,42,.) then V410_CODRAMA = 'rare-';	
			else V410_CODRAMA = compress(CODRAMA);
			end;
	else if scorecard_id = 510 then
		do;
			/*EDAD*/
			AGE = INTCK('YEAR',FNACT1_date,DTRT_date);
			IF AGE=. THEN V510_AGE = 45;
			ELSE V510_AGE = AGE;

			/*PRO_SENIO*/
			PRO_SENIO = INTCK('MONTH',DATE_PSENIO,DTRT_date);

			IF YEAR(PRO_SENIO) LE 1900 OR YEAR(PRO_SENIO) GT 2262 OR MENTPRFT > 12 or MENTPRFT < 1 THEN V510_PRO_SENIO = 42;
			ELSE IF (PRO_SENIO/12) > V510_AGE THEN V510_PRO_SENIO = 42;
			ELSE IF PRO_SENIO < 0 THEN V510_PRO_SENIO = 42;
			ELSE V510_PRO_SENIO = PRO_SENIO;

			/*TOT_OUST*/
			if TODUMR1 = . then V510_TOT_OUST=0;
			else V510_TOT_OUST = TODUMR1/100;

			/*NB_L*/

			if NDOSCLMR = . then V510_NB_L=0;
			else V510_NB_L = NDOSCLMR;

			/*BCC_NRE6CBC1*/
			if NRE6CBC1 = . then V510_NRE6CBC1=20;
			else V510_NRE6CBC1 = NRE6CBC1;

			/*BCC_TPVBC1*/
			if TPVBC1 = . then V510_TPVBC1=333.71;
			else V510_TPVBC1 = TPVBC1/100;

			/*BCC_TPV6BC1*/
			if TPV6BC1 = . then V510_TPV6BC1=333.71;
			else V510_TPV6BC1 = TPV6BC1/100;

			/*BCC_SENIO*/

			ANCLIBC1_date = input(put(ANCLIBC1, 8.), yymmdd8.);

			BCC_senio = INTCK('month',ANCLIBC1_date,DTRT_date);

			if BCC_senio = . then V510_BCC_SENIO = 176;
			else if BCC_senio/12 > age then V510_BCC_SENIO = 176;
			else V510_BCC_SENIO = BCC_senio;

			/*BCC_RE6CBC1*/
			if RE6CBC1  = . then V510_RE6CBC1 =1513.73;
			else V510_RE6CBC1  = RE6CBC1 /100;

			/*BCC_NRD6BC1*/
			if NRD6BC1  = . then V510_NRD6BC1 = 0;
			else V510_NRD6BC1  = NRD6BC1;

			/*BCC_ONM6BC1*/
			if ONM6BC1  = . then V510_ONM6BC1 = 327.925;
			else V510_ONM6BC1  = ONM6BC1/100;

			/*BCC_MNMBC1 */
			if MNMBC1   = . then V510_MNMBC1  = 782.415;
			else V510_MNMBC1  = MNMBC1 /100;

			/*BCC_NDES6BC1 */
			if NDES6BC1   = . then V510_NDES6BC1  = 0;
			else V510_NDES6BC1  = NDES6BC1;
	
			/*BCC_ONMBC1 */
			if ONMBC1   = . then V510_ONMBC1  = 0;
			else V510_ONMBC1  = ONMBC1;

			/*BCC_paysit  */
			if SIPABC1 NOT IN (0,1)   = . then V510_paysit   = 1;
			else V510_paysit   = SIPABC1 ;

			/*sithab 1*/
			V510_SITHAB_1 =sithab;

			/*SITFAM 1*/
			V510_SITFAM_1 =SITFAM;
			
			/*CSP_RARE_PLUS*/
			IF compress(CSP) IN ('15', '35', '1','01','45', '10', '31', '70', '72', '61', '30', '41', '25', '92', '91', '40', '75') THEN V510_CSP = 'rare+';
			else V510_CSP = CSP; 
		end;
	if f_business_name ='Fraud score Spain distribution Cetelem' then
		do;
			length F_VAR_SITHAB_2 F_VAR_SITFAM F_VAR_PARTNER F_VAR_SECTOR F_VAR_CAGENCE_GRP F_VAR_CPTLT1_GRP $ 20;

			/*SITHAB*/
			
			length F_VAR_SITHAB_2 $ 20;

			IF SITHAB = 1 	   THEN F_VAR_SITHAB_2 = 'owner';
			ELSE IF SITHAB = 2 THEN F_VAR_SITHAB_2 = 'family';
			ELSE IF SITHAB = 3 THEN F_VAR_SITHAB_2 = 'rent';
			ELSE IF SITHAB = 4 THEN F_VAR_SITHAB_2 = 'company';

			/*ANCHAB*/	
			IF ANCHAB NE . THEN F_VAR_ANC_HAB = YEAR(DTRT_date) - ANCHAB;
			ELSE F_VAR_ANC_HAB = -999999999;

			/*SITFAM*/

			if sitfam = 1 then F_VAR_SITFAM = "single";
			else if sitfam = 2 then F_VAR_SITFAM = "married";
			else if sitfam = 3 then F_VAR_SITFAM = "widow";
			else if sitfam = 4 then F_VAR_SITFAM = "divorced";
			else if sitfam = 7 then F_VAR_SITFAM = "concubine";

			/*NBENF*/

			IF NBENF NE . THEN F_VAR_NBENF = NBENF;
			ELSE F_VAR_NBENF = -999999999;

			/*MSAL1*/			
			IF MSAL1 NE . THEN F_VAR_MASAL1_EURO = MSAL1/100;
			ELSE F_VAR_MASAL1_EURO = -999999999;

			/*DURDEG*/
			F_VAR_DURDEG = DURDEG;

			/*NOP30CL1*/
			F_VAR_NOP30CL1 = NOP30CL1;

			/*TODUMR1*/
			F_VAR_TODUMR1 = TODUMR1;

			/*PURCH AMT*/			
			if product_type_1="Cards" then F_VAR_purch_amt=CRUTACR/100;
			else F_VAR_purch_amt = MOPCENT/100;

			/*total_mt*/
			if product_type_1="Cards" then F_VAR_total_amt=CMATACR/100;
			else F_VAR_total_amt = MOPCENT/100;

			/*AGE*/
	     	F_VAR_AGE = INTCK('YEAR',FNACT1_date,DTRT_date);

			/*ANCPROF*/

			IF ANCPROF = . OR MENTPRFT = . THEN F_VAR_ANC_PROF = -999999999;
			ELSE IF ANCPROF LT 1900 OR ANCPROF GT 2100 THEN F_VAR_ANC_PROF = -999999999;
			ELSE F_VAR_ANC_PROF = ROUND((DTRT_date-DATE_PSENIO)/30.436875);

			/*MENS*/
			if product_type_1="Cards" then F_VAR_MENS=MENSTJ/100;
			else F_VAR_MENS = MENSCENT/100;

			/*VENDEDOR_CADENA_TOP_NAME*/
			if product_type_3 = "MED-Dental" then F_VAR_PARTNER = 'MED-Dental';
			else if vendedor_cadena_top_name = 'Apple' then F_VAR_PARTNER = 'Apple';
			else if vendedor_cadena_top_name = 'PC Componentes' then F_VAR_PARTNER = 'PC Componentes';
			else if vendedor_cadena_top_name = 'Conforama' then F_VAR_PARTNER = 'Conforama';
			else if vendedor_cadena_top_name = 'Macnificos' then F_VAR_PARTNER = 'Macnificos';
			else F_VAR_PARTNER = 'Other';

			/*CSECTOR*/
			F_VAR_csector = csector;

			/*CPRO*/
			F_VAR_CPRO = CPRO;

			/*EST1_1, EST1_2*/
			F_VAR_ESTT1_1=ESTCLI1;
			F_VAR_ESTT1_2=ESTCLI2;

			/*SECTOR*/
			if csp in (96,82,83,84) then F_VAR_SECTOR = "unemployed";
			else if csp in (95,90,91) then F_VAR_SECTOR = "retired";
			else if csp = 32 then F_VAR_SECTOR = "travel";
			else if scpr in (29,10) then F_VAR_SECTOR = "logistic";
			else if scpr in (14) then F_VAR_SECTOR = "realestate";
			else if scpr in (22,23) then F_VAR_SECTOR = "professionalservices";
			else if scpr in (1,26,16,38) then F_VAR_SECTOR = "financialservices";
			else if csp = 13 then F_VAR_SECTOR = "publicF_VAR_SECTOR";	
			else if csp = 2 then F_VAR_SECTOR = "healthF_VAR_SECTOR";	
			else if csp = 20 then F_VAR_SECTOR = "otherservices";	
			else if csp in (24,21,28,39,40,41) then F_VAR_SECTOR = "industry";
			else if csp in (8,37) then F_VAR_SECTOR = "hostelry";
			else if csp = 3 then F_VAR_SECTOR = "education";	
			else if csp in (6,36) then F_VAR_SECTOR = "building";
			else if scpr in (27,25,31,17,19,35,42,11) then F_VAR_SECTOR = "trade";
			else if csp in (30,34) then F_VAR_SECTOR = "associationsandorganizations";
			else if csp in (12,33) then F_VAR_SECTOR = "husbandry";
			else F_VAR_SECTOR = 'MISSING';

			/*channel*/
			if product_type_3 in ('E-Commerce','TJ Ecommerce') then F_VAR_e_com = 'True';
			else F_VAR_e_com = 'False';

			/*client*/

			if RVIVOACT ne "" then F_VAR_known = 'True';
			else F_VAR_known = 'False';

			/*postal code*/

			if CPTLT1 > 999 then F_VAR_CPTLT1_GRP = compress(put(CPTLT1/1000,$2.));
			else F_VAR_CPTLT1_GRP = 'MISSING';

			/*CAGENCE_GRP*/

			if CAGENCE in(410,411,412,413,414,415,416) then F_VAR_CAGENCE_GRP = "ecommerce";
			else if  CAGENCE in(428) then F_VAR_CAGENCE_GRP = "pureplayer";
			else F_VAR_CAGENCE_GRP = "store";

		end;

	if b_model_id = 'ESPB0001V00' then 
		do;
			%sque_granting;
		end;

	if company = 'OSP' then 
		do;
			%scan_CH(MONTHS_PORTABILITY_NUM, meses_ultima_porta, '#', 'min', 4.);

			IF  SCORECARD_ID = 17 THEN 
				DO;
					%sc_portfolio_orange;
				END;
			ELSE IF SCORECARD_ID = 90 THEN 
				DO;
					%sc_portfolio_jazztel;
				END; 
			ELSE IF SCORECARD_ID = 5 THEN
				DO;
					IF MODEL_ID = 'ESPA0017V00' THEN
						DO;
							%sc_cliente_nuevo_empresa_orange;
						END;
					ELSE 
						DO;
							%sc_cl_nuevo_empresa_orange_d4b;
						END;
				END;
			ELSE IF SCORECARD_ID = 96 THEN
				DO;
					%sc_cliente_nuevo_pf_orange;
				END;
			ELSE IF SCORECARD_ID = 97 THEN
				DO;
					%sc_portfolio_pj_orange;
				END;
			ELSE IF SCORECARD_ID = 3 THEN
				DO;
					%MAS_MOVIL;
				END;
			ELSE IF SCORECARD_ID = 2 THEN
				DO;
					%YOIGO;
				END;
		end;

	score=sum(of val_char_:);
	b_score=sum(of b_val_char_:);
run;
