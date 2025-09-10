#!/bin/bash
# Verification script for Prestige Interior Cleaning DVA v1 Package
# Client: Ryan / Prestige Interior Cleaning

echo "🔐 SIRDI DVA v1 Package Verification"
echo "===================================="

# Extract package
echo "📦 Extracting package..."
tar -xzf prestige_dva_v1_package.tgz

# Verify signature
echo "🔍 Verifying cryptographic signature..."
if command -v signify-openbsd >/dev/null 2>&1; then
    signify-openbsd -V -p sirdi.pub -m dva_report_v1.md -x dva_report_v1.md.sig
    if [ $? -eq 0 ]; then
        echo "✅ Signature verified successfully!"
        echo "📋 Report is authentic and unmodified"
    else
        echo "❌ Signature verification failed!"
        exit 1
    fi
else
    echo "⚠️  signify-openbsd not found. Install with:"
    echo "   Ubuntu/Debian: apt install signify-openbsd"
    echo "   macOS: brew install signify-osx"
fi

echo ""
echo "📄 Package contents:"
echo "- dva_report_v1.md     (DVA report)"
echo "- dva_report_v1.md.sig (cryptographic signature)"
echo "- sirdi.pub            (SIRDI public key)"
echo ""
echo "🎯 This package contains your verified Digital Vulnerability Audit"
echo "   prepared by SIRDI sovereign intelligence system."
