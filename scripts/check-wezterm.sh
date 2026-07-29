#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
CONFIG=$DOTFILES_ROOT/wezterm/.wezterm.lua
SPEC=$DOTFILES_ROOT/wezterm/tests/config_spec.lua
CONTROLLER=$DOTFILES_ROOT/scripts/wezterm-media.sh

tmp=$(mktemp -d)
rootless_home="$tmp/user-root"
owned_pids=()
cleanup() {
  local pid
  HOME="$tmp/home" XDG_STATE_HOME="$tmp/state" XDG_RUNTIME_DIR="$tmp/runtime" \
    bash "$CONTROLLER" stop >/dev/null 2>&1 || true
  for pid in "${owned_pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  rm -rf "$tmp"
}
trap cleanup EXIT

mkdir -p \
  "$tmp/home" "$tmp/state" "$tmp/cache" "$tmp/data" "$tmp/runtime" \
  "$tmp/backgrounds" "$tmp/music" "$tmp/bin" \
  "$rootless_home/dotfiles/wezterm/bg" \
  "$rootless_home/dotfiles/wezterm/sd"

touch \
  "$tmp/backgrounds/a-default.png" \
  "$tmp/backgrounds/b-second.jpg" \
  "$tmp/backgrounds/c-third.jpeg" \
  "$tmp/backgrounds/d-fourth.webp" \
  "$tmp/music/a-default.mp3" \
  "$tmp/music/b-second.flac" \
  "$rootless_home/dotfiles/wezterm/bg/a-discovered.png" \
  "$rootless_home/dotfiles/wezterm/sd/a-discovered.mp3"
ln -s "$CONFIG" "$rootless_home/dotfiles/wezterm/.wezterm.lua"

lua_parser=
if command -v luac5.4 >/dev/null 2>&1; then
  lua_parser=luac5.4
elif command -v luac >/dev/null 2>&1; then
  lua_parser=luac
fi
[ -n "$lua_parser" ] || {
  printf 'check-wezterm: REQUIRED-BLOCKER: Lua parser is unavailable\n' >&2
  exit 1
}
"$lua_parser" -p "$CONFIG" "$SPEC"

glob="$tmp/backgrounds/d-fourth.webp;$tmp/backgrounds/b-second.jpg;$tmp/backgrounds/a-default.png;$tmp/backgrounds/c-third.jpeg;$tmp/music/b-second.flac;$tmp/music/a-default.mp3"
common_env=(
  HOME="$tmp/home"
  XDG_CONFIG_HOME="$tmp/config"
  XDG_STATE_HOME="$tmp/state"
  XDG_CACHE_HOME="$tmp/cache"
  XDG_DATA_HOME="$tmp/data"
  XDG_RUNTIME_DIR="$tmp/runtime"
  DOTFILES_ROOT="$DOTFILES_ROOT"
  DOTFILES_WEZTERM_BG_DIR="$tmp/backgrounds"
  DOTFILES_WEZTERM_MUSIC_DIR="$tmp/music"
  DOTFILES_WEZTERM_MEDIA_CONTROLLER="$CONTROLLER"
  WEZTERM_TEST_CONFIG_DIR="$DOTFILES_ROOT/wezterm"
  WEZTERM_TEST_CONFIG_FILE="$CONFIG"
  WEZTERM_TEST_GLOB="$glob"
  WEZTERM_TEST_BG_PREFIX="$tmp/backgrounds/"
)

env "${common_env[@]}" DOTFILES_WEZTERM_MODE=minimal \
  lua "$SPEC" "$CONFIG" minimal
env "${common_env[@]}" DOTFILES_WEZTERM_MODE=normal \
  WEZTERM_TEST_EXPECTED_BG="$tmp/backgrounds/a-default.png" \
  lua "$SPEC" "$CONFIG" normal
env "${common_env[@]}" DOTFILES_WEZTERM_MODE=normal \
  DOTFILES_WEZTERM_BG="$tmp/backgrounds/d-fourth.webp" \
  WEZTERM_TEST_EXPECTED_BG="$tmp/backgrounds/d-fourth.webp" \
  lua "$SPEC" "$CONFIG" normal
env "${common_env[@]}" DOTFILES_WEZTERM_MODE=aesthetic \
  lua "$SPEC" "$CONFIG" aesthetic
env "${common_env[@]}" DOTFILES_WEZTERM_MODE=normal \
  WEZTERM_TEST_GLOB='' lua "$SPEC" "$CONFIG" missing
env "${common_env[@]}" DOTFILES_WEZTERM_MODE=normal \
  WEZTERM_TEST_MPV=0 lua "$SPEC" "$CONFIG" missing-mpv
env "${common_env[@]}" DOTFILES_WEZTERM_MODE=normal \
  WEZTERM_TEST_MPV=1 WEZTERM_TEST_VOLUME=1 \
  lua "$SPEC" "$CONFIG" callbacks

rootless_bg="$rootless_home/dotfiles/wezterm/bg/a-discovered.png"
rootless_track="$rootless_home/dotfiles/wezterm/sd/a-discovered.mp3"
rootless_glob="$rootless_track;$rootless_bg"
env -u DOTFILES_ROOT \
  HOME="$rootless_home" \
  XDG_CONFIG_HOME="$tmp/config" \
  XDG_STATE_HOME="$tmp/state" \
  XDG_CACHE_HOME="$tmp/cache" \
  XDG_DATA_HOME="$tmp/data" \
  XDG_RUNTIME_DIR="$tmp/runtime" \
  DOTFILES_WEZTERM_MODE=normal \
  DOTFILES_WEZTERM_MEDIA_CONTROLLER="$CONTROLLER" \
  WEZTERM_TEST_CONFIG_DIR="$rootless_home" \
  WEZTERM_TEST_CONFIG_FILE="$rootless_home/.wezterm.lua" \
  WEZTERM_TEST_GLOB="$rootless_glob" \
  WEZTERM_TEST_EXPECTED_BG="$rootless_bg" \
  WEZTERM_TEST_EXPECTED_TRACK="$rootless_track" \
  WEZTERM_TEST_MPV=1 \
  lua "$SPEC" "$CONFIG" discovered-root

mkdir -p "$tmp/state/dotfiles/wezterm"
printf '%s\n' "$tmp/backgrounds/b-second.jpg" \
  > "$tmp/state/dotfiles/wezterm/background"
printf '0.42\n' > "$tmp/state/dotfiles/wezterm/brightness"
env "${common_env[@]}" DOTFILES_WEZTERM_MODE=normal \
  WEZTERM_TEST_EXPECTED_BG="$tmp/backgrounds/b-second.jpg" \
  lua "$SPEC" "$CONFIG" reload

cat > "$tmp/bin/mpv" <<'MPV'
#!/bin/bash
printf '%s\n' "$*" >> "$DOTFILES_WEZTERM_TEST_LOG"
child=
trap '[ -z "$child" ] || kill "$child" 2>/dev/null; exit 0' TERM INT
while :; do
  /bin/sleep 1 &
  child=$!
  wait "$child" || true
done
MPV
chmod +x "$tmp/bin/mpv"

controller_env=(
  HOME="$tmp/home"
  XDG_STATE_HOME="$tmp/state"
  XDG_RUNTIME_DIR="$tmp/runtime"
  DOTFILES_WEZTERM_TEST_LOG="$tmp/mpv.log"
)

PATH="$tmp/bin:/usr/bin:/bin" env "${controller_env[@]}" \
  bash "$CONTROLLER" check mpv
mkdir -p "$tmp/runtime/dotfiles/wezterm/controller.lock"
printf '99999999\n' > "$tmp/runtime/dotfiles/wezterm/controller.lock/owner"
PATH="$tmp/bin:/usr/bin:/bin" env "${controller_env[@]}" \
  bash "$CONTROLLER" play "$tmp/music/a-default.mp3"
pid_one=$(<"$tmp/runtime/dotfiles/wezterm/mpv.pid")
owned_pids+=("$pid_one")
kill -0 "$pid_one"

PATH="$tmp/bin:/usr/bin:/bin" env "${controller_env[@]}" \
  bash "$CONTROLLER" play "$tmp/music/b-second.flac"
pid_two=$(<"$tmp/runtime/dotfiles/wezterm/mpv.pid")
owned_pids+=("$pid_two")
[ "$pid_one" != "$pid_two" ]
if kill -0 "$pid_one" 2>/dev/null; then
  printf 'check-wezterm: previous owned player is still running\n' >&2
  exit 1
fi
kill -0 "$pid_two"

PATH="$tmp/bin:/usr/bin:/bin" env "${controller_env[@]}" \
  bash "$CONTROLLER" stop
if kill -0 "$pid_two" 2>/dev/null; then
  printf 'check-wezterm: owned player survived stop\n' >&2
  exit 1
fi

/bin/sleep 30 &
unrelated_pid=$!
owned_pids+=("$unrelated_pid")
mkdir -p "$tmp/runtime/dotfiles/wezterm"
printf '%s\n' "$unrelated_pid" > "$tmp/runtime/dotfiles/wezterm/mpv.pid"
PATH="$tmp/bin:/usr/bin:/bin" env "${controller_env[@]}" \
  bash "$CONTROLLER" stop
kill -0 "$unrelated_pid"
kill "$unrelated_pid"

cat > "$tmp/bin/wpctl" <<'WPCTL'
#!/bin/bash
printf 'wpctl %s\n' "$*" >> "$DOTFILES_WEZTERM_TEST_LOG"
WPCTL
cat > "$tmp/bin/pactl" <<'PACTL'
#!/bin/bash
printf 'pactl %s\n' "$*" >> "$DOTFILES_WEZTERM_TEST_LOG"
PACTL
chmod +x "$tmp/bin/wpctl" "$tmp/bin/pactl"

PATH="$tmp/bin" /usr/bin/env "${controller_env[@]}" \
  /bin/bash "$CONTROLLER" volume up
grep -q '^wpctl ' "$tmp/mpv.log"
rm -f "$tmp/bin/wpctl"
PATH="$tmp/bin" /usr/bin/env "${controller_env[@]}" \
  /bin/bash "$CONTROLLER" volume down
grep -q '^pactl ' "$tmp/mpv.log"
rm -f "$tmp/bin/pactl"
if PATH="$tmp/bin" /usr/bin/env "${controller_env[@]}" \
  /bin/bash "$CONTROLLER" volume up >/dev/null 2>&1; then
  printf 'check-wezterm: volume unexpectedly succeeded without a tool\n' >&2
  exit 1
fi

env "${controller_env[@]}" bash "$CONTROLLER" state-set \
  background "$tmp/backgrounds/c-third.jpeg"
env "${controller_env[@]}" bash "$CONTROLLER" state-set brightness 0.55
grep -Fxq "$tmp/backgrounds/c-third.jpeg" "$tmp/state/dotfiles/wezterm/background"
grep -Fxq '0.55' "$tmp/state/dotfiles/wezterm/brightness"

if command -v wezterm >/dev/null 2>&1; then
  for test_mode in minimal normal aesthetic; do
    env \
      HOME="$tmp/home" \
      XDG_CONFIG_HOME="$tmp/config" \
      XDG_STATE_HOME="$tmp/state" \
      XDG_CACHE_HOME="$tmp/cache" \
      XDG_DATA_HOME="$tmp/data" \
      XDG_RUNTIME_DIR="$tmp/runtime" \
      DOTFILES_ROOT="$DOTFILES_ROOT" \
      DOTFILES_WEZTERM_MODE="$test_mode" \
      wezterm --config-file "$CONFIG" show-keys >/dev/null
  done
else
  printf 'check-wezterm: OPTIONAL-SKIP: WezTerm is not installed\n'
fi

printf 'check-wezterm: PASS\n'
