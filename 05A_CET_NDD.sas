/* This file was empty in the supplied source. Do not invent a CET contract
   prefix. Set sm_cet_contract_prefix to the approved ND_OUTPUT prefix to rebuild;
   otherwise require and validate the existing monthly CET NPE table. */
%sm_default(sm_cet_contract_prefix, );
%macro sm_cet_ndd;
%if %length(%superq(sm_cet_contract_prefix))=0 %then %do;
    %put WARNING: SM_CHECK: CET NPE refresh skipped because no approved prefix was configured.;
    %sm_require(data=sm_tmp.ndod_flg_npe_CET_END, vars=account_orig mis_date max_npe);
    %sm_assert_unique(data=sm_tmp.ndod_flg_npe_CET_END, keys=account_orig mis_date,
                      out=sm_tmp.qa_cet_npe_duplicates);
    %return;
%end;
/*************************************** NDOD info *************************************/
proc sql;
create table 	sm_tmp.ndod_flg_npe_CET_TPT as
	select		a.*, 
				coalesce(b.account_id_tj,a.account_id) as account_orig format=14.
	from		sm_tmp.ndod_flg_npe(where=(substr(contract,1,%length(&sm_cet_contract_prefix))="&sm_cet_contract_prefix")) as a
	left join	SM_TMP.TPT_CARD_CET as b
	on 			a.account_id=b.account_id_tpt;
quit;

proc sql;
	create table sm_tmp.ndod_flg_npe_CET_TPT2 as 
		select	account_orig, 
				mis_date,
				max(input(flg_npe,1.)) as flg_npe,
				max(input(litigation_status,1.)) as litigation_status
		from 	sm_tmp.ndod_flg_npe_CET_TPT 
		group by 1,2;
quit;

proc sort data=sm_tmp.ndod_flg_npe_CET_TPT2;
by account_orig mis_date;
run;

data sm_tmp.ndod_flg_npe_CET_END;
	set sm_tmp.ndod_flg_npe_CET_TPT2;
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

%sm_check_step(CET monthly NPE);
%mend;
%sm_cet_ndd;
