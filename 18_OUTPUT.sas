/* Final wide write. Reporting consumers receive compact datasets in this pass. */
data sm.score_monitoring_candidate(compress=&sm_compress drop=sm_qa_issue)
     sm_tmp.cpcr_base(compress=&sm_compress keep=&sm_cpcr_vars
                      where=(mis_date ge '01JAN2021'd))
     sm_tmp.cutoffs_input(compress=&sm_compress keep=&sm_cutoffs_vars
                         where=(mis_date ge &sm_cutoffs_start and company='CETELEM'
                                and status_name ne 'Pending' and valid_call='Y'))
     sm_tmp.sm_report_input(compress=&sm_compress keep=&sm_report_vars
                           where=(("%upcase(&sm_full_report)"='Y' or mis_date ge &last_date_3m) and valid_call='Y'))
     sm_tmp.qa_final_errors(keep=company authorization_id account_id mis_date sm_qa_issue)
     sm_tmp.qa_monitoring_metrics(keep=company mis_date status_name rf_business_name
        sm_kpi_match sm_perfo_match sm_ml_lookup_match sm_cmc_lookup_match
        sm_efx_lookup_match acct_booked_h0 acct_booked_h6 acct_booked_h12
        oa_amt_cma early_bad basel_bad early_observed basel_observed valid_call);
    length sm_qa_issue $80;
    set sm_tmp.sm_final_v;
    sm_qa_issue='';
    if missing(company) or missing(authorization_id) or missing(mis_date) then do;
        sm_qa_issue='Missing application key or cohort'; output sm_tmp.qa_final_errors;
    end;
    if acct_booked_H6=0 and (oa_amt_h6 ne 0 or todu_h6 ne 0 or basel_default_h6 ne 0) then do;
        sm_qa_issue='H6 value on an unobserved horizon'; output sm_tmp.qa_final_errors;
    end;
    if acct_booked_H12=0 and (oa_amt_h12 ne 0 or todu_h12 ne 0 or basel_default_h12 ne 0) then do;
        sm_qa_issue='H12 value on an unobserved horizon'; output sm_tmp.qa_final_errors;
    end;
    if (not missing(early_bad) and early_bad not in (0,1)) or
       (not missing(basel_bad) and basel_bad not in (0,1)) then do;
        sm_qa_issue='Outcome outside binary or missing domain'; output sm_tmp.qa_final_errors;
    end;
    output sm.score_monitoring_candidate;
    output sm_tmp.cpcr_base;
    output sm_tmp.cutoffs_input;
    output sm_tmp.sm_report_input;
    output sm_tmp.qa_monitoring_metrics;
run;
%sm_check_step(Final monitoring candidate);
%sm_assert_empty(data=sm_tmp.qa_final_errors, label=Monitoring invariants);
%sm_assert_rows(base=sm_tmp.sm_app_index, candidate=sm.score_monitoring_candidate);
%sm_publish(lib=sm, candidate=score_monitoring_candidate, target=score_monitoring);

/* Counts and match rates stay reviewable without rescanning the wide dataset. */
proc summary data=sm_tmp.qa_monitoring_metrics nway missing;
    class company mis_date status_name rf_business_name;
    var sm_kpi_match sm_perfo_match sm_ml_lookup_match sm_cmc_lookup_match
        sm_efx_lookup_match acct_booked_h0 acct_booked_h6 acct_booked_h12
        oa_amt_cma early_bad basel_bad early_observed basel_observed;
    output out=sm_tmp.qa_monitoring_summary sum=;
run;

proc sql;
create table 	sm.out_sm_rpt_3m as
	select		put(mis_date, yymmd7.) as mis_date,
				company,
				red_name,
				product_type_1,
				product_type_2,
				product_type_3,
				segment_1,
				segment_2,
				segment_3,
				segment_4,
				vendedor_cadena_id,
				vendedor_id,
				vendedor_grupo_id,
				vendedor_union_id,
				case when vendedor_cadena_id in (9111030, 9111048, 9111055, 9111063,9111071) then 'Y' else 'N' end as flag_apple_apr,
				case when vendedor_sector_id = 'ENR' then 'Y' else 'N' end as flag_Sector_enr,
				vendedor_sector_id,
				rf_business_name,
				status_name,
				risk_level,
				case when CLASIFICACION_DATE ne . then 'Y' else 'N' end as fraud_flag,
				product_code_3 as product_code,
				count(*) as freq,
				sum(acct_booked_h0) as acct_booked_h0,
                sum(acct_booked_h6) as acct_booked_h6,
                sum(acct_booked_h12) as acct_booked_h12,
                sum(early_observed) as early_observed,
                sum(basel_observed) as basel_observed,
				sum(oa_amt_cma) as oa_amt_cma,
				sum(early_bad) as early_bad,
				sum(basel_bad) as basel_bad,
				sum(score_rf) as score_rf,
				sum(valid_score_RF) as valid_score_RF,
				sum(scrplust1) as scrplust1,
				sum(valid_efx) as valid_efx,
				sum(ind_rl_high) as ind_rl_high,
				sum(ind_known_Fmas) as ind_known_Fmas,
				sum(ind_known) as ind_known,
				sum(todu_30ever_h6) as todu_30ever_h6,
				sum(todu_amt_pile_h6) as todu_amt_pile_h6
	from		sm_tmp.sm_report_input
	group by 	calculated mis_date,
				company,
				red_name,
				product_type_1,
				product_type_2,
				product_type_3,
				segment_1,
				segment_2,
				segment_3,
				segment_4,
				vendedor_cadena_id,
				vendedor_id,
				vendedor_grupo_id,
				vendedor_union_id,			
				flag_apple_apr,
				flag_sector_enr,
				vendedor_sector_id,
				rf_business_name,
				status_name,
				risk_level,
				calculated fraud_flag,
				product_code_3
;			
quit;

data sm.out_sm_rpt_3m;
	set sm.out_sm_rpt_3m;
	if rf_business_name = 'A-Score DIRECT 2024' then rf_business_name = 'A-Score DIRECT';
run;

%macro sm_assemble_report;
    %if %upcase(&sm_full_report) ne Y %then %do;
        %sm_require(data=sm_bk.out_sm_rpt_&last_date_txt);
    %end;
    data sm.out_sm_rpt(where=(product_type_2 ne 'Panda'));
        set sm.out_sm_rpt_3m
        %if %upcase(&sm_full_report) ne Y %then %do;
            sm_bk.out_sm_rpt_&last_date_txt(where=(mis_date lt "&last_date_3m_txt"))
        %end;
        ;
    run;
%mend;
%sm_assemble_report;
%sm_check_step(Monitoring report);

%macro sm_export_report;
%if %upcase(&sm_export)=Y %then %do;
proc export data=sm.out_sm_rpt outfile="&dir/out_sm_rpt_&last_date_txt..csv" dbms=dlm replace;
delimiter=';';
run;
filename myfile "&dir/out_sm_rpt_&last_date_txt..csv";
ods package(newzip) open nopf;
ods package(newzip) add file=myfile;
ods package(newzip) publish archive 
  properties(
   archive_name="out_sm_rpt_&last_date_txt..zip" 
   archive_path="&dir//"
  );
ods package(newzip) close;

%end;
%mend;
%sm_export_report;
