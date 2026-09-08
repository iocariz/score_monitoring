
proc sql;
   CREATE TABLE SM_TMP.TPT_CARD_XFR as 
	    SELECT   		  		  A.ID_REV_CLASICO,
				                  A.ID_REVOLVING_FK,
	                 			  A.ID_CLASICO_FK,
	                              A.TIPO_RELACION_REV_CLASICO_FK,
	                              B.CLIENTE_FK,
	                        	  B.IND_CTO,
	                              b.FCH_FINANC,
	                              C.INDIC_CTO,
	                              B.IMP_CREDITO,
	                              B.TIPO_INTERES
	    FROM        R_SID6.CTO_REV_CLASICO  a, R_SID6.CTO_CLASICO b, R_SID6.CTO_REVOLVING c
	    WHERE 		a.ID_CLASICO_FK=b.ID_CLASICO and a.ID_REVOLVING_FK=c.ID_REVOLVING and a.TIPO_RELACION_REV_CLASICO_FK = 'TPT'

	UNION ALL

	    SELECT   				A.ID_REV_CLASICO,
	                  			A.ID_REVOLVING_FK,
				                A.ID_CLASICO_FK,
				                A.TIPO_RELACION_REV_CLASICO_FK,
				                B.CLIENTE_FK,
	                        	B.IND_CTO,
	                            b.FCH_FINANC,
	                            C.INDIC_CTO,
	                            B.IMP_CREDITO,
	                            B.TIPO_INTERES
	    FROM        R_SID6.CTO_REV_CLASICO_HM a, R_SID6.CTO_CLASICO_HM  b, R_SID6.CTO_REVOLVING_HM c
	    WHERE 		a.fecha_hist >= '01jan2018'd and a.TIPO_RELACION_REV_CLASICO_FK = 'TPT' and
	                a.ID_CLASICO_FK=b.ID_CLASICO and a.fecha_hist = b.fecha_hist and 
	                a.ID_REVOLVING_FK=c.ID_REVOLVING and a.fecha_hist = c.fecha_hist and
	                b.fecha_hist <= b.fch_financ;
quit;

data SM_TMP.TPT_CARD_XFR;
      format account_id_tj account_id_tpt 14. finan_date ddmmyy10.;
      set SM_TMP.TPT_CARD_XFR   (rename=(IMP_CREDITO=oa_amt));

      keep account_id_tpt account_id_tj customer_id finan_date oa_amt tipo_interes;

      account_id_tpt= cats(cliente_fk,ind_cto)*1;
      account_id_tj = cats(cliente_fk,indic_cto)*1;
      customer_id = CLIENTE_FK;
      finan_date = datepart(FCH_FINANC);

      if account_id_tpt gt 0;
run;

proc sort data= SM_TMP.TPT_CARD_XFR nodupkey;
by account_id_tj account_id_tpt;
run;