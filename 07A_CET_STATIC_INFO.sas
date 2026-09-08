
data  sm_tmp.sm_demand
		(keep =	mis_date open_date decision_date status_app_id entry_date due_date_1st status_name account_id customer_id  authorization_id 
		product_type_1-product_type_4 product_code: flag_tpt red_name scrv_customer_init SCRV_customer_Group_init vendedor_: tenor_init oa_amt_cma 
		fuera_norma file_id product_core TIN installment_amt_init material: origen_name dni_t1 nature_holder/*se_decision_id*/) ;

	set rln_core.h_loan_apps_booked 
		(
			rename=(oa_amt=oa_amt_cma)
			where=(	mis_date ge &init_date. and product_type_2 not in ('TelCo','TPT','Pandas') and product_type_3 ne 'MediaMarkt' 
					and vendedor_cadena_top_name not in ('MediaMarkt','YOIGO','Yoicard','Yoigo') and vendedor_cadena_name ne 'YOIGO'
					and product_core = 'Y' and flag_tpt='N' and product_code_3 not in ('TPTG','TPTI','DPY','TUG','TUI','CCG','FL','FLG'))
		)
		rln_core.h_loan_apps_others
		(
			rename=(oa_amt=oa_amt_cma)
			where=( mis_date ge &init_date. and product_type_2 not in ('TelCo','TPT','Pandas') and product_type_3 ne 'MediaMarkt' 
					and vendedor_cadena_top_name not in ('MediaMarkt,','YOIGO','Yoicard','Yoigo') and vendedor_cadena_name ne 'YOIGO'
					and  product_core = 'Y' and status_name in ('Canceled','Rejected','Expired') and flag_tpt='N' 
					and product_code_3 not in ('TPTG','TPTI','DPY','TUG','TUI','CCG','FL','FLG'))
		)
		rcc_core.h_card_apps_booked 
		(
			rename=(cma=oa_amt_cma)
			where=(	mis_date ge &init_date. and product_core = 'Y'  
				    and vendedor_cadena_top_name not in ('MediaMarkt','YOIGO','Yoicard','Yoigo') and vendedor_cadena_name ne 'YOIGO' 
					and product_code_3 not in ('TPTG','TPTI','DPY','TUG','TUI','CCG','FL','FLG')	
					and product_type_2  in ('TJ Atypical','TJ Auto','TJ Direct','TJ Traditional'))

		)
		rcc_core.h_card_apps_others
		(
			rename=(cma=oa_amt_cma)
			where=(	mis_date ge &init_date. and product_core = 'Y' 
				    and vendedor_cadena_top_name not in ('MediaMarkt','YOIGO','Yoicard','Yoigo') and vendedor_cadena_name ne 'YOIGO'  
					and product_code_3 not in ('TPTG','TPTI','DPY','TUG','TUI','CCG','FL','FLG')
					and product_type_2  in ('TJ Atypical','TJ Auto','TJ Direct','TJ Traditional') 
					and status_name in ('Canceled','Rejected','Expired'))
		)
;
run;
