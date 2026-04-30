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
#
# Resolution order (highest priority first):
#   1. $SIMPLECAP2_APP_PATH override (if set).
#   2. The bundle of any currently-running SimpleCap2 process — matches the
#      user's actual runtime expectation, especially during development.
#   3. /Applications/SimpleCap2.app, then ~/Applications/SimpleCap2.app.
#   4. Anything else Spotlight finds, sorted newest-first by mtime so a
#      stale Xcode archive doesn't mask a fresh install.
# The first candidate whose code signature matches $EXPECTED_TEAM_ID wins.
locate_app_bundle() {
  local override="${SIMPLECAP2_APP_PATH:-}"
  local candidates=()
  local seen

  _push_candidate() {
    local p="$1"
    [ -z "$p" ] && return
    [ -d "$p" ] || return
    for seen in "${candidates[@]+"${candidates[@]}"}"; do
      [ "$seen" = "$p" ] && return
    done
    candidates+=("$p")
  }

  if [ -n "$override" ]; then
    _push_candidate "$override"
  fi

  # Running instance: strip /Contents/MacOS/SimpleCap2 to get the bundle.
  local running_exe
  running_exe=$(ps -A -o command= 2>/dev/null \
    | awk '/\/Contents\/MacOS\/SimpleCap2( |$)/ {sub(/ .*/, ""); print; exit}')
  if [ -n "$running_exe" ]; then
    _push_candidate "${running_exe%/Contents/MacOS/SimpleCap2}"
  fi

  _push_candidate "/Applications/SimpleCap2.app"
  _push_candidate "$HOME/Applications/SimpleCap2.app"

  # Spotlight, sorted newest-first by directory mtime.
  local sorted
  sorted=$(mdfind "kMDItemCFBundleIdentifier == '$EXPECTED_BUNDLE_ID'" 2>/dev/null \
    | while IFS= read -r p; do
        [ -d "$p" ] && printf '%s\t%s\n' "$(stat -f '%m' "$p" 2>/dev/null || echo 0)" "$p"
      done \
    | sort -nr \
    | cut -f2-)
  while IFS= read -r line; do
    _push_candidate "$line"
  done <<<"$sorted"

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
