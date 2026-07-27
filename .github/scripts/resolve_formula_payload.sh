#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2034
resolve_formula_payload() {
  FORMULA="${NAME:-}"
  FORMULA="${FORMULA:-${FORMULA_LEGACY:-}}"

  BINARY="${OPTIONS_BINARY:-${BINARY:-}}"
  BINARY="${BINARY:-${FORMULA}}"

  TEST_MATCH="${OPTIONS_TEST_MATCH:-${TEST_MATCH:-}}"
  LICENSE="${OPTIONS_LICENSE:-${LICENSE:-MIT}}"

  URL="${OPTIONS_URL:-${URL:-}}"
  if [[ -z "${URL}" && -n "${SOURCE_REPO:-}" && -n "${VERSION:-}" && -n "${BINARY}" ]]; then
    URL="https://github.com/${SOURCE_REPO}/releases/download/v${VERSION}/${BINARY}_${VERSION}_darwin.tar.gz"
  fi

  export FORMULA BINARY TEST_MATCH LICENSE URL
}
