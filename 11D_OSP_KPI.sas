/* Narrow account histories; shared rollup eliminates virtual monthly rows. */
proc sql;
    create table work.sm_ctx_sold_raw as
    select contrato from R_adc2.CCBCON2 where posic_actual in ('049','019');
quit;
data work.sm_ctx_sold;
    set work.sm_ctx_sold_raw;
    account_id=input(contrato,14.);
    keep account_id;
run;
%sm_build_kpi(
    demand=sm_tmp.sm_demand_OSP_END_U,
    loan=rln_cor2.h_loan_account,
    card=,
    npe=sm_tmp.ndod_flg_npe_OSP_END,
    npe_key=account_id,
    sold=work.sm_ctx_sold, current=rln_cor2.m_loan_account,
    out=sm_tmp.kpi_osp, company=OSP, booked_only=Y,
    cap_history=Y
);
