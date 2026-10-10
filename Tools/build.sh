#!/bin/bash
# RetroAchievementsUI — the one door to a compile or an archive on this repo.
#
#   Tools/build.sh compile  "<task>" [min]    # build only, no simulator, no signing
#   Tools/build.sh archive  "<task>" [min]    # archive, release the machine, then export
#
# Several sessions share this Mac, so heavy compute is serialised through a machine lock.
# This script exists so that gating is not something a session has to remember: every
# archive and every compile goes through here, claims the machine, and gives it back at
# the earliest honest moment.
#
# It deliberately does NOT upload — see the note at the foot. Nothing here is secret: no
# password, no key material, no absolute /Users path, because this repo is public.
set -u

LOCK="${MACHINE_LOCK:-$HOME/Development/.claude/machine-lock}"
REPO=$(cd "$(dirname "$0")/.." && pwd -P)     # Tools/ -> repo root. See note 1 at the foot.
PROJECT=RetroAchievementsUI
SCHEME=RetroAchievementsUI
TEAM=Z8253GXZFC
KEY_ID="${ASC_KEY_ID:-299R8VMYUM}"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_$KEY_ID.p8"
MODE="${1:-}"; TASK="${2:-build}"; MIN="${3:-20}"
case "$MODE" in compile|archive) ;; *) echo "usage: build.sh compile|archive \"<task>\" [min]" >&2; exit 2;; esac

# ---- everything that can fail without the machine, fails here -------------------------
# Validate BEFORE the gate, never after. Taking the machine out of a shared queue and then
# dying on an unset variable costs every other session the wait for nothing, and the exit
# trap's release makes it look tidy while it does so.
if [ "$MODE" = archive ]; then
  : "${ASC_ISSUER_ID:?set ASC_ISSUER_ID in your environment — it is not stored in this public repo}"
  [ -r "$KEY_PATH" ] || { echo "build.sh: no ASC key at $KEY_PATH" >&2; exit 2; }
  # A missing unlock is a hard failure, not a skipped step. Signing fails one stage later
  # than the cause (see note 2), so silently proceeding without it buys an error that
  # names the wrong thing.
  [ -x "$LOCK/unlock-signing.sh" ] || { echo "build.sh: no unlock-signing.sh at $LOCK" >&2; exit 2; }
fi

# ---- enter the block ------------------------------------------------------------------
# Gate first, then claim. The gate is for ENTERING a block; the marker is what protects
# everyone else once you are in one, because the ledger header is written by the
# coordinator and the coordinator is not continuously present.
"$LOCK/can-i-build.sh" "$REPO" || { echo "build.sh: machine is held — not building" >&2; exit 3; }
"$LOCK/claim.sh" take "$REPO" "$TASK" "$MIN" || exit 3

# RELEASED guard: this script releases EARLY (at the archive boundary) and the EXIT trap
# must not release a second time. A double release writes a marker reading "was: unknown".
RELEASED=0
release_once() {
  [ "$RELEASED" = "1" ] && return 0
  RELEASED=1
  "$LOCK/claim.sh" release "$REPO" >/dev/null 2>&1
  echo "=== MACHINE RELEASED $(date +%H:%M:%S) — anything after this line is network-bound ==="
}
# Installed AFTER the claim succeeds, never before: a gate refusal exits above this line,
# so a refused run cannot fire the release path at all.
trap release_once EXIT

cd "$REPO" || exit 1
# No xcodegen here — the .xcodeproj is committed and edited directly in this repo.

LOG=/tmp/ra-build.log
if [ "$MODE" = compile ]; then
  # 'generic/platform=iOS Simulator' compiles for the simulator without booting one.
  xcodebuild -project "$PROJECT.xcodeproj" -scheme "$SCHEME" -configuration Debug \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/ra-dd \
    build > "$LOG" 2>&1
  status=$?                                  # read the status, THEN grep for reporting:
  grep -E "error:|\*\* BUILD" "$LOG" | tail -5   # a pipeline would report grep's result.
  echo "build.sh: compile exit=$status"
  exit $status
fi

# ---- archive --------------------------------------------------------------------------
ARCHIVE=/tmp/ra-$(date +%Y%m%d-%H%M%S).xcarchive
# Automatic signing plus -allowProvisioningUpdates and the auth-key flags: NO provisioning
# profile exists for this bundle id, so xcodebuild mints one through the API. Adding a
# PROVISIONING_PROFILE_SPECIFIER would break that, not fix it.
xcodebuild -project "$PROJECT.xcodeproj" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyPath "$KEY_PATH" \
  archive > "$LOG" 2>&1
status=$?
grep -E "error:|\*\* ARCHIVE" "$LOG" | tail -5
if [ $status -ne 0 ]; then
  echo "build.sh: archive FAILED exit=$status — see $LOG"
  exit $status
fi

# THE MACHINE GOES BACK HERE. The archive is the compute; the export and any upload are
# network-bound and contend with nothing, so holding the block through them is dead time
# the whole queue pays for.
release_once

# Note 2. Unlock BEFORE the export, not only before the archive: archiving does not
# re-sign for distribution, so a locked keychain fails one step later than you would
# expect — errSecInternalComponent, or a hang on a SecurityAgent dialog nobody can answer.
"$LOCK/unlock-signing.sh" || { echo "build.sh: signing keychain would not unlock" >&2; exit 4; }

PLIST=/tmp/ra-export.plist
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>$TEAM</string>
  <key>destination</key><string>export</string>
  <!-- FALSE, deliberately. The version here is always a decision, never Xcode's latest+1. -->
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PL

xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath /tmp/ra-export \
  -exportOptionsPlist "$PLIST" \
  -allowProvisioningUpdates \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyPath "$KEY_PATH" \
  > /tmp/ra-export.log 2>&1
status=$?
grep -E "error:|EXPORT" /tmp/ra-export.log | tail -5
[ $status -eq 0 ] && ls -l /tmp/ra-export/*.ipa 2>/dev/null
echo "build.sh: export exit=$status"
echo
echo "NO UPLOAD, deliberately. Uploading needs credentials that have no business in a"
echo "public repo. Take the .ipa above to the App Store Connect API tooling — that is a"
echo "network step and needs no machine block."
exit $status

# ---- two notes -------------------------------------------------------------------------
# 1. REPO resolves Tools/.. to the repo root. If this file ever moves, that expression moves
#    with it: getting it wrong does NOT error, the gate simply stops matching this repo
#    against the ledger's holder and stops exempting its own tooling.
# 2. The export method is "app-store-connect". Older Xcode wants "app-store"; if yours
#    rejects it, that is the line to change and the failure will name it.
