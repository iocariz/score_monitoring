import unittest
from test_source_contracts import ROOT
from audit_deciles import audit


class DecileAuditTests(unittest.TestCase):
    def test_unreachable_cut_point_is_reported(self):
        result = audit('if score <= 4980 then a_decile=6; else if score <=4309 then a_decile=7;')
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]['threshold'], 4309)

    def test_valid_boundaries_and_separate_chains(self):
        self.assertEqual(audit('if score <1 then decile=1; else if score <2 then decile=2; '
                               'if score <0 then decile=1; else if score <1 then decile=2;'), [])

    def test_disabled_rules_do_not_trigger(self):
        self.assertEqual(audit('/* if score <9 then decile=1; if score <2 then decile=2; */'), [])
