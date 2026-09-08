data sm_tmp.sm_demand_cmc;
	set sm_tmp.sm_demand_cmc;
	if status_name = 'Booked' and product_type_1='Card' then order = 2;
	else if status_name = 'Booked' then order=1;
	else order = 0;
run;

proc sort data=sm_tmp.sm_demand_cmc;
by authorization_id order;
run;

data sm_tmp.sm_demand_cmc;
	set sm_tmp.sm_demand_cmc;
	by authorization_id order;
	if last.authorization_id then output;
run;

proc sql;
create table	sm_tmp.sm_demand_cmc_2 as
	select		a.*,
				b.*
	from		sm_tmp.sm_demand_cmc as a
	inner join	sm_tmp.CCM_se_info_ccm_last as b
	on			a.authorization_id=b.authorization_id;	
quit;

data sm_tmp.sm_demand_cmc_3(drop=f1 f2 fecha1_date fecha2_date dif_meses);
	length final_decision tipo_cliente_cmc canal_cmc $ 50.;
	set sm_tmp.sm_demand_cmc_2(where=(status_name ne 'Pending'));

	year = year(mis_date);
	if status_name='Expired' then status_name='Canceled';

	length SE_Decision_id $2.;
	select(input(zdecis,3.));  
	  	when (10) 			SE_Decision_id='OK';
		when (25) 			SE_Decision_id='KO';
		when (0) 			SE_Decision_id='RV';
		otherwise 			SE_Decision_id='??';
	end;

	if cagence=899 then canal_cmc="SUCURSAL";
	else if cagence=801 then canal_cmc="CALL CENTER";	
	else if cagence=897 then canal_cmc="WEB";
	else canal_cmc="OTRO";

	f1 = CHG_DAY;
	f2 = ANCLIBC1;

	fecha1_date = mdy((mod((int(f1/100)),100)),(mod(f1,100)),(int(f1/10000)));
	fecha2_date = mdy((mod((int(f2/100)),100)),(mod(f2,100)),(int(f2/10000)));

	dif_meses=intck('month',fecha2_date,fecha1_date);

	if RVIVOACT in (' ','1','2','6','8','Y','Z','5','7') and dif_meses <= 6 													then tipo_cliente_cmc="Cliente nuevo BCC";
	else if RVIVOACT in (' ','1','2','6','8','Y','Z','5','7','A','B','C','D','E') and dif_meses > 6 and PLTBC1 in ('0','') 		then tipo_cliente_cmc="Cliente inactivo BCC";
	else if RVIVOACT in (' ','1','2','6','8','Y','Z','5','7','A','B','C','D','E') and dif_meses > 6 and PLTBC1 not in ('0','') 	then tipo_cliente_cmc="Cliente conocido BCC";
	else if RVIVOACT in ('A','B','C','D','E') and dif_meses <= 6  																then tipo_cliente_cmc="Cliente conocido BCC";
	else if RVIVOACT in ('A','B','C','D','E','F','G','H','I','J','K','Q','R','W','X') 											then tipo_cliente_cmc="Cliente conocido GCC";
	else 																															 tipo_cliente_cmc="Cliente Otros";

	if status_name ne 'Booked' then 
		do;
			open_date = .;
			if decision_date = . and entry_date ne . then  decision_date = entry_date;
		end;
	else if decision_date = . and open_date ne . then  decision_date = open_date;

	if se_decision_id = 'KO' then 
		do;
			if 		status_name = 'Booked'   then final_decision = 'Auto Decline & Booked';
			else if status_name = 'Rejected' then final_decision = 'Auto Decline & Rejected';
			else if status_name = 'Canceled' then final_decision = 'Auto Decline & NTU';
		end;
	else if se_decision_id = 'RV' then 
		do;
			if 		status_name = 'Booked'   then final_decision = 'Referral & Booked';
			else if status_name = 'Rejected' then final_decision = 'Referral & Rejected';
			else if status_name = 'Canceled' then final_decision = 'Referral & NTU';
		end;
	else if se_decision_id = 'OK' then 
		do;
			if 		status_name = 'Booked'   then final_decision = 'Auto Accept & Booked';
			else if status_name = 'Rejected' then final_decision = 'Auto Accept & Rejected';
			else if status_name = 'Canceled' then final_decision = 'Auto Accept & NTU';
		end;
	else
		do;
			if 		status_name = 'Booked'   then final_decision = 'Unknown & Booked';
			else if status_name = 'Rejected' then final_decision = 'Unknown & Rejected';
			else if status_name = 'Canceled' then final_decision = 'Unknown & NTU';
		end;
run;


proc sql ;			
	select "'"||diagEstudio||"'" into: ko_others separated by ', ' 		
	from r_sid8.M_DIAG_ESTUDIO		
	where origen = 'T' and substr(compress(descripcion), 1, 1) = "*"; /*and diagEstudio ^= '477'  Disponible insuficiente */;		
quit;	

proc sql noprint;			
	select "'"||diagEstudio||"'" into: rv_alerts separated by ', ' 		
	from r_sid.M_DIAG_ESTUDIO		
	where origen = 'T' and substr(compress(descripcion), 1, 1) = "#"; /*and diagEstudio ^= '402';  Asnef nombre --> discard in November, high volumen for self employees */		
quit;
proc sql noprint;
	select distinct "'"||compress(diagEstudio)||"'" into : ko_compliance separated by ', '
	from r_sid8.M_DIAG_ESTUDIO		
	where (index(upcase(descripcion), 'SANCIONADOS T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'SCORE HR T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'INCID AML T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'COD PDTE AML T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'NAC MSC') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'DILIG IMPORTE') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'DILIG CONTRAT') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'DNI CADUC') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'SALARIO BAJO') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'CSP DESC') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'ORI INGRESO') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'CSP DILIG') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T')
; 
quit;
proc sql ;
	select distinct "'"||compress(diagEstudio)||"'" into : ko_fallo_consultas separated by ', '
	from r_sid8.M_DIAG_ESTUDIO		
	where (index(upcase(descripcion), 'FALLO ASNEF T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'FALLO BUREAU T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'FALLO SC EFX') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'FALLO SCORE HR') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'FALLO SANCIONADOS T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') 
; 
quit;

proc sql noprint;
	select distinct "'"||compress(diagEstudio)||"'" into : ko_ficheros_neg separated by ', '
	from r_sid8.M_DIAG_ESTUDIO		
	where (index(upcase(descripcion), 'ASNEF T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'BUREAU T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'ASNEF T2') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'BUREAU T2') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T')
; 
quit;

proc sql ;
	select distinct "'"||compress(diagEstudio)||"'" into : ko_fraude separated by ', '
	from r_sid8.M_DIAG_ESTUDIO		
	where (index(upcase(descripcion), 'COD FRAUDE T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'COD FRAUDE T2') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'ALERTA LN') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'MARCA PREVIA PF') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') OR
	(index(upcase(descripcion), 'PERFIL FR') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') OR
	(index(upcase(descripcion), 'ALERTA ID') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') 
; 
quit;

proc sql noprint;
	select distinct "'"||compress(diagEstudio)||"'" into : ko_normativa separated by ', '
	from r_sid8.M_DIAG_ESTUDIO		
	where (index(upcase(descripcion), 'CTX T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'TJS PREAUT') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'CSP NO TJ') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'CMA>CAMAX') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'PROFESION NO FINAN') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'EDAD T1 > PROD') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'NO TRABAJA') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'EDAD MINIMA') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'CSP/ANTG ACTIV') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'RE/PERFIL') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T')  or
	(index(upcase(descripcion), 'T1-RE ANTERIOR') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'TEMPORAL/CREDI') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'FIRMA COTITULAR') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'PERFIL NO PERMITIDO') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'NUM OP MES') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T')	 OR
	(index(upcase(descripcion), 'MAX_SOL_MES') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'IMP CESP') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T')
; 
quit;

proc sql noprint;
	select distinct "'"||compress(diagEstudio)||"'" into : ko_presupuesto separated by ', '
	from r_sid8.M_DIAG_ESTUDIO		
	where (index(upcase(descripcion), 'DTI MAX') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'ING MIN') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'DISPO INSUFICI') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'ING1 < SMI') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'GOLDEN RULE') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T')
; 
quit;
proc sql noprint;
	select distinct "'"||compress(diagEstudio)||"'" into : ko_producto separated by ', '
	from r_sid8.M_DIAG_ESTUDIO		
	where (index(upcase(descripcion), 'ORDERDID FIN') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'ORDERDID AU') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'FIRMA CL') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'IMP NO PERMITIDO') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'MENS MINIMA') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'MATERIAL/DURAC') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') 
; 
quit;

proc sql noprint;
	select distinct "'"||compress(diagEstudio)||"'" into : ko_riesgo_cliente separated by ', '
	from r_sid8.M_DIAG_ESTUDIO		
	where (index(upcase(descripcion), 'INCIDENCIAS T1') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'INCIDENCIAS T2') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or 
	(index(upcase(descripcion), 'INCIDENCIA MM') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') 
; 
quit;

proc sql ;
	select distinct "'"||compress(diagEstudio)||"'" into : ko_score separated by ', '
	from r_sid8.M_DIAG_ESTUDIO		
	where (index(upcase(descripcion), 'FUERA SCORE') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T') or
	(index(upcase(descripcion), 'PERFIL RIESGO') > 0 and substr(compress(descripcion), 1, 1) = "*" and origen = 'T')
; 
quit;
%macro iterAllAlerts(field = zrech);	
	%do i = 0 %to 87 %by 3;		
		ZRECH__%eval((&i.+3)/3) 	= input(substr(&field., %eval(&i.+1), 3), 8.);	
		alert_%eval((&i.+3)/3) 		= input(substr(&field., %eval(&i.+1), 3), 8.);	
		ko_others_%eval((&i.+3)/3)  = (alert_%eval((&i.+3)/3) in (&ko_others.));	
		ko_score_%eval((&i.+3)/3)    = (alert_%eval((&i.+3)/3) in (&ko_score.));
		rv_alert_%eval((&i.+3)/3)   = (alert_%eval((&i.+3)/3) in (&rv_alerts.));
	%end;		
%mend;	

%macro iterSpecificAlert(type = );
	if %do i = 1 %to 29; ZRECH__&i. in (&&&type.) or %end; ZRECH__30 in (&&&type.) then &type. = 1; else &type. = 0;	
%mend;	

options mprint;	
data sm_tmp.sm_demand_cmc_4;
	length reject_reason $50.;	
	set sm_tmp.sm_demand_cmc_3;;
	
	%iterAllAlerts;		

	%iterSpecificAlert(type = ko_score); /*1*/
	%iterSpecificAlert(type = ko_riesgo_cliente); /*2*/
	%iterSpecificAlert(type = ko_producto); /*3*/
	%iterSpecificAlert(type = ko_presupuesto); /*4*/
	%iterSpecificAlert(type = ko_normativa); /*5*/
/*	%iterSpecificAlert(type = ko_fraude); */
	%iterSpecificAlert(type = ko_ficheros_neg); /*7*/
/*	%iterSpecificAlert(type = ko_fallo_consultas); */
	%iterSpecificAlert(type = ko_compliance); /*9*/

	num_ko_others = sum(of ko_others_:);
	num_rv_alerts =	sum(of rv_alert_:);
	num_ko_score = sum(of ko_score_:);

	IF SE_Decision_id = 'KO' THEN
		DO;
			if 		ko_riesgo_cliente = 1 then reject_reason = '01-CUSTOMER RISK';
			else if ko_ficheros_neg = 1 then reject_reason = '02-BUREAUX';
			else if ko_presupuesto = 1 then reject_reason = '03-BUDGET';
			else if ko_normativa = 1 then reject_reason = '04-CUSTOMER PROFILE';
			else if ko_fraude = 1 then reject_reason = '05-FRAUD';
			else if ko_compliance = 1 then reject_reason = '06-COMPLIANCE'; 
			else if ko_producto = 1 then reject_reason = '07-PRODUCT';
			/*else if ko_fallo_consultas = 'Y' then reject_reason2 = '20-FALLO CONSULTAS';*/
			else do;
					reject_reason = '08-OTHER';
					ko_others = 1;
				 end;
			if reject_reason = '08-OTHER' and ko_score = 1 and num_ko_others = num_ko_score then 
				do;
					reject_reason = '09-SCORE';
					flag_score_rj=1;
				end;
		END;

	  if flag_score_rj = 1 and num_rv_alerts > 0 then ind_only_score_rv = 1;
	  else ind_only_score_rv = 0; 
	
	  if flag_score_rj = 1 then ind_only_score = 1;
	  else ind_only_score = 0;
run;


/***************FRAUD FLAGS*********************/
data fraude_mensual fraude_acc fraude_auth;
	format CLASIFICACION_DATE DETECCION_DATE ddmmyy10. account_id 14. authorization_id 10.;
	set R_BI8.RAW_FRAUDE_MENSUAL;
	KEEP authorization_id account_id FCH_BASE AUTORIZACION CLASIFICACION AGENTE_DETECCION 
		 TIPO_ALERTA MOTIVO_FRAUDE ALERTA_FK ORIGEN_DETECCION PAGADO_EVITADO 
		 IDENTIFIED_TYPE AVOIDED_TYPE MES_CLASIFICACION MES_DETECCION
		 CLASIFICACION_DATE DETECCION_DATE;

	if length(compress(AUTORIZACION)) = 14 then account_id = input(autorizacion,14.);
	else authorization_id =  input(autorizacion,10.);
	CLASIFICACION_DATE = input(cats(MES_CLASIFICACION,"01"),yymmdd8.);
	DETECCION_DATE = input(cats(MES_DETECCION,"01"),yymmdd8.);

	if account_id ne . then output fraude_acc;
	if authorization_id ne . then output fraude_auth;
run;

%include "&sm_code_dir./macros/fraud.sas";
%sm_latest_fraud(data=fraude_acc, key=account_id, out=fraude_acc_sort);
%sm_latest_fraud(data=fraude_auth, key=authorization_id, out=fraude_auth_sort);



proc sql;
create table 	sm_demand_4f as 
	select 		a.*,	
				b.account_id_tpt
	from 		sm_tmp.sm_demand_cmc_4 as a
	left join	SM_TMP.TPT_CARD_CMC as b
	on			a.account_id=b.account_id_tj;
quit;

proc sql;
create table 	sm_demand_5f as
	select 		a.*,
				coalesce(b.CLASIFICACION_DATE, c.CLASIFICACION_DATE, d.CLASIFICACION_DATE) as CLASIFICACION_DATE format=ddmmyy10.,
				coalesce(b.DETECCION_DATE, c.DETECCION_DATE, d.DETECCION_DATE) as DETECCION_DATE format=ddmmyy10.,
				coalesce(b.CLASIFICACION, c.CLASIFICACION, d.CLASIFICACION) as CLASIFICACION,
				coalesce(b.AGENTE_DETECCION, c.AGENTE_DETECCION, d.AGENTE_DETECCION) as AGENTE_DETECCION,
				coalesce(b.TIPO_ALERTA, c.TIPO_ALERTA, d.TIPO_ALERTA) as TIPO_ALERTA,
				coalesce(b.MOTIVO_FRAUDE, c.MOTIVO_FRAUDE, d.MOTIVO_FRAUDE) as MOTIVO_FRAUDE,
				coalesce(b.ALERTA_FK, c.ALERTA_FK, d.ALERTA_FK) as ALERTA_FK,
				coalesce(b.ORIGEN_DETECCION, c.ORIGEN_DETECCION,d.ORIGEN_DETECCION) as ORIGEN_DETECCION,
				coalesce(b.PAGADO_EVITADO, c.PAGADO_EVITADO, d.PAGADO_EVITADO) as PAGADO_EVITADO
	from		sm_demand_4f as a
	left join fraude_acc_sort as b
	on			a.account_id=b.account_id
	left join fraude_auth_sort as c
	on			a.authorization_id=c.authorization_id
	left join fraude_acc_sort as d
	on			a.account_id_tpt=d.account_id;
quit;

data sm_demand_5frud;
	set sm_demand_5f(keep=mis_date authorization_id CLASIFICACION_DATE--PAGADO_EVITADO);
	where CLASIFICACION_DATE ne .;
run;

proc sort data=sm_demand_5frud nodupkey;
by _all_;
run;

proc sort data=sm_demand_5frud;
by authorization_id CLASIFICACION_DATE;
run;

data sm_demand_5frud;
	set sm_demand_5frud;
	by authorization_id;
	if last.authorization_id then output;
run;

proc sql;
create table 	sm_tmp.sm_demand_cmc_5 as 
	select		a.*,
				b.CLASIFICACION_DATE,
				b.DETECCION_DATE,
				b.CLASIFICACION,
				b.AGENTE_DETECCION,
				b.TIPO_ALERTA,
				b.MOTIVO_FRAUDE,
				b.ALERTA_FK,
				b.ORIGEN_DETECCION,
				b.PAGADO_EVITADO
	from		sm_tmp.sm_demand_cmc_4 as a
	left join	sm_demand_5frud as b
	on			a.authorization_id=b.authorization_id;
quit;

data sm_tmp.SM_DEMAND_CMC_END;
	length channel $ 50.;
	set sm_tmp.sm_demand_cmc_5;

	if proced = 'TELEFONO' or CAGENCE eq 801 or NUMVDR eq 2996718 then channel  = 'Call Center'; 
	else if proced = 'SUCURSAL' then channel = 'Branch';
	else if proced = 'CAJAMAR.ES' then channel = 'WEB';
	else if proced ne '' then channel ='WACC';
	else channel ='Other'; 
run;

proc freq data=sm_tmp.sm_demand_cmc;
tables mis_date*product_type_1;
run;


proc delete data=sm_tmp.sm_demand_cmc;run;
proc delete data=sm_tmp.sm_demand_cmc_2;run;
proc delete data=sm_tmp.sm_demand_cmc_3;run;
proc delete data=sm_tmp.sm_demand_cmc_4;run;
proc delete data=sm_demand_5frud;run;
proc delete data=sm_demand_5f;run;
proc delete data=sm_demand_4f;run;

