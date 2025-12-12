#!/bin/bash

set -e

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# Copy reporter to local directory to avoid path resolution issues
KNIP_REPORTER_SRC="${GITHUB_ACTION_PATH}/knip-reporter-rdjson"
KNIP_REPORTER_LOCAL=".knip-reporter-rdjson"
cp -r "${KNIP_REPORTER_SRC}" "${KNIP_REPORTER_LOCAL}"

echo '::group::Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

echo "knip version: $(./node_modules/.bin/knip --version 2>/dev/null || echo 'unknown')"
echo "Reporter copied to: ${KNIP_REPORTER_LOCAL}"

echo '::group:: Running knip with reviewdog ...'

# Create a temp file to capture knip output
KNIP_OUTPUT_FILE=$(mktemp)

# Run knip from local node_modules with local reporter
set +e
./node_modules/.bin/knip --reporter "./${KNIP_REPORTER_LOCAL}/index.js" ${INPUT_KNIP_FLAGS} > "${KNIP_OUTPUT_FILE}"
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

# Cleanup
rm -f "${KNIP_OUTPUT_FILE}"
rm -rf "${KNIP_REPORTER_LOCAL}"

echo '::endgroup::'
exit $reviewdog_rc
