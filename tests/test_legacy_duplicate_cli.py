#!/usr/bin/env python3
"""Check the real historical CLI before any schema/mapping operation."""
import argparse
import json
from pathlib import Path
import subprocess

p = argparse.ArgumentParser()
p.add_argument('binary')
a = p.parse_args()
cases = json.loads((Path(__file__).parent / 'fixtures/raw-json-unique-keys.json').read_text())['cases']
for case in cases:
    request = '{"command":"version","probe":' + case['wire'] + '}'
    result = subprocess.run([a.binary], input=request, text=True, capture_output=True, timeout=30)
    assert (result.returncode == 0) == case['valid'], (case['name'], result.stdout, result.stderr)
    if not case['valid']:
        assert 'duplicate JSON key' in result.stdout + result.stderr
    else:
        assert json.loads(result.stdout)['ok'] is True
print(f'{len(cases)} historical CLI raw key cases passed')
