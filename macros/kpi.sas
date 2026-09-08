/* Final monitoring consumes H0, H6 and H12 only. No virtual monthly table is
   materialized. H0 preserves the legacy first-observed-record definition. */
%macro sm_rollup_kpi(data=, out=, asof=, company=, booked_only=N);
    %sm_assert_unique(data=&data, keys=account_id prf_date,
                      out=work.sm_kpi_duplicate_months);
    proc sort data=&data out=work.sm_kpi_sorted;
        by account_id prf_date;
    run;
    data &out(compress=&sm_compress keep=company account_id
        acct_booked_H0 acct_booked_H6 acct_booked_H12
        oa_amt_h0 oa_amt_h6 oa_amt_h12 todu_h0 todu_h6 todu_h12
        basel_default_h6 basel_default_h12);
        length company $20;
        set work.sm_kpi_sorted;
        by account_id prf_date;
        retain acct_booked_H0 acct_booked_H6 acct_booked_H12
               oa_amt_h0 oa_amt_h6 oa_amt_h12 todu_h0 todu_h6 todu_h12
               basel_default_h6 basel_default_h12;
        company="&company";
        if first.account_id then do;
            acct_booked_h0=1;
            oa_amt_h0=oa_amt;
            todu_h0=todu;
            acct_booked_h6=0; acct_booked_h12=0;
            oa_amt_h6=0; oa_amt_h12=0;
            todu_h6=0; todu_h12=0;
            basel_default_h6=0; basel_default_h12=0;
        end;
        horizon=intck('month',mis_date,prf_date);
        if horizon=6 then do;
            acct_booked_h6=1; oa_amt_h6=oa_amt; todu_h6=todu;
            basel_default_h6=max_npe;
        end;
        if horizon=12 then do;
            acct_booked_h12=1; oa_amt_h12=oa_amt; todu_h12=todu;
            basel_default_h12=max_npe;
        end;
        if last.account_id then do;
            /* Carry only BEYOND the last observed month, not through interior gaps.
               This matches the old virtual-record rule, bounded at H12/asof. */
            if horizon < 6 and intnx('month',mis_date,6,'b') <= &asof then do;
                acct_booked_h6=1; oa_amt_h6=oa_amt; todu_h6=todu;
                basel_default_h6=max_npe;
                if ind_ctx_sold='Y' then basel_default_h6=1;
            end;
            if horizon < 12 and intnx('month',mis_date,12,'b') <= &asof then do;
                acct_booked_h12=1; oa_amt_h12=oa_amt; todu_h12=todu;
                basel_default_h12=max_npe;
                if ind_ctx_sold='Y' then basel_default_h12=1;
            end;
            %if %upcase(&booked_only)=Y %then %do;
                if status_name='Booked' then output;
            %end;
            %else %do;
                output;
            %end;
        end;
    run;
    %sm_check_step(KPI rollup &company);
%mend;

%macro sm_build_kpi(demand=, loan=, card=, npe=, npe_key=account_orig,
                    sold=, current=, out=, company=, booked_only=N, cap_history=N);
    %local sm_kpi_asof;
    %sm_require(data=&demand, vars=account_id mis_date status_name);
    %sm_require(data=&current, vars=mis_date);
    proc sql noprint;
        select max(mis_date) into :sm_kpi_asof trimmed from &current;
        create table work.sm_kpi_apps as
        select distinct account_id, mis_date, status_name
        from &demand(keep=account_id mis_date status_name)
        where not missing(account_id);
        create table work.sm_sold_keys as
        select distinct account_id from &sold where not missing(account_id);
    quit;
    %sm_check_step(KPI inputs &company);
    %if %length(%superq(sm_kpi_asof))=0 %then %do;
        %sm_fail(Empty current-date input for &company);
        %return;
    %end;
    %if %sysevalf(&sm_kpi_asof=.,boolean) %then %do;
        %sm_fail(Missing current date for &company);
        %return;
    %end;
    %sm_assert_unique(data=work.sm_kpi_apps, keys=account_id,
                      out=work.sm_multiple_cohorts);
    %sm_assert_unique(data=&npe, keys=&npe_key mis_date,
                      out=work.sm_npe_duplicate_months);
    proc sql;
        create table work.sm_kpi_history as
        select a.account_id, a.mis_date, a.status_name,
               b.mis_date as prf_date, b.oa_amt, b.todu
        from work.sm_kpi_apps as a inner join &loan as b
          on a.account_id=b.account_id
         %if %upcase(&cap_history)=Y %then %do;
             and b.mis_date < intnx('month',a.mis_date,13,'b')
         %end;
         and b.mis_date <= &sm_kpi_asof and not missing(b.mis_date)
        %if %length(&card) %then %do;
        union all
        select a.account_id, a.mis_date, a.status_name,
               b.mis_date as prf_date, b.cma as oa_amt, b.todu
        from work.sm_kpi_apps as a inner join &card as b
          on a.account_id=b.account_id
         %if %upcase(&cap_history)=Y %then %do;
             and b.mis_date < intnx('month',a.mis_date,13,'b')
         %end;
         and b.mis_date <= &sm_kpi_asof and not missing(b.mis_date)
        %end;
        ;
        create table work.sm_kpi_enriched as
        select a.*, coalesce(b.max_npe,0) as max_npe,
               case when c.account_id is not null then 'Y' else 'N' end
                   as ind_ctx_sold length=1
        from work.sm_kpi_history as a
        left join &npe as b
          on a.account_id=b.&npe_key and a.prf_date=b.mis_date
        left join work.sm_sold_keys as c on a.account_id=c.account_id;
    quit;
    %sm_check_step(KPI history &company);
    %sm_rollup_kpi(data=work.sm_kpi_enriched, out=&out,
                   asof=&sm_kpi_asof, company=&company, booked_only=&booked_only);
%mend;
