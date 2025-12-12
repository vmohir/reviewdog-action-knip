#!/bin/sh

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# Copy reporter to local directory to avoid path resolution issues with knip
KNIP_REPORTER_SRC="${GITHUB_ACTION_PATH}/knip-reporter-rdjson"
KNIP_REPORTER_LOCAL=".knip-reporter-rdjson"
cp -r "${KNIP_REPORTER_SRC}" "${KNIP_REPORTER_LOCAL}"

echo '::group::Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

./node_modules/.bin/knip --version
if [ $? -ne 0 ]; then
  echo '::group:: Running npm install to install knip ...'
  set -e
  npm install
  set +e
  echo '::endgroup::'
fi

echo "knip version: $(./node_modules/.bin/knip --version)"

echo '::group:: Running knip with reviewdog ...'
./node_modules/.bin/knip --reporter "./${KNIP_REPORTER_LOCAL}/index.js" ${INPUT_KNIP_FLAGS} \
  | reviewdog -f=rdjson \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER:-github-pr-review}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-level="${INPUT_FAIL_LEVEL}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

reviewdog_rc=$?
rm -rf "${KNIP_REPORTER_LOCAL}"
echo '::endgroup::'
exit $reviewdog_rc
