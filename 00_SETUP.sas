/* Site setup is local-only because it includes database credentials.
   Copy 00_SETUP.example.sas to 00_SETUP.local.sas and configure it on the server. */
%macro sm_load_site_setup;
    %if not %symexist(sm_code_dir) %then %do;
        %global sm_code_dir;
        %let sm_code_dir=.;
    %end;
    filename smsetup "&sm_code_dir./00_SETUP.local.sas";
    %if %sysfunc(fexist(smsetup)) %then %do;
        %include smsetup;
    %end;
    %else %do;
        %put ERROR: SM_CHECK: Missing local setup. Copy and configure 00_SETUP.example.sas as 00_SETUP.local.sas.;
        %abort cancel;
    %end;
    filename smsetup clear;
%mend;
%sm_load_site_setup;
