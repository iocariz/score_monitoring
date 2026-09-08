%let vars = ID_FECHA, EDAD, TIPODOCUM_ID, DEUDA, RATFACINCFACPAG_NUM_J, NUMINCIDPAGO_NUM, 
			NUMFACTURASPAG_NUM, ANTIGCLI, NUMFACTURASDEV_NUM_J, NUMFACTURASEMIT_NUM_J,
			INTERCONEXIONES, MAXMONTHLYAVGETURNOVER, PERCENTIL_ADMIN, INDACCESOINFORMA,
			B20CREDITO_NUM, ANTIGEMPRESA_NUM, EMPLEADOS_NUM, NUMFACTURASPAG_NUM_J, PRED_PERCENTIL, 
			RAT_LIQUIDEZ, RAT_ENDEUDA, PRED_PROBABILIDAD_IMPAGO, IMPIMPAGENCOBROS_NUM, MONTHS_PORTABILITY_NUM, 
			SCORECARD_ID, PUNTUACION, REGLAMASPRIORITARIA,CODRESP,LIMITEDISPOSITIVOS,
			NUMFACTURASDEV_NUM_12M_Y, RATFACDEVFACTEMIT_NUM_Y, NUMFACTURASDEV_NUM_Y, NUMFACTEMIT_NUM_Y, 
			FACTURACIONMEDIAMENS_6M_MM, NUMFACTURASDEV_NUM_12M_MM, NUMFACTEMIT_NUM_MM, RATFACDEVFACTEMIT_NUM_MM,
			NUMFACTURASDEV_NUM_MM,
			EDAD_RANGO_NIE 
			 ;

%let CnOp = &cad_ADC2in.;
%let CnCl = &cad_ADCout.;
%let conexion_oracle= &cad_ADC2in.; 

proc sql;
			&conexion_oracle.;
			create table sm_tmp.osp_ic3 as
			select * from connection to oracle(
				select 		
					to_char(a.VAP_ID) as VAP_ID,
					&vars.
				from 
					DWHEVOL.IC9_3 a	
				);			
			&CnCl.;
		quit;

data sm_tmp.osp_ic3(drop=puntuacion);
	set sm_tmp.osp_ic3;
	ZXNOTA = PUNTUACION;

	if REGLAMASPRIORITARIA IN ('AP01','AR01','AP03') THEN VALID_CALL = 'N';
	ELSE VALID_CALL = 'Y';
run;

DATA CHECK;
	SET sm_tmp.osp_ic3;
	WHERE VALID_CALL = 'N';
	KEEP REGLAMASPRIORITARIA CODRESP ;
RUN;

proc sql;
	create table 	sm_tmp.osp_ic3 as
		select		a.*,
					b.*,
					c.*, 
					d.*
		from 		sm_tmp.osp_ic3 as a	
		left join	sm_tmp.SCORECARD_5_TIPODOCUMADM as b
		on			a.vap_id=b.vap_id
		left join	sm_tmp.SCORECARD_96_PERCENTIL as c
		on			a.vap_id=c.vap_id
		left join	sm_tmp.SCORE_CARD_17_RATFACPAGNUNMINC as d
		on			a.vap_id=d.vap_id
	;
quit;

proc sql;
	create table 	sm_tmp.osp_ic3 as
		select		a.*,
					b.numincidpago_num_titular as NUMINCIDPAGO_NUM_97,
					c.MAXMONTHLYAVGETURNOVER_titular as MAXMONTHLYAVGETURNOVER_5
		from 		sm_tmp.osp_ic3 as a	
		left join	sm_tmp.score_cards_97_numincidpago as b
		on			a.vap_id=b.vap_id
		left join	sm_tmp.score_cards_5_maxmonthlyavge as c
		on			a.vap_id=c.vap_id
	
	;
quit;

data sm_tmp.osp_ic3;
	set sm_tmp.osp_ic3;

	if NUMINCIDPAGO_NUM_97 ne . then NUMINCIDPAGO_NUM= NUMINCIDPAGO_NUM_97;
	if MAXMONTHLYAVGETURNOVER_5 ne . then MAXMONTHLYAVGETURNOVER= MAXMONTHLYAVGETURNOVER_5;
run;

data check;
	set sm_tmp.osp_ic3;
	where scorecard_id = 17 and RATFACPAGNUNMINC ne .;
run;

DATA CHECK;
	SET sm_tmp.osp_ic3;
	keep vap_id CTI_BD_PERCENTIL RATFACPAGNUNMINC;
	WHERE SCORECARD_ID in (1,2,3);
RUN;

PROC CONTENTS DATA=R_EVO2.IC9_3 OUT=IC9_3;
RUN;

