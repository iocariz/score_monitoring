/* SQL does not guarantee order. Fail on conflicting duplicate applications. */
%sm_assert_unique(data=sm_tmp.SM_DEMAND_XFR_END, keys=authorization_id,
                  out=sm_tmp.qa_xfr_app_duplicates);
