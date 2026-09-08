/**UPDATE**/

*%LET last_date_txt = 202509;

DATA sm_tmp.sm_demand_XFR_END_U(WHERE=(MIS_DATE GE '01JAN2020'D));
	SET sm_BK.SM_DEMAND_XFR_END_U_&last_date_txt(WHERE=(mis_date LT &init_date.))
		sm_tmp.SM_DEMAND_XFR_END;		
RUN;

proc freq data=sm_BK.sm_demand_XFR_END_U_&last_date_txt;
tables mis_date*status_name;
run;

proc freq data=sm_tmp.SM_DEMAND_XFR_END;;
tables mis_date*status_name;
run;

proc freq data=sm_tmp.sm_demand_XFR_END_U;
tables mis_date*status_name;
run;

proc sort data=sm_tmp.sm_demand_XFR_END_U nodupkey;
by authorization_id;
run;
