#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: wezterm-media.sh <command> [argument]

Commands:
  check mpv|volume         Check an optional media capability
  play TRACK              Replace the owned player with TRACK
  stop                    Stop only the owned player
  volume up|down          Change the default sink volume
  state-set NAME VALUE    Persist background or brightness state
EOF
}

die() {
  printf 'wezterm-media: %s\n' "$*" >&2
  exit 2
}

home=${HOME:-}
[ -n "$home" ] || die "HOME is not set"

state_home=${XDG_STATE_HOME:-$home/.local/state}
state_dir=$state_home/dotfiles/wezterm
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
  runtime_dir=$XDG_RUNTIME_DIR/dotfiles/wezterm
else
  runtime_dir=$state_dir/runtime
fi

socket_path=$runtime_dir/mpv.sock
pid_file=$runtime_dir/mpv.pid
lock_dir=$runtime_dir/controller.lock
player_title=dotfiles-wezterm-music

ensure_private_dir() {
  local directory=$1
  mkdir -p "$directory"
  chmod 700 "$directory"
}

write_atomic() {
  local destination=$1 value=$2 temporary
  ensure_private_dir "$(dirname "$destination")"
  temporary=$(mktemp "${destination}.tmp.XXXXXX")
  printf '%s\n' "$value" > "$temporary"
  chmod 600 "$temporary"
  mv -f "$temporary" "$destination"
}

acquire_lock() {
  local attempt owner
  ensure_private_dir "$runtime_dir"
  for attempt in {1..40}; do
    if mkdir "$lock_dir" 2>/dev/null; then
      printf '%s\n' "$$" > "$lock_dir/owner"
      trap 'rm -f "$lock_dir/owner"; rmdir "$lock_dir" 2>/dev/null || true' EXIT
      return 0
    fi
    owner=
    if [ -r "$lock_dir/owner" ]; then
      IFS= read -r owner < "$lock_dir/owner" || owner=
    fi
    if ! [[ $owner =~ ^[0-9]+$ ]] || ! kill -0 "$owner" 2>/dev/null; then
      rm -f "$lock_dir/owner"
      rmdir "$lock_dir" 2>/dev/null || true
      continue
    fi
    sleep 0.05
  done
  die "media controller is busy"
}

owned_pid() {
  local pid=$1 argument saw_socket=0 saw_title=0
  [[ $pid =~ ^[0-9]+$ ]] || return 1
  [ -r "/proc/$pid/cmdline" ] || return 1

  while IFS= read -r -d '' argument; do
    case "$argument" in
      "--input-ipc-server=$socket_path") saw_socket=1 ;;
      "--title=$player_title") saw_title=1 ;;
    esac
  done < "/proc/$pid/cmdline"

  [ "$saw_socket" -eq 1 ] && [ "$saw_title" -eq 1 ]
}

stop_owned_player() {
  local pid attempt
  if [ ! -r "$pid_file" ]; then
    rm -f "$socket_path"
    return 0
  fi

  IFS= read -r pid < "$pid_file" || pid=
  if owned_pid "$pid"; then
    kill "$pid" 2>/dev/null || true
    for attempt in {1..20}; do
      if ! kill -0 "$pid" 2>/dev/null; then
        break
      fi
      sleep 0.05
    done
    if kill -0 "$pid" 2>/dev/null && owned_pid "$pid"; then
      kill -KILL "$pid" 2>/dev/null || true
    fi
  fi
  rm -f "$pid_file" "$socket_path"
}

supported_track() {
  local lower=${1,,}
  case "$lower" in
    *.mp3|*.flac|*.wav|*.m4a|*.ogg|*.opus) return 0 ;;
    *) return 1 ;;
  esac
}

supported_background() {
  local lower=${1,,}
  case "$lower" in
    *.png|*.jpg|*.jpeg|*.webp) return 0 ;;
    *) return 1 ;;
  esac
}

check_capability() {
  case "${1:-}" in
    mpv) command -v mpv >/dev/null 2>&1 ;;
    volume)
      command -v wpctl >/dev/null 2>&1 || command -v pactl >/dev/null 2>&1
      ;;
    *) die "unknown capability: ${1:-}" ;;
  esac
}

play_track() {
  local track=${1:-} mpv_path player_pid
  [ -n "$track" ] || die "play requires a track"
  [ -f "$track" ] && [ -r "$track" ] || die "track is not readable"
  supported_track "$track" || die "unsupported track format"
  mpv_path=$(command -v mpv) || die "mpv is unavailable"

  acquire_lock
  stop_owned_player
  rm -f "$socket_path"
  "$mpv_path" \
    "--title=$player_title" \
    "--input-ipc-server=$socket_path" \
    --no-video \
    --loop-file=inf \
    --really-quiet \
    -- "$track" </dev/null >/dev/null 2>&1 &
  player_pid=$!
  if ! kill -0 "$player_pid" 2>/dev/null; then
    die "mpv failed to start"
  fi
  write_atomic "$pid_file" "$player_pid"
}

stop_music() {
  acquire_lock
  stop_owned_player
}

change_volume() {
  local direction=${1:-}
  case "$direction" in
    up) ;;
    down) ;;
    *) die "volume requires up or down" ;;
  esac

  if command -v wpctl >/dev/null 2>&1; then
    if [ "$direction" = up ]; then
      wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    else
      wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    fi
  elif command -v pactl >/dev/null 2>&1; then
    if [ "$direction" = up ]; then
      pactl set-sink-volume @DEFAULT_SINK@ +5%
    else
      pactl set-sink-volume @DEFAULT_SINK@ -5%
    fi
  else
    die "no supported volume tool is available"
  fi
}

state_set() {
  local name=${1:-} value=${2:-}
  case "$name" in
    background)
      [ -f "$value" ] && [ -r "$value" ] || die "background is not readable"
      supported_background "$value" || die "unsupported background format"
      ;;
    brightness)
      [[ $value =~ ^(0\.[0-9]+|1(\.0+)?)$ ]] \
        || die "brightness must be between 0 and 1"
      awk -v value="$value" 'BEGIN { exit !(value >= 0.01 && value <= 1.0) }' \
        || die "brightness must be between 0.01 and 1"
      ;;
    *) die "unknown state name: $name" ;;
  esac
  write_atomic "$state_dir/$name" "$value"
}

command=${1:-}
case "$command" in
  check) check_capability "${2:-}" ;;
  play) play_track "${2:-}" ;;
  stop) stop_music ;;
  volume) change_volume "${2:-}" ;;
  state-set) state_set "${2:-}" "${3:-}" ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
