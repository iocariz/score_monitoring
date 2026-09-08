/* The application key is (company, authorization_id), not account_id. */
data sm_tmp.sm_demand_union / view=sm_tmp.sm_demand_union;
    length company $20;
    set sm_tmp.sm_demand_ctlm_END_U(in=a)
        sm_tmp.sm_demand_cmc_END_U(in=b)
        sm_tmp.sm_demand_XFR_END_U(in=c)
        sm_tmp.sm_demand_OSP_END_U(in=d);
    if a then company='CETELEM';
    else if b then company='CMC';
    else if c then company='XFR';
    else company='OSP';
run;
/* Key-only input: do not sort/copy the wide application rows for this check. */
data work.sm_demand_keys;
    set sm_tmp.sm_demand_union(keep=company authorization_id);
run;
%sm_assert_unique(data=work.sm_demand_keys, keys=company authorization_id,
                  out=sm_tmp.qa_demand_duplicates);

data sm_tmp.kpi_all(compress=&sm_compress);
    set sm_tmp.kpi_ctlm sm_tmp.kpi_cmc sm_tmp.kpi_xfr sm_tmp.kpi_osp;
    where not missing(account_id);
run;
%sm_assert_unique(data=sm_tmp.kpi_all, keys=company account_id,
                  out=sm_tmp.qa_kpi_duplicates);
proc sql;
    create table sm_tmp.demand_prf(compress=&sm_compress
        drop=zrech__: alert_: ko_others_: rv_alert_: ko_score_:) as
    select a.*,
           b.acct_booked_H0, b.acct_booked_H6, b.acct_booked_H12,
           b.oa_amt_h0, b.oa_amt_h6, b.oa_amt_h12,
           b.todu_h0, b.todu_h6, b.todu_h12,
           b.basel_default_h6, b.basel_default_h12,
           (b.account_id is not null) as sm_kpi_match
    from sm_tmp.sm_demand_union as a
    left join sm_tmp.kpi_all as b
      on a.company=b.company and a.account_id=b.account_id;
quit;
%sm_check_step(Application KPI join);
%sm_assert_rows(base=work.sm_demand_keys, candidate=sm_tmp.demand_prf);
