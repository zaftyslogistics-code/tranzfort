"""Extract test failure details from test_output2.txt"""
import re

lines = open('test_output2.txt', encoding='utf-8').readlines()
failures = []
i = 0
while i < len(lines):
    line = lines[i].strip()
    if '[E]' in line and 'TranZfort/' in line:
        # Extract test name and file
        parts = line.split('TranZfort/')
        if len(parts) >= 2:
            test_info = parts[1].strip().rstrip(' [E]')
            # Look backwards for the error details
            details = []
            for j in range(max(0, i-8), i):
                l = lines[j].strip()
                if 'Expected:' in l or 'Actual:' in l or 'Which:' in l:
                    details.append(l)
            failures.append((test_info, details))
    i += 1

for info, details in failures:
    print(f"FAIL: {info}")
    for d in details:
        print(f"  {d}")
    print()
