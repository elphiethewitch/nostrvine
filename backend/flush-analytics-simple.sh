#!/bin/bash

# Simple Analytics Database Flush Script
# Uses Wrangler CLI to directly flush analytics keys from KV storage

set -e

BINDING="METADATA_CACHE"
DRY_RUN=${1:-true}

echo "🧹 OpenVine Analytics Database Flush"
echo "======================================"
echo "KV Binding: $BINDING" 
echo "Dry Run: $DRY_RUN"
echo ""

echo "📋 Listing all keys in KV namespace..."
KEYS_JSON=$(wrangler kv key list --binding "$BINDING")

if [ "$KEYS_JSON" = "[]" ]; then
    echo "✅ No keys found in KV namespace - analytics database is already empty"
    exit 0
fi

echo "🔍 Filtering analytics keys..."
ANALYTICS_KEYS=$(echo "$KEYS_JSON" | jq -r '.[].name' | grep -E '^(global:|video:|popular:|popularity:|batch:|requests:|errors:|error:)' || true)

if [ -z "$ANALYTICS_KEYS" ]; then
    echo "✅ No analytics keys found - nothing to flush"
    exit 0
fi

ANALYTICS_COUNT=$(echo "$ANALYTICS_KEYS" | wc -l)
echo "📊 Found $ANALYTICS_COUNT analytics keys:"
echo "$ANALYTICS_KEYS" | sed 's/^/  - /'

if [ "$DRY_RUN" = "true" ]; then
    echo ""
    echo "⚠️  DRY RUN - Keys shown above would be deleted"
    echo "🔄 To actually delete these keys, run:"
    echo "  $0 false"
    exit 0
fi

echo ""
echo "🗑️  Deleting analytics keys..."

# Delete keys one by one (more reliable than bulk for this pattern matching)
echo "$ANALYTICS_KEYS" | while IFS= read -r key; do
    if [ -n "$key" ]; then
        echo "  Deleting: $key"
        wrangler kv key delete "$key" --binding "$BINDING"
    fi
done

echo ""
echo "✅ Analytics database flush completed!"

echo ""
echo "🔍 Verifying flush..."
REMAINING_KEYS=$(wrangler kv key list --binding "$BINDING")
REMAINING_ANALYTICS=$(echo "$REMAINING_KEYS" | jq -r '.[].name' | grep -E '^(global:|video:|popular:|popularity:|batch:|requests:|errors:|error:)' || true)

if [ -z "$REMAINING_ANALYTICS" ]; then
    echo "🎉 All analytics keys successfully removed!"
else
    echo "⚠️  Warning: Some analytics keys may remain:"
    echo "$REMAINING_ANALYTICS" | sed 's/^/  - /'
fi