#!/bin/bash
set -u

# Source the helper
source "$(dirname "$0")/lib/coredump-logic.sh"

run_test() {
    local name="$1"
    local rc="$2"
    local out="$3"
    local expected="$4"
    
    local actual
    actual=$(_evaluate_coredump_result "$rc" "$out")
    
    if [[ "$actual" == "$expected" ]]; then
        echo "PASS: ${name}"
        return 0
    else
        echo "FAIL: ${name}"
        echo "  Expected: '${expected}'"
        echo "  Actual  : '${actual}'"
        return 1
    fi
}

failures=0

# 1. No coredumps found. with exit code 1.
run_test "No coredumps found. (rc=1)" 1 "No coredumps found." "INFO: No core dumps found." || failures=$((failures + 1))

# 2. No match found. with exit code 1.
run_test "No match found. (rc=1)" 1 "No match found." "INFO: No core dumps found." || failures=$((failures + 1))

# 3. A genuine error such as Failed to connect to bus.
expected_err=$'Failed to connect to bus.\nWARN: coredumpctl failed with exit code 1.'
run_test "Genuine error (rc=1)" 1 "Failed to connect to bus." "$expected_err" || failures=$((failures + 1))

# 4. A successful query containing result rows.
run_test "Successful query (rc=0)" 0 "TIME PID UID GID SIG COREFILE EXE" "TIME PID UID GID SIG COREFILE EXE" || failures=$((failures + 1))

# 5. An empty-result message with exit code 0.
run_test "Empty-result message (rc=0)" 0 "No match found." "INFO: No core dumps found." || failures=$((failures + 1))

# 6. Genuine test with rc=0 and out=""
run_test "Empty output (rc=0)" 0 "" "" || failures=$((failures + 1))

# 7. Regression test for unexpected nonzero return code with no match message
expected_rc2=$'No match found.\nWARN: coredumpctl failed with exit code 2.'
run_test "Unexpected rc=2 with No match found." 2 "No match found." "$expected_rc2" || failures=$((failures + 1))

if [[ $failures -ne 0 ]]; then
    echo "Tests failed: $failures"
    exit 1
else
    echo "All tests passed."
    exit 0
fi
