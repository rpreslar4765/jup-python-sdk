#!/bin/bash

# Test script for Docker Alpine builds
# This script tests the Dockerfile builds for all supported Alpine versions

set -e

echo "=========================================="
echo "Jup Python SDK - Docker Alpine Test Suite"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Alpine versions to test
ALPINE_VERSIONS=("3.18" "3.19" "3.20" "3.21" "edge")

# Function to test a specific Alpine version
test_alpine_version() {
    local version=$1
    echo -e "${YELLOW}Testing Alpine $version...${NC}"

    # Build the image
    echo "Building image for Alpine $version..."
    if docker build \
        --build-arg ALPINE_VERSION=$version \
        --build-arg PYTHON_VERSION=3.11 \
        --target runtime \
        -t jup-python-sdk:alpine$version-test \
        . > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Build successful for Alpine $version${NC}"
    else
        echo -e "${RED}✗ Build failed for Alpine $version${NC}"
        return 1
    fi

    # Test SDK import
    echo "Testing SDK import on Alpine $version..."
    if docker run --rm jup-python-sdk:alpine$version-test \
        python -c "import jup_python_sdk; print('SDK loaded successfully')" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ SDK import successful on Alpine $version${NC}"
    else
        echo -e "${RED}✗ SDK import failed on Alpine $version${NC}"
        return 1
    fi

    # Test SDK components
    echo "Testing SDK components on Alpine $version..."
    if docker run --rm jup-python-sdk:alpine$version-test python -c "
from jup_python_sdk.clients.ultra_api_client import UltraApiClient
from jup_python_sdk.models.ultra_api.ultra_order_request_model import UltraOrderRequest
from jup_python_sdk.models.ultra_api.ultra_execute_request_model import UltraExecuteRequest
print('All components loaded successfully')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ SDK components test passed on Alpine $version${NC}"
    else
        echo -e "${RED}✗ SDK components test failed on Alpine $version${NC}"
        return 1
    fi

    echo ""
    return 0
}

# Main test loop
failed=0
passed=0

for version in "${ALPINE_VERSIONS[@]}"; do
    if test_alpine_version "$version"; then
        ((passed++))
    else
        ((failed++))
    fi
done

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Passed: ${GREEN}$passed${NC}"
echo -e "Failed: ${RED}$failed${NC}"
echo "=========================================="

# Exit with error if any tests failed
if [ $failed -gt 0 ]; then
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
