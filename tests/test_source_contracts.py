"""Local structural safeguards; SAS numerical fixtures are in run_tests.sas."""

import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from sas_source import active_source, check_file, mask_strings


def active(name):
    return active_source((ROOT / name).read_text())[0]


class SasLexingTests(unittest.TestCase):
    def test_comments_cannot_expose_disabled_code(self):
        source = 'data a; /* disabled /* nested text */ x="/*literal*/"; *data bad;; run;'
        code, issues = active_source(source)
        self.assertEqual(issues, [])
        self.assertNotIn('disabled', code)
        self.assertNotIn('data bad', code)
        self.assertIn('"/*literal*/"', code)

    def test_unclosed_comment_is_detected(self):
        self.assertTrue(active_source('data a; run; /* inactive')[1])

    def test_doubled_quotes(self):
        code, issues = active_source("data a; x='it''s /* text'; run;")
        self.assertFalse(issues)
        self.assertIn("it''s", code)


class PipelineContracts(unittest.TestCase):
    def test_all_sas_sources_have_balanced_lexical_structure(self):
        issues = {str(p.relative_to(ROOT)): check_file(p) for p in ROOT.rglob('*.sas')}
        self.assertEqual({p: i for p, i in issues.items() if i}, {})

    def test_driver_and_source_includes_resolve(self):
        for p in ROOT.rglob('*.sas'):
            code = active_source(p.read_text())[0]
            for rel in re.findall(r'%include\s+"&sm_code_dir\./([^"&]+)"', code, re.I):
                self.assertTrue((ROOT / rel).is_file(), (p.name, rel))
        for filename in re.findall(r'%sm_stage\(\d+,([^\)]+)\)', active('RUN_MONITORING.sas')):
            self.assertTrue((ROOT / filename).is_file(), filename)

    def test_pure_scoring_steps_are_streamed_once(self):
        self.assertRegex(active('13_SCORECARDS.sas'), r'(?i)/\s*view=sm_tmp.sm_scorecards_v')
        self.assertRegex(active('14_CHAR_ANALYSIS.sas'), r'(?i)/\s*view=sm_tmp.sm_characteristics_v')
        self.assertRegex(active('15_DECILES.sas'), r'(?i)set sm_tmp.sm_characteristics_v;')
        self.assertNotRegex(active('13_SCORECARDS.sas'), r'(?i)proc\s+(freq|sql|sort)')
        self.assertNotRegex(active('14_CHAR_ANALYSIS.sas'), r'(?i)proc\s+(freq|sql|sort)')

    def test_character_literals_fit_declared_byte_lengths(self):
        source = active('02_SCORE_MODELS.sas') + active('14_CHAR_ANALYSIS.sas')
        count = 0
        literal = r'''(?:'(?:''|[^'])*'|"(?:""|[^"])*")'''
        for m in re.finditer(r'\b((?:B_)?(?:DES_)?CHAR_[1-9])\s*=\s*(' + literal + r')\s*;', source, re.I):
            rhs = m[2].strip()
            limit = 160 if 'DES_' in m[1].upper() else 64
            value = rhs[1:-1].replace(rhs[0] * 2, rhs[0])
            self.assertLessEqual(len(value.encode('utf-8')), limit, m[1])
            count += 1
        for m in re.finditer(r'\b((?:B_)?(?:DES_)?CHAR_[1-9])\s*=\s*([^;]+);', mask_strings(source), re.I):
            rhs = m[2].strip()
            if not re.search(r'\bthen\b', rhs, re.I):
                self.assertEqual(rhs, "''", 'Nonliteral assignment needs a length audit: ' + m[1])
        self.assertGreater(count, 100)

    def test_identifier_literals_fit_declared_lengths(self):
        for m in re.finditer(r'\b\w+_(?:model|perimeter)_id\s*=\s*[\'"]([^\'"]+)', active('13_SCORECARDS.sas'), re.I):
            self.assertLessEqual(len(m[1]), 16)

    def test_risk_enrichment_materializes_wide_population_once(self):
        code = mask_strings(active('16_RISK_LEVELS.sas'))
        self.assertEqual(len(re.findall(r'(?im)^\s*data sm_tmp\.demand_prf_char_RF\b', code)), 1)
        self.assertNotRegex(code, r'(?i)demand_prf_char_RF_new')
        self.assertRegex(code, r'(?i)call missing\(_sm_ml,_sm_cmc,_sm_efx\)')
        self.assertRegex(code, r'(?i)run;\s*%sm_check_step\(Retrofit and risk levels\)')

    def test_cpcr_never_rescans_wide_final_table(self):
        code = active('19_CPCR.sas')
        self.assertNotIn('sm.score_monitoring', code.lower())
        self.assertEqual(len(re.findall(r'(?i)set sm_tmp\.cpcr_base\b', code)), 8)

    def test_kpi_and_performance_keys_include_company(self):
        self.assertIn('a.company=b.company and a.account_id=b.account_id', active('12_JOIN.sas'))
        self.assertIn('sm_perfo_key=(company account_id) / unique', active('17_BAD_RATE.sas'))
        self.assertNotRegex(active('12_JOIN.sas'), r'(?i)out\s*=\s*kk\b')

    def test_osp_uses_own_calendar_and_persistent_identity(self):
        code = active('11D_OSP_KPI.sas')
        self.assertIn('rln_cor2.m_loan_account', code)
        self.assertNotIn('rln_cor6', code)
        self.assertNotRegex(active('08D_OSP_JOIN_STATIC_IC3.sas'), r'(?i)authorization_id\s*=\s*_n_')
        self.assertIn('sm.osp_authorization_map', active('08D_OSP_JOIN_STATIC_IC3.sas'))

    def test_company_specific_kpi_populations_are_preserved(self):
        for file in ('11A_CET_KPI.sas', '11B_CMC_KPI.sas', '11D_OSP_KPI.sas'):
            self.assertIn('booked_only=Y', active(file))
        self.assertIn('booked_only=N', active('11C_XFR_KPI.sas'))

    def test_h12_reset_and_bounded_rollup(self):
        code = active('macros/kpi.sas')
        self.assertRegex(code, r'(?i)if first.account_id then do;[^;]*(?:;[^;]*)*?todu_h12=0;')
        self.assertNotIn('n_months_add', code)
        self.assertIn("intnx('month',mis_date,12,'b') <= &asof", code)

    def test_cutoffs_keep_stable_schema_and_explicit_scenario(self):
        self.assertNotIn('drop_empty_vars', active('20_CUTTOFFS.sas'))
        self.assertIn('%sm_default(sm_cutoffs_reset_flags, N)', active('macros/validation.sas'))
        code = active('macros/harmonized_performance.sas')
        self.assertIn('h_num_H6=todu_90ever; h_den_H6=todu;', code)

    def test_fraud_joins_use_resolved_events(self):
        for p in ROOT.glob('08[ABC]*.sas'):
            code = active_source(p.read_text())[0]
            self.assertNotRegex(code, r'(?i)left join\s+fraude_(acc|auth)\s+as')
            self.assertIn('%sm_latest_fraud', code)


if __name__ == '__main__':
    unittest.main()
