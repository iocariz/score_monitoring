/* Keep lists shared by the final writer and its narrow consumers. */
%let sm_cpcr_vars=authorization_id a_business_name ext_business_name nature_holder zxnota
    zxscore company acct_booked_H0 todu_30ever_h6 todu_amt_pile_h6
    CLASIFICACION_DATE mis_date oa_amt_cma mdeccent product_type_1-product_type_3
    red rf_business_name score_rf se_decision_id segment_1-segment_4 status_name
    valid_call vendedor_cadena_top_name ZRF1SCORE pltbc1 ML_SCORE_P0 scrplust1;
%let sm_cutoffs_vars=OBT1 TCOCARTGRT1 TCOPUNTUGRT1 TCOCLIT1 a_business_name ext_business_name rf_business_name scrplust1 zxscore zxnota score_rf reject_reason valid_call chaine zdispo basel_bad early_bad 
					CLASIFICACION_DATE company mis_date open_date decision_date status_app_id entry_date due_date_1st status_name account_id customer_id  authorization_id 
					product_type_1-product_type_4 product_code: flag_tpt red_name scrv_customer_init SCRV_customer_Group_init vendedor_: tenor_init oa_amt_cma 
					fuera_norma csector mdeccent file_id product_core TIN installment_amt_init material: origen_name nature_holder se_decision_id rvivoact numvdr risk_score_rf cagence
					income_T1T2_m MSAL1 MSAL2 sitfam oa_amt_h0 acct_booked_h0 todu_30ever_h6 todu_amt_pile_h6 todu_30ever_h3 todu_amt_pile_h3 nature_holder;
%let sm_report_vars=mis_date company red_name product_type_1-product_type_3 segment_1-segment_4
    vendedor_cadena_id vendedor_id vendedor_grupo_id vendedor_union_id
    vendedor_sector_id rf_business_name status_name risk_level CLASIFICACION_DATE
    product_code_3 acct_booked_h0 oa_amt_cma early_bad basel_bad score_rf
    valid_score_RF scrplust1 valid_efx ind_rl_high ind_known_Fmas ind_known
    todu_30ever_h6 todu_amt_pile_h6 valid_call acct_booked_h6 acct_booked_h12
    early_observed basel_observed;
