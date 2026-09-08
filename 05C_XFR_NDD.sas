/*************************************** NDOD info *************************************/
proc sql;
create table 	sm_tmp.ndod_flg_npe_XFR_TPT as
	select		a.*, 
				coalesce(b.account_id_tj,a.account_id) as account_orig format=14.
	from		sm_tmp.ndod_flg_npe(where=(substr(contract,1,3)='600')) as a
	left join	SM_TMP.TPT_CARD_XFR as b
	on 			a.account_id=b.account_id_tpt;
quit;

proc sql;
	create table sm_tmp.ndod_flg_npe_XFR_TPT2 as 
		select	account_orig, 
				mis_date,
				max(input(flg_npe,1.)) as flg_npe,
				max(input(litigation_status,1.)) as litigation_status
		from 	sm_tmp.ndod_flg_npe_XFR_TPT 
		group by 1,2;
quit;

proc sort data=sm_tmp.ndod_flg_npe_XFR_TPT2;
by account_orig mis_date;
run;

data sm_tmp.ndod_flg_npe_XFR_END;
	set sm_tmp.ndod_flg_npe_XFR_TPT2;
	by account_orig mis_date;

	retain max_npe 0 flg_ctx 0;

	if first.account_orig then do;
		max_npe=max(0, flg_npe);
		flg_ctx=litigation_status;
	end;

	else do;
		max_npe=max(max_npe, flg_npe);
		flg_ctx =max(flg_ctx, litigation_status);
	end;
run;