/* SAS 9.4 runtime contracts. All checks operate on metadata or narrow keys.
   Include once before the numbered programs (00_SETUP does this). */
%macro sm_default(name, value);
    %if not %symexist(&name) %then %do;
        %global &name;
        %let &name=&value;
    %end;
%mend;
%sm_default(sm_code_dir, .);
%sm_default(sm_compress, binary);
%sm_default(sm_retrofit_method, INDEX);
%sm_default(sm_diagnostics, N);
%sm_default(sm_export, Y);
%sm_default(sm_full_report, Y);
%sm_default(sm_cutoffs_reset_flags, N);
%sm_default(sm_cutoffs_start, '01JAN2023'd);
%sm_default(sm_qa_abort, Y);
%global sm_qa_failures;
%let sm_qa_failures=0;

%macro sm_fail(message);
    %let sm_qa_failures=%eval(&sm_qa_failures+1);
    %put ERROR: SM_CHECK: &message;
    %if %upcase(&sm_qa_abort)=Y %then %abort cancel;
%mend;

%macro sm_check_step(label);
    %if &syserr > 4 or &syscc > 4 %then
        %sm_fail(&label failed. SYSERR=&syserr SYSCC=&syscc);
%mend;

%macro sm_require(data=, vars=);
    %local dsid rc i name;
    %let dsid=%sysfunc(open(&data,i));
    %if &dsid=0 %then %do;
        %sm_fail(Cannot open required input &data);
        %return;
    %end;
    %do i=1 %to %sysfunc(countw(&vars));
        %let name=%scan(&vars,&i);
        %if %sysfunc(varnum(&dsid,&name))=0 %then
            %sm_fail(Required variable &name is absent from &data);
    %end;
    %let rc=%sysfunc(close(&dsid));
%mend;

%macro sm_nobs(data);
    %local dsid n rc;
    %let dsid=%sysfunc(open(&data,i));
    %let n=-1;
    %if &dsid %then %do;
        %let n=%sysfunc(attrn(&dsid,nlobs));
        %let rc=%sysfunc(close(&dsid));
    %end;
    &n
%mend;

%macro sm_assert_empty(data=, label=);
    %local n;
    %let n=%sm_nobs(&data);
    %if &n ne 0 %then %sm_fail(&label: &n rows in &data);
%mend;

%macro sm_assert_rows(base=, candidate=);
    %local a b;
    %let a=%sm_nobs(&base);
    %let b=%sm_nobs(&candidate);
    %if &a < 0 or &b < 0 or &a ne &b %then
        %sm_fail(Row count changed: &base=&a &candidate=&b);
%mend;

%macro sm_assert_unique(data=, keys=, out=work.sm_duplicate_keys,
                        allow_missing=N);
    %local key_sql missing_sql i key;
    %sm_require(data=&data, vars=&keys);
    %let key_sql=;
    %let missing_sql=0;
    %do i=1 %to %sysfunc(countw(&keys));
        %let key=%scan(&keys,&i);
        %if &i>1 %then %let key_sql=&key_sql,;
        %let key_sql=&key_sql &key;
        %let missing_sql=&missing_sql or missing(&key);
    %end;
    proc sql;
        create table &out as
        select &key_sql, count(*) as sm_key_count
        from &data
        group by &key_sql
        having count(*) > 1
        %if %upcase(&allow_missing)=N %then %do;
            or (&missing_sql)
        %end;
        ;
    quit;
    %sm_check_step(Key validation for &data);
    %sm_assert_empty(data=&out, label=Duplicate or missing key in &data);
%mend;

%macro sm_quarter_lookup(data=, out=);
    /* Preserve the original GLOBAL quarter definition, including no company BY. */
    proc sql;
        create table &out as
        select put(mis_date,yyq10.) as quarter length=10,
               (count(distinct mis_date)=3) as full_quarter
        from &data(keep=mis_date)
        group by calculated quarter;
    quit;
    %sm_check_step(Quarter lookup);
%mend;

%macro sm_publish(lib=, candidate=, target=);
    /* Metadata exchange retains the old target until the candidate passes QA. */
    %sm_require(data=&lib..&candidate);
    %if &sm_qa_failures ne 0 %then %do;
        %sm_fail(Publication refused because validation has failed);
        %return;
    %end;
    proc datasets library=&lib nolist;
        %if %sysfunc(exist(&lib..&target)) %then %do;
            exchange &candidate=&target;
            delete &candidate;
        %end;
        %else %do;
            change &candidate=&target;
        %end;
    quit;
    %sm_check_step(Publish &lib..&target);
%mend;
