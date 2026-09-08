/* Copy this file to 00_SETUP.local.sas on your SAS server.
   Populate the blank user, password and connection-string macro variables using
   your site-approved configuration. The local file is excluded from Git.
   Never put real credentials into this example or other tracked files. */
/*********************************************************************************
 PROJECT: score_monitoring
 PURPOSE: Initialization of environment, date variables, and library assignments.
**********************************************************************************/

/* 1. PROJECT DEFINITION */
%let project = score_monitoring;
%let dir     = /risk/actual/&project.;

/*********************************************************************************
 2. MACRO VARIABLES (Date Handling)
*********************************************************************************/
%let _today = %sysfunc(today());

%let init_date     = %sysfunc(intnx(month, &_today, -12, BEG));
%let init_date_se  = %sysfunc(intnx(month, &_today, -24, BEG));
%let init_date_1m  = %sysfunc(intnx(month, &_today, -13, BEG));
%let last_date     = %sysfunc(intnx(month, &_today, -1, BEG));
%let last_date_3m  = %sysfunc(intnx(month, &_today, -4, BEG));

/* Convert to formatted strings/dates for SQL/Logging */
%let init_date_val      = %sysfunc(putn(&init_date, date9.));
%let last_date_3m_val   = %sysfunc(putn(&last_date_3m, date9.));
%let init_date_1m_txt   = %sysfunc(putn(&init_date_1m, YYMMN.));
%let init_date_txt      = %sysfunc(putn(&init_date, YYMMN.));
%let init_date_se_txt   = %sysfunc(putn(&init_date_se, yymmddn8.));
%let last_date_txt      = %sysfunc(putn(&last_date, YYMMN.));
%let last_date_3m_txt   = %sysfunc(putn(&last_date_3m, yymmd7.));

/* Safe Logging using %bquote to prevent recursion errors */
%put NOTE: Project Dates initialized.;
%put NOTE: init_date=%bquote(&init_date_val) %bquote(&init_date_txt);
%put NOTE: last_date_txt=%bquote(&last_date_txt);

/*********************************************************************************
 3. LIBRARY ASSIGNMENTS
**********************************************************************************/

/* Internal Project Libnames */
libname LGD     "/risk/actual/tmp/ifrs_forward/LGD_MS/";
libname sm_bk   "&dir./backup";
libname sm      "&dir.";
libname sm_tmp  "&dir./tmp/sad57";
%let cad_ADCout=;

%let user_dwh =;
%let pw_dwh   =; /* Consider replacing with a secure reference */

/* Macro to simplify Oracle Libname assignments and error checking */
%macro assign_ora(lib=, user=, pw=, path=, schema=);
    libname &lib oracle user=&user pw="&pw" path=&path preserve_tab_names=yes connection=sharedread schema=&schema;
    %if &syserr ne 0 %then %do;
        %put ERROR: Failed to assign libname &lib;
        %abort return;
    %end;
%mend assign_ora;

/* CETELEM Connections */
%assign_ora(lib=r_nd,    user=&user_dwh, pw=&pw_dwh, path=ADC,       schema=NEW_DEFAULT);
%assign_ora(lib=r_sid,   user=&user_dwh, pw=&pw_dwh, path=ADC,       schema=SID001);
%assign_ora(lib=r_ora4,  user=&user_dwh, pw=&pw_dwh, path=ADC,       schema=ADC400EXP);
%assign_ora(lib=r_bi,    user=&user_dwh, pw=&pw_dwh, path=ADC,       schema=DWH_BI);
%assign_ora(lib=r_ifrs9, user=&user_dwh, pw=&pw_dwh, path=ADC,       schema=DWH_IFRS9);
%assign_ora(lib=r_evol,  user=&user_dwh, pw=&pw_dwh, path=ADC,       schema=DWHEVOL);

/* CETELEM Local Files */
libname rcc_core '/risk/actual/cards/core';
libname rcc_base '/risk/actual/cards/base';
libname rcc_adds '/risk/actual/cards/adds';
libname rln_core '/risk/actual/loan/core';
libname rln_base '/risk/actual/loan/base';
libname rln_adds '/risk/actual/loan/adds';
libname rcu_core '/risk/actual/customers/core';
libname rcu_base '/risk/actual/customers/base';
libname rcu_adds '/risk/actual/customers/adds';
libname r_bau    "/SEOCT/analytics/actual/tmp/bau";
libname r_tmp    "/risk/actual/tmp/&SYSUSERID.";

/* CAJAMAR / XFERA / OSP (Consolidated approach) */
%let user_shared =;
%let pw_shared    =;

/* CAJAMAR */
%assign_ora(lib=r_sid8,   user=&user_shared, pw=&pw_shared, path=ADC8EXP,    schema=SID001);
%assign_ora(lib=r_adc8,   user=&user_shared, pw=&pw_shared, path=ADC8EXP,    schema=ADC800EXP);
%assign_ora(lib=r_bi8,    user=&user_shared, pw=&pw_shared, path=ADC8EXP,    schema=DWH_BI);
%assign_ora(lib=r_ifr98,  user=&user_shared, pw=&pw_shared, path=ADC8EXP,    schema=DWH_IFRS9);

/* XFERA */
%assign_ora(lib=r_sid6,   user=&user_shared, pw=&pw_shared, path=XFRA_ADC6EXP, schema=SID001);
%assign_ora(lib=r_adc6,   user=&user_shared, pw=&pw_shared, path=XFRA_ADC6EXP, schema=ADC600EXP);
%assign_ora(lib=r_bi6,    user=&user_shared, pw=&pw_shared, path=XFRA_ADC6EXP, schema=DWH_BI);
%assign_ora(lib=r_ifr96,  user=&user_shared, pw=&pw_shared, path=XFRA_ADC6EXP, schema=DWH_IFRS9);

/* OSP */
%assign_ora(lib=DLP,      user=&user_shared, pw=&pw_shared, path=ADC2PRO,    schema=DLP001);
%assign_ora(lib=r_nd2,    user=&user_shared, pw=&pw_shared, path=ADC2PRO,    schema=NEW_DEFAULT);
%assign_ora(lib=r_evo2,   user=&user_shared, pw=&pw_shared, path=ADC2PRO,    schema=DWHEVOL);
%assign_ora(lib=R_ADC2,   user=&user_shared, pw=&pw_shared, path=ADC2PRO,    schema=ADC200EXP);

%let cad_ADC2in=; /* PROD Orange */

/* Consolidated Local paths for 800, 600, 200 series using a pattern if possible, 
   otherwise kept for clarity */
%let root8 = /risk/actual800;
libname rcc_cor8 "&root8./cards/core";
libname rcc_bas8 "&root8./cards/base";
libname rcc_add8 "&root8./cards/adds";
libname rln_cor8 "&root8./loan/core";
libname rln_bas8 "&root8./loan/base";
libname rln_add8 "&root8./loan/adds";
libname rcu_cor8 "&root8./customers/core";
libname rcu_bas8 "&root8./customers/base";
libname rcu_add8 "&root8./customers/adds";
libname r_bau8   "/SEOCT/analytics/actual800/tmp/bau";
libname r_tmp8   "&root8./tmp/&SYSUSERID.";

%let root6 = /risk/actual600;
libname rcc_cor6 "&root6./cards/core";
libname rcc_bas6 "&root6./cards/base";
libname rcc_add6 "&root6./cards/adds";
libname rln_cor6 "&root6./loan/core";
libname rln_bas6 "&root6./loan/base";
libname rln_add6 "&root6./loan/adds";
libname rcu_cor6 "&root6./customers/core";
libname rcu_bas6 "&root6./customers/base";
libname rcu_add6 "&root6./customers/adds";
libname r_bau6   "&root6./tmp/bau";
libname r_tmp6   "&root6./tmp/&SYSUSERID.";

%let root2 = /risk/actual200;
libname rln_cor2 "&root2./loan/core";
libname rln_bas2 "&root2./loan/base";
libname rln_add2 "&root2./loan/adds";
libname rcu_cor2 "&root2./customers/core";
libname rcu_bas2 "&root2./customers/base";
libname rcu_add2 "&root2./customers/adds";
libname r_bau2   "&root2./tmp/bau";
libname r_tmp2   "&root2./tmp/&SYSUSERID.";
/* Runtime contracts and profiling; set sm_code_dir before setup if needed. */
%macro sm_load_runtime;
%if not %symexist(sm_code_dir) %then %do;
    %global sm_code_dir; %let sm_code_dir=.;
%end;
%include "&sm_code_dir./macros/validation.sas";
%include "&sm_code_dir./macros/kpi.sas";
%include "&sm_code_dir./macros/harmonized_performance.sas";
%include "&sm_code_dir./macros/output_columns.sas";
%mend;
%sm_load_runtime;
options fullstimer msglevel=i;
