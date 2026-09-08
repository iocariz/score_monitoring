/**UPDATE**/

*%LET last_date_txt = 202603;

DATA sm_tmp.sm_demand_CTLM_END_U(WHERE=(MIS_DATE GE '01JAN2021'D));
	SET sm_BK.SM_DEMAND_CTLM_END_U_&last_date_txt(WHERE=(mis_date LT &init_date.))
		sm_tmp.SM_DEMAND_CTLM_END;		
RUN;

proc sort data=sm_tmp.sm_demand_CTLM_END_U nodupkey;
by authorization_id;
run;


proc sql;
select	max(mis_date) as max_data format=ddmmyy10.,
		min(mis_date) as min_data format=ddmmyy10.
from 	sm_tmp.sm_demand_CTLM_END_U
where 	nota ne .;
quit;
	
proc sql;
select	max(mis_date) as max_data format=ddmmyy10.,
		min(mis_date) as min_data format=ddmmyy10.
from 	sm_tmp.sm_demand_CTLM_END_U;
quit;

