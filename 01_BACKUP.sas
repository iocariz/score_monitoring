options nomprint nomlogic nosymbolgen;
%macro backup(lib_in, lib_out , dsn);
	%if %sysfunc(exist(&lib_out..&dsn._&last_date_txt)) %then %do;
		data _null_;
			file print;
	        put #3 @10 "Data set &dsn. exists in &lib_out.";
	    run;
	%end;
	%else %do;
		data &lib_out..&dsn._&last_date_txt;
			set  &lib_in..&dsn;
		run;
	%end;
%mend;

%backup(sm, sm_bk, score_monitoring);
%macro sm_backup_osp_map;
%if %sysfunc(exist(sm.osp_authorization_map)) %then
    %backup(sm, sm_bk, osp_authorization_map);
%mend;
%sm_backup_osp_map;
*%backup(sm, sm_bk, score_monitoring_sqe);
%backup(sm, sm_bk, out_sm_rpt);


%backup(sm_tmp, sm_bk, SM_DEMAND_CMC_END_U);
%backup(sm_tmp, sm_bk, SM_DEMAND_CTLM_END_U);
%backup(sm_tmp, sm_bk, SM_DEMAND_XFR_END_U);
%backup(sm_tmp, sm_bk, SM_DEMAND_OSP_END_U);



%symdel dsns rc sqlobs / nowarn;
data _null_;

 if _n_=0 then do;

    rc=%sysfunc(dosubl('
       proc sql;
          select
             memname
          into
             :dsns separated by " "
          from
             sashelp.vtable
          where
                libname="SM_BK"
            and  typemem="DATA"
            and  intck("month",datepart(crdate),today()) > 3
			and (memname like "SM_DEMAND%" or memname like "SCORE_MONITORING%" or memname like "OUT_SM_RPT%");
       ;quit;
    '));

  end;

  if (&sqlobs = 0) then do;
    put "** proc sql failed with  &sqlobs obs ** ";
    stop;
  end;

  rc=dosubl('
     proc datasets lib=SM_BK mt=data;
       delete &dsns ;
     run;quit;
  ');

  if rc ne 0 then do;
    put "** proc datsets failed **" rc=;
    stop;
  end;

 stop;

run;
quit;
