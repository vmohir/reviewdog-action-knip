#!/bin/bash

set -e

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
KNIP_REPORTER="${GITHUB_ACTION_PATH}/knip-reporter-rdjson/index.js"

echo '::group::Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

# Check if knip is installed, if not run npm install
set +e
npx knip --version > /dev/null 2>&1
knip_check=$?
set -e

if [ $knip_check -ne 0 ]; then
  echo '::group:: Running npm install to install knip ...'
  npm install
  echo '::endgroup::'
fi

echo "knip version: $(npx knip --version 2>/dev/null || echo 'unknown')"
echo "Reporter path: ${KNIP_REPORTER}"
echo "Reporter exists: $(test -f "${KNIP_REPORTER}" && echo 'yes' || echo 'no')"

echo '::group:: Running knip with reviewdog ...'

# Create a temp file to capture knip output
KNIP_OUTPUT_FILE=$(mktemp)

# Run knip: capture stdout (JSON) to file, show stderr on console
set +e
npx knip --reporter "${KNIP_REPORTER}" ${INPUT_KNIP_FLAGS} > "${KNIP_OUTPUT_FILE}"
knip_rc=$?
set -e

# Debug: show first 500 chars of output
echo "Knip exit code: ${knip_rc}"
echo "Knip output preview:"
head -c 500 "${KNIP_OUTPUT_FILE}"
echo ""

# knip exits with 1 when issues found, 0 when no issues
# Exit codes 0 and 1 are acceptable
if [ $knip_rc -ne 0 ] && [ $knip_rc -ne 1 ]; then
  echo "knip failed with exit code ${knip_rc}"
  cat "${KNIP_OUTPUT_FILE}"
  rm -f "${KNIP_OUTPUT_FILE}"
  echo '::endgroup::'
  exit $knip_rc
fi

# Pipe the captured output to reviewdog
cat "${KNIP_OUTPUT_FILE}" | reviewdog -f=rdjson \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER:-github-pr-review}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-level="${INPUT_FAIL_LEVEL}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}" \
    ${INPUT_REVIEWDOG_FLAGS}

reviewdog_rc=$?
rm -f "${KNIP_OUTPUT_FILE}"
echo '::endgroup::'
exit $reviewdog_rc
