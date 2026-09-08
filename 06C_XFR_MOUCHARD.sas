%let vars_wacc = 	ANCBQ
					ANCHAB
					ANCPROF
					cagence
					CHAINE
					CPRO
					cptestu
					dtrt
					FNACT1
					FNACT2
					FPAGO
					HORA
					MDECCENT
					MENSCENT
					MENSTJ
					MENSUDOS
					MOPCENT
					MSAL1
					MSAL2
					numaut
					NUMVDR
					RED
					RVIVOACT
					TIPOTRAN
					zdecis
					zrech
					zscraplica
					SITHAB
					SITFAM
					DISMAXTJ
					NDOSCAMR
					CPTLT1
					DURDEG
					CSP
					CSP2
					CMAT
					TEMPORAL
					XSCORE
					XNOTA
					SOCIEDAD
					tipoinst
					aplica
					csector
					SCRPLUS:
					ZRF1SCORE 
					ZFRAUDSCR
					MENTPRFT
					CODRAMA
					FCHTEMP
					NBENF
					TODUMR1
					NDOSCLMR
					NOP30CL1
					NOP30TJ1
					TEMPORAL
					CRUTACR
					CMATACR
					ESTCLI1 
					ESTCLI2
					CRLSIG 
					ZDISPO
					TIPNACT1
					FECADRES
					SWRENOV
					NIFT2
					proced
					grproced
					INCI:
					ZVERS
;

%let out_vars_trazas = 	ANCBQ
						ANCHAB
						ANCPROF
						cagence
						CHAINE
						CPRO
						cptestu
						dtrt
						FNACT1
						FNACT2
						FPAGO
						HORA
						MDECCENT
						MENSCENT
						MENSTJ
						MENSUDOS
						MOPCENT
						MSAL1
						MSAL2
						numaut
						NUMVDR
						RED
						RVIVOACT
						TIPOTRAN
						zdecis
						zrech
						zscraplica
						SITHAB
						SITFAM
						DISMAXTJ
						NDOSCAMR
						CPTLT1
						DURDEG
						CSP
						CSP2
						CMAT
						TEMPORAL
						ZXSCORE
						XNOTA
						SOCIEDAD
						tipoinst
						aplica
						csector
						SCRPLUS:
						ZRF1SCORE 
						ZFRAUDSCR
					    MENTPRFT
						CODRAMA
						FCHTEMP
						NBENF
						TODUMR1
						NDOSCLMR
						NOP30CL1
						NOP30TJ1
						TEMPORAL
						CRUTACR
						CMATACR
						ESTCLI1 
						ESTCLI2 
						CRLSIG 
						ZDISPO
						TIPNACT1
						FECADRES
						SWRENOV
						NIFT2
						proced
						grproced
						INCI:
						ZVERS
						;

/***DWH***/
data sm_tmp.XFR_se_info_wacc(keep=SE_history_date CHG_DAY CHG_TIME se_cptestu Authorization_id &out_vars_trazas.);
 set R_ADC6.SE_ESTU_WEB_WACC(keep=&vars_wacc. 
							 where=((tipotran is null or tipotran not in ('CLIR','PAGO','PAGR','RESU','ESTR','ACOM','RESA')
									and sociedad eq '600' and DTRT >="&init_date_se_txt."))
							 /*where=((tipotran is null or tipotran not in (/'CLIR','CLIE','ESTR','PAGR','PAGO','RESU','ACOM','RESA','EST1')) and sociedad eq '400' and DTRT >='201710')*/

							 rename= (
											XSCORE = ZXSCORE 
									  )
							);	



 SE_history_date=mdy(input(substr(put(dtrt,8.),5,2),2.),1,input(substr(put(dtrt,8.),1,4),4.));
 format SE_history_date ddmmyy10.;informat SE_history_date ddmmyy10.;

 CHG_DAY  = input(DTRT,14.);  format CHG_DAY  14.;  informat CHG_DAY  14.;
 CHG_TIME = input(HORA,6.);   format CHG_TIME  8.;  informat CHG_TIME  8.;

 /*SE_CPTESTU = input(CPTESTU,3.); format SE_CPTESTU  3.;  informat SE_CPTESTU  3.;*/
 se_cptestu=cptestu;

 Authorization_id= input(tranwrd(numaut, "C", "4"),11.); format Authorization_id 11.; informat Authorization_id 11.;

 if cptestu ne 11 and Authorization_id ne .;
run;


%let varlist = 		 FNACT1
					 FNACT2
					 CPTLT1
					 SITFAM
					 SITHAB
					 ANCHAB 
					 ANCPROF
					 ANCBQ 
					 DURDEG 
					 NUMVDR 
					 CAGENCE
					 CHAINE 
					 RED 
					 DISMAXTJ
					/* ZXNOTA */
					 SOCIEDAD
					 NBENF
					 CODRAMA
					 MENTPRFT
					 FCHTEMP
					 TODUMR1
					 ZDISPO
					 FECADRES
					 ZSEGM
					 ANCLIBC1
					 SIPABC1


;

%let nvars=%sysfunc(countw(&varlist));
%put &nvars.;
%macro renamer;
 %do i=1 %to &nvars;
 rename x&i = %scan(&varlist,&i) ;
 %end;
%mend renamer; 
data sm_tmp.XFR_se_info_wacc;
	set sm_tmp.XFR_se_info_wacc;

	array charx(&nvars.) &varlist.;
	array x(&nvars.);
	do i=1 to  &nvars.;
		x(i)=input(charx{i},best12.);
	end;
	drop &varlist. i;
	%renamer;
run; 

data sm_tmp.XFR_se_info_wacc;
	set sm_tmp.XFR_se_info_wacc;
	format zxnota 30.;
	zxnota = input(xnota, best32.);
run;


proc sql;
create table num_calls as
	select numaut, count(*) as n_calls
	from sm_tmp.XFR_se_info_wacc
	group by 1;
quit;
proc sql;
create table num_clie as
	select numaut, count(*) as n_clie
	from 	sm_tmp.XFR_se_info_wacc
	where TIPOTRAN = 'CLIE'
	group by 1;
quit;

proc sql;
create table 	sm_tmp.XFR_se_info_wacc  as
	select		a.*,
				b.n_calls,
				c.n_clie
	from		sm_tmp.XFR_se_info_wacc  as a
	left join	num_calls as b
	on			a.numaut=b.numaut
	left join	num_clie as c
	on			a.numaut=c.numaut;
quit;
data sm_tmp.XFR_se_info_wacc;
	set sm_tmp.XFR_se_info_wacc;
	if n_clie >= 1 and n_calls > 1 and TIPOTRAN = 'CLIE' then delete;
run;
proc sort data=sm_tmp.XFR_se_info_wacc out=sm_tmp.XFR_se_info_all2_sort;
	by Authorization_id CHG_DAY CHG_TIME se_cptestu;
run;
data sm_tmp.XFR_se_info_ccm_last;
	set sm_tmp.XFR_se_info_all2_sort;
	by Authorization_id CHG_DAY CHG_TIME se_cptestu;
	if last.authorization_id;
run;
data sm_tmp.XFR_se_info_ccm_last;
	set sm_tmp.XFR_se_info_ccm_last;
	if tipotran in ('EST1','CLIE') then VALID_CALL = 'N';
	ELSE VALID_CALL = 'Y';
run;


proc freq data=sm_tmp.XFR_se_info_ccm_last;
tables tipotran*red;
run;
proc delete data=sm_tmp.XFR_se_info_all2_sort;run;
proc delete data=sm_tmp.XFR_se_info_all2;run;
proc delete data=sm_tmp.XFR_se_info;run;
proc delete data=sm_tmp.XFR_se_info_wacc2;run;
proc delete data=sm_tmp.XFR_se_info_wacc;run;
proc freq data=sm_tmp.XFR_se_info_ccm_last;
tables proced*grproced;
run;

