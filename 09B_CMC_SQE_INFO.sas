/***DWH***/

PROC SQL;
CREATE TABLE 	sm_tmp.CMC_SQUE_DATA AS
	SELECT		a.*
	FROM		r_ADC8.LETRA_SCRV_H as a
	WHERE 		/*a.lscrv in ('A','B','C','D','E','F','G','H','I','J','K') 
	AND			*/a.nota ne . 
	AND 		fecha_base ge "&init_date_1m_txt."

UNION ALL

	SELECT		a.*
	FROM		r_ADC8.LETRA_SCRV as a
	WHERE 		/*a.lscrv in ('A','B','C','D','E','F','G','H','I','J','K')
	AND 		 */a.nota ne .
;
QUIT;
DATA sm_tmp.CMC_SQUE_DATA;
	FORMAT MIS_DATE MIS_DATE_1M DDMMYY10. CUSTOMER_ID 12.;
	SET sm_tmp.CMC_SQUE_DATA;
	mis_date = intnx('month',input(fecha_base,yymmn6.),0,'BEG');
	mis_date_1m =intnx('month',mis_date,1,'BEG');
	CUSTOMER_ID = INPUT(CLIENTE,12.);
	keep customer_id MIS_DATE mis_date_1m nota lscrv var:;
RUN;
PROC SQL;
CREATE TABLE 	sm_tmp.sm_demand_cmc_END AS
	SELECT		A.*,
				B.*
	FROM		sm_tmp.sm_demand_cmc_END AS A
	LEFT JOIN	sm_tmp.CMC_SQUE_DATA AS B
	ON			A.CUSTOMER_ID=B.CUSTOMER_ID
	AND			A.MIS_DATE =B.MIS_DATE_1M;
QUIT;
