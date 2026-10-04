#!/usr/bin/env python3
"""Exercise an actual compiled canonical Nim CLI; no SDK or network dependencies."""
import argparse
import json
import subprocess


def number(token):
    mantissa, _, exp = token.lower().partition('e')
    negative = mantissa.startswith('-')
    mantissa = mantissa.lstrip('-')
    power = 0
    if exp:
        digits = exp.lstrip('+-')
        for index in range(0, len(digits), 500):
            chunk = digits[index:index+500]
            power = power * 10**len(chunk) + int(chunk)
        if exp.startswith('-'): power = -power
    whole, _, fraction = mantissa.partition('.')
    digits = (whole + fraction).lstrip('0') or '0'
    if digits == '0': return ('number', False, '0', 0)
    trimmed = digits.rstrip('0')
    return ('number', negative, trimmed, power-len(fraction)+len(digits)-len(trimmed))


def decode(raw):
    return json.loads(raw, parse_int=number, parse_float=number)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('binary')
    parser.add_argument('--corpus', action='append', default=[])
    args = parser.parse_args()
    cases = [b'{"id":"fixture:numeric","dataset":"test","dtype":"person","schemaVersion":"0.10.1","createdAt":1e999999999999999999999,"extensions":{"small":1e-999999999999999999999,"fraction":0.12345678901234567890123456789,"false":false,"null":null}}']
    for file in args.corpus:
        with open(file, 'rb') as stream: cases.extend(stream.read().splitlines())
    for case in cases:
        request = b'{"command":"roundtrip","document":'+case+b'}'
        run = subprocess.run([args.binary], input=request, capture_output=True, timeout=30)
        if run.returncode or decode(run.stdout)['document'] != decode(case):
            raise RuntimeError((run.returncode,run.stdout,run.stderr))
    for value in ['1.00000000000000000000000000001','1e-999999999999999999999','-1e400']:
        request = '{"command":"roundtrip","document":{"id":"fixture:invalid","dataset":"test","dtype":"person","schemaVersion":"0.10.1","createdAt":'+value+'}}'
        run = subprocess.run([args.binary],input=request.encode(),capture_output=True,timeout=30)
        if run.returncode == 0: raise RuntimeError('accepted invalid integer: '+value)
    for raw in [b'{"command":"roundtrip","document":01}',b'{"command":"roundtrip","document":{"extensions":{"n":1e}}}']:
        run = subprocess.run([args.binary],input=raw,capture_output=True,timeout=30)
        if run.returncode == 0: raise RuntimeError('accepted malformed JSON')
    print(f'{len(cases)} exact CLI documents and 5 rejection checks passed')


if __name__ == '__main__': main()
