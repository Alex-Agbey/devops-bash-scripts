#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "--------------------------------------"
echo "🚀 Starting DevOps Toolkit Test Suite"
echo "--------------------------------------"

# Run all files ending in .bats in the tests folder
bats tests/*.bats

echo ""
echo "✅ All tests passed successfully!"
echo "--------------------------------------"