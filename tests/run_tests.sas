/* SAS 9.4 executable fixtures. All libraries point inside this session's WORK.
   Run from the repository: sas -sysin tests/run_tests.sas -log tests/sas-tests.log
   Or set sm_code_dir before %INCLUDE in Enterprise Guide. No Oracle access. */
%macro sm_test_bootstrap;
    %if not %symexist(sm_code_dir) %then %do;
        %global sm_code_dir; %let sm_code_dir=.;
    %end;
%mend;
%sm_test_bootstrap;
%include "&sm_code_dir./macros/validation.sas";
%include "&sm_code_dir./macros/kpi.sas";
%include "&sm_code_dir./macros/harmonized_performance.sas";
%include "&sm_code_dir./macros/fraud.sas";
%include "&sm_code_dir./macros/osp_identity.sas";
%include "&sm_code_dir./macros/cutoff_scenario.sas";
options dlcreatedir fullstimer;
libname sm_tmp "%sysfunc(pathname(work))/sm_tmp";
libname sm_bk "%sysfunc(pathname(work))/sm_bk";
libname sm "%sysfunc(pathname(work))/sm";
%let sm_compress=no;
%global sm_test_count;
%let sm_test_count=0;

%macro expect_equal(actual, expected, label);
    %if not %sysevalf(&actual=&expected,boolean) %then %do;
        %put ERROR: TEST_FAIL &label: actual=&actual expected=&expected;
        %abort cancel;
    %end;
    %let sm_test_count=%eval(&sm_test_count+1);
    %put NOTE: TEST_PASS &label;
%mend;

%macro compare_fixture(base=, actual=, keys=, vars=, label=);
    %local compare_rc;
    proc sort data=&base(keep=&keys &vars) out=work.test_expected;
        by &keys;
    run;
    proc sort data=&actual(keep=&keys &vars) out=work.test_actual;
        by &keys;
    run;
    proc compare base=work.test_expected compare=work.test_actual
                 method=absolute criterion=1e-12 noprint;
        id &keys;
        var &vars;
    run;
    %let compare_rc=&sysinfo;
    %expect_equal(&compare_rc,0,&label);
%mend;

/* Mature -> immature catches retained H12 leakage; interior gaps must stay gaps. */
data work.history;
    length status_name $12 ind_ctx_sold $1;
    input account_id mis_date :date9. prf_date :date9. oa_amt todu max_npe ind_ctx_sold $;
    status_name='Booked';
    datalines;
1 01JAN2024 01JAN2024 200 200 0 N
1 01JAN2024 01JUL2024 200 160 0 N
1 01JAN2024 01JAN2025 200 120 0 N
2 01FEB2025 01FEB2025 1000 1000 0 N
2 01FEB2025 01MAY2025 1000 900 0 N
3 01JAN2024 01JAN2024 100 100 0 Y
3 01JAN2024 01APR2024 100 50 0 Y
4 01JAN2024 01JAN2024 300 300 0 N
4 01JAN2024 01AUG2024 300 200 0 N
4 01JAN2024 01FEB2025 300 100 0 N
;
run;
%sm_rollup_kpi(data=work.history,out=work.kpi,asof='01SEP2025'd,company=CETELEM);
data work.expected_kpi;
    if 0 then set work.kpi;
    input account_id acct_booked_h6 acct_booked_h12 todu_h6 todu_h12
          basel_default_h6 basel_default_h12;
    datalines;
1 1 1 160 120 0 0
2 1 0 900 0 0 0
3 1 1 50 50 1 1
4 0 0 0 0 0 0
;
run;
%compare_fixture(base=work.expected_kpi, actual=work.kpi, keys=account_id,
    vars=acct_booked_h6 acct_booked_h12 todu_h6 todu_h12 basel_default_h6 basel_default_h12,
    label=KPI horizons maturity sold-account carry and interior gaps);

data work.history_unbooked;
    set work.history;
    status_name='Canceled';
run;
%sm_rollup_kpi(data=work.history_unbooked,out=work.kpi_booked_only,
               asof='01SEP2025'd,company=CMC,booked_only=Y);
%expect_equal(%sm_nobs(work.kpi_booked_only),0,Booked-only KPI populations exclude canceled accounts);
%sm_rollup_kpi(data=work.history_unbooked,out=work.kpi_all_status,
               asof='01SEP2025'd,company=XFR,booked_only=N);
%expect_equal(%sm_nobs(work.kpi_all_status),4,XFR preserves its original all-status KPI rule);

/* Both source types must supply an H6 numerator AND a denominator. */
data work.loan_harm;
    input account_id mis_date horizon todu_30ever todu_90ever todu;
    datalines;
1 24000 3 10 2 100
1 24000 6 20 8 90
;
run;
data work.card_harm;
    input account_id mis_date horizon todu_30ever todu_90ever todu;
    datalines;
2 24000 3 30 3 200
2 24000 6 40 15 180
;
run;
%sm_harmonized_performance(loan=work.loan_harm,card=work.card_harm,
                          out3=work.h3,out6=work.h6);
data work.expected_h6;
    if 0 then set work.h6;
    input account_id h_num_h6 h_den_h6;
    datalines;
1 8 90
2 15 180
;
run;
%compare_fixture(base=work.expected_h6,actual=work.h6,keys=account_id,
                 vars=h_num_h6 h_den_h6,label=Loan and card H6 layout);
data work.expected_h3;
    if 0 then set work.h3;
    input account_id h_num_h3 h_den_h3;
    datalines;
1 10 100
2 30 200
;
run;
%compare_fixture(base=work.expected_h3,actual=work.h3,keys=account_id,
                 vars=h_num_h3 h_den_h3,label=Loan and card H3 layout);

/* Quarter completeness counts distinct months globally; repeated rows don't add months. */
data work.dates;
    input mis_date :date9.;
    datalines;
01JAN2024
01JAN2024
01FEB2024
01MAR2024
01APR2024
01MAY2024
;
run;
%sm_quarter_lookup(data=work.dates,out=work.quarters);
data work.expected_quarters;
    if 0 then set work.quarters;
    quarter=put('01JAN2024'd,yyq10.); full_quarter=1; output;
    quarter=put('01APR2024'd,yyq10.); full_quarter=0; output;
run;
%compare_fixture(base=work.expected_quarters,actual=work.quarters,keys=quarter,
                 vars=full_quarter,label=Quarter distinct months);

/* The actual step 16: group medians, mean imputation, composite hash keys,
   failed lookups after successful lookups, native overrides and a risk boundary. */
data sm_tmp.demand_prf_char;
    length company $20 a_business_name ext_business_name $100
           product_type_1-product_type_3 $50 SCRV_customer_Group_init $30
           red_name $20 ZXSCORE $8;
    mis_date='01JAN2024'd; score=400; zxnota=400; scrplust1=88;
    SCRV_customer_Group_init='New'; red_name='DIRECT'; ZXSCORE='5';
    F_DECILE_DEMAND=5; product_type_1='Direct'; product_type_2='Loan';
    product_type_3='A'; ML_SCORE_P0=.; company='CETELEM';
    a_business_name='A-Score DIRECT 2024';
    ext_business_name='Equifax Risk Score - Direct CTLM';
    do authorization_id=10 to 12; output; end;
    product_type_3='B';
    do authorization_id=13 to 14; output; end;
    company='CMC'; ext_business_name='Equifax Risk Score - Direct CMC';
    a_business_name='A-Score DIRECT ML CMC'; product_type_3='A';
    ML_SCORE_P0=0; authorization_id=20; output;
    authorization_id=21; output;
    ML_SCORE_P0=0.9; authorization_id=22; output;
    company='CETELEM'; a_business_name='A-Score DIRECT 2024';
    ext_business_name='Equifax Risk Score V3 - Direct CTLM';
    authorization_id=30; output;
    company='XFR'; a_business_name=''; ext_business_name='';
    authorization_id=31; output;
    company='CETELEM'; a_business_name='A-Score DISTRIB Retail Traditional CTLM';
    authorization_id=40; ML_SCORE_P0=0.9654058; output;
    authorization_id=41; ML_SCORE_P0=0.9654060; output;
run;
data sm_tmp.sm_score_lookup_input;
    set sm_tmp.demand_prf_char(keep=company authorization_id mis_date ext_business_name
        ML_SCORE_P0 product_type_1 product_type_2 product_type_3);
run;
data sm_tmp.sm_app_index;
    set sm_tmp.demand_prf_char(keep=company authorization_id mis_date);
run;
data sm_bk.ml_rf_mi;
    length company $20;
    input company $ authorization_id ML_SCORE_P0_RF;
    datalines;
CETELEM 10 0.55
CMC 10 0.99
CMC 30 0.77
;
run;
data sm_tmp.RETROFIT_DIRECT_CMC_SCORED;
    input authorization_id score_RF;
    datalines;
20 0.2
22 0.4
;
run;
data sm_bk.new_efx_base;
    length company $20;
    input company $ authorization_id riskv3;
    datalines;
CETELEM 10 10
CETELEM 12 30
CETELEM 13 70
;
run;
%let sm_retrofit_method=HASH;
%include "&sm_code_dir./16_RISK_LEVELS.sas";
data work.hash_result;
    set sm_tmp.demand_prf_char_RF;
run;
%let sm_retrofit_method=INDEX;
%include "&sm_code_dir./16_RISK_LEVELS.sas";
%compare_fixture(base=work.hash_result,actual=sm_tmp.demand_prf_char_RF,
    keys=company authorization_id,
    vars=ML_SCORE_P0_RF ML_SCORE_P0_RF_CMC risk_score_rf score_rf risk_level
         sm_ml_lookup_match sm_cmc_lookup_match sm_efx_lookup_match,
    label=Index and hash retrofit paths are equivalent);
data work.expected_cmc;
    if 0 then set work.ml_rf_mi_cmc;
    input authorization_id ML_SCORE_P0_RF_CMC;
    datalines;
20 0.8
21 0.7
22 0.9
;
run;
%compare_fixture(base=work.expected_cmc,actual=work.ml_rf_mi_cmc,keys=authorization_id,
                 vars=ML_SCORE_P0_RF_CMC,label=CMC mean imputation and native probability);
data work.expected_efx;
    if 0 then set work.efx_v3_imputed;
    input authorization_id riskv3;
    datalines;
10 10
11 20
12 30
13 70
14 70
;
run;
data work.test_cet_efx;
    set work.efx_v3_imputed;
    where company='CETELEM';
run;
%compare_fixture(base=work.expected_efx,actual=work.test_cet_efx,keys=authorization_id,
                 vars=riskv3,label=EFX imputation preserves product groups);
data work.hash_failures;
    set sm_tmp.demand_prf_char_RF;
    if authorization_id=10 and ML_SCORE_P0_RF ne 0.55 then output;
    if authorization_id=31 and
       (not missing(ML_SCORE_P0_RF) or not missing(ML_SCORE_P0_RF_CMC)
        or not missing(risk_score_rf)) then output;
    if authorization_id=30 and (risk_score_rf ne 88 or not missing(ML_SCORE_P0_RF)) then output;
    if authorization_id=40 and risk_level ne 'High' then output;
    if authorization_id=41 and risk_level ne 'Medium' then output;
run;
%expect_equal(%sm_nobs(work.hash_failures),0,Hash misses company isolation native override and thresholds);

/* Latest fraud classification wins regardless of source ordering. */
data work.fraud;
    length event $8;
    input account_id CLASIFICACION_DATE DETECCION_DATE event $;
    datalines;
1 100 110 old
1 200 210 latest
1 200 220 revised
1 200 220 revised
2 150 160 only
;
run;
%sm_latest_fraud(data=work.fraud,key=account_id,out=work.latest_fraud);
data work.expected_fraud;
    if 0 then set work.latest_fraud;
    account_id=1; event='revised'; output;
    account_id=2; event='only'; output;
run;
%compare_fixture(base=work.expected_fraud,actual=work.latest_fraud,keys=account_id,
                 vars=event,label=Deterministic latest fraud event);

/* Persistent OSP map: reordering and adding applications cannot renumber old IDs. */
data work.vaps;
    length sm_vap_key $64;
    sm_vap_key='B'; output; sm_vap_key='A'; output;
run;
%sm_osp_ids(data=work.vaps,map=work.osp_ids);
data work.vaps;
    length sm_vap_key $64;
    sm_vap_key='C'; output; sm_vap_key='A'; output;
run;
%sm_osp_ids(data=work.vaps,map=work.osp_ids);
data work.expected_ids;
    if 0 then set work.osp_ids;
    sm_vap_key='A'; authorization_id=1; output;
    sm_vap_key='B'; authorization_id=2; output;
    sm_vap_key='C'; authorization_id=3; output;
run;
%compare_fixture(base=work.expected_ids,actual=work.osp_ids,keys=sm_vap_key,
                 vars=authorization_id,label=OSP map survives reordered incremental input);

%include "&sm_code_dir./tests/finalization_fixtures.sas";
%include "&sm_code_dir./tests/join_fixtures.sas";
%include "&sm_code_dir./tests/comparison_fixtures.sas";
%include "&sm_code_dir./tests/cutoff_output_fixtures.sas";

/* Policy reset is an explicit scenario, not the default monitoring behavior. */
%let sm_cutoffs_reset_flags=N;
data work.policy_observed;
    m_ct_sc_direct_finto25='Y';
    %sm_cutoff_scenario;
    if m_ct_sc_direct_finto25 ne 'Y' then abort cancel;
run;
%let sm_cutoffs_reset_flags=Y;
data work.policy_scenario;
    m_ct_sc_direct_finto25='Y';
    %sm_cutoff_scenario;
    if m_ct_sc_direct_finto25 ne 'N' then abort cancel;
run;
%expect_equal(%sm_nobs(work.policy_observed),1,Observed cutoff flags retained);
%expect_equal(%sm_nobs(work.policy_scenario),1,Counterfactual cutoff flags reset);
%let sm_cutoffs_reset_flags=N;

/* Negative tests intentionally emit SM_CHECK errors, but never touch production. */
%let sm_qa_abort=N;
data work.bad_keys;
    length company $20;
    company='CETELEM'; authorization_id=1; output; output;
    company='CMC'; authorization_id=1; output;
run;
%sm_assert_unique(data=work.bad_keys,keys=company authorization_id,out=work.bad_key_report);
%expect_equal(&sm_qa_failures,1,Duplicate application rejected);
%expect_equal(%sm_nobs(work.bad_key_report),1,Duplicate report respects company);
%let sm_qa_failures=0;
data work.good_keys;
    length company $20;
    company='CETELEM'; authorization_id=1; output;
    company='CMC'; authorization_id=1; output;
run;
%sm_assert_unique(data=work.good_keys,keys=company authorization_id,out=work.good_key_report);
%expect_equal(&sm_qa_failures,0,Same numeric ID in different companies is permitted);
data work.missing_keys;
    length company $20;
    company='CETELEM'; authorization_id=.; output;
run;
%sm_assert_unique(data=work.missing_keys,keys=company authorization_id,out=work.missing_key_report);
%expect_equal(&sm_qa_failures,1,Missing application key rejected);
%let sm_qa_failures=0;
%sm_assert_rows(base=work.good_keys,candidate=work.bad_keys);
%expect_equal(&sm_qa_failures,1,Join row multiplication rejected);
data work.published;
    value=1;
run;
data work.candidate;
    value=2;
run;
%sm_publish(lib=work,candidate=candidate,target=published);
data _null_;
    set work.published;
    if value ne 1 then abort cancel;
run;
%expect_equal(%sysfunc(exist(work.candidate)),1,Failed candidate not published);
%let sm_qa_failures=0;
%let sm_qa_abort=Y;
%sm_check_step(Fixture suite);
%put NOTE: ALL_SAS_TESTS_PASSED count=&sm_test_count;
