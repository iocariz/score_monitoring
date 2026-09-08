%let vars = mis_date status_app_id decision_date status_name open_date entry_date account_id customer_id nif file_id due_date_1st
			product_core product_code: product_type_1-product_type_4 TIN tenor_init installment_amt_init SCRV_customer_init 
			SCRV_customer_group_init vendedor_: material: origen_name oa_amt_cma income_t1t2_m 
			authorization_id se_decision_id flag_tpt precon_ind red_name origen_name fuera_norma flag_riesgo_masmovil;

data sm_tmp.sm_demand_XFR(keep=&vars.);
	set rln_cor6.h_loan_apps_booked(rename=(oa_amt=oa_amt_cma) where=(mis_Date >= &init_date. and product_core = 'Y' and flag_tpt = 'N'))
		rln_cor6.h_loan_apps_others(rename=(oa_amt=oa_amt_cma) where=(mis_Date >= &init_date. and product_core = 'Y' and flag_tpt = 'N'))
		rcc_cor6.h_card_apps_booked(rename=(cma=oa_amt_cma) where=(mis_Date >= &init_date. and product_core = 'Y'))
		rcc_cor6.h_card_apps_others(rename=(cma=oa_amt_cma) where=(mis_Date >= &init_date. and product_core = 'Y'));;
run;

PROC FREQ DATA=sm_tmp.sm_demand_XFR
;
	TABLES vendedor_cadena_id*mis_date /  SCORES=TABLE;
	where red_name='DIRECT';
RUN;

