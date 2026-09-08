"""Find descending cut points in consecutive ascending SAS decile chains.

This is a targeted configuration audit, not a complete SAS control-flow parser.
Exit 1 means unresolved cut points were found; it does not propose new values.
"""
import json
import re
from pathlib import Path

from sas_source import active_source

RULE = re.compile(
    r'\b(?:ELSE\s+)?IF\s+(\w+)\s*(?:<=|<|le\b|lt\b)\s*'
    r'(-?\d+(?:\.\d+)?)\s+THEN\s+(\w*DECILE\w*)\s*=\s*(\d+)', re.I
)


def audit(source):
    active, _ = active_source(source)
    previous = None
    chain_max = None
    issues = []
    for match in RULE.finditer(active):
        variable, cut, target, bucket = match.groups()
        current = (variable.upper(), float(cut), target.upper(), int(bucket))
        same_chain = (previous and current[0] == previous[0] and current[2] == previous[2]
                      and current[3] == previous[3] + 1)
        if same_chain:
            if current[1] <= chain_max:
                issues.append({
                    'line': active.count('\n', 0, match.start()) + 1,
                    'score': current[0], 'decile_variable': current[2],
                    'previous_decile': previous[3], 'blocking_threshold': chain_max,
                    'decile': current[3], 'threshold': current[1],
                    'issue': 'Non-increasing cut point makes this branch unreachable',
                })
        chain_max = max(chain_max, current[1]) if same_chain else current[1]
        previous = current
    return issues


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    issues = audit((root / '15_DECILES.sas').read_text())
    print(json.dumps({'file': '15_DECILES.sas', 'unresolved_rules': issues}, indent=2))
    raise SystemExit(bool(issues))
