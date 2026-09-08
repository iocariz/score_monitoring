%let vars = mis_date status_app_id decision_date status_name open_date entry_date account_id customer_id nif file_id due_date_1st
			product_core product_code: product_type_1-product_type_4 TIN tenor_init installment_amt_init SCRV_customer_init 
			SCRV_customer_group_init vendedor_: material: origen_name oa_amt_cma income_t1t2_m 
			authorization_id se_decision_id flag_tpt precon_ind red_name origen_name fuera_norma ad_albaran_id flag_precon;

data sm_tmp.sm_demand_cmc(keep=&vars.);
	set rln_cor8.h_loan_apps_booked(rename=(oa_amt=oa_amt_cma) where=(mis_Date >= &init_date. and product_core = 'Y' and flag_tpt = 'N'))
		rln_cor8.h_loan_apps_others(rename=(oa_amt=oa_amt_cma) where=(mis_Date >= &init_date. and product_core = 'Y' and flag_tpt = 'N'))
		rcc_cor8.h_card_apps_booked(rename=(cma=oa_amt_cma) where=(mis_Date >= &init_date. and product_core = 'Y' and product_type_3 ne 'Bicontrato'))/*modificamos el product_type_2 por product_type_3, ya que se ha modificado el agregado*/
		rcc_cor8.h_card_apps_others(rename=(cma=oa_amt_cma) where=(mis_Date >= &init_date. and product_core = 'Y' and product_type_3 ne 'Bicontrato'));;/*modificamos el product_type_2 por product_type_3, ya que se ha modificado el agregado*/
run;

proc freq data=sm_tmp.sm_demand_cmc;
tables mis_date*status_name;
run;

proc sql;
create table sm_tmp.sm_demand_cmc as
	select a.*,
		   b.zsegm
	from   sm_tmp.sm_demand_cmc as a
	left join sm_tmp.CCM_se_info_ccm_last as b
	on 	   a.authorization_id=b.authorization_id;	
quit;

data sm_tmp.sm_demand_cmc;
	set sm_tmp.sm_demand_cmc;
	if product_type_2 = 'Other' then 
		do;
			if ZSEGM in (5,6,7) then
			do;
				product_type_2 ='Consolidation'; 
				product_type_3 ='Consolidation';
			end;
			else if ZSEGM=1 then 
			do;
				product_type_2 ='New/Inactive'; 
				product_type_3 ='HP';
			end;
			else if ZSEGM=2 then 
			do;
				product_type_2 ='New/Inactive'; 
				product_type_3 ='MP';
			end;
			else if ZSEGM=3 then 
			do;
				product_type_2 ='Known'; 
				product_type_3 ='Premium';
			end;
			else if ZSEGM=4 then 
			do;
				product_type_2 ='Known'; 
				product_type_3 ='No Premium';
			end;
		end;

run;


proc freq data=sm_tmp.sm_demand_cmc;
tables mis_Date*product_type_1;
run;