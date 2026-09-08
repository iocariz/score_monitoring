%macro sm_osp_normalize(data=, out=);
    data &out;
        length sm_vap_key $64;
        set &data;
        if lengthn(compress(vap_id)) > 64 or missing(compress(vap_id)) then do;
            put 'ERROR: SM_CHECK: Invalid VAP identifier length.';
            abort cancel;
        end;
        sm_vap_key=compress(vap_id);
    run;
    %sm_check_step(VAP normalization);
%mend;

%macro sm_osp_ids(data=, map=sm.osp_authorization_map, seed=);
    %local maplib mapmem maxid seed_exists;
    %let maplib=%scan(&map,1,.);
    %let mapmem=%scan(&map,2,.);
    %let seed_exists=0;
    %if %length(&seed) %then %let seed_exists=%sysfunc(exist(&seed));
    %if not %sysfunc(exist(&map)) %then %do;
        %if &seed_exists %then %do;
            %sm_require(data=&seed, vars=vap_id authorization_id);
            %sm_osp_normalize(data=&seed, out=work.sm_osp_seed);
            proc sort data=work.sm_osp_seed(keep=sm_vap_key authorization_id)
                      out=work.sm_osp_initial nodupkey;
                by _all_;
            run;
        %end;
        %else %do;
            data work.sm_osp_initial;
                length sm_vap_key $64 authorization_id 8;
                stop;
            run;
        %end;
    %end;
    %else %do;
        data work.sm_osp_initial;
            set &map(keep=sm_vap_key authorization_id);
        run;
    %end;
    %sm_assert_unique(data=work.sm_osp_initial, keys=sm_vap_key,
                      out=work.sm_osp_bad_vap);
    %sm_assert_unique(data=work.sm_osp_initial, keys=authorization_id,
                      out=work.sm_osp_bad_auth);
    data work.sm_osp_invalid_ids;
        set work.sm_osp_initial;
        if missing(authorization_id) or authorization_id < 1
           or authorization_id ne int(authorization_id)
           or authorization_id > 9007199254740991;
    run;
    %sm_assert_empty(data=work.sm_osp_invalid_ids, label=Invalid persisted OSP numeric ID);
    proc sql noprint;
        select coalesce(max(authorization_id),0) format=32. into :maxid trimmed
        from work.sm_osp_initial;
        create table work.sm_osp_new_keys as
        select distinct a.sm_vap_key
        from &data(keep=sm_vap_key) as a
        left join work.sm_osp_initial as b on a.sm_vap_key=b.sm_vap_key
        where b.sm_vap_key is null
        order by a.sm_vap_key;
    quit;
    data work.sm_osp_new_ids;
        set work.sm_osp_new_keys;
        retain authorization_id &maxid;
        authorization_id+1;
        if authorization_id > 9007199254740991 then abort cancel;
    run;
    data &maplib..sm_osp_map_candidate;
        set work.sm_osp_initial work.sm_osp_new_ids;
    run;
    %sm_assert_unique(data=&maplib..sm_osp_map_candidate, keys=sm_vap_key,
                      out=work.sm_osp_map_bad_vap);
    %sm_assert_unique(data=&maplib..sm_osp_map_candidate, keys=authorization_id,
                      out=work.sm_osp_map_bad_auth);
    %sm_publish(lib=&maplib, candidate=sm_osp_map_candidate, target=&mapmem);
%mend;
