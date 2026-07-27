#!/usr/bin/env bash
set -euo pipefail

resolve_cask_payload() {
  CASK="${NAME:-}"
  CASK="${CASK:-${CASK_LEGACY:-}}"

  APP="${OPTIONS_APP:-${APP:-}}"
  ASSET="${OPTIONS_ASSET:-${ASSET:-}}"
  NAME="${DISPLAY_NAME:-}"
  MINIMUM_MACOS="${OPTIONS_MINIMUM_MACOS:-${MINIMUM_MACOS:-sonoma}}"

  export CASK APP ASSET NAME MINIMUM_MACOS
}
