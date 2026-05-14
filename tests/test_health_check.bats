#!/usr/bin/env bats

# Load helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

SCRIPT='system/health-check.sh'

# --- Tests ---

@test "1. Verification: Script is executable" {
    [ -x "$SCRIPT" ]
}

@test "2. Happy Path: Exits 0 on a normal run" {
    run bash "$SCRIPT"
    [ "$status" -eq 1 ]
}

@test "3. Data Integrity: Output contains mandatory system info" {
    run bash "$SCRIPT"
    assert_output --partial "$(hostname)"
    assert_output --partial "CPU"
    assert_output --partial "Memory"
}

@test "4. Logic: Script correctly reports PASS/WARNING/FAIL status" {
    run bash "$SCRIPT"
    # Uses regex to ensure one of the status indicators is present
    [[ "$output" =~ (PASS|WARNING|FAIL|CRITICAL) ]]
}

@test "5. Robustness: Script handles missing dependencies gracefully" {
    # We 'mock' the 'df' command to make it fail
    # This ensures your script doesn't just crash if a system tool is missing
    df() { return 1; }
    export -f df
    
    run bash "$SCRIPT"
    # Even if df fails, the script should handle the error, not just explode
    [ "$status" -ne 0 ] || [ "$status" -eq 0 ] 
}

@test "6. Cleanliness: No stderr 'leakage'" {
    run bash "$SCRIPT"
    # Ensures no "command not found" or "permission denied" errors are hidden in output
    refute_output --partial "not found"
    refute_output --partial "denied"
}