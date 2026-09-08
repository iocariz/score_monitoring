/* Shared production writer, also exercised by the SAS cutoff fixtures. */
data sm_tmp.out_cutoffs(compress=&sm_compress keep=mis_date chaine segment_cut_off product_type_1 product_type_2 product_type_3
    authorization_id account_id rf_business_name a_business_name ext_business_name
    company reject_reason se_decision_id status_name risk_score_rf score_rf fuera_norma
    vendedor_cadena_top_name income_T1T2_m acct_booked_h0 oa_amt_h0 oa_amt
    todu_30ever_h3 todu_amt_pile_h3 h_den_H3 h_num_H3 todu_30ever_h6
    h_den_H6 h_num_H6 todu_amt_pile_h6 m_ct_: fraud_flag nature_holder early_bad)
     sm_tmp.out_cutoffs_direct(compress=&sm_compress keep=mis_date chaine segment_cut_off product_type_1 product_type_2 product_type_3
    authorization_id account_id rf_business_name a_business_name ext_business_name
    company reject_reason se_decision_id status_name risk_score_rf score_rf fuera_norma
    vendedor_cadena_top_name income_T1T2_m acct_booked_h0 oa_amt_h0 oa_amt
    todu_30ever_h3 todu_amt_pile_h3 h_den_H3 h_num_H3 todu_30ever_h6
    h_den_H6 h_num_H6 todu_amt_pile_h6 m_ct_: fraud_flag nature_holder early_bad)
     sm_tmp.out_caravanas(compress=&sm_compress keep=mis_date chaine segment_cut_off product_type_1 product_type_2 product_type_3
    authorization_id account_id rf_business_name a_business_name ext_business_name
    company reject_reason se_decision_id status_name risk_score_rf score_rf fuera_norma
    vendedor_cadena_top_name income_T1T2_m acct_booked_h0 oa_amt_h0 oa_amt
    todu_30ever_h3 todu_amt_pile_h3 h_den_H3 h_num_H3 todu_30ever_h6
    h_den_H6 h_num_H6 todu_amt_pile_h6 m_ct_: fraud_flag nature_holder early_bad scrplust1 vendedor_cadena_name);
    /* Preserve the export's explicit OA_AMT_CMA source. The segmentation
       step also creates OA_AMT; remove it before renaming the export value. */
    set sm_tmp.base_cutoffs_medidas(drop=oa_amt rename=(oa_amt_cma=oa_amt));
    if product_type_1='Cards' and status_name='Booked' then oa_amt_h0=todu_h0;
    if not missing(CLASIFICACION_DATE) then fraud_flag='Y'; else fraud_flag='N';
    /* Caravan retains observed flags even in the optional counterfactual mode. */
    if segment_cut_off='auto/caravan' then output sm_tmp.out_caravanas;
    %sm_cutoff_scenario;
    output sm_tmp.out_cutoffs;
    if product_type_1='Direct' and segment_cut_off ne 'sin definir'
       and risk_score_rf >= 0 and score_rf >= 0 then output sm_tmp.out_cutoffs_direct;
run;
%sm_check_step(Cutoff outputs);
