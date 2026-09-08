/*************************************** NDOD info *************************************/
data sm_tmp.ndod_flg_npe_OSP;
	format mis_date ddmmyy10. account_id 14.;
	set r_nd2.ND_OUTPUT(keep=contract date_base flg_npe litigation_status);
	account_id = input(contract, 14.);
	mis_date = intnx('month',datepart(date_base),0,'b');
	/*if mis_date ge &init_date. /*and (flg_npe=1 or litigation_status=1)*/;	
run;
proc sql;
    create table sm_tmp.osp_ndod_monthly as
    select account_id, mis_date,
           max(input(flg_npe,1.)) as flg_npe,
           max(input(litigation_status,1.)) as litigation_status
    from sm_tmp.ndod_flg_npe_OSP
    where substr(contract,1,3)='202'
    group by account_id, mis_date;
quit;
proc sort data=sm_tmp.osp_ndod_monthly;
by account_id mis_date;
run;

data sm_tmp.ndod_flg_npe_OSP_END;
	set sm_tmp.osp_ndod_monthly;
	by account_id mis_date;

	retain max_npe 0 flg_ctx 0;

	if first.account_id then do;
		max_npe=max(0, flg_npe);
		flg_ctx=litigation_status;
	end;

	else do;
		max_npe=max(max_npe, flg_npe);
		flg_ctx =max(flg_ctx, litigation_status);
	end;
run;
