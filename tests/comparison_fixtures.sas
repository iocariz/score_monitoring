/* Validate the frozen-output comparison itself on an identical pair and a drift. */
%include "&sm_code_dir./tests/validate_outputs.sas";
data work.baseline_fixture;
    set work.test_final_rows;
    oa_amt_cma=100; oa_amt_h0=100; oa_amt_h6=80; oa_amt_h12=60;
    todu_h0=100; todu_h6=80; todu_h12=60;
    basel_default_h6=0; acct_booked_h0=1;
    length risk_level $50;
    risk_level='Medium';
run;
%sm_validate_outputs(base=work.baseline_fixture,candidate=work.baseline_fixture,
                     outlib=work,row_compare=Y,strict=Y);
%expect_equal(%sm_nobs(work.population_differences),0,Identical output populations compare equal);
%expect_equal(%sm_nobs(work.row_differences),0,Identical output values compare equal);
data work.changed_fixture;
    set work.baseline_fixture;
    if company='CETELEM' and authorization_id=1 then todu_h12=todu_h12+1;
run;
%sm_validate_outputs(base=work.baseline_fixture,candidate=work.changed_fixture,
                     outlib=work,row_compare=Y,strict=N);
%expect_equal(%sysevalf(%sm_nobs(work.aggregate_differences)>0),1,
               Cohort comparison detects changed balance);
%expect_equal(%sysevalf(%sm_nobs(work.row_differences)>0),1,
               Row comparison detects changed balance);
