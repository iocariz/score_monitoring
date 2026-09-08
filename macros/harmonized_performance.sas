%macro sm_harmonized_performance(loan=, card=, out3=, out6=);
    /* Read each source once; identical numerator/denominator layout for cards. */
    data &out3(keep=account_id mis_date h_num_H3 h_den_H3)
         &out6(keep=account_id mis_date h_num_H6 h_den_H6);
        set &loan(keep=account_id mis_date horizon todu_30ever todu_90ever todu
                  where=(horizon in (3,6)))
            &card(keep=account_id mis_date horizon todu_30ever todu_90ever todu
                  where=(horizon in (3,6)));
        if horizon=3 then do;
            h_num_H3=todu_30ever; h_den_H3=todu;
            output &out3;
        end;
        else if horizon=6 then do;
            h_num_H6=todu_90ever; h_den_H6=todu;
            output &out6;
        end;
    run;
    %sm_check_step(Harmonized performance);
    %sm_assert_unique(data=&out3, keys=account_id, out=work.sm_h3_duplicates);
    %sm_assert_unique(data=&out6, keys=account_id, out=work.sm_h6_duplicates);
%mend;
