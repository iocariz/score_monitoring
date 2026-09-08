/*************************************** NDOD info *************************************/
data sm_tmp.ndod_flg_npe(where=(mis_date ge '01JAN2021'D));
	format mis_date ddmmyy10. account_id 14.;
	set R_ND.ND_OUTPUT(keep=contract date_base flg_npe litigation_status);
	account_id = input(contract, 14.);
	mis_date = intnx('month',datepart(date_base),0,'b');
	
	/*if mis_date ge &init_date. /*and (flg_npe=1 or litigation_status=1)*/;	
run;

