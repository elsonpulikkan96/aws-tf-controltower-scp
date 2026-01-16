#!/bin/bash
set -e

echo "=== AWS Control Tower & SCP Policy Validator ==="
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Install with: brew install jq"
    exit 1
fi

# Validate all SCP JSON files
echo "Validating SCP policies..."
for policy in policies/scp/**/*.json; do
    if [ -f "$policy" ]; then
        echo "  Checking $policy..."
        if jq empty "$policy" 2>/dev/null; then
            echo "    ✓ Valid JSON"
        else
            echo "    ✗ Invalid JSON"
            exit 1
        fi
    fi
done

# Validate tag policies
echo ""
echo "Validating tag policies..."
for policy in policies/tag-policies/*.json; do
    if [ -f "$policy" ]; then
        echo "  Checking $policy..."
        if jq empty "$policy" 2>/dev/null; then
            echo "    ✓ Valid JSON"
        else
            echo "    ✗ Invalid JSON"
            exit 1
        fi
    fi
done

# Validate backup policies
echo ""
echo "Validating backup policies..."
for policy in policies/backup-policies/*.json; do
    if [ -f "$policy" ]; then
        echo "  Checking $policy..."
        if jq empty "$policy" 2>/dev/null; then
            echo "    ✓ Valid JSON"
        else
            echo "    ✗ Invalid JSON"
            exit 1
        fi
    fi
done

echo ""
echo "=== All policies validated successfully! ==="
