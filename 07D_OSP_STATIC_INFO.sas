PROC SQL;
CREATE TABLE 
	INFO_GENERAL_VAP_ORN AS
select 
	input(BNP_INTERNAL_ID, 14.) AS account_id format=14.,
    GEN.VAP_ID as VAP_ID,
	length(GEN.VAP_ID) as long,
	VAP_ENTITY
from 
	DLP.VAP_GENERAL_DATA GEN;
RUN;

data  sm_tmp.sm_demand_osp
		(keep =	mis_date open_date account_id decision_date status_app_id entry_date due_date_1st status_name account_id customer_id  authorization_id 
		product_type_1-product_type_4 product_code: red_name scrv_customer_init SCRV_customer_Group_init vendedor_: tenor_init oa_amt_cma 
		fuera_norma file_id product_core TIN installment_amt_init material: origen_name dni_t1 nature_holder/*se_decision_id*/) ;

	set rln_cor2.h_loan_apps_booked 
		(
			rename=(oa_amt=oa_amt_cma)
			
		)
		rln_cor2.h_loan_apps_others
		(
			rename=(oa_amt=oa_amt_cma)
		)
;
run;

proc sql;
	create table 
		sm_tmp.sm_demand_osp as
		select
			a.*,
			b.vap_id,
			b.vap_entity
		from 
			sm_tmp.sm_demand_osp as a
		inner join 
			INFO_GENERAL_VAP_ORN(where=(VAP_ENTITY not in ('ORS','JZS'))) as b
		on	
			a.account_id = b.account_id
;
quit; 

proc freq data=sm_tmp.sm_demand_osp;
tables vap_entity;
run;
