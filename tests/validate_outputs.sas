/* Real-data comparison on frozen inputs. Include macros/validation.sas first.
   Example:
   %sm_validate_outputs(base=old.score_monitoring,candidate=new.score_monitoring,
                        outlib=qa,row_compare=Y,strict=N);
   Sources are read-only. OUTLIB must be a separate writable SAS library.
   Each source is scanned once to create a narrow snapshot. */
%macro sm_validate_outputs(base=, candidate=, outlib=work, row_compare=N, strict=N);
    %local side ds cols groups values sm_compare_rc sm_row_rc;
    %let groups=company mis_date status_name rf_business_name;
    %let values=acct_booked_h0 acct_booked_h6 acct_booked_h12 oa_amt_cma
        oa_amt_h0 oa_amt_h6 oa_amt_h12 todu_h0 todu_h6 todu_h12
        basel_default_h6 basel_default_h12 early_bad basel_bad score_rf;
    %let cols=company authorization_id account_id mis_date status_name
        rf_business_name risk_level &values;
    %do side=1 %to 2;
        %if &side=1 %then %let ds=&base;
        %else %let ds=&candidate;
        %sm_require(data=&ds, vars=&cols);
        data &outlib..snapshot_&side;
            /* Normalize comparison attributes; production schemas are audited below. */
            length company $20 status_name $32 rf_business_name $100 risk_level $50;
            set &ds(keep=&cols);
            format _all_;
            informat _all_;
            early_observed=(status_name='Booked' and not missing(early_bad));
            basel_observed=(status_name='Booked' and not missing(basel_bad));
        run;
        %sm_check_step(Comparison snapshot &side);
        %sm_assert_unique(data=&outlib..snapshot_&side, keys=company authorization_id,
                          out=&outlib..duplicate_keys_&side);
        proc summary data=&outlib..snapshot_&side nway missing;
            class &groups;
            var &values early_observed basel_observed;
            output out=&outlib..totals_&side sum=;
        run;
        proc sort data=&outlib..totals_&side;
            by &groups;
        run;
        proc contents data=&ds out=&outlib..schema_&side(keep=name type length format informat)
                      noprint;
        run;
    %end;
    proc sql;
        create table &outlib..population_differences as
        select coalesce(a.company,b.company) as company length=20,
               coalesce(a.authorization_id,b.authorization_id) as authorization_id,
               (a.authorization_id is not null) as in_base,
               (b.authorization_id is not null) as in_candidate
        from &outlib..snapshot_1 as a full join &outlib..snapshot_2 as b
          on a.company=b.company and a.authorization_id=b.authorization_id
        where a.authorization_id is null or b.authorization_id is null;
        create table &outlib..schema_differences as
        select coalesce(a.name,b.name) as name length=32,
               a.type as base_type, b.type as candidate_type,
               a.length as base_length, b.length as candidate_length,
               a.format as base_format, b.format as candidate_format
        from &outlib..schema_1 as a full join &outlib..schema_2 as b
          on upcase(a.name)=upcase(b.name)
        where a.name is null or b.name is null or a.type ne b.type
           or a.length ne b.length or a.format ne b.format or a.informat ne b.informat;
    quit;
    proc compare base=&outlib..totals_1 compare=&outlib..totals_2
        method=relative(1) criterion=1e-10 noprint
        out=&outlib..aggregate_differences outnoequal outbase outcomp outdif;
        id &groups;
        var _freq_ &values early_observed basel_observed;
    run;
    %let sm_compare_rc=&sysinfo;
    %let sm_row_rc=0;
    %if %upcase(&row_compare)=Y %then %do;
        proc sort data=&outlib..snapshot_1;
            by company authorization_id;
        run;
        proc sort data=&outlib..snapshot_2;
            by company authorization_id;
        run;
        proc compare base=&outlib..snapshot_1 compare=&outlib..snapshot_2
            method=relative(1) criterion=1e-10 noprint
            out=&outlib..row_differences outnoequal outbase outcomp outdif;
            id company authorization_id;
            var account_id mis_date status_name rf_business_name risk_level
                &values early_observed basel_observed;
        run;
        %let sm_row_rc=&sysinfo;
    %end;
    data &outlib..comparison_status;
        length base candidate $80;
        base="&base"; candidate="&candidate";
        base_rows=%sm_nobs(&outlib..snapshot_1);
        candidate_rows=%sm_nobs(&outlib..snapshot_2);
        population_differences=%sm_nobs(&outlib..population_differences);
        aggregate_compare_sysinfo=&sm_compare_rc;
        row_compare_requested=("%upcase(&row_compare)"='Y');
        row_compare_sysinfo=&sm_row_rc;
    run;
    %sm_check_step(Frozen-output comparison);
    /* Strict mode is for equivalent implementations, e.g. HASH vs INDEX.
       The old buggy output is expected to differ; inspect and explain differences. */
    %if %upcase(&strict)=Y %then %do;
        %sm_assert_empty(data=&outlib..population_differences, label=Population changed);
        %if &sm_compare_rc ne 0 or &sm_row_rc ne 0 %then
            %sm_fail(Output comparison differs. Inspect &outlib..comparison_status);
    %end;
%mend;
