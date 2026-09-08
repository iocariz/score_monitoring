# SAS 9.4 score-monitoring pipeline

The numbered programs have been updated to reduce repeated processing of the wide population and to detect inconsistent joins and outcomes. The motivating dataset is 53 GB. No runtime or space improvement has been measured yet: this workspace has neither SAS nor the production data. Python checks validate source structure; the executable SAS fixtures and frozen-output comparison must run on the SAS server.

## Run and configuration

Use `RUN_MONITORING.sas` to load the helper macros, score definitions and numbered programs in order. The default setup loads site-specific library assignments and dates from the ignored `00_SETUP.local.sas` through `00_SETUP.sas`. Existing Oracle sources, historical demand backups and the external retrofit caches are still prerequisites; this repository does not generate those caches.

On a new checkout, copy `00_SETUP.example.sas` to `00_SETUP.local.sas` and configure the blank user, password and connection-string variables on your SAS server. The local file is ignored by Git; never commit credentials or generated datasets. The existing working configuration on this machine has been preserved in that local file.

Example in Enterprise Guide or a batch wrapper:

```sas
%let sm_code_dir=/your/server/path/score_monitoring;
%let sm_start_stage=1;
%let sm_end_stage=20;
%let sm_export=N;              /* Skip the CSV/ZIP while validating. */
%let sm_full_report=Y;
%let sm_retrofit_method=INDEX; /* Or HASH after checking combined lookup memory. */
%let sm_compress=binary;       /* Benchmark binary, char and no on your server. */
%include "&sm_code_dir./RUN_MONITORING.sas";
```

For validation against isolated libraries, assign all required libraries and date macro variables yourself, and set `sm_setup=N`. Do this in a separate SAS session. The setup macro otherwise replaces library assignments. Set `last_date`, `last_date_txt`, `init_date` and the other date variables used by the selected stages consistently; the existing setup shows their definitions.

The first migration should rebuild the changed upstream stages and their dependants. Do not start at 12 with old KPI tables: the new KPI tables require `company`. After a successful migration, stages 12–20 can be rerun against unchanged, validated stage-11 inputs. Stages 13–15 form one streaming chain; stage 17's view must be consumed by 18 in the same run. Stages 19 and 20 require the narrow outputs from 18; stage 20 also needs the performance lookup prepared by 17.

The sequential driver enables `FULLSTIMER` and emits `SM_STAGE_BEGIN` / `SM_STAGE_END` markers. Checks stop the run on missing inputs, duplicate/missing required keys, unexpected row multiplication, lookup errors or invalid final outcomes. Do not set `sm_qa_abort=N` in production; that setting is used only for negative fixtures.

## Changed processing flow

1. **11A–11D:** share one narrow account-history rollup. It computes H0/H6/H12 without writing rows for every virtual month. It preserves the first-observed-record H0 definition, actual H6/H12 snapshots, sold-account carry-forward and the original company-specific history caps. CET, CMC and OSP retain booked-only KPI output; XFR retains its original all-status output. It does not fill interior missing months. OSP uses its own current calendar. A local macro variable prevents these steps from overwriting the report's global `last_date`.
2. **12:** validates application keys `(company, authorization_id)` and KPI keys `(company, account_id)` before the join. It retains the application population, including applications without an account, and records `sm_kpi_match`. It no longer sorts the wide output into an unused `kk` table or silently discards duplicate applications.
3. **13–15:** scorecard and characteristic derivations stream through two DATA-step views into one materialization. Characteristic values use 64 bytes and descriptions 160 bytes; model/perimeter IDs use 16 bytes. Local checks verify the supplied literals fit, including UTF-8 byte lengths. Step 15 also writes narrow application and retrofit inputs.
4. **16:** prepares CMC mean and EFX grouped-median imputation from those narrow inputs, then attaches all retrofit values and applies the existing score/risk rules in one wide write. The original seven wide writes become one. `sm_retrofit_method=INDEX` uses three narrow indexed tables; `HASH` loads the three narrow lookups into memory together. Both clear misses and use company-qualified keys. The fixture suite compares both paths. INDEX is the default because the available server memory is unknown; benchmark the I/O tradeoff.
5. **17–18:** builds company-qualified performance lookups and a global quarter lookup, then performs final calculations through one view. A single final write also emits `cpcr_base`, `cutoffs_input`, `sm_report_input` and narrow QA metrics. The candidate's checks must pass before its name is exchanged with `sm.score_monitoring`. This is a SAS metadata publication step, not a transaction covering report generation or exports. Keep an independent backup for rollback.
6. **19:** retains the eight CPCR branch definitions, reading only the narrow CPCR input. It no longer scans the 53 GB final dataset eight times.
7. **20:** reads the narrow cutoff population, validates lookup uniqueness, fixes the loan/card H6 numerator/denominator layout, and creates the three outputs together. It preserves a stable column schema instead of dropping columns that happen to be all missing in a particular run. The extra trace-field join is removed; its four fields already flow from step 06A.

The report rebuilds all available history from the narrow reporting input by default (`sm_full_report=Y`). This updates outcomes on older cohorts as they mature. `sm_full_report=N` retains the previous last-three-month replacement mode and requires the corresponding report backup; use it only when older partitions are deliberately frozen. It would retain old historical results during this migration. Quarter completeness keeps the original **global** definition: three distinct `mis_date` values within a quarter, regardless of company.

## Correctness changes that can change results

- H12 balances are reset for each account, eliminating retained values from the previous account.
- A booked application's `early_bad`/`basel_bad` is missing when H6/H12 is unobserved. A missing performance lookup also leaves `early_bad` missing. `early_observed` and `basel_observed` explicitly identify observed booked outcomes; their sums are added to the report. Calculate bad rates using these denominators. Unbooked outcomes retain their legacy zero values but do not enter the new observed denominators.
- Performance/KPI joins cannot match a different company's identical numeric ID. Repeated account/month records or multiple cohorts for one KPI account are reported and stop the run; no arbitrary deduplication is used to conceal them.
- Fraud joins in 08A–08C now use the resolved fraud datasets. The selected whole event has the latest classification date, then latest detection date, then deterministic payload order for remaining ties. This replaces arbitrary source ordering and can change which event wins. Paid fraud requires a known classification month from 0 through 6 after the application month; negative and missing gaps do not qualify.
- OSP authorization IDs come from persistent `sm.osp_authorization_map`, not `_N_`. On first use it seeds from the existing OSP `_END_U` table if available, so existing numeric IDs are retained. New normalized VAP keys receive new integers. Invalid IDs, conflicting mappings and ambiguous latest-call ties stop the run. **Retain and back up this map; run only one writer at a time.** Without a prior map or seed, IDs are assigned from the initial sorted population and must then be persisted. Unused OSP IC3 joins that could multiply rows have been removed.
- OSP monthly NPE processing no longer overwrites its TPT table. The XFR final selection checks uniqueness instead of relying on an unsorted `BY` group.
- Cutoff policy flags retain their observed values by default. Set `sm_cutoffs_reset_flags=Y` for the previous counterfactual reset of the selected flags. The caravan output keeps observed flags in either mode. Duplicate-demand flags are aggregated by the normalized numeric authorization ID; malformed nonempty IDs are reported.
- The cutoff export removes the earlier derived `oa_amt` before renaming `oa_amt_cma` to `oa_amt`, preventing a name collision. This preserves the amount source explicitly selected by the export. Its shared writer is in `macros/cutoff_outputs.sas`; `tests/cutoff_output_fixtures.sas` exercises the three real outputs, card H0 amounts, fraud flags and both policy modes.

Model coefficients, EFX bins, imputation groups and risk thresholds have been retained. Some inconsistent decile configurations are explicitly unresolved below.

## Unresolved source rules

`05A_CET_NDD.sas` was empty in the supplied source. A CET contract prefix cannot be inferred safely from the CMC/XFR programs. If the approved rule is a prefix, set `sm_cet_contract_prefix` to rebuild using the corresponding NPE/TPT aggregation. Otherwise provide the actual membership rule. With no prefix configured, the program warns and requires an existing `sm_tmp.ndod_flg_npe_CET_END` with unique account/month keys; it cannot verify that existing table's freshness or business definition. If that table is absent, the run stops.

`tools/audit_deciles.py` reports six unreachable branches in four original chains:

- Group 2 CTLM and CMC demand deciles: 4980 is followed by 4309 and 4669, blocking bins 7 and 8.
- ORANGE APPLICATION BUSINESS booked deciles: 664 is followed by 655, blocking bin 8.
- ORANGE APPLICATION PERSONAL PORTABILITY booked deciles: 565 is followed by 550, blocking bin 5.

No replacement threshold has been guessed. Stage 15 warns; the dedicated audit exits 1 until these rules are corrected from approved model specifications. Details are in `tests/known_decile_issues.json`. Passing the structural suite does **not** clear these model-rule findings.

## Tests

Local verification on 8 September 2026: **19 Python tests passed**, and all SAS files passed the lexical checks. The separate decile audit reports the six known unreachable branches above. SAS numerical fixtures and production benchmarks have not been executed here.

Run the local checks with Python 3.10 or later; no third-party packages are required:

```sh
python3 -m unittest discover -s tests -v
python3 tools/sas_source.py
python3 tools/audit_deciles.py
```

The first two commands should pass. The third currently exits 1 for the documented decile rules. Structural checks are not a SAS compiler, macro expander or model validation.

Run the SAS fixtures in a **fresh SAS 9.4 session**, from the repository directory:

```sh
sas -sysin tests/run_tests.sas -log tests/sas-tests.log -print tests/sas-tests.lst
```

Alternatively set `sm_code_dir` and include `tests/run_tests.sas` in Enterprise Guide. The suite points `sm`, `sm_tmp`, `sm_bk` and mock performance libraries into this session's WORK directory and does not connect to Oracle. PROC STDIZE needs the same SAS/STAT capability used by the original pipeline.

Fixtures cover retained H12 values, maturity, sold-account carry, interior history gaps, loan/card H3/H6 amounts, distinct quarter months, real stage-12 company-qualified joins, real stage-16 mean/median imputation and INDEX/HASH equivalence, score overrides, a risk threshold boundary, lookup misses, real stage-17 indexed joins and final outcomes, fraud date boundaries, deterministic fraud selection, persistent OSP IDs, policy reset modes, duplicate/missing keys, row multiplication and publication refusal after failed QA.

A successful numerical run ends with `NOTE: ALL_SAS_TESTS_PASSED`. Expected negative tests deliberately emit `ERROR: SM_CHECK` messages near the end; verify the final success marker and all `TEST_PASS` results. An absent success marker is a failed or incomplete run. No claim is made that these fixtures have passed on SAS yet.

## Production-data validation and performance measurement

Use frozen source/cached tables and separate writable libraries for the old and updated runs. Include `tests/validate_outputs.sas` after `macros/validation.sas`, then call:

```sas
%sm_validate_outputs(base=old.score_monitoring,
                     candidate=new.score_monitoring,
                     outlib=qa, row_compare=Y, strict=N);
```

Both inputs are read-only. Each is scanned once into a narrow snapshot. The comparison produces population differences, duplicate-key reports, cohort/company/status/model totals, schema changes, and optionally row-level differences keyed by `(company, authorization_id)`. The optional row comparison sorts only the narrow snapshots and needs extra temporary space. It compares critical outcomes, exposures, scores and classifications; it is not an exhaustive comparison of every source characteristic. `strict=Y` is suitable for two implementations expected to agree, such as INDEX versus HASH. When comparing the old buggy output to corrected output, explain the intentional differences listed above and investigate the remaining differences. Do not accept numerical equivalence solely because total row counts match.

During every updated run, inspect `sm_tmp.qa_monitoring_summary`, especially KPI/performance match counts for booked accounts, missing score coverage, observed horizon counts and bad totals by cohort/company/model. Match flags indicate key presence, not that a nonmissing score was supplied. Some retrofit misses are expected outside their eligible model populations; compare coverage within the relevant population. `qa_final_errors` must be empty to publish. There is no universal match-rate threshold inferred from unavailable production data.

For timing, hold the input snapshot, SAS settings and output filesystem constant. Compare `FULLSTIMER` real time, CPU time and peak memory per stage; include temporary/index space and final compressed file size. DATA-step views shift their execution time into the consuming step, so compare 13–15 together and 17–18 together. Use a representative population spanning companies, dates, models and missingness, then a full run. Benchmark INDEX/HASH and compression options separately. No fixed `MEMSIZE`, `SORTSIZE`, buffer settings or parallel jobs are imposed without server measurements.

The original findings and supporting SAS documentation remain in `SAS_PERFORMANCE_REVIEW.md`; its line references describe the pre-change snapshot. Keyed lookup miss handling follows the [SAS SET statement](https://support.sas.com/documentation/cdl/en/lestmtsref/63323/HTML/default/p00hxg3x8lwivcn1f0e9axziw57y.htm), and publication uses the documented [DATASETS EXCHANGE statement](https://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/a000393161.htm).
