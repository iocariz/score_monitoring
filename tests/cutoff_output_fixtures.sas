/* Exercise the actual cutoff writer, including the existing OA_AMT collision. */
%let sm_cutoffs_reset_flags=Y;
data sm_tmp.base_cutoffs_medidas;
    length chaine $8 segment_cut_off $500 product_type_1-product_type_3 $50
        rf_business_name a_business_name ext_business_name vendedor_cadena_top_name
        vendedor_cadena_name $100 company $20 reject_reason $64
        se_decision_id $2 status_name $12 fuera_norma $1 nature_holder $20;
    mis_date='01JAN2024'd; company='CETELEM'; status_name='Booked';
    score_rf=500; risk_score_rf=50; scrplust1=50; acct_booked_h0=1;
    oa_amt_h0=100; income_T1T2_m=1000; early_bad=0;
    todu_30ever_h3=0; todu_amt_pile_h3=100; h_den_h3=100; h_num_h3=0;
    todu_30ever_h6=0; todu_amt_pile_h6=90; h_den_h6=90; h_num_h6=0;
    %sm_cutoff_scenario;
    m_ct_sc_direct_finto25='Y';
    /* OA_AMT is a different, pre-existing derived value on purpose. */
    oa_amt=999; oa_amt_cma=1234; CLASIFICACION_DATE=.; todu_h0=77;
    authorization_id=1; account_id=1; product_type_1='Direct'; segment_cut_off='direct/new'; output;
    authorization_id=2; account_id=2; product_type_1='Cards'; segment_cut_off='cards'; output;
    authorization_id=3; account_id=3; product_type_1='Auto';
    segment_cut_off='auto/caravan'; CLASIFICACION_DATE='01MAR2024'd; output;
run;
%let sm_cutoffs_reset_flags=N;
%include "&sm_code_dir./macros/cutoff_outputs.sas";
%expect_equal(%sm_nobs(sm_tmp.out_cutoffs),3,All cutoff output rows retained);
%expect_equal(%sm_nobs(sm_tmp.out_cutoffs_direct),1,Direct cutoff population retained);
%expect_equal(%sm_nobs(sm_tmp.out_caravanas),1,Caravan cutoff population retained);
data work.cutoff_writer_failures;
    set sm_tmp.out_cutoffs;
    if oa_amt ne 1234 or m_ct_sc_direct_finto25 ne 'Y' then output;
    if account_id=2 and oa_amt_h0 ne 77 then output;
    if account_id=3 and fraud_flag ne 'Y' then output;
    if account_id in (1,2) and fraud_flag ne 'N' then output;
run;
%expect_equal(%sm_nobs(work.cutoff_writer_failures),0,
    Existing amount collision card H0 fraud flags and observed policy values);
%let sm_cutoffs_reset_flags=Y;
%include "&sm_code_dir./macros/cutoff_outputs.sas";
data work.cutoff_scenario_failures;
    set sm_tmp.out_cutoffs(in=a) sm_tmp.out_caravanas(in=b);
    if a and m_ct_sc_direct_finto25 ne 'N' then output;
    if b and m_ct_sc_direct_finto25 ne 'Y' then output;
run;
%expect_equal(%sm_nobs(work.cutoff_scenario_failures),0,
    Actual cutoff writer resets scenario flags but preserves caravan flags);
%let sm_cutoffs_reset_flags=N;
