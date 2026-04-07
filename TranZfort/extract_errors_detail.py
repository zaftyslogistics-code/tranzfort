"""Extract detailed error info from test_output2.txt"""
lines = open('test_output2.txt', encoding='utf-8').readlines()

i = 0
while i < len(lines):
    line = lines[i].strip()
    if '[E]' in line and 'TranZfort/' in line:
        test_name = line.split(': ', 1)[-1].replace(' [E]', '') if ': ' in line else line
        # Search backwards for error details
        details = []
        for j in range(max(0, i-15), i):
            l = lines[j].strip()
            if any(k in l for k in ['Expected:', 'Actual:', 'Which:', 'TestFailure', 'off-screen', 'obscuring', 'pointer']):
                details.append(l)
        if details:
            print(f"=== {test_name}")
            for d in details:
                print(f"  {d}")
            print()
    i += 1
