%macro sm_latest_fraud(data=, key=, out=);
    /* Whole rows are selected, so event attributes cannot come from different
       records. Latest classification, then latest detection; lexical payload
       order is the deterministic tie-break for otherwise equal dates. */
    proc sort data=&data(where=(not missing(&key))) out=work.sm_fraud_distinct nodupkey;
        by _all_;
    run;
    proc sort data=work.sm_fraud_distinct out=work.sm_fraud_ordered equals;
        by &key descending CLASIFICACION_DATE descending DETECCION_DATE;
    run;
    data &out;
        set work.sm_fraud_ordered;
        by &key descending CLASIFICACION_DATE descending DETECCION_DATE;
        if first.&key;
    run;
    %sm_check_step(Fraud selection by &key);
    %sm_assert_unique(data=&out, keys=&key, out=work.sm_fraud_duplicates);
%mend;
