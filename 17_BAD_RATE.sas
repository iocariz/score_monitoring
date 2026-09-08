data sm_tmp.perfo(compress=&sm_compress);
    length company $20 table $10;
	set r_bau.h_loan_account_booked_perfo_sum (keep=month_date_txt account_id ind_30ever_H6 todu_30ever_h6 todu_amt_pile_H6 todu_30ever_h3 todu_amt_pile_H3 oa_amt_h0  rename=(oa_amt_h0=oa_amt_cma_h0) in=a)
		r_bau.h_card_account_booked_perfo_sum( keep=month_date_txt account_id ind_30ever_H6 todu_30ever_h6 todu_amt_pile_H6 todu_30ever_h3 todu_amt_pile_H3 todu_h0 cma_h0 	   rename=(cma_h0=oa_amt_cma_h0) 	in=b)
		r_bau8.h_loan_account_booked_perfo_sum(keep=month_date_txt account_id ind_30ever_H6 todu_30ever_h6 todu_amt_pile_H6 todu_30ever_h3 todu_amt_pile_H3 oa_amt_h0  rename=(oa_amt_h0=oa_amt_cma_h0) in=c)
		r_bau8.h_card_account_booked_perfo_sum(keep=month_date_txt account_id ind_30ever_H6 todu_30ever_h6 todu_amt_pile_H6 todu_30ever_h3 todu_amt_pile_H3 todu_h0 cma_h0 	   rename=(cma_h0=oa_amt_cma_h0) 	in=d)
		r_bau6.h_loan_account_booked_perfo_sum(keep=month_date_txt account_id ind_30ever_H6 todu_30ever_h6 todu_amt_pile_H6 todu_30ever_h3 todu_amt_pile_H3 oa_amt_h0  rename=(oa_amt_h0=oa_amt_cma_h0) in=e)
		r_bau6.h_card_account_booked_perfo_sum(keep=month_date_txt account_id ind_30ever_H6 todu_30ever_h6 todu_amt_pile_H6 todu_30ever_h3 todu_amt_pile_H3 todu_h0 cma_h0 	   rename=(cma_h0=oa_amt_cma_h0) 	in=f)
		r_bau2.h_loan_account_booked_perfo_sum(keep=month_date_txt account_id ind_30ever_H6 todu_30ever_h6 todu_amt_pile_H6 todu_30ever_h3 todu_amt_pile_H3 oa_amt_h0  rename=(oa_amt_h0=oa_amt_cma_h0) in=g)
		;

		if a then table = 'CTLM-LOAN';
		else if b then table = 'CTLM-CARD';
		else if c then table = 'CMC-LOAN';
		else if d then table = 'CMC-CARD';
		else if e then table = 'XFR-LOAN';
		else if f then table = 'XFR-CARD';
		else if g then table = 'OSP-LOANS';
            if a or b then company='CETELEM';
            else if c or d then company='CMC';
            else if e or f then company='XFR';
            else company='OSP';
            if not missing(account_id);
run;

data sm_tmp.fraud_perfo_ns(rename=(ind_60ever=ind_60ever_H3));
    length company $20;
	set r_bau.h_loan_account_booked_perfo (keep=account_id ind_60ever horizon)
		r_bau.h_card_account_booked_perfo (keep=account_id ind_60ever horizon);
	where horizon = 3 and not missing(account_id);
    company='CETELEM';
run;

%sm_assert_unique(data=sm_tmp.perfo, keys=company account_id,
                  out=sm_tmp.qa_perfo_duplicates);
%sm_assert_unique(data=sm_tmp.fraud_perfo_ns, keys=company account_id,
                  out=sm_tmp.qa_fraud_perfo_duplicates);
%sm_quarter_lookup(data=sm_tmp.sm_app_index, out=work.sm_quarters);
proc datasets lib=sm_tmp nolist;
    modify perfo;
    index create sm_perfo_key=(company account_id) / unique;
quit;
%sm_check_step(Performance lookup preparation);

/* A single consumer (step 18) materializes this view and its narrow outputs. */
data sm_tmp.sm_final_v / view=sm_tmp.sm_final_v;
    length company $20 quarter $10 materiality_cat segment_1-segment_4 $50;
    if _n_=1 then do;
        if 0 then set sm_tmp.fraud_perfo_ns(keep=ind_60ever_H3)
                      work.sm_quarters(keep=full_quarter);
        declare hash hc(dataset:'sm_tmp.fraud_perfo_ns');
        hc.defineKey('company','account_id');
        hc.defineData('ind_60ever_H3');
        if hc.defineDone() ne 0 then abort cancel;
        declare hash hq(dataset:'work.sm_quarters');
        hq.defineKey('quarter');
        hq.defineData('full_quarter');
        if hq.defineDone() ne 0 then abort cancel;
    end;
    set sm_tmp.demand_prf_char_RF;
    set sm_tmp.perfo(keep=company account_id month_date_txt todu_30ever_h6
        todu_amt_pile_H6 todu_30ever_h3 todu_amt_pile_H3 oa_amt_cma_h0 ind_30ever_H6)
        key=sm_perfo_key / unique;
    sm_perfo_match=(_IORC_=0);
    if _IORC_=%sysrc(_DSENOM) then do;
        _ERROR_=0;
        call missing(month_date_txt,todu_30ever_h6,todu_amt_pile_H6,
                     todu_30ever_h3,todu_amt_pile_H3,oa_amt_cma_h0,ind_30ever_H6);
    end;
    else if _IORC_ ne 0 then do;
        put 'ERROR: SM_CHECK: Performance index failure ' _IORC_=;
        abort cancel;
    end;
    sm_fraud_perfo_match=(hc.find()=0);
    if not sm_fraud_perfo_match then call missing(ind_60ever_H3);
    %include "&sm_code_dir./macros/finalize_row.sas";
    if hq.find() ne 0 then do;
        put 'ERROR: SM_CHECK: Missing quarter lookup ' quarter=;
        abort cancel;
    end;
run;
