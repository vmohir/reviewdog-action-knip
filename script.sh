#!/bin/sh

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"
KNIP_REPORTER="${GITHUB_ACTION_PATH}/knip-reporter-rdjson/index.js"

echo '::group::Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

npx --no-install -c 'knip --version'
if [ $? -ne 0 ]; then
  echo '::group:: Running npm install to install knip ...'
  npm install
  echo '::endgroup::'
fi

echo "knip version: $(npx --no-install -c 'knip --version')"

echo '::group:: Running knip with reviewdog ...'
knip_output=$(npx --no-install -c "knip --reporter ${KNIP_REPORTER} ${INPUT_KNIP_FLAGS}" 2>&1)
knip_rc=$?

# knip exits with 1 when issues found, 0 when no issues
# We want to continue even if issues found (rc=1)
if [ $knip_rc -ne 0 ] && [ $knip_rc -ne 1 ]; then
  echo "knip failed with exit code ${knip_rc}"
  echo "${knip_output}"
  echo '::endgroup::'
  exit $knip_rc
fi

echo "${knip_output}" | reviewdog -f=rdjson \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER:-github-pr-review}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-level="${INPUT_FAIL_LEVEL}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}" \
    ${INPUT_REVIEWDOG_FLAGS}

reviewdog_rc=$?
echo '::endgroup::'
exit $reviewdog_rc
