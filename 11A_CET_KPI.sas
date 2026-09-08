/* Narrow account histories; shared rollup eliminates virtual monthly rows. */
%sm_build_kpi(
    demand=sm_tmp.sm_demand_CTLM_END_U,
    loan=rln_core.h_loan_account,
    card=rcc_core.h_card_account,
    npe=sm_tmp.ndod_flg_npe_CET_END,
    npe_key=account_orig,
    sold=rcu_base.h_ctx_sold, current=rln_core.m_loan_account,
    out=sm_tmp.kpi_ctlm, company=CETELEM, booked_only=Y,
    cap_history=Y
);
