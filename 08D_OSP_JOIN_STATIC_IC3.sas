/* Normalize once, choose an explicitly ordered call, and persist stable IDs.
   The identity map is state: retain it across runs and back it up. */
%include "&sm_code_dir./macros/osp_identity.sas";
%sm_osp_normalize(data=sm_tmp.sm_demand_osp, out=work.sm_osp_demand);
%sm_osp_normalize(data=sm_tmp.osp_ic3, out=work.sm_osp_calls);
/* Exact duplicate calls may be repeated by upstream sources. Resolve the latest
   ID_FECHA; ties at that date must be identical, rather than arbitrary winners. */
proc sort data=work.sm_osp_calls out=work.sm_osp_calls_distinct nodupkey;
    by _all_;
run;
%sm_assert_unique(data=work.sm_osp_calls_distinct, keys=sm_vap_key ID_FECHA,
                  out=sm_tmp.qa_osp_call_ties);
proc sort data=work.sm_osp_calls_distinct out=work.sm_osp_calls_sorted;
    by sm_vap_key descending ID_FECHA;
run;
data work.sm_osp_latest_call;
    set work.sm_osp_calls_sorted;
    by sm_vap_key descending ID_FECHA;
    if first.sm_vap_key;
run;
%sm_assert_unique(data=work.sm_osp_demand, keys=sm_vap_key,
                  out=sm_tmp.qa_osp_app_duplicates);
%sm_osp_ids(data=work.sm_osp_demand, seed=sm_tmp.sm_demand_OSP_END_U);
proc sql;
    create table sm_tmp.SM_DEMAND_OSP_END(compress=&sm_compress drop=sm_vap_key) as
    select a.*, b.*, c.authorization_id, 1 as match
    from work.sm_osp_demand(drop=authorization_id vap_id) as a
    inner join work.sm_osp_latest_call as b
      on a.sm_vap_key=b.sm_vap_key
    inner join sm.osp_authorization_map as c on a.sm_vap_key=c.sm_vap_key;
quit;
%sm_check_step(OSP application join);
%sm_assert_unique(data=sm_tmp.SM_DEMAND_OSP_END, keys=authorization_id,
                  out=sm_tmp.qa_osp_final_duplicates);
