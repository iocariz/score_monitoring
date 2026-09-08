/**UPDATE**/
DATA sm_tmp.sm_demand_OSP_END_U(WHERE=(MIS_DATE GE '01JAN2020'D));
	SET /*sm_BK.SM_DEMAND_OSP_END_U_&last_date_txt(WHERE=(mis_date LT &init_date.))*/
		sm_tmp.SM_DEMAND_OSP_END;		
RUN;
/*
proc freq data=sm_BK.sm_demand_OSP_END_U_&last_date_txt;
tables mis_date*status_name;
run;

proc freq data=sm_tmp.SM_DEMAND_OSP_END;;
tables mis_date*status_name;
run;

proc freq data=sm_tmp.sm_demand_OSP_END_U;
tables mis_date*status_name;
run;

proc sort data=sm_tmp.sm_demand_OSP_END_U nodupkey;
by authorization_id;
run;
*/

proc sql;
create table sum as
	select
		put(mis_date, yymmd7.) as mis_date,
		scorecard_id,
		sum(oa_amt_cma) as oa_amt_cma
	from
		sm_tmp.sm_demand_OSP_END_U
	where
		valid_call = 'Y'
	group by 1,2;
quit;

proc freq data=sm_tmp.SM_DEMAND_OSP_END;
tables mis_date;
run;