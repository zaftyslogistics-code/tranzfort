"""Run each failing test file individually and extract error details."""
import subprocess, re

files = [
    'test/features/shell/presentation/settings_screen_test.dart',
    'test/features/shell/presentation/account_profile_trust_status_test.dart',
    'test/features/shell/presentation/supplier_dashboard_screen_test.dart',
    'test/features/shell/presentation/supplier_load_detail_screen_test.dart',
    'test/features/shell/presentation/user_app_shell_test.dart',
    'test/features/supplier/presentation/post_load_screen_test.dart',
    'test/features/trucker/presentation/trucker_dashboard_screen_test.dart',
    'test/features/trucker/presentation/trucker_load_detail_screen_test.dart',
]

for f in files:
    result = subprocess.run(
        ['flutter', 'test', f],
        capture_output=True, text=True, encoding='utf-8', errors='replace'
    )
    output = result.stdout + result.stderr
    # Find summary line
    summary = ''
    for line in output.split('\n'):
        if 'All tests passed' in line or 'Some tests failed' in line:
            summary = line.strip()
            break

    if 'All tests passed' in summary:
        print(f"PASS: {f}")
        continue

    # Extract [E] test names and their Expected/Actual
    lines = output.split('\n')
    print(f"\nFAIL: {f}")
    print(f"  {summary}")
    for i, line in enumerate(lines):
        if '[E]' in line:
            # Get test name
            name = line.strip().split(': ', 1)[-1].replace(' [E]', '') if ': ' in line else line.strip()
            # Look back for Expected/Actual
            for j in range(max(0, i-10), i):
                l = lines[j].strip()
                if 'Expected:' in l or 'Actual:' in l or 'Which:' in l:
                    if not hasattr(run_failing_tests, '_printed'):
                        pass
                    print(f"    {l}")
            print(f"  TEST: {name}")
