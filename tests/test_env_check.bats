#!/usr/bin/env bats

# Load helpers - Ensure these paths match your 'test_helper' folder
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

SCRIPT='deploy/env-check.sh'

# The 'teardown' function runs after EVERY test.
# This is "Pro" because it ensures the environment is clean for the next test.
teardown() {
    unset DOCKERHUB_USERNAME
    unset IMAGE_NAME
    unset IMAGE_TAG
    unset DATABASE_URL
    unset SECRET_KEY
}

@test "1. Security: env-check fails when no variables are set" {
    run bash "$SCRIPT"
    assert_failure
    assert_output --partial 'MISSING'
}

@test "2. Granularity: fails if only ONE variable is missing" {
    export DOCKERHUB_USERNAME='alexagbey'
    export IMAGE_NAME='shortlink-api'
    export IMAGE_TAG='latest'
    export DATABASE_URL='postgresql://localhost/test'
    # Notice SECRET_KEY is missing
    
    run bash "$SCRIPT"
    assert_failure
    assert_output --partial 'SECRET_KEY'
}

@test "3. Success Path: passes when the environment is fully saturated" {
    export DOCKERHUB_USERNAME='alexagbey'
    export IMAGE_NAME='shortlink-api'
    export IMAGE_TAG='latest'
    export DATABASE_URL='postgresql://localhost/test'
    export SECRET_KEY='test-secret-12345'
    
    run bash "$SCRIPT"
    assert_success
    # Checking for a specific success message proves the script finished correctly
    assert_output --partial 'READY'
}

@test "4. Formatting: ensures output is readable for engineers" {
    run bash "$SCRIPT"
    # A pro script should use clean brackets or status indicators
    assert_output --partial '[MISSING]'
}