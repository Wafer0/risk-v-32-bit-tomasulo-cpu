#!/bin/bash
# Lint the RTL code

echo "Running Verible linter..."
echo ""

# Run linter and filter out acceptable warnings
LINT_OUTPUT=$(verible-verilog-lint rtl/*.sv 2>&1)
LINT_EXIT=$?

# Filter out the PROGRAM_FILE parameter type warning (acceptable - Yosys doesn't support string type)
FILTERED_OUTPUT=$(echo "$LINT_OUTPUT" | grep -v "PROGRAM_FILE" || true)

# Check if there are any remaining errors (lines with colons indicate errors)
REMAINING_ERRORS=$(echo "$FILTERED_OUTPUT" | grep ":" || true)

if [ -n "$REMAINING_ERRORS" ]; then
    echo "$LINT_OUTPUT"
    echo ""
    echo "Linting found issues - please fix them"
    exit 1
else
    echo "Linting passed"
    echo ""
    echo "Linting passed - no critical issues found"
fi

