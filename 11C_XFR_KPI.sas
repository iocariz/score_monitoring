/* Narrow account histories; shared rollup eliminates virtual monthly rows. */
proc sql;
    create table work.sm_ctx_sold_raw as
    select contrato from R_adc6.CCBCON600 where posic_actual in ('049','019');
quit;
data work.sm_ctx_sold;
    set work.sm_ctx_sold_raw;
    account_id=input(contrato,14.);
    keep account_id;
run;
%sm_build_kpi(
    demand=sm_tmp.sm_demand_XFR_END_U,
    loan=rln_cor6.h_loan_account,
    card=rcc_cor6.h_card_account,
    npe=sm_tmp.ndod_flg_npe_XFR_END,
    npe_key=account_orig,
    sold=work.sm_ctx_sold, current=rln_cor6.m_loan_account,
    out=sm_tmp.kpi_xfr, company=XFR, booked_only=N,
    cap_history=N
);
