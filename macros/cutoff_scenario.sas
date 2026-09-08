%macro sm_cutoff_scenario;
    %if %upcase(&sm_cutoffs_reset_flags)=Y %then %do;
		m_ct_sc_direct_finto25 = 'N';
		m_ct_sc_direct_cutoff_precon_25 = 'N';
		m_ct_sc_direct_cutoff_jun26 = 'N';
		m_ct_sc_direct_conso_balc_jun26 = 'N';
		m_ct_sc_direct_openb_jun26 = 'N';

		m_ct_sc_auto_hyundai_mar26 = 'N';
		m_ct_sc_auto_green25 = 'N';
		m_ct_sc_auto_kia_hyundai_mar25 = 'N';
		m_ct_sc_auto_cutoff_moto_25 = 'N';
		m_ct_sc_auto_microcars_25 = 'N';
		m_ct_sc_distri_vitaldent = 'N';
		m_ct_sc_distri_ecommerce25 = 'N';
		m_ct_sc_distri_cutoff_sec_apr26 = 'N';
		m_ct_sc_distri_apr_mar26 = 'N';
    %end;
%mend;
