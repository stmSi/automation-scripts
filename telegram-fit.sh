#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  cat <<'EOF'
Usage:
  telegram-fit.sh input [output.mp4] [target_bytes] [width]

Defaults:
  output.mp4    -> input basename + .telegram.mp4
  target_bytes  -> 1900000000
  width         -> 1280

Environment overrides:
  AUDIO_KBPS    -> default 128
  PRESET        -> default medium

Examples:
  telegram-fit.sh movie.mkv
  telegram-fit.sh movie.mkv movie.telegram.mp4
  telegram-fit.sh movie.mkv movie.premium.mp4 3900000000 1600
EOF
  exit $(( $# < 1 ))
fi

in="$1"
out="${2:-${in%.*}.telegram.mp4}"
target_bytes="${3:-1900000000}"
width="${4:-1280}"
audio_kbps="${AUDIO_KBPS:-128}"
preset="${PRESET:-medium}"
passlog="/tmp/telegram-fit.$$"

if [[ ! -f "$in" ]]; then
  printf 'Input file not found: %s\n' "$in" >&2
  exit 1
fi

if ! [[ "$target_bytes" =~ ^[0-9]+$ && "$width" =~ ^[0-9]+$ && "$audio_kbps" =~ ^[0-9]+$ ]]; then
  printf 'target_bytes, width, and AUDIO_KBPS must be integers.\n' >&2
  exit 1
fi

cleanup() {
  rm -f "${passlog}"*
}
trap cleanup EXIT

duration="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")"

if [[ -z "$duration" ]]; then
  printf 'Could not read media duration from: %s\n' "$in" >&2
  exit 1
fi

video_kbps="$(awk -v dur="$duration" -v target="$target_bytes" -v audio="$audio_kbps" '
BEGIN {
  overhead_bps = 20 * 1024 * 1024 * 8 / dur
  total_bps = target * 8 / dur - overhead_bps
  video_bps = total_bps - audio * 1000
  if (video_bps < 300000) video_bps = 300000
  printf "%d\n", video_bps / 1000
}')"

printf 'Input: %s\n' "$in"
printf 'Output: %s\n' "$out"
printf 'Duration: %.3f s\n' "$duration"
printf 'Target size: %s bytes\n' "$target_bytes"
printf 'Width: %spx\n' "$width"
printf 'Audio bitrate: %sk\n' "$audio_kbps"
printf 'Video bitrate: %sk\n' "$video_kbps"

ffmpeg -y -i "$in" \
  -map 0:v:0 \
  -vf "scale=${width}:-2:flags=lanczos,setsar=1" \
  -c:v libx264 -preset "$preset" -b:v "${video_kbps}k" \
  -pass 1 -passlogfile "$passlog" \
  -pix_fmt yuv420p -an -f mp4 /dev/null

ffmpeg -y -i "$in" \
  -map 0:v:0 -map 0:a:0? \
  -vf "scale=${width}:-2:flags=lanczos,setsar=1" \
  -c:v libx264 -preset "$preset" -b:v "${video_kbps}k" \
  -pass 2 -passlogfile "$passlog" \
  -pix_fmt yuv420p \
  -c:a aac -b:a "${audio_kbps}k" -ac 2 \
  -movflags +faststart \
  "$out"

stat -c '%n %s bytes' "$out"
