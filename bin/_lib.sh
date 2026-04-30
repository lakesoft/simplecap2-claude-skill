# shellcheck shell=bash
#
# Shared helpers for the simplecap2 plugin's bin/ scripts.
# This file is sourced (not executed); no shebang.
#
# Responsibilities:
#   - Locate the SimpleCap2.app bundle on the user's machine.
#   - Verify its code signature against the expected Apple Developer Team ID
#     so a malicious "SimpleCap2" rebuild or a same-bundle-id imposter app
#     can't intercept calls.
#   - Provide friendly stderr messages when something is wrong.

EXPECTED_TEAM_ID="EDF37AMEEW"
EXPECTED_BUNDLE_ID="jp.lakesoft.simplecap2"

# Print the absolute path to a verified SimpleCap2.app bundle on stdout.
# Returns non-zero (with diagnostic on stderr) if no installation passes
# Team ID verification.
locate_app_bundle() {
  local override="${SIMPLECAP2_APP_PATH:-}"
  local candidates=()

  if [ -n "$override" ]; then
    candidates+=("$override")
  fi
  if [ -d "/Applications/SimpleCap2.app" ]; then
    candidates+=("/Applications/SimpleCap2.app")
  fi
  if [ -d "$HOME/Applications/SimpleCap2.app" ]; then
    candidates+=("$HOME/Applications/SimpleCap2.app")
  fi

  # Spotlight-fallback: any other install location, including DerivedData
  # for local development.
  while IFS= read -r line; do
    [ -n "$line" ] && candidates+=("$line")
  done < <(mdfind "kMDItemCFBundleIdentifier == '$EXPECTED_BUNDLE_ID'" 2>/dev/null)

  if [ ${#candidates[@]} -eq 0 ]; then
    cat >&2 <<EOF
SimpleCap2 not found.
- Install it from the Mac App Store, or
- Set SIMPLECAP2_APP_PATH=/path/to/SimpleCap2.app for a custom install location.
EOF
    return 1
  fi

  # Pick the first candidate that passes Team ID verification.
  local cand
  for cand in "${candidates[@]}"; do
    [ -d "$cand" ] || continue
    local team_id
    team_id=$(codesign -dv --verbose=4 "$cand" 2>&1 | awk -F'=' '/^TeamIdentifier=/ {print $2}')
    if [ "$team_id" = "$EXPECTED_TEAM_ID" ]; then
      printf '%s\n' "$cand"
      return 0
    fi
  done

  cat >&2 <<EOF
SimpleCap2 was found but its code signature did not match the expected
Lakesoft Team ID ($EXPECTED_TEAM_ID). Refusing to use it.

This protects against tampered binaries or same-bundle-id imposters.
Please reinstall the genuine SimpleCap2 from the Mac App Store.

Checked locations:
$(printf '  - %s\n' "${candidates[@]}")
EOF
  return 1
}

# Print the absolute path to the SimpleCap2 CLI binary on stdout
# (= app bundle's executable). Verifies the same Team ID as the bundle.
locate_app_binary() {
  local bundle
  bundle=$(locate_app_bundle) || return 1
  printf '%s/Contents/MacOS/SimpleCap2\n' "$bundle"
}
