/* Included by run_tests.sas; exercise the ACTUAL indexed performance join/view. */
libname r_bau "%sysfunc(pathname(work))/r_bau";
libname r_bau8 "%sysfunc(pathname(work))/r_bau8";
libname r_bau6 "%sysfunc(pathname(work))/r_bau6";
libname r_bau2 "%sysfunc(pathname(work))/r_bau2";
%macro empty_perfo(lib);
    data &lib..h_loan_account_booked_perfo_sum
         &lib..h_card_account_booked_perfo_sum;
        length month_date_txt $7 account_id ind_30ever_h6 todu_30ever_h6
            todu_amt_pile_h6 todu_30ever_h3 todu_amt_pile_h3
            oa_amt_h0 cma_h0 todu_h0 8;
        stop;
    run;
%mend;
%empty_perfo(r_bau);
%empty_perfo(r_bau8);
%empty_perfo(r_bau6);
%empty_perfo(r_bau2);
data r_bau.h_loan_account_booked_perfo_sum;
    if 0 then set r_bau.h_loan_account_booked_perfo_sum;
    account_id=42; ind_30ever_h6=1; todu_30ever_h6=25;
    todu_amt_pile_h6=100; oa_amt_h0=100; month_date_txt='JAN2024';
run;
data r_bau8.h_loan_account_booked_perfo_sum;
    if 0 then set r_bau8.h_loan_account_booked_perfo_sum;
    account_id=42; ind_30ever_h6=0; todu_30ever_h6=0;
    todu_amt_pile_h6=200; oa_amt_h0=200; month_date_txt='JAN2024';
run;
data r_bau.h_loan_account_booked_perfo;
    account_id=42; horizon=3; ind_60ever=1;
run;
data r_bau.h_card_account_booked_perfo;
    if 0 then set r_bau.h_loan_account_booked_perfo;
    stop;
run;
data sm_tmp.demand_prf_char_RF;
    length company $20 status_name $12 f_model_id $16 PAGADO_EVITADO $8
        vendedor_cadena_top_name rf_business_name $100 DTRT $8
        product_type_1-product_type_3 $50 SE_Decision_id $2 reject_reason $30;
    mis_date='01JAN2024'd; status_name='Booked';
    product_type_1='Direct'; product_type_2='Known'; product_type_3='Gold';
    f_model_id=''; fnact1=1; DTRT='20240131'; ZFRAUDSCR=0;
    vendedor_cadena_top_name='Other'; SE_Decision_id='OK'; ko_score=0;
    score_RF=400; scrplust1=60; acct_booked_h6=1; acct_booked_h12=1;
    company='CETELEM'; authorization_id=1; account_id=42; basel_default_h12=1; output;
    company='CMC'; authorization_id=1; basel_default_h12=0; output;
    /* A failed index/hash lookup immediately after successful lookups. */
    company='XFR'; authorization_id=2; account_id=44;
    acct_booked_h6=0; acct_booked_h12=0; output;
    company='CETELEM'; f_model_id='ESPF0001V00'; PAGADO_EVITADO='PAGADO';
    do authorization_id=50 to 54;
        account_id=authorization_id;
        select(authorization_id);
            when(50) CLASIFICACION_DATE='01DEC2023'd;
            when(51) CLASIFICACION_DATE=.;
            when(52) CLASIFICACION_DATE='01JAN2024'd;
            when(53) CLASIFICACION_DATE='01JUL2024'd;
            when(54) CLASIFICACION_DATE='01AUG2024'd;
        end;
        output;
    end;
run;
data sm_tmp.sm_app_index;
    set sm_tmp.demand_prf_char_RF(keep=company authorization_id account_id mis_date status_name);
run;
%include "&sm_code_dir./17_BAD_RATE.sas";
data work.test_final_rows;
    set sm_tmp.sm_final_v;
run;
%expect_equal(%sm_nobs(work.test_final_rows),8,Final view preserves row count);
data work.finalization_failures;
    set work.test_final_rows;
    if company='CETELEM' and account_id=42 then do;
        if early_bad ne 1 or basel_bad ne 1 or ind_60ever_H3 ne 1
           or sm_perfo_match ne 1 or early_observed ne 1 then output;
    end;
    if company='CMC' and account_id=42 then do;
        if early_bad ne 0 or basel_bad ne 0 or not missing(ind_60ever_H3)
           or oa_amt_cma_h0 ne 200 or early_observed ne 1 then output;
    end;
    if account_id=44 then do;
        if not missing(early_bad) or not missing(basel_bad)
           or not missing(todu_amt_pile_h6) or not missing(ind_60ever_H3)
           or sm_perfo_match ne 0 or early_observed ne 0 or basel_observed ne 0 then output;
    end;
    if account_id in (50,51,54) and fraude_pagado ne 0 then output;
    if account_id in (52,53) and fraude_pagado ne 1 then output;
    if company ne 'CETELEM' and not missing(segment_4) then output;
run;
%expect_equal(%sm_nobs(work.finalization_failures),0,
    Company-safe indexed joins missing lookup resets maturity and fraud date boundaries);
