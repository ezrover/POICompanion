#!/bin/bash
# button-validation.sh
# Automated validation script for Roadtrip-Copilot Button Design System
# This script prevents circular border regressions and ensures platform parity
#
# Usage: ./scripts/button-validation.sh
# Exit codes: 0 = success, 1 = critical violations, 2 = warnings only

set -e

echo "🔍 Validating Button Design System Compliance..."
echo "=================================================="

# Define color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters for violations
CRITICAL_VIOLATIONS=0
WARNINGS=0
TOTAL_CHECKS=0

# Helper function to check files exist
check_files_exist() {
    local pattern="$1"
    local description="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "Checking for $description... "
    
    if [ -d "mobile/" ]; then
        local found_files=$(find mobile/ -type f \( -name "*.swift" -o -name "*.kt" -o -name "*.css" -o -name "*.scss" \) -exec grep -l "$pattern" {} \; 2>/dev/null || true)
        if [ ! -z "$found_files" ]; then
            return 0  # Files found
        fi
    fi
    return 1  # No files found
}

# 1. Check for CRITICAL VIOLATIONS - Circular button patterns
echo -e "\n${BLUE}1. Checking for PROHIBITED circular patterns...${NC}"
echo "---------------------------------------------------"

# iOS circular patterns
echo -n "   iOS circular patterns: "
IOS_CIRCLE_VIOLATIONS=$(find mobile/ios -name "*.swift" -exec grep -n "clipShape(Circle\|Circle()\|\.clipShape.*Circle" {} + 2>/dev/null || true)

if [ ! -z "$IOS_CIRCLE_VIOLATIONS" ]; then
    echo -e "${RED}❌ CRITICAL VIOLATIONS FOUND${NC}"
    echo "$IOS_CIRCLE_VIOLATIONS"
    CRITICAL_VIOLATIONS=$((CRITICAL_VIOLATIONS + 1))
else
    echo -e "${GREEN}✅ Clean${NC}"
fi

# Android circular patterns
echo -n "   Android circular patterns: "
ANDROID_CIRCLE_VIOLATIONS=$(find mobile/android -name "*.kt" -exec grep -n "CircleShape\|clip.*Circle\|shape.*Circle" {} + 2>/dev/null || true)

if [ ! -z "$ANDROID_CIRCLE_VIOLATIONS" ]; then
    echo -e "${RED}❌ CRITICAL VIOLATIONS FOUND${NC}"
    echo "$ANDROID_CIRCLE_VIOLATIONS"
    CRITICAL_VIOLATIONS=$((CRITICAL_VIOLATIONS + 1))
else
    echo -e "${GREEN}✅ Clean${NC}"
fi

# CSS circular patterns
echo -n "   CSS circular patterns: "
CSS_CIRCLE_VIOLATIONS=$(find mobile/ -name "*.css" -o -name "*.scss" -exec grep -n "border-radius.*50%\|border-radius.*999\|clip-path.*circle" {} + 2>/dev/null || true)

if [ ! -z "$CSS_CIRCLE_VIOLATIONS" ]; then
    echo -e "${RED}❌ CRITICAL VIOLATIONS FOUND${NC}"
    echo "$CSS_CIRCLE_VIOLATIONS"
    CRITICAL_VIOLATIONS=$((CRITICAL_VIOLATIONS + 1))
else
    echo -e "${GREEN}✅ Clean${NC}"
fi

# 2. Check for hardcoded values instead of design tokens
echo -e "\n${BLUE}2. Checking for hardcoded values (should use design tokens)...${NC}"
echo "-------------------------------------------------------------"

# iOS hardcoded values
echo -n "   iOS hardcoded corner radius: "
IOS_HARDCODED=$(find mobile/ios -name "*.swift" -exec grep -n "cornerRadius.*[0-9]\|RoundedRectangle.*[0-9]" {} + 2>/dev/null | grep -v "DesignTokens\|//.*✅\|//.*CORRECT" || true)

if [ ! -z "$IOS_HARDCODED" ]; then
    echo -e "${YELLOW}⚠️  WARNINGS FOUND${NC}"
    echo "$IOS_HARDCODED" | head -10  # Limit output
    [ $(echo "$IOS_HARDCODED" | wc -l) -gt 10 ] && echo "... (truncated, $(echo "$IOS_HARDCODED" | wc -l) total violations)"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Clean${NC}"
fi

# Android hardcoded values
echo -n "   Android hardcoded values: "
ANDROID_HARDCODED=$(find mobile/android -name "*.kt" -exec grep -n "RoundedCornerShape([0-9]\|\.dp\|Color(0x" {} + 2>/dev/null | grep -v "DesignTokens\|//.*✅\|//.*CORRECT" || true)

if [ ! -z "$ANDROID_HARDCODED" ]; then
    echo -e "${YELLOW}⚠️  WARNINGS FOUND${NC}"
    echo "$ANDROID_HARDCODED" | head -10  # Limit output
    [ $(echo "$ANDROID_HARDCODED" | wc -l) -gt 10 ] && echo "... (truncated, $(echo "$ANDROID_HARDCODED" | wc -l) total violations)"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Clean${NC}"
fi

# 3. Check for proper touch targets
echo -e "\n${BLUE}3. Checking touch target compliance...${NC}"
echo "-------------------------------------"

# iOS touch targets below minimum
echo -n "   iOS touch targets (min 44pt): "
IOS_SMALL_TARGETS=$(find mobile/ios -name "*.swift" -exec grep -n "\.frame.*width.*[1-3][0-9]\|\.frame.*height.*[1-3][0-9]\|\.size.*[1-3][0-9]" {} + 2>/dev/null | grep -v "DesignTokens\|//.*✅" || true)

if [ ! -z "$IOS_SMALL_TARGETS" ]; then
    echo -e "${YELLOW}⚠️  POTENTIAL VIOLATIONS${NC}"
    echo "$IOS_SMALL_TARGETS" | head -5
    [ $(echo "$IOS_SMALL_TARGETS" | wc -l) -gt 5 ] && echo "... (truncated, $(echo "$IOS_SMALL_TARGETS" | wc -l) total findings)"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Clean${NC}"
fi

# Android touch targets below minimum
echo -n "   Android touch targets (min 48dp): "
ANDROID_SMALL_TARGETS=$(find mobile/android -name "*.kt" -exec grep -n "\.size.*[1-4][0-7]\.dp\|width.*[1-4][0-7]\.dp\|height.*[1-4][0-7]\.dp" {} + 2>/dev/null | grep -v "DesignTokens\|//.*✅" || true)

if [ ! -z "$ANDROID_SMALL_TARGETS" ]; then
    echo -e "${YELLOW}⚠️  POTENTIAL VIOLATIONS${NC}"
    echo "$ANDROID_SMALL_TARGETS" | head -5
    [ $(echo "$ANDROID_SMALL_TARGETS" | wc -l) -gt 5 ] && echo "... (truncated, $(echo "$ANDROID_SMALL_TARGETS" | wc -l) total findings)"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Clean${NC}"
fi

# 4. Check for platform-specific implementations (anti-parity)
echo -e "\n${BLUE}4. Checking for platform-specific styling (anti-parity)...${NC}"
echo "---------------------------------------------------------"

# iOS-specific styling patterns
echo -n "   iOS platform-specific patterns: "
IOS_PLATFORM_SPECIFIC=$(find mobile/ios -name "*.swift" -exec grep -n "44\.0\|44pt\|iOS.*specific" {} + 2>/dev/null | grep -v "DesignTokens\|//.*comment\|minimum.*44" || true)

if [ ! -z "$IOS_PLATFORM_SPECIFIC" ]; then
    echo -e "${YELLOW}⚠️  POTENTIAL ISSUES${NC}"
    echo "$IOS_PLATFORM_SPECIFIC" | head -3
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Clean${NC}"
fi

# Android-specific styling patterns
echo -n "   Android platform-specific patterns: "
ANDROID_PLATFORM_SPECIFIC=$(find mobile/android -name "*.kt" -exec grep -n "48\.dp\|Android.*specific\|elevation.*dp" {} + 2>/dev/null | grep -v "DesignTokens\|//.*comment\|minimum.*48" || true)

if [ ! -z "$ANDROID_PLATFORM_SPECIFIC" ]; then
    echo -e "${YELLOW}⚠️  POTENTIAL ISSUES${NC}"
    echo "$ANDROID_PLATFORM_SPECIFIC" | head -3
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✅ Clean${NC}"
fi

# 5. Check for proper design token usage
echo -e "\n${BLUE}5. Checking design token implementation...${NC}"
echo "---------------------------------------------"

# Check if design token files exist
echo -n "   iOS DesignTokens.swift: "
if [ -f "mobile/ios/RoadtripCopilot/DesignSystem/DesignTokens.swift" ]; then
    echo -e "${GREEN}✅ Found${NC}"
else
    echo -e "${YELLOW}⚠️  Missing${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo -n "   Android DesignTokens.kt: "
if [ -f "mobile/android/app/src/main/java/com/roadtrip/copilot/design/DesignTokens.kt" ]; then
    echo -e "${GREEN}✅ Found${NC}"
else
    echo -e "${YELLOW}⚠️  Missing${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for proper design token usage in code
echo -n "   iOS token usage: "
IOS_TOKEN_USAGE=$(find mobile/ios -name "*.swift" -exec grep -l "DesignTokens\." {} + 2>/dev/null | wc -l || echo "0")
if [ "$IOS_TOKEN_USAGE" -gt 0 ]; then
    echo -e "${GREEN}✅ Found in $IOS_TOKEN_USAGE files${NC}"
else
    echo -e "${YELLOW}⚠️  No usage found${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo -n "   Android token usage: "
ANDROID_TOKEN_USAGE=$(find mobile/android -name "*.kt" -exec grep -l "DesignTokens\." {} + 2>/dev/null | wc -l || echo "0")
if [ "$ANDROID_TOKEN_USAGE" -gt 0 ]; then
    echo -e "${GREEN}✅ Found in $ANDROID_TOKEN_USAGE files${NC}"
else
    echo -e "${YELLOW}⚠️  No usage found${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# 6. Check for prohibited patterns in comments (documentation violations)
echo -e "\n${BLUE}6. Checking for prohibited pattern documentation...${NC}"
echo "------------------------------------------------"

echo -n "   Documentation of prohibited patterns: "
PROHIBITED_DOCS=$(find mobile/ -name "*.swift" -o -name "*.kt" -exec grep -n "NEVER USE\|❌.*USE\|PROHIBITED" {} + 2>/dev/null | wc -l || echo "0")

if [ "$PROHIBITED_DOCS" -gt 0 ]; then
    echo -e "${GREEN}✅ Found $PROHIBITED_DOCS documented violations${NC}"
else
    echo -e "${YELLOW}⚠️  No documentation found${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# 7. Generate summary report
echo -e "\n${BLUE}VALIDATION SUMMARY${NC}"
echo "=================="

echo "Total checks performed: $TOTAL_CHECKS"
echo -e "Critical violations: ${RED}$CRITICAL_VIOLATIONS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

# Performance recommendations
echo -e "\n${BLUE}PERFORMANCE RECOMMENDATIONS:${NC}"
if [ "$WARNINGS" -gt 5 ]; then
    echo -e "${YELLOW}⚡ Consider implementing design tokens to reduce warnings${NC}"
fi

if [ "$CRITICAL_VIOLATIONS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "\n${GREEN}🎉 EXCELLENT! Your button implementation is fully compliant!${NC}"
    echo -e "${GREEN}✅ No circular borders detected${NC}"
    echo -e "${GREEN}✅ Platform parity maintained${NC}"
    echo -e "${GREEN}✅ Design system compliance verified${NC}"
elif [ "$CRITICAL_VIOLATIONS" -eq 0 ]; then
    echo -e "\n${GREEN}✅ GOOD! No critical violations found.${NC}"
    echo -e "${YELLOW}⚠️  Consider addressing warnings for optimal compliance.${NC}"
else
    echo -e "\n${RED}❌ CRITICAL VIOLATIONS DETECTED!${NC}"
    echo -e "${RED}🚨 Platform parity at risk - immediate action required!${NC}"
    echo -e "${RED}💥 Circular border regression detected - this violates design system!${NC}"
fi

# Additional validation recommendations
echo -e "\n${BLUE}NEXT STEPS:${NC}"
if [ "$CRITICAL_VIOLATIONS" -gt 0 ]; then
    echo "1. 🔥 URGENT: Fix all circular border patterns immediately"
    echo "2. 📝 Replace with rounded rectangles using design tokens"
    echo "3. 🧪 Test platform parity after fixes"
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo "4. 🎨 Replace hardcoded values with design tokens"
    echo "5. 📏 Verify touch targets meet minimum requirements"
    echo "6. 🔍 Review platform-specific implementations"
fi

echo "7. 🤖 Run automated tests to verify changes"
echo "8. 👀 Conduct visual regression testing across platforms"

# Exit with appropriate code
if [ "$CRITICAL_VIOLATIONS" -gt 0 ]; then
    echo -e "\n${RED}❌ Button validation FAILED due to critical violations.${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  Button validation PASSED with warnings.${NC}"
    exit 2
else
    echo -e "\n${GREEN}✅ Button validation PASSED successfully!${NC}"
    exit 0
fi