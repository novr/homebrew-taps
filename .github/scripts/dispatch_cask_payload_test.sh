#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

build_payload() {
  local display_name="${1:-}"
  local minimum_macos="${2:-}"

  jq -n \
    --arg name "nyap" \
    --arg version "1.0.0" \
    --arg sha256 "e0d200a665351832dd11a065443d38b504969c77a8660ad4f49fc6405f7d7518" \
    --arg desc "Test" \
    --arg source_repo "novr/Nyap" \
    --arg app "Nyap.app" \
    --arg asset "Nyap-macOS.zip" \
    --arg display_name "${display_name}" \
    --arg minimum_macos "${minimum_macos}" \
    '{
      client_payload: {
        name: $name,
        version: $version,
        sha256: $sha256,
        desc: $desc,
        source_repo: $source_repo,
        options: (
          {app: $app, asset: $asset}
          + (if $display_name != "" then {name: $display_name} else {} end)
          + (if $minimum_macos != "" then {minimum_macos: $minimum_macos} else {} end)
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
assert_top_level_count "base cask payload" "${base_payload}" 10
[[ "$(echo "${base_payload}" | jq -r '.client_payload | keys | sort | join(",")')" == "desc,name,options,sha256,source_repo,version" ]] || {
  echo "Assertion failed: unexpected core keys"
  exit 1
}
[[ "$(echo "${base_payload}" | jq '.client_payload | has("cask")')" == "false" ]] || {
  echo "Assertion failed: legacy cask key must not be present"
  exit 1
}
[[ "$(echo "${base_payload}" | jq '.client_payload.options.app')" == '"Nyap.app"' ]] || {
  echo "Assertion failed: options.app missing"
  exit 1
}

optional_payload="$(build_payload "Nyap" "sonoma")"
assert_top_level_count "optional cask payload" "${optional_payload}" 10
[[ "$(echo "${optional_payload}" | jq '.client_payload.options.name')" == '"Nyap"' ]] || {
  echo "Assertion failed: options.name display name missing"
  exit 1
}

export NAME="nyap"
export OPTIONS_APP="Nyap.app"
export OPTIONS_ASSET="Nyap-macOS.zip"
export DISPLAY_NAME="Nyap"
# shellcheck source=.github/scripts/resolve_cask_payload.sh
source .github/scripts/resolve_cask_payload.sh
resolve_cask_payload
[[ "${CASK}" == "nyap" ]] || { echo "Assertion failed: cask token"; exit 1; }
[[ "${NAME}" == "Nyap" ]] || { echo "Assertion failed: display name"; exit 1; }

export NAME=""
export CASK_LEGACY="nyap"
export APP="Flat.app"
export OPTIONS_APP="Options.app"
resolve_cask_payload
[[ "${CASK}" == "nyap" ]] || { echo "Assertion failed: legacy cask token"; exit 1; }
[[ "${APP}" == "Options.app" ]] || { echo "Assertion failed: options.app precedence"; exit 1; }

echo "dispatch_cask_payload tests passed"
