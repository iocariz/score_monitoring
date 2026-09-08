%macro scan_CH(Variable_TK,Variable,sep,par,prec);
	%do i = 1 %to 10;
		&Variable.&i = input(scan(&Variable_TK,&i,&sep),&prec);
		IF &Variable.&i = -999 then &Variable.&i = .;
	%end;
	select;
		when (&par = 'min') &Variable = min(of &Variable.1-&Variable.10);
	end;
%mend;

%macro score_direct_2024;

/***********************************Constant************************************/
	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 0;


	/*VAR1: DISMAXTJ*/

	CHAR_1 = 'DISPMAXTJ';

	if SCRV_CUSTOMER_GROUP_INIT = 'New' then DISMAXTJ = .;
	if DISMAXTJ le 47100 or DISMAXTJ = . then 
		do;
			DES_CHAR_1 = '(-inf, 47100]';
			VAL_CHAR_1 = 50;
		end;
	else if DISMAXTJ le 108251 then 
		do;
			DES_CHAR_1 = '(47100, 108251]';
			VAL_CHAR_1 = 70;
		end;
	else 
		do;
			DES_CHAR_1 = '(108251, inf]';
			VAL_CHAR_1 = 90;
		end;

	/*VAR2:has_coapp_&_financed_amount*/

	CHAR_2 = 'has_coapp_&_financed_amount';

	/*COOP*/
	length VAR_NIF_T2 $ 100.;
	if NIFT2 = '' then VAR_NIF_T2 = 'No Co-App';
	else VAR_NIF_T2 = 'Has Co-App';

	If  product_type_1 = 'Cards' then financed_amount = CRUTACR/100;
	else financed_amount = MOPCENT/100;

	/*finance_amount*/
	length VAR_financed_amount $ 100.;
	if financed_amount le 4000 then VAR_financed_amount = '(-inf,4000]';
	else if financed_amount lt 8517 then VAR_financed_amount = '(4000,8517]';
	else if financed_amount lt 16776 then VAR_financed_amount = '(8517,16776]';
	else VAR_financed_amount = '(16776,inf]';

	/*GRUPO 1*/
	if VAR_NIF_T2 = 'Has Co-App' and  VAR_financed_amount = '(-inf,4000]' then 
	DES_CHAR_2 = "(Has Co-App & financed amount ≤ 4000) or (No Co-App & financed amount ≤ 8517)";

	if VAR_NIF_T2 = 'No Co-App' and  VAR_financed_amount = '(-inf,4000]' then 
	DES_CHAR_2 = "(Has Co-App & financed amount ≤ 4000) or (No Co-App & financed amount ≤ 8517)";

	if VAR_NIF_T2 = 'No Co-App' and  VAR_financed_amount = '(4000,8517]' then 
	DES_CHAR_2 = "(Has Co-App & financed amount ≤ 4000) or (No Co-App & financed amount ≤ 8517)";

	/* GRUPO 2*/
	if VAR_NIF_T2 = 'Has Co-App' and  VAR_financed_amount = '(4000,8517]' then 
	DES_CHAR_2 = "(Has Co-App & 4000 < financed amount ≤ 8517) or (No Co-App & financed amount > 8517)";

	if VAR_NIF_T2 = 'No Co-App' and  VAR_financed_amount = '(8517,16776]' then 
	DES_CHAR_2 = "(Has Co-App & 4000 < financed amount ≤ 8517) or (No Co-App & financed amount > 8517)";

	if VAR_NIF_T2 = 'No Co-App' and  VAR_financed_amount = '(16776,inf]' then 
	DES_CHAR_2 = "(Has Co-App & 4000 < financed amount ≤ 8517) or (No Co-App & financed amount > 8517)";

	/* GRUPO 3*/
	if VAR_NIF_T2 = 'Has Co-App' and  VAR_financed_amount = '(16776,inf]' then 
	DES_CHAR_2 = "Has Co-App & financed amount > 8517";

	if VAR_NIF_T2 = 'Has Co-App' and  VAR_financed_amount = '(8517,16776]' then 
	DES_CHAR_2 = "Has Co-App & financed amount > 8517";

	if DES_CHAR_2 = "(Has Co-App & financed amount ≤ 4000) or (No Co-App & financed amount ≤ 8517)"  THEN VAL_CHAR_2 = 50;
	else if DES_CHAR_2 = "(Has Co-App & 4000 < financed amount ≤ 8517) or (No Co-App & financed amount > 8517)"  THEN VAL_CHAR_2 = 65;
	else if DES_CHAR_2 = "Has Co-App & financed amount > 8517"  THEN VAL_CHAR_2 = 90;

	/*VAR3: SITHAB*/
	CHAR_3 = 'SITHAB';

	length SITHAB_D $ 100.;

	if 		SITHAB in (.)		then SITHAB_D = 'Missing';
	else if SITHAB = 1		 	then SITHAB_D = 'Owner';
	else if SITHAB = 2		 	then SITHAB_D = 'Family';
	else if SITHAB = 3		 	then SITHAB_D = 'Rent';
	else if SITHAB = 4		 	then SITHAB_D = 'Company';
	else if SITHAB = 5		 	then SITHAB_D = 'Missing';

	if SITHAB_D in ("Family", "Missing", "Rent") then 
		do;
			DES_CHAR_3 = "('Family', 'Missing', 'Rent')";
			VAL_CHAR_3 = 50;
		end;
	else if SITHAB_D in ('Owner','Company') then 
		do;
			DES_CHAR_3 = "('Owner','Company')";
			VAL_CHAR_3 = 69;
		end;

	/*VAR4: PRODUCT_TYPE_3*/
	CHAR_4 = 'PRODUCT_TYPE_3';

	if 		product_type_3 in ("Gold", "Premium") 	then 
		do;
			DES_CHAR_4 = "('Gold', 'Premium')";
			VAL_CHAR_4=74;
		end;
	else if product_type_3 in ("HP","MP") 			then 
		do;
			DES_CHAR_4 = "('HP', 'MP')";
			VAL_CHAR_4=50;
		end;
	else if product_type_3 in ("No Premium","Silver","Silver Auto") 		then 
		do;
			DES_CHAR_4 = "('No Premium')";
			VAL_CHAR_4=62;
		end;

	/*VAR5: CSP*/
	CHAR_5 = 'CSP';
	if		compress(CSP) in ("81", "80", "90", "31", "95", "74", "73", "66", "72", "91", "41", "15", "10", "61", "99", "96", "") then 
		do;
			DES_CHAR_5 = 'High Risk';
			VAL_CHAR_5 = 50;
		end;
	else if compress(CSP) in ("60", "35", "75", "45", "70", "20", "30", "40", "25", "1", "92", "01")  then 
		do;
			DES_CHAR_5 = 'Low Risk';
			VAL_CHAR_5=65;
		end;
	else 
		do;
			DES_CHAR_5 = 'High Risk';
			VAL_CHAR_5 = 50;
		end;

	/*VAR6: SITFAM*/
	CHAR_6 = 'SITFAM';
	length  SITFAM_D $ 100.;
	if 		SITFAM in (0,5,6,.)	then SITFAM_D = 'Missing';
	else if SITFAM = 1		 	then SITFAM_D = 'Single';
	else if SITFAM = 2		 	then SITFAM_D = 'Married';
	else if SITFAM = 3		 	then SITFAM_D = 'Widow';
	else if SITFAM = 4		 	then SITFAM_D = 'Divorced';
	else if SITFAM = 7		 	then SITFAM_D = 'Concubine';

	if SITFAM_D in ("Single", "Missing", "Widow", "Divorced") then 
		do;
			DES_CHAR_6 = "('Single', 'Missing', 'Widow', 'Divorced')";
			VAL_CHAR_6 = 50;
		end;
	else if SITFAM_D in ('Married','Concubine') then 
		do;
			DES_CHAR_6 = "('Married','Concubine')";
			VAL_CHAR_6 = 56;
		end;
	else VAL_CHAR_6 = 50;
					
	/*VAR7: INCIT1_L12*/
	CHAR_7 = 'INCIT1_L12';
	INCIT1_0 = 	input(compress(INCIT1),1.);
	INCIT1_1 = 	input(compress(INCI1T1),1.);
	INCIT1_2 = 	input(compress(INCI2T1),1.);
	INCIT1_3 = 	input(compress(INCI3T1),1.);
	INCIT1_4 = 	input(compress(INCI4T1),1.);
	INCIT1_5 = 	input(compress(INCI5T1),1.);
	INCIT1_6 = 	input(compress(INCI6T1),1.);
	INCIT1_7 = 	input(compress(INCI7T1),1.);
	INCIT1_8 = 	input(compress(INCI8T1),1.);
	INCIT1_9 = 	input(compress(INCI9T1),1.);
	INCIT1_10 = input(compress(INCI10T1),1.);
	INCIT1_11 = input(compress(INCI11T1),1.);
	INCIT1_12 = input(compress(INCI12T1),1.);

	INCIT1_L12_ = sum(INCIT1_0, INCIT1_1 , INCIT1_2, INCIT1_3, INCIT1_4, INCIT1_5, INCIT1_6, INCIT1_7, INCIT1_8, INCIT1_9, INCIT1_10, INCIT1_11, INCIT1_12);
					
	if INCIT1_L12_ >0 then 
		do;
			DES_CHAR_7 = '(0,inf)';
			VAL_CHAR_7 = 50;
		end;
	else 
		DO;
			DES_CHAR_7 = '(-inf,0]';
			VAL_CHAR_7 = 64;
		END;
%mend;


%macro score_direct_XFR_2024;

/***********************************Constant************************************/
	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 0;

	/*VAR1: DISMAXTJ*/
	CHAR_1 = 'DISMAXTJ';
	if rvivoact = '' then DISMAXTJ = 0;

	DES_CHAR_1 = '(-inf, 47100]';
	VAL_CHAR_1 = 50;

	/*VAR2:has_coapp_&_financed_amount*/
	CHAR_2 = 'has_coapp_&_financed_amount';

	/*COOP*/
	length VAR_NIF_T2 $ 100.;
	if NIFT2 = '' then VAR_NIF_T2 = 'No Co-App';
	else VAR_NIF_T2 = 'Has Co-App';

	If  product_type_1 = 'Cards' then financed_amount = CRUTACR/100;
	else financed_amount = MOPCENT/100;

	/*finance_amount*/
	length VAR_financed_amount $ 100.;
	if financed_amount le 4000 then VAR_financed_amount = '(-inf,4000]';
	else if financed_amount lt 8517 then VAR_financed_amount = '(4000,8517]';
	else if financed_amount lt 16776 then VAR_financed_amount = '(8517,16776]';
	else VAR_financed_amount = '(16776,inf]';

	/*GRUPO 1*/
	if VAR_NIF_T2 = 'Has Co-App' and  VAR_financed_amount = '(-inf,4000]' then 
	DES_CHAR_2 = "(Has Co-App & financed amount ≤ 4000) or (No Co-App & financed amount ≤ 8517)";

	if VAR_NIF_T2 = 'No Co-App' and  VAR_financed_amount = '(-inf,4000]' then 
	DES_CHAR_2 = "(Has Co-App & financed amount ≤ 4000) or (No Co-App & financed amount ≤ 8517)";

	if VAR_NIF_T2 = 'No Co-App' and  VAR_financed_amount = '(4000,8517]' then 
	DES_CHAR_2 = "(Has Co-App & financed amount ≤ 4000) or (No Co-App & financed amount ≤ 8517)";

	/* GRUPO 2*/
	if VAR_NIF_T2 = 'Has Co-App' and  VAR_financed_amount = '(4000,8517]' then 
	DES_CHAR_2 = "(Has Co-App & 4000 < financed amount ≤ 8517) or (No Co-App & financed amount > 8517)";

	if VAR_NIF_T2 = 'No Co-App' and  VAR_financed_amount = '(8517,16776]' then 
	DES_CHAR_2 = "(Has Co-App & 4000 < financed amount ≤ 8517) or (No Co-App & financed amount > 8517)";

	if VAR_NIF_T2 = 'No Co-App' and  VAR_financed_amount = '(16776,inf]' then 
	DES_CHAR_2 = "(Has Co-App & 4000 < financed amount ≤ 8517) or (No Co-App & financed amount > 8517)";

	/* GRUPO 3*/
	if VAR_NIF_T2 = 'Has Co-App' and  VAR_financed_amount = '(16776,inf]' then 
	DES_CHAR_2 = "Has Co-App & financed amount > 8517";

	if VAR_NIF_T2 = 'Has Co-App' and  VAR_financed_amount = '(8517,16776]' then 
	DES_CHAR_2 = "Has Co-App & financed amount > 8517";

	if DES_CHAR_2 = "(Has Co-App & financed amount ≤ 4000) or (No Co-App & financed amount ≤ 8517)"  THEN VAL_CHAR_2 = 50;
	else if DES_CHAR_2 = "(Has Co-App & 4000 < financed amount ≤ 8517) or (No Co-App & financed amount > 8517)"  THEN VAL_CHAR_2 = 65;
	else if DES_CHAR_2 = "Has Co-App & financed amount > 8517"  THEN VAL_CHAR_2 = 90;

	/*VAR3: SITHAB*/

	CHAR_3 = 'SITHAB';

	length SITHAB_D $ 100.;
	if 		SITHAB in (.)		then SITHAB_D = 'Missing';
	else if SITHAB = 1		 	then SITHAB_D = 'Owner';
	else if SITHAB = 2		 	then SITHAB_D = 'Family';
	else if SITHAB = 3		 	then SITHAB_D = 'Rent';
	else if SITHAB = 4		 	then SITHAB_D = 'Company';
	else if SITHAB = 5		 	then SITHAB_D = 'Missing';

	if SITHAB_D in ("Family", "Missing", "Rent") then 
		do;
			DES_CHAR_3 = "('Family', 'Missing', 'Rent')";
			VAL_CHAR_3 = 50;
		end;
	else if SITHAB_D in ('Owner','Company') then 
		do;
			DES_CHAR_3 = "('Owner','Company')";
			VAL_CHAR_3 = 69;
		end;

	/*VAR4: PRODUCT_TYPE_3*/

	CHAR_4 = 'PRODUCT_TYPE_3';

	DES_CHAR_4 = "('HP', 'MP')";
	VAL_CHAR_4=50;

	/*VAR5: CSP*/

	CHAR_5 = 'CSP';

	if		compress(CSP) in ("81", "80", "90", "31", "95", "74", "73", "66", "72", "91", "41", "15", "10", "61", "99", "96", "") then 
		do;
			DES_CHAR_5 = 'High Risk';
			VAL_CHAR_5 = 50;
		end;
	else if compress(CSP) in ("60", "35", "75", "45", "70", "20", "30", "40", "25", "1", "92","01")  then 
		do;
			DES_CHAR_5 = 'Low Risk';
			VAL_CHAR_5=65;
		end;
	else 
		do;
			DES_CHAR_5 = 'High Risk';
			VAL_CHAR_5 = 50;
		end;

	/*VAR6: SITFAM*/

	CHAR_6 = 'SITFAM';

	length  SITFAM_D $ 100.;
	if 		SITFAM in (0,5,6,.)	then SITFAM_D = 'Missing';
	else if SITFAM = 1		 	then SITFAM_D = 'Single';
	else if SITFAM = 2		 	then SITFAM_D = 'Married';
	else if SITFAM = 3		 	then SITFAM_D = 'Widow';
	else if SITFAM = 4		 	then SITFAM_D = 'Divorced';
	else if SITFAM = 7		 	then SITFAM_D = 'Concubine';

	if SITFAM_D in ("Single", "Missing", "Widow", "Divorced") then 
		do;
			DES_CHAR_6 = "('Single', 'Missing', 'Widow', 'Divorced')";
			VAL_CHAR_6 = 50;
		end;
	else if SITFAM_D in ('Married','Concubine') then 
		do;
			DES_CHAR_6 = "('Married','Concubine')";
			VAL_CHAR_6 = 56;
		end;
	else VAL_CHAR_6 = 50;
					
	/*VAR7: INCIT1_L12*/

	CHAR_7 = 'INCIT1_L12';

	INCIT1_0 = 	input(compress(INCIT1),1.);
	INCIT1_1 = 	input(compress(INCI1T1),1.);
	INCIT1_2 = 	input(compress(INCI2T1),1.);
	INCIT1_3 = 	input(compress(INCI3T1),1.);
	INCIT1_4 = 	input(compress(INCI4T1),1.);
	INCIT1_5 = 	input(compress(INCI5T1),1.);
	INCIT1_6 = 	input(compress(INCI6T1),1.);
	INCIT1_7 = 	input(compress(INCI7T1),1.);
	INCIT1_8 = 	input(compress(INCI8T1),1.);
	INCIT1_9 = 	input(compress(INCI9T1),1.);
	INCIT1_10 = input(compress(INCI10T1),1.);
	INCIT1_11 = input(compress(INCI11T1),1.);
	INCIT1_12 = input(compress(INCI12T1),1.);

	INCIT1_L12_ = sum(INCIT1_0, INCIT1_1 , INCIT1_2, INCIT1_3, INCIT1_4, INCIT1_5, INCIT1_6, INCIT1_7, INCIT1_8, INCIT1_9, INCIT1_10, INCIT1_11, INCIT1_12);
			
	if INCIT1_L12_ >0 then 
		do;
			DES_CHAR_7 = '(0,inf)';
			VAL_CHAR_7 = 50;
		end;
	else 
		DO;
			DES_CHAR_7 = '(-inf,0]';
			VAL_CHAR_7 = 64;
		END;
%mend;

%macro score_direct;
	
		/***********************************constant************************************/
		DES_CHAR_0 = 'Constant';
		VAL_CHAR_0 = 0;

		/************************************Age T1**************************************/
		CHAR_1 = 'Age of applicant';	

		IF KEDAD1>47 AND KEDAD1<=80 THEN 
			DO;
				DES_CHAR_1 = '01: More than 47';
				VAL_CHAR_1 = 42;
			END;
		ELSE IF KEDAD1>27 AND KEDAD1<=47 THEN 
			DO;
				DES_CHAR_1 = '02: More than 27 up to 47';
				VAL_CHAR_1 = 40;
			END;
		ELSE 
			DO;
				DES_CHAR_1 = '03: Up to 27 or Missing/Not Valid Variables';
				VAL_CHAR_1 = 34;
			END;

		/*******************************Applicant monthly income************************/
		CHAR_2 = 'Applicant monthly income';
	
		IF MSAL1>200000 AND MSAL1<=1000000 THEN 
			DO;
				DES_CHAR_2 = '01: More than 2000';
				VAL_CHAR_2 = 63;	
			END;
		ELSE IF MSAL1>150000 AND MSAL1<=200000 THEN 
			DO;
				DES_CHAR_2 = '02:More than 1500 up to 2000';
				VAL_CHAR_2 = 54;	
			END;
		ELSE IF MSAL1>100000 AND MSAL1<=150000 THEN 
			DO;
				DES_CHAR_2 = '03:More than 1000 up to 1500';
				VAL_CHAR_2 = 44;
			END;
		ELSE 
			DO;
				DES_CHAR_2 = '04:Up to 1000 of Missing/Not valid values';
				VAL_CHAR_2 = 34;	
			END;

	/*************************************CSP_f************************************/
		CHAR_3 = 'Applicant profession code';

		if CSP IN ("45","10","25","31","01","60","41","40","30","35","70") THEN
			DO;
				DES_CHAR_3 = '01: Manager, businessman, employed';
				VAL_CHAR_3 = 65;
			END;
		ELSE IF CSP IN ("74","92","80","75","81","61","66","91","72","20","15","90","73") THEN 
			DO;
				DES_CHAR_3 = '02: Labourer, military, temporary, self-employed';
				VAL_CHAR_3 = 55;
			END;
		ELSE IF CSP IN (""," ","  ","95","96","99") THEN 
			DO;
				DES_CHAR_3 = '03: Unemployed, pensioneer, unknown or missing/not valid values';
				VAL_CHAR_3 = 34;
			END;
		ELSE 
			DO;
				DES_CHAR_3 = '03: Unemployed, pensioneer, unknown or missing/not valid values';
				VAL_CHAR_3 = 34;
			END;

		/*********************************Channel type*********************************/
		CHAR_4 = 'Applicant origin';

		if channel_type in ('On-Line','') then 
			do;
				DES_CHAR_4 = '02: On-Line';
				VAL_CHAR_4 = 34;
			end;
		else if channel_type = 'Off-Line' then
			do;
				DES_CHAR_4 = '01: Off-Line';
				VAL_CHAR_4 = 47;
			end;


	/*******************************Co-Applicant monthly income*************************/
		CHAR_5 = 'Co-Applicant monthly income';

		IF MSAL2>=50000 AND MSAL2<=1000000 THEN 
			DO;
				DES_CHAR_5 = '01: Valid values';
				VAL_CHAR_5 = 63;
			END;
		ELSE 
			DO;
				DES_CHAR_5 = '02: Misssing/Not valid values';
				VAL_CHAR_5 = 34;
			END;

	/*************************************customer_type_f*****************************/
		CHAR_6 = 'Customer type';

		IF customer_type="New" THEN 
			DO;
				DES_CHAR_6 = '02: New';
				VAL_CHAR_6 = 34;  
			END;
		ELSE 
			DO;
				DES_CHAR_6 = '01: Known or inactive';
				VAL_CHAR_6 = 53;
			END;

		/************************************Family Situation*****************************/
		CHAR_7 = 'Family situation';

		IF SITFAM IN (2,7) THEN 
			DO;
				DES_CHAR_7 = '01: Married or concubine';
				VAL_CHAR_7 = 43;	
			END;
		ELSE IF SITFAM IN (1,5,4,3,.) THEN 
			DO;
				DES_CHAR_7 = '02: Single, widow, divorced, unknown or Missing/Not valid values';
				VAL_CHAR_7 = 34;	
			END;;

	/************************************Housing Type*****************************/
		CHAR_8 = 'Housing Type';

		IF SITHAB=1 THEN 
			DO;
				DES_CHAR_8 = '01: Owner';
				VAL_CHAR_8 = 50;
			END;
		ELSE 
			DO;
				DES_CHAR_8 = '02: Not Owner';
				VAL_CHAR_8 = 34;			
			END;

		/********************************DISMAXTJ_f_div_MSAL1_f*************************/

		CHAR_9 = 'DISMAXTJ_f_div_MSAL1_f';

		 IF   (MSAL1>=50000 AND MSAL1<=1000000 AND DISMAXTJ>0 AND DISMAXTJ<=500000 AND NDOSCAMR>0) AND (DISMAXTJ*100<=MSAL1*500 AND DISMAXTJ*100>MSAL1*40) THEN 
				DO;
					DES_CHAR_9 = '01: More than 0.4';
					VAL_CHAR_9 = 74;
				END;
	      ELSE IF (MSAL1>=50000 AND MSAL1<=1000000 AND DISMAXTJ>0 AND DISMAXTJ<=500000 AND NDOSCAMR>0) AND 
	                  (DISMAXTJ*100<=MSAL1*40 AND DISMAXTJ*100>MSAL1*10) THEN 
				DO;
					DES_CHAR_9 = '02: More than 0.1 up to 0.4';
					VAL_CHAR_9 = 52;
				END;
	      ELSE 
				DO;
					DES_CHAR_9 = '03: Up to 0.1 or Missing/Invalid values';
					VAL_CHAR_9 = 34;
				END;   
%mend;

%macro score_automoto;
/***********************************Constant************************************/
	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 20982;
/*****************************WNTENT43:Down Payment*********************/
	CHAR_1 = 'Down Payment';
	IF KIMPENT > 41 THEN	
		DO;
			DES_CHAR_1 = '01:>41%';
			VAL_CHAR_1 = 9013;
		END;
	ELSE IF KIMPENT >= 19 THEN
		DO;
			DES_CHAR_1 = '02:19-41%';
			VAL_CHAR_1 = 2887;
		END;
	ELSE
		DO;
			DES_CHAR_1 = '03:<19%';
			VAL_CHAR_1 = 0;
		END;
/*****************************WNTINGR43:Family income*********************/	
	CHAR_2 = 'Family income';	
	IF WINGRES > 155400 THEN	
		DO;
			DES_CHAR_2 = '01:FAMILY INCOMES > 1554';
			VAL_CHAR_2 = 3118;
		END;
	ELSE 
		DO;
			DES_CHAR_2 = '02:FAMILY INCOMES <= 1554';
			VAL_CHAR_2 = 0;
		END;
/*****************************WNTPROF43:CSP*********************/
	CHAR_3 = 'CSP';	
	IF CSP IN ("01" "02" "10" "15" "20" "25" "30" "31" "34" "35"       
             "40" "41" "45" "60" "66" "70" "72" "73" "75") THEN	
		DO;
			DES_CHAR_3 = '01:CSP GROUP 1';
			VAL_CHAR_3 = 4182;
		END;
	ELSE 
		DO;
			DES_CHAR_3 = '02: OTHER CSPs';
			VAL_CHAR_3 = 0;
		END;

/*********************WNTPROF43:MATERIAL DURACION****************/	
	CHAR_4 = 'AUTO TYPE AND TENOR';	
	IF KSAUTO IN ('MOTO','OTROS') AND DURDEG <=24 THEN	
		DO;
			DES_CHAR_4 = '01: MOTO/OTHER & TENOR <=24 MONTHS OR VN & TENOR <= 76 MONTHS';
			VAL_CHAR_4 = 7659;
		END;
	ELSE IF KSAUTO IN ('COCHE_NUEVO','COCHE_SEMINUEVO') AND DURDEG <=76 THEN	
		DO;
			DES_CHAR_4 = '01: MOTO/OTHER & TENOR <=24 MONTHS OR VN & TENOR <= 76 MONTHS';
			VAL_CHAR_4 = 7659;
		END;	
	ELSE IF KSAUTO IN ('COCHE_OCASION') AND DURDEG <=61 THEN	
		DO;
			DES_CHAR_4 = '02: VO & TENOR <= 61 MONTHS OR VN & TENOR >76 MONTHS';
			VAL_CHAR_4 = 3064;
		END;	
	ELSE IF KSAUTO IN ('COCHE_NUEVO','COCHE_SEMINUEVO') AND DURDEG >76 THEN	
		DO;
			DES_CHAR_4 = '02: VO & TENOR <= 61 MONTHS OR VN & TENOR >76 MONTHS';
			VAL_CHAR_4 = 3064;
		END;	
	ELSE	
		DO;
			DES_CHAR_4 = '03: MOTO/OTHER & TENOR >24 MONTHS OR CO & TENOR > 61 MONTHS';
			VAL_CHAR_4 = 0;
		END;
/*********************WNTSITFAM43:FAMILY SITUATION****************/	
	CHAR_5 = 'FAMILY SITUATION';	
	IF SITFAM = 2 THEN	
		DO;
			DES_CHAR_5 = '01: FAMILY SITUATION:MARRIED';
			VAL_CHAR_5 = 4882;
		END;
	ELSE 
		DO;
			DES_CHAR_5 = '02:OTHER FAMILY SITUATIONS';
			VAL_CHAR_5 = 0;
		END;	
/*********************WNTANTBAN43:SENIORITY IN THE BANK****************/	
	CHAR_6 = 'SENIORITY IN THE BANK';	
	IF KANTBCO > 6 THEN	
		DO;
			DES_CHAR_6 = '01: SENIORITY IN THE BANK > 6 YEARS';
			VAL_CHAR_6 = 6788;
		END;
	ELSE 
		DO;
			DES_CHAR_6 = '02: SENIORITY IN THE BANK <= 6 YEARS';
			VAL_CHAR_6 = 0;
		END;	
/*********************WNTANTPRO43:LABORAL SENIORITY****************/	
	CHAR_7 = 'LABORAL SENIORITY';	
	IF KANTPF1 > 8 THEN	
		DO;
			DES_CHAR_7 = '01: LABORAL SENIORITY > 8 YEARS';
			VAL_CHAR_7 = 2464;
		END;
	ELSE 
		DO;
			DES_CHAR_7 = '02: LABORAL SENIORITY <= 8 YEARS';
			VAL_CHAR_7 = 0;
		END;	

/*********************WNTANTPRO43:SENIORITY IN THE HOUSE AND TYPE OF HOUSE****************/	
	CHAR_8 = 'SENIORITY IN THE HOUSE AND TYPE OF HOUSE';	
	IF  SITHAB=1 THEN	
		DO;
			DES_CHAR_8 = '01: HOUSE OWNER';
			VAL_CHAR_8 = 6372;
		END;
	ELSE IF KANTRESI1>7 THEN
		DO;
			DES_CHAR_8 = '02: REST OF SITUATIONS WITH A SENIORITY > 7 YEARS';
			VAL_CHAR_8 = 3857;
		END;
	ELSE 	
		DO;
			DES_CHAR_8 = '03: REST OF SITUATIONS';
			VAL_CHAR_8 = 0;
		END;

%mend;
%macro score_distrib2;
	
		/***********************************constant************************************/
		DES_CHAR_0 = 'Constant';
		VAL_CHAR_0 = 4711;

		/*************WSCO2DUR44:DURATION X RATIO CREDIT LIMIT/INCOME*******************/
		CHAR_1 = 'DURATION X RATIO CREDIT LIMIT/INCOME';	

		IF DURDEG <= 6 OR (DURDEG > 6 AND DURDEG <= 10 AND WDECREV <= 600) THEN 
			DO;
				DES_CHAR_1 = '01:Tenor [-, 6] or Tenor ]6, 10] and ratio ]-, 0.6]';
				VAL_CHAR_1 = 849;
			END;
		ELSE IF (DURDEG <=18 AND DURDEG > 10) OR
				(DURDEG > 6  AND DURDEG <= 10 AND WDECREV > 600) OR
				(DURDEG > 18  AND DURDEG <= 24 AND WDECREV <= 600) THEN 
			DO;
				DES_CHAR_1 = '02: Tenor (6, 10] ratio (0.6, +] or Tenor (10, 18] or tenor ]18, 24] ratio ]-, 0.6]';
				VAL_CHAR_1 = 0;
			END;
		ELSE IF DURDEG > 24 OR (DURDEG > 18 AND DURDEG <= 24 AND WDECREV > 600) THEN 
			DO;
				DES_CHAR_1 = '03: Tenor (18, 24] rd (0.6, +] or tenor (24, +]';
				VAL_CHAR_1 = -1012;
			END;
		ELSE
			DO;
				DES_CHAR_1 = '03: Tenor (18, 24] rd (0.6, +] or tenor (24, +]';
				VAL_CHAR_1 = -1012;
			END;
		/*************WSCO2JOB44:SENIORITY X WORK CATEGORY*******************/
		CHAR_2 = 'SENIORITY X WORK CATEGORY';

		IF KANTPF1 > 11 AND CSP NOT IN ('90','95') THEN 
			DO;
				DES_CHAR_2 = '01: Job seniority > 11 not retired or pensioner';
				VAL_CHAR_2 = 956;
			END;
		ELSE IF (KANTPF1 > 3 AND KANTPF1 <=8 AND 
			CSP IN ("01","02","20" ,"25","30","31","35","40","41","45","70","72","74")) OR
			(KANTPF1 <= 3 AND CSP IN ("30","31","35","40","41","45")) THEN 
			DO;
				DES_CHAR_2 = '02: Low Risk and job seniority [0,3] or low/medium risk and job seniority (3,8] or not retired/pensioner and job seniority (8,11]';
				VAL_CHAR_2 = 627;
			END;
		ELSE IF (KANTPF1 > 8 AND KANTPF1 <=11 AND 
			CSP NOT IN ("","01","07" ,"10","11","15","34","42","46","48","65","71","90","91","94","95","99")) THEN
			DO;
				DES_CHAR_2 = '02: Low Risk and job seniority [0,3] or low/medium risk and job seniority (3,8] or not retired/pensioner and job seniority (8,11]';
				VAL_CHAR_2 = 627;
			END;
		ELSE IF (KANTPF1 <= 3  AND 
			CSP IN ("01","02","20" ,"25","60","70","72","74")) OR
			(KANTPF1 >3  AND KANTPF1 <=8  AND CSP IN ("60","61","66","80","81")) OR CSP IN ("90","95") THEN
			DO;
				DES_CHAR_2 = '03: High risk and job seniority [0, 3] or job seniority (3, 8] or retired/pensioner';
				VAL_CHAR_2 = 0;
			END;
		ELSE IF (KANTPF1 <= 11 AND 
			CSP IN ("","01","07" ,"10","11","15","34","42""46","48","65","71","91","94","99")) OR
			(KANTPF1 <= 3 AND CSP IN ("61","66","80","81")) THEN 
			DO;
				DES_CHAR_2 = '04: High risk and job seniority [0-, 3] and unknown values';
				VAL_CHAR_2 = - 408;
			END;
		ELSE 
			DO;
				DES_CHAR_2 = '04: High risk and job seniority [0-, 3] and unknown values';
				VAL_CHAR_2 = - 408;
			END;
		/*************WSCO2ENT44:RATIO OF DOWN PAYMENT*******************/
		CHAR_3 = 'RATIO OF DOWN PAYMENT';

		IF KIMPENT > 10 THEN 
			DO;
				DES_CHAR_3 = '01: Down payment > 1%';
				VAL_CHAR_3 = 0;
			END;
		ELSE 
			DO;
				DES_CHAR_3 = '02: Down payment <= 1% OR MISSING';
				VAL_CHAR_3 = -561;
			END;
		/*************WSCO2AGE44:AGE*******************/
		CHAR_4 = 'AGE';

		IF KEDAD1 > 60 THEN 
			DO;
				DES_CHAR_4 = '01: Age > 60 years';
				VAL_CHAR_4 = 415;
			END;
		ELSE IF KEDAD1 > 25 AND KEDAD1 <=60 THEN 
			DO;
				DES_CHAR_4 = '02: Age between 26 and 60 years';
				VAL_CHAR_4 = 0;
			END;
		ELSE
			DO;
				DES_CHAR_4 = '03: Age below 26 years';
				VAL_CHAR_4 = -517;
			END;	
		/*************WSCO2MAT44:INSTALMENT x MATERIAL CODE*******************/
		CHAR_5 = 'INSTALMENT x MATERIAL CODE';

		IF (KMENSCENT >20000) THEN
			DO;
				DES_CHAR_5='01: MONTHLY AMOUNT > 200';
				VAL_CHAR_5=452;
			END;

		ELSE IF (KMENSCENT <= 20000 AND 
		         CMAT IN ('330','340','342','343','344','345','349','350','351','353','354','355','359',
		                  '390','450','460','461','462','463','464','465','469','491','492','494','900')) THEN
			DO;
				DES_CHAR_5='02: MONTHLY AMOUNT <= 200 AND CMAT_1';
				VAL_CHAR_5=0;
			END;

		ELSE IF (KMENSCENT <= 20000 AND 
		         CMAT IN ('300','333','341','400','420','430','439','449','451','452','453','454','455',
		                  '456','470','499','500','508','515','530','599','600','611','660')) THEN
			DO;
				DES_CHAR_5='03: MONTHLY AMOUNT <= 200 AND CMAT_2';    /* MISMO DESC*/
				VAL_CHAR_5=-437;
			END;
		ELSE
			DO;
				DES_CHAR_5='03: MONTHLY AMOUNT <= 200 AND CMAT_2';
				VAL_CHAR_5=-437;
			END;

		/*************WSC2BANK44: BANK SENIORITY*******************/
		CHAR_6 = 'BANK SENIORITY';
		IF KANTBCO > 5 THEN 
			DO;
				DES_CHAR_6='01: BANK SEMIORITY > 5 YEARS';
				VAL_CHAR_6=0;				
			END;
		ELSE 
			DO;
				DES_CHAR_6='02: BANK SEMIORITY <= 5 YEARS';
				VAL_CHAR_6=-360;				
			END;
		/*************WSCO2RES44:RESIDENTIAL STATUS*******************/
		CHAR_7 = 'RESIDENTIAL STATUS';
		IF SITHAB IN (0,1) THEN 
			DO;
				DES_CHAR_7='01: OWNER OR MORTGAGE';
				VAL_CHAR_7=0;				
			END;
		ELSE 
			DO;
				DES_CHAR_7='02: OTHER OR MISSING';
				VAL_CHAR_7=-276;				
			END;
%mend;

%macro score_distrib1;
	
		/***********************************constant************************************/
		DES_CHAR_0 = 'Constant';
		VAL_CHAR_0 = -1051;

		/*************WNTCODMAT41:MATERIAL GROUP*******************/
		CHAR_1 = 'MATERIAL GROUP';	

		IF WGRCMAT = 1 THEN 
			DO;
				DES_CHAR_1 = '01: Material group 1';
				VAL_CHAR_1 = 681;
			END;
		ELSE IF WGRCMAT = 2 THEN 
			DO;
				DES_CHAR_1 = '02: Material group 2';
				VAL_CHAR_1 = 257;
			END;
		ELSE
			DO;
				DES_CHAR_1 = '03: Material group 3';
				VAL_CHAR_1 = 0;
			END;

		/*************WNTDUREE41:TENOR*******************/
		CHAR_2 = 'TENOR';

		IF DURDEG <= 6 THEN 
			DO;
				DES_CHAR_2 = '01: Tenor <= 6';
				VAL_CHAR_2 = 2074;
			END;
		ELSE IF DURDEG <= 12 THEN 
			DO;
				DES_CHAR_2 = '02: Tenor between 7 and 12';
				VAL_CHAR_2 = 981;
			END;
		ELSE IF DURDEG <= 18 THEN 
			DO;
				DES_CHAR_2 = '03: Tenor between 13 and 18';
				VAL_CHAR_2 = 421;
			END;
		ELSE  
			DO;
				DES_CHAR_2 = '04: Tenor greater than 18 or missing';
				VAL_CHAR_2 = 0;
			END;

		/*****WNTECRESI41:MARITAL STATUS X RESIDENCE TYPE*****/
		CHAR_3 = 'MARITAL STATUS X RESIDENCE TYPE';

		IF SITFAM = 2 AND SITHAB  IN (0,1) THEN 
			DO;
				DES_CHAR_3 = '01:Married and owner';
				VAL_CHAR_3 = 1686;
			END;
		ELSE IF SITFAM = 2 AND SITHAB NOT IN (0,1) THEN 
			DO;
				DES_CHAR_3 = '02:Married and not owner';
				VAL_CHAR_3 = 932;
			END;
		ELSE IF SITFAM NE 2 AND SITHAB IN (0,1,2,4) THEN 
			DO;
				DES_CHAR_3 = '03:Not married and owner/family/company';
				VAL_CHAR_3 = 861;
			END;
		ELSE IF SITFAM NE 2 AND SITHAB NOT IN (0,1,2,4) THEN 
			DO;
				DES_CHAR_3 = '04:Not married and rent';
				VAL_CHAR_3 = 0;
			END;
		ELSE 
			DO;
				DES_CHAR_3 = '04:Not married and rent';
				VAL_CHAR_3 = 0;
			END;
		/*****WNTEDAD41:AGE*****/
		CHAR_4 = 'AGE';
		IF KEDAD1 > 40 THEN
			DO;
				DES_CHAR_4 = '01:Age > 40';
				VAL_CHAR_4 = 564;
			END;
		ELSE IF KEDAD1 > 25 AND KEDAD1 <=40 THEN
			DO;
				DES_CHAR_4 = '02:Age between 26 and 40';
				VAL_CHAR_4 = 700;
			END;
		ELSE IF KEDAD1 > 20 AND KEDAD1 <=25 THEN
			DO;
				DES_CHAR_4 = '03:Age between 21 and 25';
				VAL_CHAR_4 = 466;
			END;
		ELSE IF KEDAD1 <=20 THEN
			DO;
				DES_CHAR_4 = '04:Age <= 20 or missing';
				VAL_CHAR_4 = 0;
			END;
		ELSE 
			DO;
				DES_CHAR_4 = '04:Age <= 20 or missing';
				VAL_CHAR_4 = 0;
			END;
		/*****WNTENT41:DOWN PAYMENT*****/
		CHAR_5 = 'DOWN PAYMENT';
		IF KIMPENT >0 THEN
			DO;
				DES_CHAR_5 = '01:Down payment > 0';
				VAL_CHAR_5 = 662;
			END;
		ELSE 
			DO;
				DES_CHAR_5 = '02:Down payment <= 0';
				VAL_CHAR_5 = 0;
			END;
		/*****WNTIMPREV41:CREDIT AMOUNT * INCOME*****/
		CHAR_6 = 'CREDIT AMOUNT * INCOME';
		IF WRIMPREV >= 0 AND WRIMPREV <= 60  THEN
			DO;
				DES_CHAR_6 = '01:INCOME RATIO <= 60';
				VAL_CHAR_6 = 431;
			END;
		ELSE IF WRIMPREV >= 60 AND WRIMPREV <= 139 THEN
			DO;
				DES_CHAR_6 = '02:Income ratio between 61 and 139';
				VAL_CHAR_6 = 229;
			END;
		ELSE 
			DO;
				DES_CHAR_6 = '03:Income ratio > 139';
				VAL_CHAR_6 = 0;
			END;
		/*****WNTPFAPF41:LABORAL SENIORITY*****/
		CHAR_7 = 'LABORAL SENIORITY';
		IF CSP IN ("90","91","95") THEN
			DO;
				DES_CHAR_7 = '04:Retired, pensioner';
				VAL_CHAR_7 = 365;
			END;
		ELSE IF KANTPF1 <= 1 or CSP in ("99","96") or KANTPF1=0 THEN
			DO;
				DES_CHAR_7 = '05:Unemployed person, unknown, laboral seniority <= 1 OR 99';
				VAL_CHAR_7 = 0;
			END;
		ELSE IF KANTPF1 > 1 AND KANTPF1 <=3 THEN
			DO;
				DES_CHAR_7 = '03:Laboral seniority between 1 and 3';
				VAL_CHAR_7 = 717;
			END;
		ELSE IF KANTPF1 > 3 AND KANTPF1 <=6 THEN
			DO;
				DES_CHAR_7 = '02:Laboral seniority between 4 and 6';
				VAL_CHAR_7 = 996;
			END;
		ELSE IF KANTPF1 > 6 THEN
			DO;
				DES_CHAR_7 = '01:Laboral seniority above 6';
				VAL_CHAR_7 = 1504;
			END;
		ELSE 
			DO;
				DES_CHAR_7 = '05:Unemployed person, unknown, laboral seniority <= 1 OR 99';
				VAL_CHAR_7 = 0;
			END;
		/*****WNTPFEDA41:JOB X EDAD*****/
		CHAR_8 = 'JOB X EDAD';
		IF CSP IN("90","91") THEN
			DO;
				DES_CHAR_8 = '01:Retired';
				VAL_CHAR_8 = 1486;
			END;
		ELSE IF CSP IN ("40","41","45","70") THEN
			DO;
				DES_CHAR_8 = '02:Others public';
				VAL_CHAR_8 = 1103;
			END;
		ELSE IF CSP = "95" AND KEDAD1 >= 50 THEN
			DO;
				DES_CHAR_8 = '03:Pensioner and age above 50';
				VAL_CHAR_8 = 1063;
			END;
		ELSE IF CSP IN ("30","31","35","60","82","83","84") THEN
			DO;
				DES_CHAR_8 = '04:Other Private';
				VAL_CHAR_8 = 1000;
			END;
		ELSE IF CSP IN ("80","74","75","72","01","02","10","15","20","25") THEN
			DO;
				DES_CHAR_8 = '05:Worker, military, Agric, Arts, Commerce';
				VAL_CHAR_8 = 369;
			END;
		ELSE 
			DO;
				DES_CHAR_8 = '06:Other';
				VAL_CHAR_8 = 0;
			END;
%mend;


%macro score_cards;

/*

  WNOTA46  = 3524 + WTJEC46 + WTJAPF46 + WTJPF46 + WTJPTT46                     
             + WTJARE46 + WTJRESI46 +  WTJCOD46 + WTJPHONE46 + WTJABCO46

*/
	
		/***********************************constant************************************/
		DES_CHAR_0 = 'Constant';
		VAL_CHAR_0 = 3524;

		/*************WTJEC46:MATERIAL GROUP*******************/
		CHAR_1 = 'FAMILY STATUS';	

		IF SITFAM IN (2,3,7) THEN 
			DO;
				DES_CHAR_1 = '01: Married, legitime couple or widow';
				VAL_CHAR_1 = 675;
			END;
		ELSE
			DO;
				DES_CHAR_1 = '02: Other family status or missing';
				VAL_CHAR_1 = 0;
			END;

		/*************WTJAPF46: JOB SENIORITY/AGE/JOB SENIORITY******************/
		CHAR_2 = 'JOB SENIORITY/AGE/JOB SENIORITY';	

		IF CSP IN (90,91,95,96) AND KEDAD1 > 50 THEN 
			DO;
				DES_CHAR_2 = '02: No job seniority and age (50, +]';
				VAL_CHAR_2 = -490;
			END;
		ELSE IF CSP IN (90,91,95,96) AND KEDAD1 <= 50 THEN 
			DO;
				DES_CHAR_2 = '05: No job seniority and age [0, 50]';
				VAL_CHAR_2 = -1550;
			END;
		ELSE IF KANTPF1 <=1 AND KEDAD1 > 23 THEN 
			DO;
				DES_CHAR_2 = '04: Job seniority [0,1] and age (23, +]';
				VAL_CHAR_2 = -1160;
			END;
		ELSE IF KANTPF1 > 1 and KANTPF1 <=5 AND KEDAD1 > 23 THEN 
			DO;
				DES_CHAR_2 = '03: Job seniority (1,5] and age (23, +]';
				VAL_CHAR_2 = -630;
			END;
		ELSE IF KANTPF1 > 5 and KANTPF1 < 99 THEN 
			DO;
				DES_CHAR_2 = '01: Job seniority (5,+]';
				VAL_CHAR_2 = 0;
			END;
		ELSE  
			DO;
				DES_CHAR_2 = '05: No job seniority and age [0, 50]';
				VAL_CHAR_2 = -1550;
			END;

		/*************WTJPF46: JOB SENIORITY/AGE/JOB SENIORITY******************/
		CHAR_3 = 'INCOME';	

		IF 	(KMSAL1TJ <= 82800) OR (KMSAL1TJ <=120000 
			AND CSP IN ("01" "02" "10" "15" "20" "25" "30" "31" "35" "61"
             "66" "80" "81" "82" "83" "84")) OR CSP = "" THEN 
			DO;
				DES_CHAR_3 = '02: Income [0, 828] and private (828, 1200]';
				VAL_CHAR_3 = 0;
			END;
		ELSE  
			DO;
				DES_CHAR_3 = '01: Other';
				VAL_CHAR_3 = 341;
			END;
		/*************WTJPTT46: AREA CODE******************/
		CHAR_4 = 'AREA CODE';	

		IF 	KCODPT1 IN (48,20,01,39) THEN 
			DO;
				DES_CHAR_4 = '01: Basque Country and Cantabria';
				VAL_CHAR_4 = 863;
			END;
		ELSE IF KCODPT1 IN (8,17,25,43,51,52,7,35,38,0) THEN 
			DO;
				DES_CHAR_4 = '03: Catalonia, Galicia and Islands';
				VAL_CHAR_4 = 0;
			END;
		ELSE  
			DO;
				DES_CHAR_4 = '02: Other';
				VAL_CHAR_4 = 323;
			END;

		/*************WTJARE46: HOUSE AGE******************/
		CHAR_5 = 'RESIDENCE SENIORITY ';	

		IF 	(KANTRESI1 > 6 and KANTRESI1 < 99 ) THEN 
			DO;
				DES_CHAR_5 = '01: Residence Seniority (6,+]';
				VAL_CHAR_5 = 0;
			END;
		ELSE IF KANTRESI1 <= -6  THEN 
			DO;
				DES_CHAR_5= '02: Residence Seniority (6,+]';
				VAL_CHAR_5 = -240;
			END;
		ELSE  
			DO;
				DES_CHAR_5 = '02: Residence Seniority (6,+]';
				VAL_CHAR_5 = -240;
			END;

		/*************WTJRESI46: RESIDENCE TYPE******************/
		CHAR_6 = 'TYPE OF RESIDENCE ';	

		IF 	(SITHAB = 1) THEN 
			DO;
				DES_CHAR_6 = '01: House Owners';
				VAL_CHAR_6 = 245;
			END;
		ELSE  
			DO;
				DES_CHAR_6 = '02: Other Residence Types';
				VAL_CHAR_6 = 0;
			END;
		/*************WTJCOD46: WORK CONTRACT******************/
		CHAR_7 = 'TYPE OF CONTRACT';	

		IF 	(TEMPORAL = 'F') THEN 
			DO;
				DES_CHAR_7 = '01: Fixed contract';
				VAL_CHAR_7 = 215;
			END;
		ELSE  
			DO;
				DES_CHAR_7 = '02: Other';
				VAL_CHAR_7 = 0;
			END;
		/*************WTJPHONE46: CONTACT MODE******************/
		CHAR_8 = 'CONTACT MODE';	

		DES_CHAR_8 = '01: Land Line';
		VAL_CHAR_8 = 671;

		/*************WTJABCO46: BANK SENIORITY******************/
		CHAR_9 = 'CONTACT MODE';	

		IF 	KANTBCO <= 7 THEN 
			DO;
				DES_CHAR_9 = '03: <=7 year bank account';
				VAL_CHAR_9 = -370;
			END;
		ELSE  IF KANTBCO > 7 and KANTBCO <= 15 THEN
			DO;
				DES_CHAR_9 = '02: <= 15 years bank account';
				VAL_CHAR_9 = -290;
			END;
		ELSE IF KANTBCO > 15 THEN
			DO;
				DES_CHAR_9 = '01: > 15 years bank account';
				VAL_CHAR_9 = 0;
			END;
		ELSE 
			DO;
				DES_CHAR_9 = '03: <=7 year bank account';
				VAL_CHAR_9 = -370;
			END;
%mend;
%macro sque_granting;
		/***********************************constant************************************/
		B_DES_CHAR_0 = 'Constant';
		B_VAL_CHAR_0 = -1081.087552;

		/*****Drnr_24: Customer seniority * DR * NR a H24**************************************/
		B_CHAR_1 = 'DDRNR_24';	

		IF VAR1 = 1 THEN
			DO;
				B_DES_CHAR_1 = '01:reco=0; [36,+]; wpe24=0';
				B_VAL_CHAR_1 = 2660.6629324;
			END;
		ELSE IF VAR1 = 2 THEN
			DO;
				B_DES_CHAR_1 = '02:reco=0; ]12,36]; wpe24=0';
				B_VAL_CHAR_1 = 2411.0731698;
			END;
		ELSE IF VAR1 = 3 THEN
			DO;
				B_DES_CHAR_1 = '03:reco=0; [-,12]antig_cli; wpe24=0';
				B_VAL_CHAR_1 = 2172.756478;
			END;
		ELSE IF VAR1 = 4 THEN
			DO;
				B_DES_CHAR_1 = '04:reco=0; ]18,+]; wpe24>0';
				B_VAL_CHAR_1 = 1736.3128307;
			END;
		ELSE IF VAR1 = 5 THEN
			DO;
				B_DES_CHAR_1 = '05:reco=0; [-,18]antig_cli; wpe24>0';
				B_VAL_CHAR_1 = 1264.1654916;
			END;
		ELSE IF VAR1 = 6 THEN
			DO;
				B_DES_CHAR_1 = '06:[0,2]meses_reco';
				B_VAL_CHAR_1 = 1237.7784702;
			END;
		ELSE IF VAR1 = 7 THEN
			DO;
				B_DES_CHAR_1 = '07:]2,5]meses_reco';
				B_VAL_CHAR_1 = 588.10338663;
			END;
		ELSE IF VAR1 = 8 THEN
			DO;
				B_DES_CHAR_1 = '08:]5,+]meses_reco';
				B_VAL_CHAR_1 = 0;
			END;

		/*****Tod_deu: Outstanding * Debt *****************************************************/
		B_CHAR_2 = 'DTOD_DEU';	

		IF VAR2 = 1 THEN
			DO;
				B_DES_CHAR_2 = '01:[-,200]todu';
				B_VAL_CHAR_2 = 1914.4489046;
			END;
		ELSE IF VAR2 = 2 THEN
			DO;
				B_DES_CHAR_2 = '02:]200,450]todu; [-,0.36]deuda';
				B_VAL_CHAR_2 = 645.14958624;
			END;
		ELSE IF VAR2 = 3 THEN
			DO;
				B_DES_CHAR_2 = '03:]450,+]todu; [-,0.36]deuda';
				B_VAL_CHAR_2 = 557.89100188;
			END;
		ELSE IF VAR2 = 4 THEN
			DO;
				B_DES_CHAR_2 = '04:]0.36,0.6]deuda';
				B_VAL_CHAR_2 = 412.6420685;
			END;
		ELSE IF VAR2 = 5 THEN
			DO;
				B_DES_CHAR_2 = '05:]0.6,1]deuda';
				B_VAL_CHAR_2 = 265.53074097;
			END;
		ELSE IF VAR2 = 6 THEN
			DO;
				B_DES_CHAR_2 = '06:]1,+]deuda';
				B_VAL_CHAR_2 = 0;
			END;

		/*****Dant_cli: Customer seniority * number of contracts ********************************/
		B_CHAR_3 = 'Dant_cli';	

		IF VAR3 = 1 THEN
			DO;
				B_DES_CHAR_3 = '01:]72,+]antig; +1doss';
				B_VAL_CHAR_3 = 1169.769145;
			END;
		ELSE IF VAR3 = 2 THEN
			DO;
				B_DES_CHAR_3 = '02:]72,+]antig; 1doss';
				B_VAL_CHAR_3 = 798.83739548;
			END;
		ELSE IF VAR3 = 3 THEN
			DO;
				B_DES_CHAR_3 = '03: [-,72]antig; +1doss';
				B_VAL_CHAR_3 = 512.12910256;
			END;
		ELSE IF VAR3 = 4 THEN
			DO;
				B_DES_CHAR_3 = '04:[-,72]antig; 1doss';
				B_VAL_CHAR_3 = 0;
			END;

		/*************DEST_CIV: estado civil *******************/
		B_CHAR_4 = 'DEST_CIV';	

		IF VAR4 = 1 THEN
			DO;
				B_DES_CHAR_4 = '01:Casado';
				B_VAL_CHAR_4 = 581.76856567;
			END;
		ELSE IF VAR4 = 2 THEN
			DO;
				B_DES_CHAR_4 = '02:soltero-viudo';
				B_VAL_CHAR_4 = 70.949274581;
			END;
		ELSE IF VAR4 = 3 THEN
			DO;
				B_DES_CHAR_4 = '03:Divor-separado-concub-Resto';
				B_VAL_CHAR_4 = 0;
			END;

		/*****Dret_act: Monthly payment of delay *************************************************/
		B_CHAR_5 = 'Dret_act';	

		IF VAR5 = 1 THEN
			DO;
				B_DES_CHAR_5 = '01:retraso<1';
				B_VAL_CHAR_5 = 809.55675949;
			END;
		ELSE IF VAR5 = 2 THEN
			DO;
				B_DES_CHAR_5 = '02:retraso[1,1.5]';
				B_VAL_CHAR_5 = 578.6523763;
			END;
		ELSE IF VAR5 = 3 THEN
			DO;
				B_DES_CHAR_5 = '03:retraso>1.5mens';
				B_VAL_CHAR_5 = 0;
			END;

		/*****Danum_ap: Postponement * length contract ******************************************/
		B_CHAR_6 = 'Danum_ap';	

		IF VAR6 = 1 THEN
			DO;
				B_DES_CHAR_6 = '01:[-,0]aplazam; max_WPE06=0';
				B_VAL_CHAR_6 = 1060.3423104;
			END;
		ELSE IF VAR6 = 2 THEN
			DO;
				B_DES_CHAR_6 = '02:[-,0]aplazam; max_WPE06>0 o ]0,1]aplazam';
				B_VAL_CHAR_6 = 425.47069948;
			END;
		ELSE IF VAR6 = 3 THEN
			DO;
				B_DES_CHAR_6 = '03:]1,2]aplazam';
				B_VAL_CHAR_6 = 375.81225087;
			END;
		ELSE IF VAR6 = 4 THEN
			DO;
				B_DES_CHAR_6 = '04:]2,+]aplazam';
				B_VAL_CHAR_6 = 0;
			END;

		/*****DCVIVIEN: Housing code *************************************************************/
		B_CHAR_7 = 'Housing code';

		IF VAR7 = 1 THEN
			DO;
				B_DES_CHAR_7 = '01:Prop-Acceso prop';
				B_VAL_CHAR_7 = 706.34031977;
			END;
		ELSE IF VAR7 = 2 THEN
			DO;
				B_DES_CHAR_7 = '02:Familiar-Empresa';
				B_VAL_CHAR_7 = 696.94720119;
			END;
		ELSE IF VAR7 = 3 THEN
			DO;
				B_DES_CHAR_7 = '03:Alquiler-Resto';
				B_VAL_CHAR_7 = 0;
			END;

		/*****Dret_act: Monthly payment of delay *************************************************/
		B_CHAR_8 = 'Dmax_wnm: Monthly payment of delay';
		IF VAR8 = 1 THEN
			DO;
				B_DES_CHAR_8 = '01:[-,7]mens_pend';
				B_VAL_CHAR_8 = 749.8077109 ;
			END;
		ELSE IF VAR8 = 2 THEN
			DO;
				B_DES_CHAR_8 = '02:]7,+]mens_pend; 1 activ';
				B_VAL_CHAR_8 = 206.69920799;
			END;
		ELSE IF VAR8 = 3 THEN
			DO;
				B_DES_CHAR_8 = '03:]7,+]mens_pend; +1 activ';
				B_VAL_CHAR_8 = 0;
			END;

		/*************DSR_DRA: SR_SRA *******************/
		B_CHAR_9 = 'DSR_DRA';	

		IF VAR9 = 1 THEN
			DO;
				B_DES_CHAR_9 = '01:SRA';
				B_VAL_CHAR_9 = 205.85567175;
			END;
		ELSE IF VAR9 = 2 THEN
			DO;
				B_DES_CHAR_9 = '02:Resto';
				B_VAL_CHAR_9 = 0;
			END;
%mend;


/**Orange**/

%macro sc_portfolio_orange();

/***********************************Constant************************************/
	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 595;

	/*EDAD*/

	CHAR_1 = 'EDAD';

	IF EDAD <18 THEN
		DO;
			DES_CHAR_1 = 'Other';
			VAL_CHAR_1 = 3;	
		END;
	else if EDAD >= 18 AND EDAD <= 30 THEN
		DO;
			DES_CHAR_1 = '<= 30 años';
			VAL_CHAR_1 = -26;
		END; 
	ELSE IF EDAD <= 41 THEN
		DO;
			DES_CHAR_1 = '31 - 41 años';
			VAL_CHAR_1 = -12;
		END;
	ELSE IF EDAD <= 48 OR EDAD = -99 THEN
		DO;
			DES_CHAR_1 = '42 - 48 años. No info';
			VAL_CHAR_1 = 0;
		END;
	ELSE IF EDAD <= 58 THEN
		DO;
			DES_CHAR_1 = '49 - 58 años';
			VAL_CHAR_1 = 9;
		END;
	ELSE IF EDAD <= 67 THEN
		DO;
			DES_CHAR_1 = '59 - 67 años';
			VAL_CHAR_1 = 15;
		END;	
	ELSE IF EDAD > 67 THEN
		DO;
			DES_CHAR_1 = '68 - high';
			VAL_CHAR_1 = 22;
		END;
	ELSE	
		DO;
			DES_CHAR_1 = 'Other';
			VAL_CHAR_1 = 3;	
		END;

	/*TIPO DE DOCUMENTO*/

	CHAR_2 = 'TIPO DE DOCUMENTO';

	IF TIPODOCUM_ID = 2 THEN 
		DO;
			DES_CHAR_2 = 'NIF';
			VAL_CHAR_2 = 0;
		END;
	ELSE IF TIPODOCUM_ID IN (1,3,4,5) THEN 
		DO;
			DES_CHAR_2 = 'Resto';
			VAL_CHAR_2 = -25;					
		END;
	ELSE	
		DO;
			DES_CHAR_2 = 'Other';
			VAL_CHAR_2 = -3;		
		END;

	/*IMPORTE PAGADO BADEX*/

	CHAR_3 = 'IMPORTE PAGADO BADEX';

	IF DEUDA IN (.,0) THEN	
		DO;
			DES_CHAR_3 = 'No está en Bureau';
			VAL_CHAR_3 = 0;
		END;
	ELSE IF DEUDA >= 0.01 THEN	
		DO;
			DES_CHAR_3 = 'Está en Bureau';
			VAL_CHAR_3 = -52;
		END;
	ELSE	
		DO;
			DES_CHAR_3 = 'Other';
			VAL_CHAR_3 = -4;
		END;

	/*Ratio facturas con incidencia vs facturas pagadas Jazztel*/

	CHAR_4 = 'Ratio facturas con incidencia vs facturas pagadas Jazztel';

	IF RATFACINCFACPAG_NUM_J = . THEN
		DO;
			DES_CHAR_4 = 'Missing/Others';
			VAL_CHAR_4 = 0;	
		END;
	ELSE IF RATFACINCFACPAG_NUM_J < 0  THEN 
		DO;
			DES_CHAR_4 = '0.03-0.05, No cliente Jazztel';
			VAL_CHAR_4 = 0;	
		END;
	ELSE IF RATFACINCFACPAG_NUM_J >= 0 AND RATFACINCFACPAG_NUM_J <= 0.02 THEN
		DO;
			DES_CHAR_4 = '<=0.02';
			VAL_CHAR_4 = 24;
		END;
	ELSE IF RATFACINCFACPAG_NUM_J <= 0.05 THEN
		DO;
			DES_CHAR_4 = '0.03-0.05, No cliente Jazztel';
			VAL_CHAR_4 = 0;					
		END;
	ELSE 
		DO;
			DES_CHAR_4 = '>0.05';
			VAL_CHAR_4 = -36;					
		END;

	IF RATFACPAGNUNMINC = . THEN RATFACPAGNUNMINC = round(NUMINCIDPAGO_NUM /NUMFACTURASPAG_NUM, .01);

	/*Ratio facturas con incidencia vs facturas pagadas Orange*/

	CHAR_5 = 'Ratio facturas con incidencia vs facturas pagadas Orange';

	IF RATFACPAGNUNMINC < 0 THEN 
		DO;
			DES_CHAR_5 = 'OTHER';
			VAL_CHAR_5 = 10;	
		END;
	ELSE IF RATFACPAGNUNMINC >= 0 AND RATFACPAGNUNMINC <= 0.02 THEN 
		DO;
			DES_CHAR_5 = '<=0.02';
			VAL_CHAR_5 = 30;	
		END;
	ELSE IF RATFACPAGNUNMINC <= 0.05 THEN
		DO;
			DES_CHAR_5 = '0.03-0.05';
			VAL_CHAR_5 = 9;
		END;
	ELSE IF RATFACPAGNUNMINC <= 0.15 or RATFACPAGNUNMINC = . THEN
		DO;
			DES_CHAR_5 = '0.06-0.15';
			VAL_CHAR_5 = 0;					
		END;
	ELSE IF RATFACPAGNUNMINC <= 0.35 THEN
		DO;
			DES_CHAR_5 = '0.16-0.35';
			VAL_CHAR_5 = -17;					
		END;
	ELSE 
		DO;
			DES_CHAR_5 = '>0.35';
			VAL_CHAR_5 = -53;					
		END;

	/*2.2.6 Antigüedad de cliente*/

	CHAR_6 = 'Antigüedad de cliente';
	IF ANTIGCLI = . THEN
		DO;
			DES_CHAR_6 = '36 – 65 meses, No info';
			VAL_CHAR_6 = 0;
		END;
	ELSE IF ANTIGCLI >= 0 AND ANTIGCLI <= 9 THEN
		DO;
			DES_CHAR_6 = '<=9 meses';
			VAL_CHAR_6 = -32;
		END;
	ELSE IF ANTIGCLI <= 22 THEN
		DO;
			DES_CHAR_6 = '10 – 22 meses';
			VAL_CHAR_6 = -19;
		END;
	ELSE IF ANTIGCLI <= 35 THEN
		DO;
			DES_CHAR_6 = '23 – 35 meses';
			VAL_CHAR_6 = -10;
		END;
	ELSE IF ANTIGCLI <= 65 THEN
		DO;
			DES_CHAR_6 = '36 – 65 meses, No info';
			VAL_CHAR_6 = 0;
		END;
	ELSE IF ANTIGCLI <= 96 THEN
		DO;
			DES_CHAR_6 = '66 – 96 meses';
			VAL_CHAR_6 = 8;
		END;
	ELSE IF ANTIGCLI <= 168 THEN
		DO;
			DES_CHAR_6 = '97 – 168 meses';
			VAL_CHAR_6 = 20;
		END;
	ELSE IF ANTIGCLI > 168 THEN
		DO;
			DES_CHAR_6 = '>168 meses';
			VAL_CHAR_6 = 30;
		END;
	ELSE 
		DO;
			DES_CHAR_6 = 'Other';
			VAL_CHAR_6 = 4;
		END;
%mend;

%macro sc_portfolio_jazztel();

/***********************************Constant************************************/
	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 654;

	/*Antigüedad de cliente*/
	CHAR_1 = 'Antigüedad de cliente';

	IF ANTIGCLI = . AND ANTIGCLI < 4 THEN
		DO;
			DES_CHAR_1 = 'Missing/Other';
			VAL_CHAR_1 = 5;
		END;
	ELSE IF ANTIGCLI >= 4 AND ANTIGCLI <= 10 THEN
		DO;
			DES_CHAR_1 = '4 - 10 meses';
			VAL_CHAR_1 = -27;
		END;
	ELSE IF ANTIGCLI <= 18 THEN
		DO;
			DES_CHAR_1 = '11 - 18 meses';
			VAL_CHAR_1 = -12;
		END;
	ELSE IF ANTIGCLI <= 42 THEN
		DO;
			DES_CHAR_1 = '19 - 42 meses';
			VAL_CHAR_1 = 0;
		END;
	ELSE IF ANTIGCLI <= 53 THEN
		DO;
			DES_CHAR_1 = '43 - 53 meses';
			VAL_CHAR_1 = 11;
		END;
	ELSE IF ANTIGCLI <= 69 THEN
		DO;
			DES_CHAR_1 = '54 - 69 meses';
			VAL_CHAR_1 = 14;
		END;
	ELSE IF ANTIGCLI <= 84 THEN
		DO;
			DES_CHAR_1 = '70 - 84 meses';
			VAL_CHAR_1 = 23;
		END;
	ELSE 
		DO;
			DES_CHAR_1 = '85 - High';
			VAL_CHAR_1 = 31;
		END;

	/*TIPO DE DOCUMENTO*/

	CHAR_2 = 'TIPO DE DOCUMENTO';

	IF TIPODOCUM_ID = 2 THEN 
		DO;
			DES_CHAR_2 = 'NIF';
			VAL_CHAR_2 = 0;
		END;
	ELSE IF TIPODOCUM_ID IN (1,4,5) THEN 
		DO;
			DES_CHAR_2 = 'Resto';
			VAL_CHAR_2 = -48;					
		END;
	ELSE
		DO;
			DES_CHAR_2 = 'Missing/Others';
			VAL_CHAR_2 = 0;					
		END;

	/*Nº Facturas con Incidencia de Pago  */

	CHAR_3 = 'N Facturas con Incidencia de Pago';

	IF NUMINCIDPAGO_NUM < 0 OR NUMINCIDPAGO_NUM = . THEN
		DO;
			DES_CHAR_3 = 'Missing/Others';
			VAL_CHAR_3 = -5;
		END;
	ELSE IF NUMINCIDPAGO_NUM >= 0 AND NUMINCIDPAGO_NUM <=1 THEN
		DO;
			DES_CHAR_3 = 'No cliente Orange, 0 - 1 incidencias';
			VAL_CHAR_3 = 0;					
		END;
	ELSE IF NUMINCIDPAGO_NUM <= 3 THEN
		DO;
			DES_CHAR_3 = '2 - 3 incidencias';
			VAL_CHAR_3 = -16;					
		END;
	ELSE IF NUMINCIDPAGO_NUM <= 7 THEN
		DO;
			DES_CHAR_3 = '4 - 7 incidencias';
			VAL_CHAR_3 = -27;					
		END;
	ELSE IF NUMINCIDPAGO_NUM > 7 THEN
		DO;
			DES_CHAR_3 = '8 - HIGH';
			VAL_CHAR_3 = -34;					
		END;

	/*N FACTURAS PAGADAS ORANGE*/

	CHAR_4 = 'N FACTURAS PAGADAS ORANGE';

	IF NUMFACTURASPAG_NUM < 0 OR NUMFACTURASPAG_NUM = . THEN
		DO;
			DES_CHAR_4 = 'Missing/Others';
			VAL_CHAR_4 = 6;
		END;
	ELSE IF NUMFACTURASPAG_NUM >= 1 AND NUMFACTURASPAG_NUM <=12 THEN
		DO;
			DES_CHAR_4 = '1 - 12 facturas pagadas';
			VAL_CHAR_4 = -3;					
		END;
	ELSE IF NUMFACTURASPAG_NUM <= 24 OR NUMFACTURASPAG_NUM = 0 THEN
		DO;
			DES_CHAR_4 = 'No cliente Orange, 13 - 24 facturas pagadas';
			VAL_CHAR_4 = 0;					
		END;
	ELSE IF NUMFACTURASPAG_NUM <= 48 THEN
		DO;
			DES_CHAR_4 = '25 - 48 facturas pagadas';
			VAL_CHAR_4 = 16;					
		END;
	ELSE IF NUMFACTURASPAG_NUM <= 90 THEN
		DO;
			DES_CHAR_4 = '49 - 90 facturas pagadas';
			VAL_CHAR_4 = 23;					
		END;
	ELSE 
		DO;
			DES_CHAR_4 = '> 90 facturas pagadas';
			VAL_CHAR_4 = 32;					
		END;

	/*Nº Facturas devueltas Jazztel*/

	CHAR_5 = 'N Facturas devueltas Jazztel';

	IF NUMFACTURASDEV_NUM_J < 0 OR NUMFACTURASDEV_NUM_J = . THEN
		DO;
			DES_CHAR_5 = 'Missing/Others';
			VAL_CHAR_5 = -15;
		END;
	ELSE IF NUMFACTURASDEV_NUM_J >= 0 AND NUMFACTURASDEV_NUM_J <=1 THEN
		DO;
			DES_CHAR_5 = '0 - 1 facturas devueltas';
			VAL_CHAR_5 = 0;					
		END;
	ELSE IF NUMFACTURASDEV_NUM_J <= 3 OR NUMFACTURASDEV_NUM_J = 0 THEN
		DO;
			DES_CHAR_5 = '2 - 3 facturas devueltas';
			VAL_CHAR_5 = -31;					
		END;
	ELSE IF NUMFACTURASDEV_NUM_J <= 8 THEN
		DO;
			DES_CHAR_5 = '4 - 8 facturas devueltas';
			VAL_CHAR_5 = -48;					
		END;
	ELSE 
		DO;
			DES_CHAR_5 = '> 8 facturas devueltas';
			VAL_CHAR_5 = -75;					
		END;

	/*Nº Facturas emitidas Jazztel*/

	CHAR_6 = 'N Facturas emitidas Jazztel';

	IF NUMFACTURASEMIT_NUM_J < 0 OR NUMFACTURASEMIT_NUM_J = . THEN
		DO;
			DES_CHAR_6 = 'Missing/Others';
			VAL_CHAR_6 = 0;
		END;
	ELSE IF NUMFACTURASEMIT_NUM_J >= 0 AND NUMFACTURASEMIT_NUM_J <=10 THEN
		DO;
			DES_CHAR_6 = '1 - 10 facturas emitidas';
			VAL_CHAR_6 = -27;					
		END;
	ELSE IF NUMFACTURASEMIT_NUM_J <= 20 OR NUMFACTURASEMIT_NUM_J = 0 THEN
		DO;
			DES_CHAR_6 = '11 - 20 facturas emitidas';
			VAL_CHAR_6 = -20;					
		END;
	ELSE IF NUMFACTURASEMIT_NUM_J <= 30 THEN
		DO;
			DES_CHAR_6 = '21 - 30 facturas emitidas';
			VAL_CHAR_6 = -9;					
		END;
	ELSE IF NUMFACTURASEMIT_NUM_J <= 55 THEN
		DO;
			DES_CHAR_6 = '31 - 55 facturas emitidas';
			VAL_CHAR_6 = 0;					
		END;
	ELSE IF NUMFACTURASEMIT_NUM_J <= 72 THEN
		DO;
			DES_CHAR_6 = '56 - 72 facturas emitidas';
			VAL_CHAR_6 = 8;					
		END;
	ELSE IF NUMFACTURASEMIT_NUM_J <= 90 THEN
		DO;
			DES_CHAR_6 = '73 - 90 facturas emitidas';
			VAL_CHAR_6 = 11;					
		END;
	ELSE 
		DO;
			DES_CHAR_6 = '> 90 facturas emitidas';
			VAL_CHAR_6 = 14;					
		END;
%mend;
%macro sc_cliente_nuevo_empresa_orange();
/***********************************Constant************************************/
	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 542;

	/*Interconexiones*/
	CHAR_1 = 'Interconexiones';

	IF INTERCONEXIONES IN (0,.) THEN 
		DO;
			DES_CHAR_1 = 'No tiene interconexión';
			VAL_CHAR_1 = 0;		
		END;
	ELSE IF INTERCONEXIONES = 1 THEN
		DO;
			DES_CHAR_1 = 'Tiene interconexión';
			VAL_CHAR_1 = 9;	
		END;
	ELSE 
		DO;
			DES_CHAR_1 = 'Other';
			VAL_CHAR_1 = 4;	
		END;

	/*Tipo de documento Administrador*/	

	CHAR_2 = 'Tipo de documento Administrador';

	IF tipodocum_admin1 IN (2,9,.) THEN
		DO;
			DES_CHAR_2 = 'NIF';
			VAL_CHAR_2 = 0;				
		END;
	ELSE IF tipodocum_admin1 IN (1,3,4,5) THEN
		DO;
			DES_CHAR_2 = 'Resto';
			VAL_CHAR_2 = -15;				
		END;
	ELSE
		DO;
			DES_CHAR_2 = 'Other';
			VAL_CHAR_2 = -2;	
		END;

	/*Máxima facturación media mensual Orange*/

	CHAR_3 = 'Máxima facturación media mensual Orange';

	IF MAXMONTHLYAVGETURNOVER = -99 THEN
		DO;
			DES_CHAR_3 = 'No cliente Orange, <=50€';
			VAL_CHAR_3 = 0;
		END;
	ELSE IF MAXMONTHLYAVGETURNOVER = -99999.9999 THEN
		DO;
			DES_CHAR_3 = 'No cliente Orange, <=50€';
			VAL_CHAR_3 = 0;
		END;
	ELSE IF MAXMONTHLYAVGETURNOVER <=50 THEN
		DO;
			DES_CHAR_3 = 'No cliente Orange, <=50€';
			VAL_CHAR_3 = 0;
		END;
	ELSE IF MAXMONTHLYAVGETURNOVER > 50 AND MAXMONTHLYAVGETURNOVER <=120 THEN
		DO;
			DES_CHAR_3 = '50,01-120€';
			VAL_CHAR_3 = 17;
		END;
	ELSE IF MAXMONTHLYAVGETURNOVER > 120 THEN
		DO;
			DES_CHAR_3 = '>120';
			VAL_CHAR_3 = 30;
		END;

	/*Perfil administrador*/

	CHAR_4 = 'Perfil administrador';

	IF PERCENTIL_ADMIN = . THEN
		DO;
			DES_CHAR_4 = 'Other';
			VAL_CHAR_4 = 4;
		END;
	ELSE IF PERCENTIL_ADMIN GE 0 AND PERCENTIL_ADMIN LE 30 THEN
		DO;
			DES_CHAR_4 = '<=30';
			VAL_CHAR_4 = -38;
		END;
	ELSE IF PERCENTIL_ADMIN LE 50 OR PERCENTIL_ADMIN = -99 THEN
		DO;
			DES_CHAR_4 = 'No info. 31-50';
			VAL_CHAR_4 = 0;
		END;
	ELSE IF PERCENTIL_ADMIN LE 75 THEN
		DO;
			DES_CHAR_4 = '51-75';
			VAL_CHAR_4 = 6;
		END;
	ELSE IF PERCENTIL_ADMIN LE 90 THEN
		DO;
			DES_CHAR_4 = '76-90';
			VAL_CHAR_4 = 12;
		END;
	ELSE IF PERCENTIL_ADMIN LE 99 THEN
		DO;
			DES_CHAR_4 = '>90';
			VAL_CHAR_4 = 20;
		END;

	/*Crédito Informa*/

	CHAR_5 = 'Crédito Informa';

	IF 		INDACCESOINFORMA = . 	THEN B20CREDITO_NUM2 = -777777;
	ELSE IF INDACCESOINFORMA = 0 	THEN B20CREDITO_NUM2 = -888888;
	ELSE IF INDACCESOINFORMA = 1 	THEN B20CREDITO_NUM2 = B20CREDITO_NUM;

	IF B20CREDITO_NUM2 = . THEN 
		DO;
			DES_CHAR_5 = 'No info, No Informa, No llamada, <=1000';
			VAL_CHAR_5 = 0;

		END;
	ELSE IF B20CREDITO_NUM2 <= 1000 THEN 
		DO;
			DES_CHAR_5 = 'No info, No Informa, No llamada, <=1000';
			VAL_CHAR_5 = 0;
		END;
	ELSE IF B20CREDITO_NUM2 <= 7000 THEN 
		DO;
			DES_CHAR_5 = '2000-7000';
			VAL_CHAR_5 = 13;
		END;
	ELSE IF B20CREDITO_NUM2 > 7000 THEN
		DO;
			DES_CHAR_5 = '>7000';
			VAL_CHAR_5 = 27;
		END;
	ELSE
		DO;
			DES_CHAR_5 = 'Other';
			VAL_CHAR_5 = 10;
		END;

	/*Antigüedad de la empresa*/

	CHAR_6 = 'Antigüedad de la empresa';

	IF 		INDACCESOINFORMA = . 	THEN ANTIGEMPRESA_NUM2 = -777777;
	ELSE IF INDACCESOINFORMA = 0 	THEN ANTIGEMPRESA_NUM2 = -888888;
	ELSE IF INDACCESOINFORMA = 1 	THEN ANTIGEMPRESA_NUM2 = ANTIGEMPRESA_NUM;

	IF ANTIGEMPRESA_NUM2 = . THEN 
		DO;
			DES_CHAR_6 = 'Other';
			VAL_CHAR_6 = 2;
		END;
	ELSE IF ANTIGEMPRESA_NUM2 >= 0 AND ANTIGEMPRESA_NUM2 <= 48 THEN 
		DO;
			DES_CHAR_6 = '<= 48 meses';
			VAL_CHAR_6 = -6;
		END;
	ELSE IF ANTIGEMPRESA_NUM2 <= 120 or ANTIGEMPRESA_NUM2 < 0  THEN 
		DO;
			DES_CHAR_6 = 'No info, No Informa, No llamada, 49-120 meses';
			VAL_CHAR_6 = 0;
		END;
	ELSE 
		DO;
			DES_CHAR_6 = '> 120';
			VAL_CHAR_6 = 9;
		END;

	/*Número de empleados*/

	CHAR_6 = 'Antigüedad de la empresa';

	IF 		INDACCESOINFORMA = . 	THEN EMPLEADOS_NUM2 = -777777;
	ELSE IF INDACCESOINFORMA = 0 	THEN EMPLEADOS_NUM2 = -888888;
	ELSE IF INDACCESOINFORMA = 1 	THEN EMPLEADOS_NUM2 = EMPLEADOS_NUM;

	IF EMPLEADOS_NUM2 = . THEN 
		DO;
			DES_CHAR_7 = 'No info, No Informa, No llamada, Sin empleados';
			VAL_CHAR_7 = 0;
		END;
	ELSE IF EMPLEADOS_NUM2 >= 1 and EMPLEADOS_NUM2 <= 3 THEN 
		DO;
			DES_CHAR_7 = '1-3 empleados';
			VAL_CHAR_7 = 5;
		END;
	ELSE IF EMPLEADOS_NUM2 > 3 THEN
		DO;
			DES_CHAR_7 = '> 3';
			VAL_CHAR_7 = 11;
		END;
	ELSE 
		DO;
			DES_CHAR_7 = 'No info, No Informa, No llamada, Sin empleados';
			VAL_CHAR_7 = 0;
		END;

%mend;

%macro sc_cl_nuevo_empresa_orange_d4b();
/***********************************Constant************************************/
	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 561;

	/*Crédito Informa*/
	CHAR_1 = 'Crédito Informa';

	IF 		INDACCESOINFORMA = . 	THEN B20CREDITO_NUM2 = -777777;
	ELSE IF INDACCESOINFORMA = 0 	THEN B20CREDITO_NUM2 = -888888;
	ELSE IF INDACCESOINFORMA = 1 	THEN B20CREDITO_NUM2 = B20CREDITO_NUM;

	IF B20CREDITO_NUM2 = . THEN 
		DO;
			DES_CHAR_1 = 'No informa, No llamada, No info, 2000 - 6000';
			VAL_CHAR_1 = 0;
		END;
	ELSE IF B20CREDITO_NUM2 <= 2000 THEN 
		DO;
			DES_CHAR_1 = '<=2000';
			VAL_CHAR_1 = -10;
		END;
	ELSE IF B20CREDITO_NUM2 <= 6000 THEN 
		DO;
			DES_CHAR_1 = 'No informa, No llamada, No info, 2000 - 6000';
			VAL_CHAR_1 = 0;
		END;
	ELSE IF B20CREDITO_NUM2 > 6000 THEN
		DO;
			DES_CHAR_1 = '>6000';
			VAL_CHAR_1 = 9;
		END;
	ELSE
		DO;
			DES_CHAR_1 = 'Other';
			VAL_CHAR_1 = 0;
		END;

	/*Interconexiones*/
	CHAR_2 = 'Interconexiones';

	IF INTERCONEXIONES IN (0,.) THEN 
		DO;
			DES_CHAR_2 = 'No tiene interconexión';
			VAL_CHAR_2 = 0;		
		END;
	ELSE IF INTERCONEXIONES = 1 THEN
		DO;
			DES_CHAR_2 = 'Tiene interconexión';
			VAL_CHAR_2 = 7;	
		END;
	ELSE 
		DO;
			DES_CHAR_2 = 'Other';
			VAL_CHAR_2 = 3;	
		END;


	/*Tipo de documento Administrador*/	

	CHAR_3 = 'Tipo de documento Administrador';

	IF tipodocum_admin1 IN (2) THEN
		DO;
			DES_CHAR_3 = 'NIF';
			VAL_CHAR_3 = 0;				
		END;
	ELSE IF tipodocum_admin1 IN (1,3,4,5,9) THEN
		DO;
			DES_CHAR_3 = 'Resto';
			VAL_CHAR_3 = -12;				
		END;
	ELSE
		DO;
			DES_CHAR_3 = 'Other';
			VAL_CHAR_3 = 3;	
		END;

	/*2.2.4 Percentil Delphi for Business*/

	CHAR_4 = 'Percentil Delphi for Business';

	DES_CHAR_4 = 'Other';
	VAL_CHAR_4 = -3;

	IF PERCENTIL_D4B = . THEN
		DO;
			DES_CHAR_4 = '20-75, No info';
			VAL_CHAR_4 = 0;
		END;
	ELSE IF PERCENTIL_D4B >=1 AND PERCENTIL_D4B <=12 THEN
		DO;
			DES_CHAR_4 = '1-12';
			VAL_CHAR_4 = -42;
		END;

	ELSE IF PERCENTIL_D4B >=13 AND PERCENTIL_D4B <=19 THEN
		DO;
			DES_CHAR_4 = '13-19';
			VAL_CHAR_4 = -11;
		END;
	ELSE IF PERCENTIL_D4B >=20 AND PERCENTIL_D4B <=75 THEN
		DO;
			DES_CHAR_4 = '20-75, No info';
			VAL_CHAR_4 = 0;
		END;
	ELSE IF PERCENTIL_D4B >=76 AND PERCENTIL_D4B <=88 THEN
		DO;
			DES_CHAR_4 = '76-88';
			VAL_CHAR_4 = 8;
		END;
	ELSE IF PERCENTIL_D4B >=89 AND PERCENTIL_D4B <=100 THEN
		DO;
			DES_CHAR_4 = '89-100';
			VAL_CHAR_4 = 11;
		END;


	/*Perfil administrador*/

	CHAR_5 = 'Percentil administrador';


	DES_CHAR_5 = 'Other';
	VAL_CHAR_5 = 1;

	IF PERCENTIL_ADMIN = . THEN
		DO;
			DES_CHAR_5 = 'No Info.34-72';
			VAL_CHAR_5 = 0;
		END;
	ELSE IF PERCENTIL_ADMIN GE 0 AND PERCENTIL_ADMIN LE 10 THEN
		DO;
			DES_CHAR_5 = '0-10';
			VAL_CHAR_5 = -54;
		END;
	ELSE IF PERCENTIL_ADMIN LE 33 OR PERCENTIL_ADMIN = -99 THEN
		DO;
			DES_CHAR_5 = '11-33';
			VAL_CHAR_5 = -8;
		END;
	ELSE IF PERCENTIL_ADMIN LE 72 THEN
		DO;
			DES_CHAR_5 = 'No Info.34-72';
			VAL_CHAR_5 = 0;
		END;
	ELSE IF PERCENTIL_ADMIN LE 89 THEN
		DO;
			DES_CHAR_5 = '73-89';
			VAL_CHAR_5 = 8;
		END;
	ELSE IF PERCENTIL_ADMIN LE 99 THEN
		DO;
			DES_CHAR_5 = '90-99';
			VAL_CHAR_5 = 13;
		END;

	/*Antigüedad de la empresa*/

	CHAR_6 = 'Antigüedad de la empresa';

	IF 		INDACCESOINFORMA = . 	THEN ANTIGEMPRESA_NUM2 = -777777;
	ELSE IF INDACCESOINFORMA = 0 	THEN ANTIGEMPRESA_NUM2 = -888888;
	ELSE IF INDACCESOINFORMA = 1 	THEN ANTIGEMPRESA_NUM2 = ANTIGEMPRESA_NUM;

	DES_CHAR_6 = 'Other';
	VAL_CHAR_6 = 5;

	IF ANTIGEMPRESA_NUM2 >= 0 AND ANTIGEMPRESA_NUM2 <= 72 THEN 
		DO;
			DES_CHAR_6 = '0-72';
			VAL_CHAR_6 = -6;
		END;
	ELSE IF ANTIGEMPRESA_NUM2 <= 156 or ANTIGEMPRESA_NUM2 < 0  THEN 
		DO;
			DES_CHAR_6 = 'No info, No Informa, No llamada, 76-156 meses';
			VAL_CHAR_6 = 0;
		END;
	ELSE IF ANTIGEMPRESA_NUM2 > 156 THEN
		DO;
			DES_CHAR_6 = '> 156';
			VAL_CHAR_6 = 20;
		END;

	/*Número de empleados*/

	CHAR_7 = 'Número de empleados';

	IF 		INDACCESOINFORMA = . 	THEN EMPLEADOS_NUM2 = -777777;
	ELSE IF INDACCESOINFORMA = 0 	THEN EMPLEADOS_NUM2 = -888888;
	ELSE IF INDACCESOINFORMA = 1 	THEN EMPLEADOS_NUM2 = EMPLEADOS_NUM;

	IF EMPLEADOS_NUM2 = . OR (EMPLEADOS_NUM2 >= 1 and EMPLEADOS_NUM2 <= 3) THEN 
		DO;
			DES_CHAR_7 = 'Other';
			VAL_CHAR_7 = 9;
		END;
	ELSE IF EMPLEADOS_NUM2 > 3 THEN
		DO;
			DES_CHAR_7 = '>3 empleados';
			VAL_CHAR_7 = 28;
		END;
	ELSE 
		DO;
			DES_CHAR_7 = 'No info, No Informa, No llamada, <=3 empleados';
			VAL_CHAR_7 = 0;
		END;
%mend;

%macro sc_cliente_nuevo_pf_orange();

	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 563;

	/*EDAD*/
	CHAR_1 = 'EDAD';
	IF	EDAD = -99 THEN
		DO;
			DES_CHAR_1 = '39 – 46 años, No info';
			VAL_CHAR_1 = 0;
		END;
	ELSE IF EDAD >= 18 AND EDAD <= 25 THEN
		DO;
			DES_CHAR_1 = '<= 25 años';
			VAL_CHAR_1 = -47;
		END; 
	ELSE IF EDAD <= 33 THEN
		DO;
			DES_CHAR_1 = '26 - 33 años';
			VAL_CHAR_1 = -9;
		END;
	ELSE IF EDAD <= 38 THEN
		DO;
			DES_CHAR_1 = '33 - 38 años.';
			VAL_CHAR_1 = -4;
		END;
	ELSE IF EDAD <= 46 OR EDAD = -99 THEN
		DO;
			DES_CHAR_1 = '39 – 46 años, No info';
			VAL_CHAR_1 = 0;
		END;
	ELSE IF EDAD <= 54 THEN
		DO;
			DES_CHAR_1 = '47 - 54 años';
			VAL_CHAR_1 = 9;
		END;	
	ELSE IF EDAD <= 64 THEN
		DO;
			DES_CHAR_1 = '55 - 64 años';
			VAL_CHAR_1 = 11;
		END;
	ELSE IF EDAD >= 65 THEN
		DO;
			DES_CHAR_1 = '> 64 años';
			VAL_CHAR_1 = 14;
		END;
	ELSE	
		DO;
			DES_CHAR_1 = 'Other';
			VAL_CHAR_1 = 0;	
		END;

	/*Número de facturas devueltas de Jazztel*/

	CHAR_2 = 'Número de facturas devueltas de Jazztel';
	IF NUMFACTURASDEV_NUM_J = 0 THEN
		DO;
			DES_CHAR_2 = 'Sin facturas devueltas';
			VAL_CHAR_2 = 20;
		END;
	ELSE IF NUMFACTURASDEV_NUM_J <= 2 OR NUMFACTURASDEV_NUM_J = - 99 THEN
		DO;
			DES_CHAR_2 = 'No cliente Jazztel, 1-2 facturas devueltas';
			VAL_CHAR_2 = 0;
		END;
	ELSE IF NUMFACTURASDEV_NUM_J <= 8 THEN
		DO;
			DES_CHAR_2 = '3 – 8 facturas devueltas';
			VAL_CHAR_2 = -35;
		END;
	ELSE IF NUMFACTURASDEV_NUM_J > 8 THEN
		DO;
			DES_CHAR_2 = '9 - High';
			VAL_CHAR_2 = -49;
		END; 
	ELSE IF NUMFACTURASDEV_NUM_J < 0 OR NUMFACTURASDEV_NUM_J = . THEN
		DO;
			DES_CHAR_2 = 'Other';
			VAL_CHAR_2 = -2;
		END;
			
	/*Número de facturas pagadas de Jazztel*/

	CHAR_3 = 'Número de facturas pagadas de Jazztel';		
	IF NUMFACTURASPAG_NUM_J >= 0 AND NUMFACTURASPAG_NUM_J <= 18  THEN
		DO;
			DES_CHAR_3 = '<= 18 facturas pagadas';
			VAL_CHAR_3 = -21;
		END;
	ELSE IF NUMFACTURASPAG_NUM_J <= 36 OR NUMFACTURASPAG_NUM_J = - 99 THEN
		DO;
			DES_CHAR_3 = '19 - 36 facturas, No info';
			VAL_CHAR_3 = 0;
		END;
	ELSE IF NUMFACTURASPAG_NUM_J > 36 THEN
		DO;
			DES_CHAR_3 = '37 - high';
			VAL_CHAR_3 = 23;
		END;
	ELSE IF NUMFACTURASPAG_NUM_J < 0 OR NUMFACTURASPAG_NUM_J = . THEN
		DO;
			DES_CHAR_3 = 'Other';
			VAL_CHAR_3 = 2;
		END;

	/*Número de incidencias de pago de Orange*/
	CHAR_4 = 'Número de incidencias de pago de Orange';	
	IF NUMINCIDPAGO_NUM >= 0 AND NUMINCIDPAGO_NUM <= 1 OR NUMINCIDPAGO_NUM = -99 THEN
		DO;
			DES_CHAR_4 = 'No cliente de Orange, 0 – 1 incidencias';
			VAL_CHAR_4 = 0;
		END;
	ELSE IF NUMINCIDPAGO_NUM <= 7 THEN
		DO;
			DES_CHAR_4 = '2 - 7 incidencias';
			VAL_CHAR_4 = -46;					
		END; 
	ELSE IF NUMINCIDPAGO_NUM > 7 THEN
		DO;
			DES_CHAR_4 = '8 - high';
			VAL_CHAR_4 = -64;					
		END;
	ELSE		
		DO;
			DES_CHAR_4 = 'Missing/Others';
			VAL_CHAR_4 = -12;	
		END; 

	/*Número de facturas pagadas de Orange*/
	CHAR_5 = 'Número de facturas pagadas de Orange';			
	IF NUMFACTURASPAG_NUM > 0 AND NUMFACTURASPAG_NUM <= 10 THEN
		DO;
			DES_CHAR_5 = '1 – 10 facturas pagadas';
			VAL_CHAR_5 = -7;
		END;
	ELSE IF NUMFACTURASPAG_NUM <= 24 OR NUMFACTURASPAG_NUM = 0 THEN
		DO;
			DES_CHAR_5 = 'No cliente de Orange, 11-24 facturas pagadas';
			VAL_CHAR_5 = 0;
		END;
	ELSE IF NUMFACTURASPAG_NUM <= 48 THEN
		DO;
			DES_CHAR_5 = '25 – 48 facturas pagadas';
			VAL_CHAR_5 = 42;
		END;
	ELSE IF NUMFACTURASPAG_NUM <= 96 THEN
		DO;
			DES_CHAR_5 = '49 - 96 facturas pagadas';
			VAL_CHAR_5 = 56;
		END;
	ELSE IF NUMFACTURASPAG_NUM > 96 THEN
		DO;
			DES_CHAR_5 = '>	96 facturas pagadas';
			VAL_CHAR_5 = 69;
		END;
	ELSE IF NUMFACTURASPAG_NUM <= 0 OR NUMFACTURASPAG_NUM = . THEN
		DO;
			DES_CHAR_5 = 'Other';
			VAL_CHAR_5 = 15;
		END;

	/*Percentil (Delphi) */
	CHAR_6 = 'Percentil (Delphi)';
	IF CTI_BD_PERCENTIL >= 0 AND CTI_BD_PERCENTIL <= 6 THEN
		DO;
			DES_CHAR_6 = '<=6';
			VAL_CHAR_6 = -51;
		END;
	ELSE IF CTI_BD_PERCENTIL >= 0 AND CTI_BD_PERCENTIL <= 13 THEN
		DO;
			DES_CHAR_6 = '7-13';
			VAL_CHAR_6 = -46;
		END;
	ELSE IF CTI_BD_PERCENTIL >= 0 AND CTI_BD_PERCENTIL <= 30 THEN
		DO;
			DES_CHAR_6 = '14-30';
			VAL_CHAR_6 = -21;
		END;
	ELSE IF CTI_BD_PERCENTIL >= 0 AND CTI_BD_PERCENTIL <= 45 THEN
		DO;
			DES_CHAR_6 = '31-45';
			VAL_CHAR_6 = -11;
		END;
	ELSE IF CTI_BD_PERCENTIL >= 0 AND CTI_BD_PERCENTIL <= 69 OR CTI_BD_PERCENTIL in (-9999999,-99) THEN
		DO;
			DES_CHAR_6 = '46-69, No info';
			VAL_CHAR_6 = 0;
		END;
	ELSE IF CTI_BD_PERCENTIL >= 0 AND CTI_BD_PERCENTIL <= 75 THEN
		DO;
			DES_CHAR_6 = '70-75';
			VAL_CHAR_6 = 7;
		END;
	ELSE IF CTI_BD_PERCENTIL >= 0 AND CTI_BD_PERCENTIL <= 89 THEN
		DO;
			DES_CHAR_6 = '76-89';
			VAL_CHAR_6 = 12;
		END;
	ELSE IF CTI_BD_PERCENTIL >= 0 AND CTI_BD_PERCENTIL <= 95 THEN
		DO;
			DES_CHAR_6 = '90-95';
			VAL_CHAR_6 = 18;
		END;
	ELSE IF CTI_BD_PERCENTIL >= 0 AND CTI_BD_PERCENTIL <= 99 THEN
		DO;
			DES_CHAR_6 = '98-99';
			VAL_CHAR_6 = 25;
		END;
	ELSE	
		DO;
			DES_CHAR_6 = 'Other';
			VAL_CHAR_6 = 5;				
		END;

		/*MESES DESDE ULTIMA PORTABILIDAD*/
	CHAR_7 = 'MESES DESDE ULTIMA PORTABILIDAD';
	IF meses_ultima_porta = .  THEN
		DO;
			DES_CHAR_7 = '12 - 36 meses';
			VAL_CHAR_7 = 0;						
	END;
	ELSE IF MESES_ULTIMA_PORTA >= 0 AND MESES_ULTIMA_PORTA <= 1 THEN
		DO;
			DES_CHAR_7 = '<=1 mes';
			VAL_CHAR_7 = -31;						
		END;
	ELSE IF MESES_ULTIMA_PORTA <= 11 THEN
		DO;
			DES_CHAR_7 = '2 - 11 meses';
			VAL_CHAR_7 = -4;						
		END;
	ELSE IF MESES_ULTIMA_PORTA <= 36 OR MESES_ULTIMA_PORTA = . THEN
		DO;
			DES_CHAR_7 = '12 - 36 meses';
			VAL_CHAR_7 = 0;						
		END;
	ELSE IF MESES_ULTIMA_PORTA > 36 THEN
		DO;
			DES_CHAR_7 = '>36 meses';
			VAL_CHAR_7 = 38;						
		END;
	ELSE	
		DO;
			DES_CHAR_7 = 'Other';
			VAL_CHAR_7 = 8;
		END;
%mend;

%macro sc_portfolio_pj_orange();

	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 604;

	/*Antigüedad de la empresa*/
	CHAR_1 = 'Antigüedad de la empresa';
	IF 		INDACCESOINFORMA = . 	THEN ANTIGEMPRESA_NUM2 = -777777;
	ELSE IF INDACCESOINFORMA = 0 	THEN ANTIGEMPRESA_NUM2 = -888888;
	ELSE IF INDACCESOINFORMA = 1 	THEN ANTIGEMPRESA_NUM2 = ANTIGEMPRESA_NUM;

	IF ANTIGEMPRESA_NUM2 = . THEN 
		DO;
			DES_CHAR_1 = 'Other';
			VAL_CHAR_1 = 4;
		END;
	ELSE IF ANTIGEMPRESA_NUM2 > 0 AND ANTIGEMPRESA_NUM2 <= 84 THEN 
		DO;
			DES_CHAR_1 = '1 - 84 meses';
			VAL_CHAR_1 = -16;
		END;
	ELSE IF ANTIGEMPRESA_NUM2 <= 108 or ANTIGEMPRESA_NUM2 < 0  THEN 
		DO;
			DES_CHAR_1 = 'No info, No Informa, No llamada, 85-108 meses';
			VAL_CHAR_1 = 0;
		END;
	ELSE IF ANTIGEMPRESA_NUM2 <= 228  THEN 
		DO;
			DES_CHAR_1 = '109 - 228 meses';
			VAL_CHAR_1 = 12;
		END;
	ELSE 
		DO;
			DES_CHAR_1 = '229 - high';
			VAL_CHAR_1 = 19;
		END;

	/*Ratio de Liquidez*/
	CHAR_2 = 'Ratio de Liquidez';

	IF (RAT_LIQUIDEZ >= 0.0001 AND RAT_LIQUIDEZ <= 0.7) 
		OR (RAT_LIQUIDEZ GE -10 AND RAT_LIQUIDEZ LE -9)  THEN
		DO;
			DES_CHAR_2 = 'No llamada, No Informa, No info, 0 - 0,7';
			VAL_CHAR_2 = 0;
		END; 
	ELSE IF RAT_LIQUIDEZ >= 0.0001 AND RAT_LIQUIDEZ <= 1.2 THEN 
		DO;
			DES_CHAR_2 = '0,7001 - 1,2';
			VAL_CHAR_2 = 13;
		END;
	ELSE IF RAT_LIQUIDEZ > 1.2 THEN 
		DO;
			DES_CHAR_2 = '1.2001 - high';
			VAL_CHAR_2 = 23;
		END;
	ELSE 
		DO;
			DES_CHAR_2 = 'Other';
			VAL_CHAR_2 = 11;			
		END;

	/*Ratio de Endeudamiento*/
	CHAR_3 = 'Ratio de Endeudamiento';
	IF RAT_ENDEUDA LT 0 THEN 
		DO;
			DES_CHAR_3 = '> 0,74, No llamada, No Informa, No info';
			VAL_CHAR_3 = 0;	
		END;
	ELSE IF RAT_ENDEUDA LE 0.22 THEN
		DO;
			DES_CHAR_3 = '0-0.22';
			VAL_CHAR_3 = 20;				
		END;
	ELSE IF RAT_ENDEUDA LE 0.74 THEN
		DO;
			DES_CHAR_3 = '0,2201 - 0,74';
			VAL_CHAR_3 = 12;				
		END;
	ELSE IF RAT_ENDEUDA GT 0.74   THEN
		DO;
			DES_CHAR_3 = '> 0,74, No llamada, No Informa, No info';
			VAL_CHAR_3 = 0;				
		END;
	ELSE 
		DO;
			DES_CHAR_3 = 'Other';
			VAL_CHAR_3 = 5;				
		END;

	/*Antiguedad del cliente Orange*/
	CHAR_4 = 'Antiguedad del cliente Orange';
	IF ANTIGCLI GE 4 AND ANTIGCLI LE 9 THEN 
	 	DO;
			DES_CHAR_4 = '4 - 9 meses';
			VAL_CHAR_4 = -30;
		END;
	ELSE IF ANTIGCLI LE 21 THEN
		DO;
			DES_CHAR_4 = '10 - 21 meses';
			VAL_CHAR_4 = -19;
		END;
	ELSE IF ANTIGCLI LE 38 OR ANTIGCLI = -99 THEN
		DO;
			DES_CHAR_4 = 'No info, 22 - 38 meses';
			VAL_CHAR_4 = 0;
		END;
	ELSE IF ANTIGCLI LE 60 THEN
		DO;
			DES_CHAR_4 = '39 - 60 meses';
			VAL_CHAR_4 = 12;
		END;
	ELSE IF ANTIGCLI LE 78 THEN
		DO;
			DES_CHAR_4 = '61 - 78 meses';
			VAL_CHAR_4 = 25;
		END;
	ELSE IF ANTIGCLI GT 78 THEN
		DO;
			DES_CHAR_4 = '> 78 meses';
			VAL_CHAR_4 = 30;
		END;	
	ELSE	
		DO;
			DES_CHAR_4 = 'Other';
			VAL_CHAR_4 = 9;
		END;

	/* Numero de incidencias de pago*/

	CHAR_5 = 'Numero de incidencias de pago';

	IF NUMINCIDPAGO_NUM < 0 THEN
		DO;
			DES_CHAR_5 = 'Missing/Others';
			VAL_CHAR_5 = -14;
		END;
	ELSE IF NUMINCIDPAGO_NUM >= 0 AND NUMINCIDPAGO_NUM <= 1 THEN
		DO;
			DES_CHAR_5 = '<= 1 incidencias';
			VAL_CHAR_5 = 0;
		END;
	ELSE IF NUMINCIDPAGO_NUM <= 3 THEN
		DO;
			DES_CHAR_5 = '2 - 3 incidencias';
			VAL_CHAR_5 = -34;					
		END; 
	ELSE IF NUMINCIDPAGO_NUM <= 6 THEN
		DO;
			DES_CHAR_5 = '4 - 6 incidencias';
			VAL_CHAR_5 = -45;					
		END;
	ELSE IF NUMINCIDPAGO_NUM > 6 THEN
		DO;
			DES_CHAR_5 = '7 - high';
			VAL_CHAR_5 = -56;					
		END;
	ELSE		
		DO;
			DES_CHAR_5 = 'Missing/Others';
			VAL_CHAR_5 = -14;	
		END; 

	/*Importe impagado en Bureau de Experian*/

	CHAR_6 = 'Importe impagado en Bureau de Experian';

	IF DEUDA = 0 THEN 
		DO;
			DES_CHAR_6 = 'No está en Bureau';
			VAL_CHAR_6 = 0;
		END;
	ELSE IF DEUDA > 0 THEN
		DO;
			DES_CHAR_6 = '0.01-high';
			VAL_CHAR_6 = -71;
		END;
	ELSE 
		DO;
			DES_CHAR_6 = 'Missing/Others';
			VAL_CHAR_6 = -4;
		END;

%mend;

%macro mas_movil();

	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 578;

	/*TIPO DE DOCUMENTO*/

	CHAR_1 = 'TIPO DE DOCUMENTO';

	IF TIPODOCUM_ID = 2 THEN 
		DO;
			DES_CHAR_1 = '03:NIF';
			VAL_CHAR_1 = 0;
		END;
	ELSE IF TIPODOCUM_ID = 4 THEN 
		DO;
			DES_CHAR_1 = '01:Resto';
			VAL_CHAR_1 = -12;					
		END;
	ELSE	
		DO;
			DES_CHAR_1 = '02:Other';
			VAL_CHAR_1 = -2;		
		END;

	/*EDAD CLIENTE*/
	IF EDAD = . THEN 
		DO;
			DES_CHAR_2 = '03:40-58, No info';
			VAL_CHAR_2 = 0;
		END;
	ELSE IF EDAD <=18 THEN
		DO;
			DES_CHAR_2 = '04:Other';
			VAL_CHAR_2 = 1;		
		END;
	ELSE IF EDAD <=30 THEN 
		DO;
			DES_CHAR_2 = '01:18-30';
			VAL_CHAR_2 = -25;
		END;
	ELSE IF EDAD <=39 THEN
		DO;
			DES_CHAR_2 = '02:31-39';
			VAL_CHAR_2 = -16;
		END;
	ELSE IF EDAD <=58 THEN
		DO;
			DES_CHAR_2 = '03:40-58, No info';
			VAL_CHAR_2 = 0;
		END;
	ELSE IF EDAD <=65 THEN
		DO;
			DES_CHAR_2 = '05:59-65';
			VAL_CHAR_2 = 12;
		END;
	ELSE
		DO;
			DES_CHAR_2 = '06:66-HIGH';
			VAL_CHAR_2 = 22;
		END;	

	/*IMPORTE MEDIO DE LAS FACTURAS EN LOS ÚLTIMOS 6 MESES*/
	IF FACTURACIONMEDIAMENS_6M_MM = . THEN
		DO;
			DES_CHAR_3 = '03:30.0001-HIGH,NO INFO';
			VAL_CHAR_3 = 0;
		END;
	ELSE IF FACTURACIONMEDIAMENS_6M_MM < 0 THEN
		DO;
			DES_CHAR_3 = '02:Other';
			VAL_CHAR_3 = -1;
		END;
	ELSE IF FACTURACIONMEDIAMENS_6M_MM >= 0 AND FACTURACIONMEDIAMENS_6M_MM <=30 THEN
		DO;
			DES_CHAR_3 = '01:0-30';
			VAL_CHAR_3 = -19;
		END;
	ELSE 
		DO;
			DES_CHAR_3 = '03:30.0001-HIGH,NO INFO';
			VAL_CHAR_3 = 0;
		END;

	/*NUMERO FACTURAS DEVUELTAS ÚLTIMOS 12 MESES EN MAS MÓVIL*/

	IF NUMFACTURASDEV_NUM_12M_MM < 0 THEN
		DO;
			DES_CHAR_4 = '05:Other';
			VAL_CHAR_4 = -12;
		END; 
	ELSE IF NUMFACTURASDEV_NUM_12M_MM IN (0,.) THEN
		DO;
			DES_CHAR_4 = '06:0, No info';
			VAL_CHAR_4 = 0;
		END; 
	ELSE IF NUMFACTURASDEV_NUM_12M_MM = 1 THEN
		DO;
			DES_CHAR_4 = '04:1';
			VAL_CHAR_4 = -16;
		END; 	
	ELSE IF NUMFACTURASDEV_NUM_12M_MM <= 3 THEN
		DO;
			DES_CHAR_4 = '03:2-3';
			VAL_CHAR_4 = -24;
		END; 
	ELSE IF NUMFACTURASDEV_NUM_12M_MM <= 8 THEN
		DO;
			DES_CHAR_4 = '02:4-8';
			VAL_CHAR_4 = -44;
		END;  
	ELSE 
		DO;
			DES_CHAR_4 = '01:9-HIGH';
			VAL_CHAR_4 = -59;
		END; 

	/*Numero de facturas emitidas MM*/
	IF NUMFACTEMIT_NUM_MM <= 0 THEN
		DO;
			DES_CHAR_5 = '04:Other';
			VAL_CHAR_5 = 2;
		END;
	ELSE IF NUMFACTEMIT_NUM_MM >=	0 AND NUMFACTEMIT_NUM_MM > 6 THEN
		DO;
			DES_CHAR_5 = '01:< 6 facturas emitidas';
			VAL_CHAR_5 = -40;	
		END;
	ELSE IF NUMFACTEMIT_NUM_MM <= 10 THEN
		DO;
			DES_CHAR_5 = '02:6 - 10 facturas emitidas';
			VAL_CHAR_5 = -26;	
		END;
	ELSE IF NUMFACTEMIT_NUM_MM <= 24 THEN
		DO;
			DES_CHAR_5 = '03:11 - 24 facturas emitidas';
			VAL_CHAR_5 = 0;	
		END;
	ELSE 
		DO;
			DES_CHAR_5 = '05:> 24 facturas emitidas';
			VAL_CHAR_5 = 18;	
		END;

	/*RATIO DE FACTURAS DEVUELTAS ENTRE EMITIDAS EN MAS MÓVIL*/

	IF 		RATFACDEVFACTEMIT_NUM_MM < 0 THEN
		DO;
			DES_CHAR_6 = '05:Other';
			VAL_CHAR_6 = -16;
		END; 
	ELSE IF RATFACDEVFACTEMIT_NUM_MM LE 0.05 OR RATFACDEVFACTEMIT_NUM_MM = . THEN
		DO;
			DES_CHAR_6 = '06:0-0,05, No info';
			VAL_CHAR_6 = 0;
		END; 
	ELSE IF RATFACDEVFACTEMIT_NUM_MM LE 0.10 THEN
		DO;
			DES_CHAR_6 = '04:0,06-0,10';
			VAL_CHAR_6 = -30;
		END; 	
	ELSE IF RATFACDEVFACTEMIT_NUM_MM <= 0.15 THEN
		DO;
			DES_CHAR_6 = '03:0,11-0,15';
			VAL_CHAR_6 = -38;
		END; 
	ELSE IF RATFACDEVFACTEMIT_NUM_MM <= 0.60 THEN
		DO;
			DES_CHAR_6 = '02:0,16-0,60';
			VAL_CHAR_6 = -41;
		END;  
	ELSE 
		DO;
			DES_CHAR_6 = '01:0,61-high';
			VAL_CHAR_6 = -60;
		END; 
%mend;
%macro yoigo();

	DES_CHAR_0 = 'Constant';
	VAL_CHAR_0 = 614;

	/*TIPO DE DOCUMENTO*/

	CHAR_1 = 'TIPO DE DOCUMENTO';

	IF TIPODOCUM_ID = 2 THEN 
		DO;
			DES_CHAR_1 = '03:NIF';
			VAL_CHAR_1 = 0;
		END;
	ELSE IF TIPODOCUM_ID = 4 THEN 
		DO;
			DES_CHAR_1 = '01:Resto';
			VAL_CHAR_1 = -34;					
		END;
	ELSE	
		DO;
			DES_CHAR_1 = '02:Other';
			VAL_CHAR_1 = -4;		
		END;

	/*EDAD CLIENTE*/
	IF EDAD = . THEN 
		DO;
			DES_CHAR_2 = '05:46-53. No info';
			VAL_CHAR_2 = 0;
		END;
	ELSE IF EDAD <=18 THEN
		DO;
			DES_CHAR_2 = '04:Other';
			VAL_CHAR_2 = -4;		
		END;
	ELSE IF EDAD <=29 THEN 
		DO;
			DES_CHAR_2 = '01:Low-29';
			VAL_CHAR_2 = -32;
		END;
	ELSE IF EDAD <=35 THEN
		DO;
			DES_CHAR_2 = '02:30-35';
			VAL_CHAR_2 = -12;
		END;
	ELSE IF EDAD <=45 THEN
		DO;
			DES_CHAR_2 = '03:36-45';
			VAL_CHAR_2 = -8;
		END;
	ELSE IF EDAD <=53 THEN
		DO;
			DES_CHAR_2 = '05:46-53. No info';
			VAL_CHAR_2 = 0;
		END;
	ELSE
		DO;
			DES_CHAR_2 = '06:54-HIGH';
			VAL_CHAR_2 = 5;
		END;	

	/*ANTIGÜEDAD CLIENTE*/
	IF ANTIGCLI = . THEN
		DO;
			DES_CHAR_3 = '04:32-53, No info';
			VAL_CHAR_3 = 0;
		END;
	ELSE IF ANTIGCLI <  4 THEN
		DO;
			DES_CHAR_3 = '05:Other';
			VAL_CHAR_3 = 1;
		END;
	ELSE IF ANTIGCLI >= 4 AND ANTIGCLI <=12 THEN
		DO;
			DES_CHAR_3 = '01:4-12';
			VAL_CHAR_3 = -56;			
		END;
	ELSE IF ANTIGCLI <=22 THEN
		DO;
			DES_CHAR_3 = '02:13-22';
			VAL_CHAR_3 = -24;			
		END;
	ELSE IF ANTIGCLI <=31 THEN
		DO;
			DES_CHAR_3 = '03:23-31';
			VAL_CHAR_3 = -18;			
		END;
	ELSE IF ANTIGCLI <=53 THEN
		DO;
			DES_CHAR_3 = '04:32-53, No info';
			VAL_CHAR_3 = 0;			
		END;
	ELSE IF ANTIGCLI <=120 THEN
		DO;
			DES_CHAR_3 = '06:54-120';
			VAL_CHAR_3 = 15;			
		END;
	ELSE 
		DO;
			DES_CHAR_3 = '07:121-High';
			VAL_CHAR_3 = 22;			
		END;

	/*NUMERO FACTURAS DEVUELTAS ÚLTIMOS 12 MESES EN YOIGO*/

	IF NUMFACTURASDEV_NUM_12M_Y < 0 THEN
		DO;
			DES_CHAR_4 = '04:Other';
			VAL_CHAR_4 = -6;
		END; 
	ELSE IF NUMFACTURASDEV_NUM_12M_Y IN (0,.) THEN
		DO;
			DES_CHAR_4 = '05:0, No info';
			VAL_CHAR_4 = 0;
		END; 
	ELSE IF NUMFACTURASDEV_NUM_12M_Y = 1 THEN
		DO;
			DES_CHAR_4 = '03:1';
			VAL_CHAR_4 = -19;
		END; 	
	ELSE IF NUMFACTURASDEV_NUM_12M_Y <= 4 THEN
		DO;
			DES_CHAR_4 = '02:2-4';
			VAL_CHAR_4 = -26;
		END; 
	ELSE 
		DO;
			DES_CHAR_4 = '01:5-HIGH';
			VAL_CHAR_4 = -43;
		END; 

	/*RATIO DE FACTURAS DEVUELTAS ENTRE EMITIDAS EN MAS MÓVIL*/

	IF 		RATFACDEVFACTEMIT_NUM_Y < 0 THEN
		DO;
			DES_CHAR_5 = '04:Other';
			VAL_CHAR_5 = -8;
		END; 
	ELSE IF RATFACDEVFACTEMIT_NUM_Y LE 0.04 OR RATFACDEVFACTEMIT_NUM_Y = . THEN
		DO;
			DES_CHAR_5 = '05:0-0,05, No info';
			VAL_CHAR_5 = 0;
		END; 

	ELSE IF RATFACDEVFACTEMIT_NUM_Y <= 0.15 THEN
		DO;
			DES_CHAR_5 = '03:0,05-0,15';
			VAL_CHAR_5 = -24;
		END; 
	ELSE IF RATFACDEVFACTEMIT_NUM_Y <= 0.40 THEN
		DO;
			DES_CHAR_5 = '02:0,16-0,40';
			VAL_CHAR_5 = -38;
		END;  
	ELSE 
		DO;
			DES_CHAR_5 = '01:0,41-high';
			VAL_CHAR_5 = -52;
		END; 
%mend;

