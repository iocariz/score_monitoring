/* Step 18 emitted this filtered, narrow input during the final write. */
%sm_require(data=sm_tmp.cutoffs_input);
data work.sm_duplicate_demand_raw(keep=authorization_id FLG_DEMANDA_DUPLICADA_SESID)
     sm_tmp.qa_invalid_duplicate_ids(keep=autorizacion);
    set R_BI.STG_CAT_DEMANDA(keep=autorizacion FLG_DEMANDA_DUPLICADA_SESID);
    authorization_id=input(autorizacion,?? best32.);
    if not missing(authorization_id) then output work.sm_duplicate_demand_raw;
    else if not missing(autorizacion) then output sm_tmp.qa_invalid_duplicate_ids;
run;
%sm_assert_empty(data=sm_tmp.qa_invalid_duplicate_ids, label=Invalid duplicate-demand identifier);
proc sql;
    create table work.demanda_duplicada_cet as
    select authorization_id, max(FLG_DEMANDA_DUPLICADA_SESID) as fld_dup
    from work.sm_duplicate_demand_raw
    group by authorization_id;
    create table sm_tmp.base_cutoffs(compress=&sm_compress) as
    select a.*, b.fld_dup as dedup_demanda
    from sm_tmp.cutoffs_input as a
    left join work.demanda_duplicada_cet as b
      on a.authorization_id=b.authorization_id
    where not (a.status_name ne 'Booked' and b.fld_dup=1);
quit;
%sm_check_step(Cutoff population);
data sm_tmp.base_cutoffs_segments;
    /* Increased length of tmp to 500 to prevent truncation */
    length segment_cutoff_1 segment_cutoff_2 segment_cutoff_3 segment_cutoff_4 segment_cutoff_5 $100. 
           segment_cut_off segment_cut_off_tmp $500.;
    set sm_tmp.base_cutoffs;
    if status_name='Expired' then status_name='Canceled';

    /* --- DIRECT SECTION --- */
    if red_name = 'DIRECT' then do;
        if vendedor_cadena_id in (9112285, 9112293, 9112343, 9112350) then do;
            if TCOCARTGRT1 = 17 then do;
                segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'B2C Telco';
                if tcoclit1 in ('A','B') then do; segment_cutoff_4 = 'Orange'; segment_cutoff_5 = 'Known'; end;
                else do; segment_cutoff_4 = 'Orange'; segment_cutoff_5 = 'Not Known'; end;
            end;
            else if TCOCARTGRT1 = 90 then do;
                segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'B2C Telco';
                if tcoclit1 in ('A','B') then do; segment_cutoff_4 = 'Jazztel'; segment_cutoff_5 = 'Known'; end;
                else do; segment_cutoff_4 = 'Jazztel'; segment_cutoff_5 = 'Not Known'; end;
            end;
            else if TCOCARTGRT1 = 2 then do;
                segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'B2C Telco';
                if tcoclit1 in ('A','B') then do; segment_cutoff_4 = 'Yoigo'; segment_cutoff_5 = 'Known'; end;
                else do; segment_cutoff_4 = 'Yoigo'; segment_cutoff_5 = 'Not Known'; end;
            end;
            else if TCOCARTGRT1 = 3 then do;
                segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'B2C Telco';
                if tcoclit1 in ('A','B') then do; segment_cutoff_4 = 'MasMovil'; segment_cutoff_5 = 'Known'; end;
                else do; segment_cutoff_4 = 'MasMovil'; segment_cutoff_5 = 'Not Known'; end;
            end;
            else if TCOCARTGRT1 not in (90,17,2,3) then do;
                segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'B2C Telco'; segment_cutoff_4 = 'Others';
            end;
        end;
        else if vendedor_cadena_id = 9112319 then do;
            segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'Banca Digital'; segment_cutoff_4 = 'MR';
            if rvivoact in ('',' ', '1','2','6','8','Y','Z','5','7') then segment_cutoff_5 = 'New_Inactive';
            else segment_cutoff_5 = 'Known';
        end;
        else if vendedor_cadena_id = 9112327 then do;
            segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'Banca Digital'; segment_cutoff_4 = 'LR';
        end;
        else if vendedor_cadena_id = 9112335 then do;
            segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'Banca Digital'; segment_cutoff_4 = 'VLR';
        end;
        else if product_type_2 = 'New/Inactive' or (product_type_2 = 'TJ Direct' and product_type_3 in ('HP','MP')) then do;
            segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'New';
            if vendedor_cadena_id in (9111204, 9111212) then segment_cutoff_4 = 'Fintonic';
            else if vendedor_cadena_id in (9112376, 9112384, 9112400) then segment_cutoff_4 = 'Org_Pacing';
            else if OBT1 in ('AVOK','AVKO') then segment_cutoff_4 = 'OB';
            else segment_cutoff_4 = 'Resto';
        end;
        else if product_type_2 = 'Defense' then do;
            segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'Defense';
        end;
        else if product_type_2 in ('Known','TJ Direct') then do;
            segment_cutoff_1 = 'Direct'; segment_cutoff_2 = 'PL'; segment_cutoff_3 = 'Known';
            if product_type_3 in ('Silver','Silver Auto', 'Gold', 'Bronce') then do;
                if RVIVOACT IN ('A','B','C','D','E','Y','Z','5','7') OR (RVIVOACT = '' AND NUMVDR = '2999423') then segment_cutoff_4 = 'Precon';
                else segment_cutoff_4 = 'Precon_others';
            end;
            else if product_type_3 = 'Premium' then segment_cutoff_4 = 'Premium';
            else if product_type_3 = 'No Premium' then do;
                segment_cutoff_4 = 'No Premium';
                if RVIVOACT in ('A','B') then segment_cutoff_5 = 'A-B';
                else if RVIVOACT in ('C','D') then segment_cutoff_5 = 'C-D';
                else if RVIVOACT in ('E','F') then segment_cutoff_5 = 'E-F';
                else segment_cutoff_5 = '>=G';
            end;
        end;
        else if product_type_2 in ('Consolidation','Balcon IN') then do;
            segment_cutoff_1 = 'Direct';
            if product_type_3 in ('MP','HP') then do; segment_cutoff_2 = 'Consolidation'; segment_cutoff_3 = 'New'; end;
            else if product_type_3 = 'No Premium' then do;
                segment_cutoff_2 = 'Consolidation'; segment_cutoff_3 = 'Known'; segment_cutoff_4 = 'No Premium';
                if RVIVOACT in ('A','B','C','D','E','F') then segment_cutoff_5 = 'A-F';
                else segment_cutoff_5 = '>=G';
            end;
            else if product_type_3 = 'Premium' then do; segment_cutoff_2 = 'Consolidation'; segment_cutoff_3 = 'Known'; segment_cutoff_4 = 'Premium'; end;
        end;
    end;

    /* --- DISTRIBUTION SECTION --- */
    else if red_name = 'DISTRIBUTION' then do;
        if rf_business_name = 'Equifax Risk Score V3 - Retail E-COMM CTLM' then do;
            segment_cutoff_1 = 'Distribution'; segment_cutoff_2 = 'Online';
            if SCRV_customer_Group_init = 'New' then do; segment_cutoff_3 = 'New_inactive'; segment_cutoff_4 = 'New'; end;
            else if SCRV_customer_Group_init = 'Inactive' then do; segment_cutoff_3 = 'New_inactive'; segment_cutoff_4 = 'Inactive'; end;
            else do;
                segment_cutoff_3 = 'Known';
                if SCRV_customer_init in ('A','B','C') then segment_cutoff_4 = 'A-C';
                else if SCRV_customer_init in ('D','E','F') then segment_cutoff_4 = 'D-F';
                else segment_cutoff_4 = '>=G';
            end;
        end;
        else if vendedor_cadena_top_name = 'Securitas' then do;
            segment_cutoff_1 = 'Distribution'; segment_cutoff_2 = 'Securitas';
        end;
        else if rf_business_name = 'A-Score DISTRIB Retail Traditional CTLM' then do;
            segment_cutoff_1 = 'Distribution'; segment_cutoff_2 = 'Offline';
            if vendedor_cadena_id = 9108994 then do;
                if scrv_customer_group_init = 'New' then do; segment_cutoff_3 = 'Apple'; segment_cutoff_4 = 'New_inactive'; segment_cutoff_5 = 'New'; end;
                else if scrv_customer_group_init = 'Inactive' then do; segment_cutoff_3 = 'Apple'; segment_cutoff_4 = 'New_inactive'; segment_cutoff_5 = 'Inactive'; end;
                else do;
                    segment_cutoff_3 = 'Apple'; segment_cutoff_4 = 'Known';
                    if SCRV_customer_init in ('A','B','C') then segment_cutoff_5 = 'A-C';
                    else if SCRV_customer_init in ('D','E','F') then segment_cutoff_5 = 'D-F';
                    else segment_cutoff_5 = '>=G';
                end;
            end;
            else if vendedor_cadena_id in (9111030, 9111048, 9111055, 9111063, 9111071) then do;
                segment_cutoff_1 = 'Distribution'; segment_cutoff_2 = 'Offline'; segment_cutoff_3 = 'APR';
                if scrv_customer_group_init = 'New' then do; segment_cutoff_4 = 'New_inactive'; segment_cutoff_5 = 'New'; end;
                else if scrv_customer_group_init = 'Inactive' then do; segment_cutoff_4 = 'New_inactive'; segment_cutoff_5 = 'Inactive'; end;
                else do;
                    segment_cutoff_4 = 'Known';
                    if SCRV_customer_init in ('A','B','C') then segment_cutoff_5 = 'A-C';
                    else if SCRV_customer_init in ('D','E','F') then segment_cutoff_5 = 'D-F';
                    else segment_cutoff_5 = '>=G';
                end;
            end;
            else if vendedor_cadena_top_name = 'VitalDent' then do;
                segment_cutoff_1 = 'Distribution'; segment_cutoff_2 = 'Offline'; segment_cutoff_3 = 'VitalDent';
                if scrv_customer_group_init = 'New' then do; segment_cutoff_4 = 'New_inactive'; segment_cutoff_5 = 'New'; end;
                else if scrv_customer_group_init = 'Inactive' then do; segment_cutoff_4 = 'New_inactive'; segment_cutoff_5 = 'Inactive'; end;
                else do;
                    segment_cutoff_4 = 'Known';
                    if SCRV_customer_init in ('A','B','C') then segment_cutoff_5 = 'A-C';
                    else if SCRV_customer_init in ('D','E','F') then segment_cutoff_5 = 'D-F';
                    else segment_cutoff_5 = '>=G';
                end;
            end;
            else do; /* THE "OTHER" CASE */
                segment_cutoff_1 = 'Distribution'; segment_cutoff_2 = 'Offline'; segment_cutoff_3 = 'Other';
                if scrv_customer_group_init = 'New' then do; segment_cutoff_4 = 'New_inactive'; segment_cutoff_5 = 'New'; end;
                else if scrv_customer_group_init = 'Inactive' then do; segment_cutoff_4 = 'New_inactive'; segment_cutoff_5 = 'Inactive'; end;
                else do;
                    segment_cutoff_4 = 'Known';
                    if SCRV_customer_init in ('A','B','C') then segment_cutoff_5 = 'A-C';
                    else if SCRV_customer_init in ('D','E','F') then segment_cutoff_5 = 'D-F';
                    else segment_cutoff_5 = '>=G';
                end;
            end;
        end; /* <--- FIXED: This END closes the rf_business_name block */
    end; /* <--- This END closes the red_name = 'DISTRIBUTION' block */

    /* --- AUTO SECTION --- */
    else if red_name = 'AUTO' then do;
		 if product_type_1 = 'Cards' then do;
            segment_cutoff_1 = 'Auto'; segment_cutoff_2 = product_type_2;
		 end;   
  	     else if product_type_2 = 'Car' then do;
            segment_cutoff_1 = 'Auto';
            if vendedor_cadena_top_name in ('Ford', 'Other') then do;
                segment_cutoff_3 = 'PF_Partners';
                if product_type_3 in ('VO','VS') then segment_cutoff_2 = 'Car_VOVS';
                else segment_cutoff_2 = 'Car_VN';
            end;
            else do;
                segment_cutoff_3 = 'Brands';
                if product_type_3 in ('VO','VS') then segment_cutoff_2 = 'Car_VOVS';
                else segment_cutoff_2 = 'Car_VN';
            end;

            if scrv_customer_group_init in ('New', 'Inactive') then segment_cutoff_4 = 'New_inactive';
            else do;
                segment_cutoff_4 = 'Known';
                if RVIVOACT in ('A','B','C') then segment_cutoff_5 = 'A-C';
                else if RVIVOACT in ('D','E','F') then segment_cutoff_5 = 'D-F';
                else segment_cutoff_5 = '>=G';
            end;
        end;
        else if product_type_2 = 'Moto' then do;
            segment_cutoff_1 = 'Auto'; segment_cutoff_2 = product_type_2;
            if scrv_customer_group_init in ('New', 'Inactive') then do; segment_cutoff_3 = 'New_inactive'; end;
            else do;
                segment_cutoff_3 = 'Known';
                if RVIVOACT in ('A','B','C') then segment_cutoff_4 = 'A-C';
                else if RVIVOACT in ('D','E','F') then segment_cutoff_4 = 'D-F';
                else segment_cutoff_4 = '>=G';
            end;
        end;
		else if product_type_3 in ('Microcar','Caravan','Nautical') then do;
			segment_cutoff_1 = 'Auto'; segment_cutoff_2 = product_type_3;
		end;
		else do;
			segment_cutoff_1 = 'Auto'; segment_cutoff_2 = 'Auto Other';
		end;
    end;

    /* --- FINAL CONCATENATION (Fixed to prevent trailing slashes) --- */
    length full_str $500;
    full_str = cats(segment_cutoff_1, 
                ifc(segment_cutoff_2 ne '', cats('/', segment_cutoff_2), ''),
                ifc(segment_cutoff_3 ne '', cats('/', segment_cutoff_3), ''),
                ifc(segment_cutoff_4 ne '', cats('/', segment_cutoff_4), ''),
                ifc(segment_cutoff_5 ne '', cats('/', segment_cutoff_5), ''));
    segment_cut_off_tmp = compress(lowcase(full_str));

    /* --- MISC --- */
    if OBT1 IN ('AVOK', 'AVKO') or vendedor_cadena_id in (9112376, 9112384) then open_banking = 'Y';
    else open_banking = 'N';

	/* --- SEGMENT CUTOFF --- */

	if segment_cut_off_tmp in (	'direct/consolidation/known/nopremium/a-f'
								'direct/consolidation/known/premium'
								'direct/consolidation/new',
								'direct/pl/known/nopremium/a-b',
								'direct/pl/known/nopremium/c-d',
								'direct/pl/known/nopremium/e-f',
								'distribution/offline/apple/known/a-c',
								'distribution/offline/apple/known/d-f',
								'distribution/offline/apr/known/a-c',
								'distribution/offline/apr/known/d-f',
								'distribution/online/known/a-c',
								'distribution/online/known/d-f',
								'distribution/securitas',
								'auto/car_vn/brands/known/a-c',
								'auto/car_vn/brands/known/d-f',
								'auto/car_vn/brands/new_inactive',
								'auto/car_vn/pf_partners/known/a-c',
								'auto/car_vn/pf_partners/known/d-f',
								'auto/car_vn/pf_partners/new_inactive',
								'auto/car_vovs/brands/known/a-c',
								'auto/car_vovs/brands/known/d-f',
								'auto/car_vovs/brands/new_inactive',
								'auto/car_vovs/pf_partners/known/a-c',
								'auto/car_vovs/pf_partners/known/d-f',
								'auto/car_vovs/pf_partners/new_inactive',
								'auto/caravan',
								'auto/microcar',
								'auto/moto/known/a-c',
								'auto/moto/known/d-f',
								'auto/moto/new_inactive',
								'distribution/offline/other/known/a-c',
								'distribution/offline/other/known/d-f'
							  )  then  segment_cut_off = segment_cut_off_tmp;

	else if segment_cut_off_tmp in (
									'direct/pl/known/precon',
									'direct/pl/known/precon_others',
									'direct/pl/known/premium'
									) then  segment_cut_off = 'direct/pl/known/precon';

	else if segment_cut_off_tmp in (
									'direct/pl/new/ob',
									'direct/pl/new/org_pacing',
									'direct/pl/new/resto'
									) then  segment_cut_off = 'direct/pl/new';

	else if segment_cut_off_tmp in (
									'distribution/offline/apple/new_inactive/inactive',
									'distribution/offline/apple/new_inactive/new'
									) then  segment_cut_off = 'distribution/offline/apple/new_inactive';

	else if segment_cut_off_tmp in (
									'distribution/offline/apr/new_inactive/inactive',
									'distribution/offline/apr/new_inactive/new'
									) then  segment_cut_off = 'distribution/offline/apr/new_inactive';

	else if segment_cut_off_tmp in (
									'distribution/offline/other/new_inactive/inactive',
									'distribution/offline/other/new_inactive/new'
									) then  segment_cut_off = 'distribution/offline/other/new_inactive';

	else if segment_cut_off_tmp in (
									'distribution/offline/vitaldent/new_inactive/inactive',
									'distribution/offline/vitaldent/new_inactive/new'
									) then  segment_cut_off = 'distribution/offline/vitaldent/new_inactive';

	else if segment_cut_off_tmp in (
									'distribution/offline/vitaldent/known/a-c',
									'distribution/offline/vitaldent/known/d-f'
									) then  segment_cut_off = 'distribution/offline/vitaldent/known/a-f';

	else if segment_cut_off_tmp in (
									'distribution/online/new_inactive/new',
									'distribution/online/new_inactive/inactive'
									) then  segment_cut_off = 'distribution/online/new_inactive';

	else segment_cut_off = 'sin definir';	

	if product_type_1 = 'Cards' then oa_amt = mdeccent/100;
	else oa_amt = oa_amt_cma;	

	income_T1T2_m = sum(MSAL1, MSAL2)/100;
run;


%sm_harmonized_performance(
    loan=r_bau.H_LOAN_ACCOUNT_1STDUE_PERFO,
    card=r_bau.H_CARD_ACCOUNT_1STDUE_PERFO,
    out3=work.harm_indicador_H3, out6=work.harm_indicador_H6);
%sm_assert_unique(data=r_bau.loan_measure_tp, keys=account_id,
                  out=sm_tmp.qa_measure_duplicates);
proc sql;
create table sm_tmp.base_cutoffs_medidas(compress=&sm_compress) as
	select 
		a.*,
		
		
		
		
		
		
		
		
		
		
		
		

		b.CUTOFF_DIRECT_FINTO25		as m_ct_sc_direct_finto25,
		b.CUTOFF_PRECON_DIRECT_25   as m_ct_sc_direct_cutoff_precon_25,
		b.cutoff_direct_jun26 		as m_ct_sc_direct_cutoff_jun26,
		b.CUTOFF_CONSO_BALC_JUN26   as m_ct_sc_direct_conso_balc_jun26,
		b.CUTOFF_OPENB_JUN26		as m_ct_sc_direct_openb_jun26,

		b.Medida_pdv				as m_ct_auto_pdv,
		b.medida_microcar_pdv		as m_ct_auto_microcar_pdv,
		b.CUTOFF_GREEN25			as m_ct_sc_auto_green25,
		b.cutoff_KIA_HYUNDAI_MAR25  as m_ct_sc_auto_kia_hyundai_mar25,
		b.CUTOFF_MOTO25				as m_ct_sc_auto_cutoff_moto_25,
		b.CUTOFF_MICROCAR25			as m_ct_sc_auto_microcars_25,
		b.ARRAIGO_AUTO_MAR26		as m_ct_auto_arraigo_mar26,
		b.Cutoff_HYUNDAI_MAR26		as m_ct_sc_auto_hyundai_mar26,

		b.MEDIDAS_VITALDENT			as m_ct_sc_distri_vitaldent,
		b.medida_score_fraude		as m_ct_distri_score_fraude,
		b.medida_asnef_apple		as m_ct_distri_asnef_apple,
		b.CUTOFF_ECOMMERCE25		as m_ct_sc_distri_ecommerce25,
		b.CUTOFF_SECURITAS_APR26	as m_ct_sc_distri_cutoff_sec_apr26,
		b.CUTOFF_APRS_MAR26			as m_ct_sc_distri_apr_mar26,
		c.h_den_H6,
		c.h_num_H6,
		d.h_den_H3,
		d.h_num_H3,
		e.todu_h0
	from
		sm_tmp.base_cutoffs_segments as a
	left join
		r_bau.loan_measure_tp as b
	on
		a.account_id = b.account_id
	left join
		harm_indicador_H6 as c
	on
		a.account_id=c.account_id
	left join
		harm_indicador_H3 as d
	on
		a.account_id=d.account_id
	left join
		sm_tmp.perfo as e
	on
		a.account_id=e.account_id and a.company=e.company;
	;
quit;
%sm_check_step(Cutoff enrichment);
%sm_assert_rows(base=sm_tmp.base_cutoffs_segments, candidate=sm_tmp.base_cutoffs_medidas);
%include "&sm_code_dir./macros/cutoff_scenario.sas";
%include "&sm_code_dir./macros/cutoff_outputs.sas";
