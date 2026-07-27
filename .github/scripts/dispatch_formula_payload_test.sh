#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

build_payload() {
  local service_config="${1:-}"
  local service_run_args="${2:-}"
  local service_config_source="${3:-}"

  jq -n \
    --arg name "mytool" \
    --arg version "1.0.0" \
    --arg sha256 "e0d200a665351832dd11a065443d38b504969c77a8660ad4f49fc6405f7d7518" \
    --arg desc "Test" \
    --arg source_repo "novr/mytool" \
    --arg binary "mytool" \
    --arg test_match "USAGE" \
    --arg license "MIT" \
    --arg service_config "${service_config}" \
    --arg service_run_args "${service_run_args}" \
    --arg service_config_source "${service_config_source}" \
    '{
      client_payload: {
        name: $name,
        version: $version,
        sha256: $sha256,
        desc: $desc,
        source_repo: $source_repo,
        options: (
          {binary: $binary, test_match: $test_match, license: $license}
          + (if $service_config != "" then {service_config: $service_config} else {} end)
          + (if $service_run_args != "" then {service_run_args: $service_run_args} else {} end)
          + (if $service_config_source != "" then {service_config_source: $service_config_source} else {} end)
        )
      }
    }'
}

assert_top_level_count() {
  local label="$1"
  local payload="$2"
  local max="$3"
  local count
  count="$(echo "${payload}" | jq '.client_payload | keys | length')"
  if [[ "${count}" -gt "${max}" ]]; then
    echo "Assertion failed: ${label} has ${count} top-level keys (max ${max})"
    exit 1
  fi
}

base_payload="$(build_payload)"
assert_top_level_count "base payload" "${base_payload}" 10
[[ "$(echo "${base_payload}" | jq -r '.client_payload | keys | sort | join(",")')" == "desc,name,options,sha256,source_repo,version" ]] || {
  echo "Assertion failed: unexpected core keys"
  exit 1
}
[[ "$(echo "${base_payload}" | jq '.client_payload | has("formula")')" == "false" ]] || {
  echo "Assertion failed: legacy formula key must not be present"
  exit 1
}
[[ "$(echo "${base_payload}" | jq '.client_payload | has("url")')" == "false" ]] || {
  echo "Assertion failed: url must not be at top level"
  exit 1
}

service_payload="$(build_payload "mytool/config.yaml" "run,--config" "config.yaml.example")"
assert_top_level_count "service payload" "${service_payload}" 10
[[ "$(echo "${service_payload}" | jq '.client_payload.options.service_run_args')" == '"run,--config"' ]] || {
  echo "Assertion failed: options.service_run_args missing"
  exit 1
}

update_payload="$(jq -n \
  --arg name "mytool" \
  --arg version "1.0.0" \
  --arg sha256 "e0d200a665351832dd11a065443d38b504969c77a8660ad4f49fc6405f7d7518" \
  --arg source_repo "novr/mytool" \
  --arg binary "mytool" \
  --arg test_match "USAGE" \
  --arg license "MIT" \
  --arg desc "" \
  '{
    client_payload: (
      {
        name: $name,
        version: $version,
        sha256: $sha256,
        source_repo: $source_repo,
        options: {binary: $binary, test_match: $test_match, license: $license}
      }
      + (if $desc != "" then {desc: $desc} else {} end)
    )
  }')"
assert_top_level_count "update payload" "${update_payload}" 10
[[ "$(echo "${update_payload}" | jq -r '.client_payload | keys | sort | join(",")')" == "name,options,sha256,source_repo,version" ]] || {
  echo "Assertion failed: update payload should omit desc"
  exit 1
}

export NAME="mytool"
export VERSION="1.0.0"
export SOURCE_REPO="novr/mytool"
export OPTIONS_BINARY="mytool"
# shellcheck source=.github/scripts/resolve_formula_payload.sh
source .github/scripts/resolve_formula_payload.sh
resolve_formula_payload
[[ "${URL}" == "https://github.com/novr/mytool/releases/download/v1.0.0/mytool_1.0.0_darwin.tar.gz" ]] || {
  echo "Assertion failed: derived url mismatch: ${URL}"
  exit 1
}

legacy_payload="$(jq -n \
  --arg formula "br" \
  --arg version "0.0.7" \
  --arg sha256 "e0d200a665351832dd11a065443d38b504969c77a8660ad4f49fc6405f7d7518" \
  --arg source_repo "novr/bitrise-cli" \
  --arg url "https://github.com/novr/bitrise-cli/releases/download/v0.0.7/br_0.0.7_darwin.tar.gz" \
  '{client_payload:{formula:$formula,version:$version,sha256:$sha256,source_repo:$source_repo,url:$url}}')"
export NAME=""
export FORMULA_LEGACY="$(echo "${legacy_payload}" | jq -r '.client_payload.formula')"
export VERSION="$(echo "${legacy_payload}" | jq -r '.client_payload.version')"
export SHA256="$(echo "${legacy_payload}" | jq -r '.client_payload.sha256')"
export SOURCE_REPO="$(echo "${legacy_payload}" | jq -r '.client_payload.source_repo')"
export URL="$(echo "${legacy_payload}" | jq -r '.client_payload.url')"
export OPTIONS_BINARY=""
export BINARY=""
export TEST_MATCH=""
resolve_formula_payload
[[ "${FORMULA}" == "br" ]] || { echo "Assertion failed: legacy formula name"; exit 1; }
[[ "${URL}" == "https://github.com/novr/bitrise-cli/releases/download/v0.0.7/br_0.0.7_darwin.tar.gz" ]] || {
  echo "Assertion failed: legacy url mismatch: ${URL}"
  exit 1
}

export NAME="mytool"
export OPTIONS_BINARY="from-options"
export BINARY="from-flat"
export OPTIONS_TEST_MATCH="OPTIONS_MATCH"
export TEST_MATCH="FLAT_MATCH"
export OPTIONS_LICENSE="Apache-2.0"
export LICENSE="MIT"
export OPTIONS_URL="https://example.com/custom.tar.gz"
export URL="https://example.com/flat.tar.gz"
resolve_formula_payload
[[ "${BINARY}" == "from-options" ]] || { echo "Assertion failed: options.binary precedence"; exit 1; }
[[ "${TEST_MATCH}" == "OPTIONS_MATCH" ]] || { echo "Assertion failed: options.test_match precedence"; exit 1; }
[[ "${LICENSE}" == "Apache-2.0" ]] || { echo "Assertion failed: options.license precedence"; exit 1; }
[[ "${URL}" == "https://example.com/custom.tar.gz" ]] || { echo "Assertion failed: options.url precedence"; exit 1; }

echo "dispatch_formula_payload tests passed"
