#!/usr/bin/env python3
"""Install with Nimble then compile the whole contract suite outside the checkout."""
import argparse,os,subprocess,tempfile
from pathlib import Path
r=Path(__file__).resolve().parent.parent
p=argparse.ArgumentParser();p.add_argument('--no-rebuild',action='store_true',help='reuse separately compiled real adapter binaries');p.add_argument('--validation-only',action='store_true',help='test the lightweight installed validation API only');a=p.parse_args()
subprocess.run(['nimble','install','-y',*(['--noRebuild'] if a.no_rebuild else [])],cwd=r,check=True)
with tempfile.TemporaryDirectory(prefix='starintel-installed-') as temp:
 d=Path(temp)
 # Prove the lightweight API is included by Nimble and works outside checkout.
 (d/'test_validation.nim').write_text((r/'tests/test_validation.nim').read_text().replace('import ../src/starintel_doc/validation','import starintel_doc/validation'))
 lightweight=['nim','c','-r','--parallelBuild:1','--nimcache:'+str(d/'validation-cache'),str(d/'test_validation.nim')]
 if os.environ.get('NIMBLE_DIR'): lightweight.insert(2,'--nimblePath:'+str(Path(os.environ['NIMBLE_DIR'])/'pkgs2'))
 subprocess.run(lightweight,cwd=d,check=True)
 if a.validation_only:
  print('Nimble-installed validation-only API passed outside checkout')
  raise SystemExit(0)
 # Only the import changes: test all real generated bindings from installed closure.
 (d/'test_installed.nim').write_text((r/'tests/test_canonical.nim').read_text().replace('import ../src/starintel_doc/canonical','import starintel_doc/canonical'))
 command=['nim','c','--compileOnly','--genScript','--parallelBuild:1','--nimcache:'+str(d/'cache'),'--out:'+str(d/'test'),str(d/'test_installed.nim')]
 if os.environ.get('NIMBLE_DIR'):command.insert(2,'--nimblePath:'+str(Path(os.environ['NIMBLE_DIR'])/'pkgs2'))
 subprocess.run(command,cwd=d,check=True)
 subprocess.run(['bash',str(d/'cache/compile_test.sh')],cwd=d/'cache',check=True)
 fixtures = r/'src/starintel_doc/schemas/starintel-0.10.1'
 subprocess.run([str(d/'cache/test'),str(fixtures/'research-fixtures.json'),str(fixtures/'supported-workflow-fixtures.json')],cwd=d,check=True)
print('Nimble-installed full canonical contract suite passed outside checkout')
