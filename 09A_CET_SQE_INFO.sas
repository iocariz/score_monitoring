/***DWH***/

PROC SQL;
CREATE TABLE 	sm_tmp.SQUE_DATA AS
	SELECT		a.*
	FROM		R_ORA4.LETRA_SCRV_H as a
	WHERE 		/*a.lscrv in ('A','B','C','D','E','F','G','H','I','J','K') 
	AND			*/a.nota ne . 
	AND 		fecha_base ge "&init_date_1m_txt."

UNION ALL

	SELECT		a.*
	FROM		R_ORA4.LETRA_SCRV as a
	WHERE 		/*a.lscrv in ('A','B','C','D','E','F','G','H','I','J','K')
	AND 		 */a.nota ne .
;
QUIT;
DATA sm_tmp.SQUE_DATA;
	FORMAT MIS_DATE MIS_DATE_1M DDMMYY10. CUSTOMER_ID 12.;
	SET sm_tmp.SQUE_DATA;
	mis_date = intnx('month',input(fecha_base,yymmn6.),0,'BEG');
	mis_date_1m =intnx('month',mis_date,1,'BEG');
	CUSTOMER_ID = INPUT(CLIENTE,12.);
	keep customer_id MIS_DATE mis_date_1m nota lscrv var:;
RUN;
PROC SQL;
CREATE TABLE 	sm_tmp.sm_demand_CTLM_END AS
	SELECT		A.*,
				B.*
	FROM		sm_tmp.sm_demand_CTLM_END AS A
	LEFT JOIN	sm_tmp.SQUE_DATA AS B
	ON			A.CUSTOMER_ID=B.CUSTOMER_ID
	AND			A.MIS_DATE =B.MIS_DATE_1M;
QUIT;


proc sql;
select	max(mis_date) as max_data format=ddmmyy10.,
		min(mis_date) as min_data format=ddmmyy10.
from 	sm_tmp.sm_demand_CTLM_END
where 	nota ne .;
quit;
	
proc sql;
select	max(mis_date) as max_data format=ddmmyy10.,
		min(mis_date) as min_data format=ddmmyy10.
from 	sm_tmp.sm_demand_CTLM_END;
quit;