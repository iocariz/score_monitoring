# SAS score monitoring: original performance review

Reviewed on 8 September 2026. Environment supplied by the user: SAS 9.4, a 53 GB final dataset, and most processing time in programs 12 onward.

The first priority is reducing repeated materialization of the wide monitoring table. Program 16 contains seven active DATA steps that each read and write the full population; program 19 reads the final table separately for eight segments. These are stronger candidates than rewriting the score formulas.

This is a static code review, not a benchmark or a validation of model coefficients. No SAS executable, runtime logs, input datasets, or external retrofit tables were available locally. All performance benefits below are hypotheses to measure. This document describes the original snapshot. The programs have since been updated; see [README.md](README.md) for the implemented flow, checks and remaining source-rule questions. Line numbers below refer to the original snapshot.

## 1. Consolidate program 16 around narrow lookup tables

Evidence: [16_RISK_LEVELS.sas](16_RISK_LEVELS.sas), full-population DATA steps beginning at lines **1, 112, 229, 321, 339, 362, and 485**.

The current sequence copies the wide dataset to rename/derive scores, attaches three lookup values in separate passes, then performs further passes for naming, score selection, and risk classification. Hash lookups already reduce join costs, but each one still creates another wide dataset.

Proposed sequence:

1. Prepare the CMC and EFX retrofit inputs using only their keys, score values, filter fields, and imputation group variables.
2. Preserve the existing CMC mean imputation at lines 215–218 and EFX median imputation by `mis_date company product_type_1 product_type_2 product_type_3` at lines 290–296. Run these operations on narrow datasets.
3. Attach `ML_SCORE_P0_RF`, `ML_SCORE_P0_RF_CMC`, and `risk_score_rf` in one DATA step, using three narrow hashes if their combined memory footprint fits.
4. Execute the score selection, business-name mapping, and risk-level logic in their current order within that same step.

Target: **seven wide writes become one**, plus narrow preparation datasets. The preparation inputs do not depend on the three newly attached lookup values, so they can be prepared before attachment. Emitting these narrow inputs during the preceding scoring pass avoids additional wide reads.

A particularly easy improvement is at lines 257–286: `data efx; set ...;` currently copies every column for the selected population, although the following query uses only seven columns. Replace that extraction with:

```sas
/* Alternative to the EFX extraction at 16_RISK_LEVELS.sas:257.
   The date restriction is currently applied in its sole consumer. */
data work.efx;
    set sm_tmp.demand_prf_char_RF(
        keep=authorization_id ext_business_name mis_date company
             product_type_1 product_type_2 product_type_3
        where=(mis_date ge '01JAN2021'd and ext_business_name in (
            'Equifax Risk Score - Direct CMC',
            'Equifax Risk Score - Direct CTLM',
            'Equifax Risk Score Retail Auto Green',
            'Equifax Risk Score Retail E-COMM CTLM'
        ))
    );
run;
```

Similarly, the CMC preparation at lines 197–224 ultimately needs `authorization_id`, `company`, `ML_SCORE_P0`, and the joined `score_RF`; its current long list of application characteristics is unnecessary for the shown consumers.

Check uniqueness of each hash source on `(company, authorization_id)` before combining lookups. Define an explicit missing-match policy and check `find()` return values. Preserve the ordering of the later overrides: for example, the native EFX V3 score assignment at line 346 follows the retrofit lookup. A hash lookup returns the data for a matching key; it does not establish that the source key is unique. [SAS hash documentation](https://support.sas.com/documentation/cdl/en/lrcon/65287/HTML/default/n1b4cbtmb049xtn1vh9x4waiioz4.htm).

## 2. Reduce row width before repeated processing

Evidence: [14_CHAR_ANALYSIS.sas](14_CHAR_ANALYSIS.sas), lines **2–3**; [13_SCORECARDS.sas](13_SCORECARDS.sas), lines **4–5**.

Program 14 declares 36 characteristic/description fields plus `KSAUTO` at `$200`: **7,400 bytes per observation in declared, uncompressed storage** for this group alone. At one million rows that is 7.4 GB, before other fields. This arithmetic does not establish their share of the actual 53 GB file: compression, metadata, and the row count are unknown.

Profile maximum byte lengths, then set explicit, stable lengths with room for future values. Model IDs and perimeter IDs also do not generally need the same length as business descriptions. Keep account and authorization numeric identifiers at eight bytes; shrinking their storage can lose precision.

If downstream consumers permit it, store detailed `CHAR_`, `DES_CHAR_`, and model input fields in a separate characteristics dataset keyed by application/model, and keep the frequently scanned monitoring dataset compact. Where the 53 GB detail output is contractually required, retain it but emit narrow reporting datasets alongside it.

Use `KEEP=` on input datasets to reduce variables processed in memory, and explicit projection on SQL joins. SAS input `KEEP=` and output `KEEP=` have different scope. Base SAS files are row-oriented: selecting fewer variables does **not** promise a proportional reduction in physical bytes read from an existing wide file. Materializing a narrow reusable dataset makes the subsequent scans cheaper. [SAS KEEP= reference](https://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/a000131144.htm).

Check the current compression setting before changing it. Benchmark `COMPRESS=NO`, `CHAR`, and `BINARY` on the same representative slice, including both creation and downstream processing time. Compression can reduce I/O while increasing CPU and can occasionally increase size. [SAS 9.4 COMPRESS= reference](https://support.sas.com/documentation/cdl/en/ledsoptsref/69751/HTML/default/n014hy7167t2asn1j7qo99qv16wa.htm).

## 3. Remove unnecessary wide passes in 12–15 and 17–18

Evidence: [12_JOIN.sas](12_JOIN.sas), lines **30–46**; [13_SCORECARDS.sas](13_SCORECARDS.sas), line **1**; [14_CHAR_ANALYSIS.sas](14_CHAR_ANALYSIS.sas), line **1**; [15_DECILES.sas](15_DECILES.sas), line **2**.

- Program 12 joins `a.*` and `b.*`, then rewrites `demand_prf` only to drop columns. Project the required columns in the join or apply output dataset `DROP=` options when creating the join result.
- Its final `PROC SORT ... OUT=kk DUPOUT=pp` sorts the entire wide table, but neither output is used elsewhere in the supplied programs. Program 13 continues with the original `demand_prf`. Replace this diagnostic with a narrow key-count query and a duplicate failure/report policy.
- Programs 13, 14, and the active portion of 15 are consecutive row-level transformations. Consolidate them into one DATA step, or use single-consumer views where useful. Preserve compile-time lengths and the reset behavior at former DATA-step boundaries. For example, a field dropped by program 13 currently becomes missing if subsequently referenced in a new step; simple concatenation can change that behavior.
- Program 13's active `PROC FREQ`, grouped `check_efx` query, and `check` extraction can use a narrow diagnostic output emitted during the main pass.

The floating-decile `PROC RANK` blocks after line 603 of program 15 are inside an unclosed block comment in the supplied file. They are **not current runtime bottlenecks**. The active fixed thresholds still require a full-table transformation pass.

In [17_BAD_RATE.sas](17_BAD_RATE.sas), lines **67 and 96**, lookup attachment and bad-flag derivation currently create two wide outputs. [18_OUTPUT.sas](18_OUTPUT.sas), lines **1 and 71**, then creates two more for segmentation and quarter completeness.

Combine the row-level parts of these four operations. Compute quarter completeness from a narrow date dataset and attach it during the final write. Preserve the existing definition, which is global by quarter and counts distinct `mis_date` values; changing to company/model completeness is a separate business change. SAS SQL's current `select *, count(distinct mis_date) ... group by quarter` requires remerging summary information with detail. An explicit summary alone is not inherently faster; the benefit is avoiding another wide materialization. [SAS remerge documentation](https://support.sas.com/documentation/cdl/en/sqlproc/63043/HTML/default/n123fsko39j44pn16zlt087e1m2h.htm).

For scale only: a complete read and rewrite of a 53 GB file represents approximately **106 GB of file-volume traversal**. Removing three comparable read/write pairs represents approximately 318 GB. These are illustrative volumes, not measured physical I/O or elapsed-time predictions; intermediate sizes and caching differ.

## 4. Read the final dataset once for the eight CPCR populations

Evidence: [19_CPCR.sas](19_CPCR.sas), input `SET` statements at lines **4, 39, 89, 143, 170, 226, 278, and 313**.

The lowest-risk approach is to materialize one narrow CPCR input and point all eight existing branches to it. That preserves the independent filters and calculations while replacing eight wide-source accesses with one wide-source access plus narrow scans.

```sas
/* Proposal: create once before the eight branches of 19_CPCR.sas. */
data work.cpcr_base;
    set sm.score_monitoring(
        keep=authorization_id a_business_name ext_business_name nature_holder
             zxnota zxscore company acct_booked_H0 todu_30ever_h6
             todu_amt_pile_h6 CLASIFICACION_DATE mis_date oa_amt_cma
             mdeccent product_type_1-product_type_3 red rf_business_name
             score_rf se_decision_id segment_1-segment_4 status_name
             valid_call vendedor_cadena_top_name ZRF1SCORE pltbc1
             ML_SCORE_P0 scrplust1
        where=(mis_date ge '01JAN2021'd)
    );
run;
```

A second iteration can generate all eight outputs in one DATA step. Preserve overlapping membership with independent conditions, and restore input values between branches that modify `score_rf` or `rf_business_name`. Replacing everything with an `ELSE IF` chain would require proof that the populations are mutually exclusive.

Replacing `year(mis_date) ge 2021` with `mis_date ge '01JAN2021'd` also avoids repeated function evaluation and exposes a direct date predicate. Index use depends on selectivity and the available index; it is not guaranteed.

The active report query in [18_OUTPUT.sas](18_OUTPUT.sas), lines **214–276**, should read a narrow recent-period report input emitted during finalization. Retain the current group dimensions and sums. The much larger characteristic-analysis loops later in that file are commented out.

## 5. Benchmark the existing index lookup in program 17

Evidence: [17_BAD_RATE.sas](17_BAD_RATE.sas), lines **62–91**.

The code already uses an index on `perfo.account_id` plus a small fraud hash. This is a reasonable design to measure, not something to replace automatically with a full-table hash.

For a large fraction of the account population, repeated keyed access may cost more than a sorted sequential merge of a **narrow** account-performance table. Compare total preparation plus lookup time for:

- the existing index lookup;
- a hash containing only the necessary performance columns, if memory allows;
- a sort/merge using narrow account/application keys, then attaching results during a required final write.

Include index-building time, memory, and source row ordering in the comparison. Avoid sorting all 53 GB solely to test a join alternative. SAS explicitly notes that indexed BY access is not always faster than sorting and sequential processing. [SAS index guidance](https://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/a000440261.htm).

First establish uniqueness. `SET ... KEY=account_id / UNIQUE` is not a declaration that the source has a unique account key, and replacing it with a SQL join can multiply rows if duplicates exist. Program 12 also joins KPI data by account alone after concatenating companies. Confirm that account IDs are globally unique, or carry company through the KPI datasets and use the composite key. Check whether an account can have more than one monitored application/cohort.

## 6. Streamline cutoffs, then consider incremental processing

Evidence: [20_CUTTOFFS.sas](20_CUTTOFFS.sas), lines **100–156, 465–506, and 571–629**.

- Move `status_name ne 'Pending'` and `valid_call='Y'` into the initial filtered input. Keep the booked-versus-duplicate rule after its lookup and preserve the later `Expired` recode.
- Convert the duplicate-demand authorization key to numeric once in a narrow staging table; join on the normalized key instead of `input(b.AUTORIZACION,10.)`. Check for collisions after conversion before aggregating/deduplicating.
- Prepare H3 and H6 information in a single read of each loan/card source using `horizon in (3,6)`, and emit the two narrow outputs. Preserve the appropriate numerator for each horizon.
- Replace routine `drop_empty_vars` use with an explicit output schema. The macro scans all selected cells and rewrites the dataset, and is invoked twice. A data-dependent schema can also remove fields referenced by subsequent `KEEP=` lists. If blank-column suppression is a genuine export requirement, apply it to the final narrow export only.
- Consolidate the output branches where their transformations agree; preserve the differences in the caravan output.

Longer term, separate stable application/scoring attributes from changing performance observations and refresh only affected cohorts. The pipeline currently keeps older demand and rebuilds recent demand in program 10, then processes the combined history again from program 12 onward.

Do not restrict the entire job to the last month. Older cohorts still acquire H6/H12 outcomes; CMC/XFR intermediate KPI summaries also calculate later horizons, and historical corrections/retrofit changes may require backfills. First document which outputs need those later horizons, version score mappings and imputation inputs, then partition by cohort/month with a defined correction window.

## Correctness checks before using an optimized output

These issues matter because performance rewrites can change which duplicate or retained value survives:

1. **H12 balance can carry over between accounts.** All four `11*_KPI.sas` programs retain `todu_H12` but do not initialize it in the `first.account_id` block. A subsequent account without an H12 observation can inherit the preceding account's value. Define the intended zero/missing initialization and include an immature account immediately after a mature account in validation.
2. **OSP uses the XFR reporting-date source.** [11D_OSP_KPI.sas](11D_OSP_KPI.sas), line **58**, reads `rln_cor6.m_loan_account` although its performance source is `rln_cor2`. Confirm the intended calendar; this affects virtual records when source dates differ.
3. **The H6 card branch is incomplete.** [20_CUTTOFFS.sas](20_CUTTOFFS.sas), lines **487–505**, selects four columns for loans but only three for cards and labels the third `todu_90ever as h_den_H6`. It needs an explicit, consistent numerator/denominator layout. SAS set operators align by position rather than alias. [SAS set-operator reference](https://support.sas.com/documentation/cdl/en/sqlproc/63043/HTML/default/n0vo2lglyrnexwn14emi8m0jqvrj.htm).
4. **Cutoff measure flags are overwritten.** Program 20 loads policy flags at lines **525–545**, then resets many to `'N'` at **587–601** and **612–626**. Confirm whether this is an intended counterfactual export before treating it as observed monitoring data.
5. **Fraud joins can multiply records.** Programs `08A` and `08B` create `fraude_acc_sort` and `fraude_auth_sort` but join the unsummarized `fraude_acc` and `fraude_auth`. Simply switching to the sorted tables can change the chosen fraud event. Define date/precedence rules, aggregate to the intended key, then join.
6. **OSP has an unstable identifier and implicit ordering.** [08D_OSP_JOIN_STATIC_IC3.sas](08D_OSP_JOIN_STATIC_IC3.sas), lines **13–17**, applies `BY vap_id` after SQL without an explicit sort and sets `authorization_id=_n_`. Confirm sorted/indexed input and use a stable application identifier before any incremental redesign.
7. **A clean rebuild has missing dependencies.** `05A_CET_NDD.sas` is empty, while `11A_CET_KPI.sas` consumes `sm_tmp.ndod_flg_npe_CET_END`. Retrofit inputs in program 16 also come from pre-existing external datasets. Document these inputs before comparing two runs.

Keep defect corrections separate from changes intended to preserve existing outputs. An optimized run should not silently perpetuate a confirmed defect merely to pass comparison, and a deliberate correction should have a documented expected difference.

## Measurement and acceptance plan

Start by capturing per-step time, memory, and dataset metadata on the SAS server:

```sas
options fullstimer msglevel=i;

proc options option=(compress memsize sortsize threads work);
run;

proc contents data=sm.score_monitoring;
run;

proc sql;
    select libname, memname, nobs, nvar, obslen, filesize, compress
    from dictionary.tables
    where libname in ('SM','SM_TMP','WORK')
      and memtype='DATA'
      and (memname like 'DEMAND_PRF%'
           or memname in ('SCORE_MONITORING','PERFO','EFX','CPCR_BASE'));
quit;
```

`FULLSTIMER` supplies host-dependent per-step resource information in the SAS log. Interpret elapsed-versus-CPU time alongside I/O and memory rather than assuming all waits are disk bottlenecks. [SAS FULLSTIMER guidance](https://blogs.sas.com/content/sgf/2015/03/11/sas-fullstimer-turn-it-on/).

Recommended implementation order:

1. Capture the baseline; replace the unused wide diagnostic sort in 12; narrow the EFX/CMC preparations in 16; stage one narrow CPCR input in 19.
2. Consolidate program 16, then 17–18; combine 13–15 after checking DATA-step boundary semantics.
3. Benchmark compression, row lengths, and the program 17 lookup strategy.
4. Introduce a stable compact monitoring schema and incremental cohort refreshes once current results and source dependencies are established.

Run baseline and candidate against frozen inputs in separate output libraries. Start with a representative set of complete application histories across all companies/models, including missing matches, duplicate keys, sold accounts, immature H6/H12 cohorts, and score-threshold boundaries. Preserve full imputation-group populations or use frozen imputation parameters: a random row sample can change the medians and means and invalidate comparisons.

Validate application/key multiplicities before any deduplication, unmatched lookup counts, variable types/lengths, and row-level scores/flags. Compare model/company/month/status totals for applications, balances, defaults, valid calls, deciles, and risk levels. Use `PROC COMPARE` on consistently keyed outputs; choose numeric tolerances only where arithmetic order changes justify them. Then measure a full-volume candidate run including preparation, sorts, indexes, and exports.

No SAS examples above have been executed locally. Expected gains should be reported only after this measurement, with the source snapshot and any deliberate correctness changes recorded.
