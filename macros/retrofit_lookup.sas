/* INDEX bounds memory; HASH avoids random I/O when all three lookups fit RAM. */
%macro sm_retrofit_prepare;
    %if %upcase(&sm_retrofit_method)=INDEX %then %do;
        data work.sm_lookup_ml(index=(sm_lookup_key=(authorization_id company) / unique));
            set sm_bk.ml_rf_mi(keep=authorization_id company ML_SCORE_P0_RF
                rename=(ML_SCORE_P0_RF=_sm_ml));
        run;
        data work.sm_lookup_cmc(index=(sm_lookup_key=(authorization_id company) / unique));
            set work.ml_rf_mi_cmc(keep=authorization_id company ML_SCORE_P0_RF_CMC
                rename=(ML_SCORE_P0_RF_CMC=_sm_cmc));
        run;
        data work.sm_lookup_efx(index=(sm_lookup_key=(authorization_id company) / unique));
            set work.efx_v3_mi(keep=authorization_id company risk_score_rf
                rename=(risk_score_rf=_sm_efx));
        run;
        %sm_check_step(Retrofit indexes);
    %end;
    %else %if %upcase(&sm_retrofit_method) ne HASH %then %do;
        %sm_fail(sm_retrofit_method must be INDEX or HASH);
    %end;
%mend;

%macro sm_retrofit_init;
    %if %upcase(&sm_retrofit_method)=HASH %then %do;
        if _n_=1 then do;
            declare hash hm(dataset:
              'sm_bk.ml_rf_mi(keep=authorization_id company ML_SCORE_P0_RF rename=(ML_SCORE_P0_RF=_sm_ml))');
            _sm_rc=hm.defineKey('authorization_id','company');
            _sm_rc=sum(_sm_rc,hm.defineData('_sm_ml'));
            _sm_rc=sum(_sm_rc,hm.defineDone());
            declare hash hc(dataset:
              'work.ml_rf_mi_cmc(keep=authorization_id company ML_SCORE_P0_RF_CMC rename=(ML_SCORE_P0_RF_CMC=_sm_cmc))');
            _sm_rc=sum(_sm_rc,hc.defineKey('authorization_id','company'));
            _sm_rc=sum(_sm_rc,hc.defineData('_sm_cmc'));
            _sm_rc=sum(_sm_rc,hc.defineDone());
            declare hash he(dataset:
              'work.efx_v3_mi(keep=authorization_id company risk_score_rf rename=(risk_score_rf=_sm_efx))');
            _sm_rc=sum(_sm_rc,he.defineKey('authorization_id','company'));
            _sm_rc=sum(_sm_rc,he.defineData('_sm_efx'));
            _sm_rc=sum(_sm_rc,he.defineDone());
            if _sm_rc ne 0 then do;
                put 'ERROR: SM_CHECK: Could not initialize retrofit hashes.';
                abort cancel;
            end;
        end;
    %end;
%mend;

%macro sm_index_find(table=, field=, flag=);
    set &table key=sm_lookup_key / unique;
    &flag=(_IORC_=0);
    if _IORC_=%sysrc(_DSENOM) then do;
        _ERROR_=0;
        call missing(&field);
    end;
    else if _IORC_ ne 0 then do;
        put 'ERROR: SM_CHECK: Retrofit index failure ' _IORC_=;
        abort cancel;
    end;
%mend;

%macro sm_retrofit_find;
    %if %upcase(&sm_retrofit_method)=HASH %then %do;
        sm_ml_lookup_match=(hm.find()=0);
        sm_cmc_lookup_match=(hc.find()=0);
        sm_efx_lookup_match=(he.find()=0);
    %end;
    %else %do;
        %sm_index_find(table=work.sm_lookup_ml,field=_sm_ml,flag=sm_ml_lookup_match);
        %sm_index_find(table=work.sm_lookup_cmc,field=_sm_cmc,flag=sm_cmc_lookup_match);
        %sm_index_find(table=work.sm_lookup_efx,field=_sm_efx,flag=sm_efx_lookup_match);
    %end;
%mend;
