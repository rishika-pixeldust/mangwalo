#!/bin/bash
# MangWalo demo-video assembly:
#   golden frames (capture_screens_test.dart) -> slides (make_slides.py)
#   -> narration (macOS `say`, Rishi en-IN) -> segments -> docs/demo-video.mp4
set -euo pipefail
cd "$(dirname "$0")"

# Voice is overridable so a better engine can be dropped in without touching
# the script. The built-in "compact" voices sound synthetic; macOS Premium /
# Enhanced voices (System Settings -> Accessibility -> Spoken Content ->
# System Voice -> Manage Voices) are markedly more natural and work here
# unchanged. Example:
#
#   MANGWALO_VOICE="Rishi (Enhanced)" ./tool/demo/build_video.sh
#
VOICE="${MANGWALO_VOICE:-Rishi}"
# Slower than conversational: narration over slides needs room to land, and
# the compact voices in particular read badly when rushed.
RATE="${MANGWALO_RATE:-152}"
mkdir -p audio segments

# Narration source:
#   say      (default) synthesise with the macOS voice above
#   external use audio you supply as tool/demo/audio/s0..s6.{aiff,wav,mp3,m4a}
#            — slide durations are taken from YOUR files, so a human or neural
#            voice-over lands in perfect sync with no manual timing
#   none     no audio track at all; slides run for TARGETS[] seconds
MODE="${MANGWALO_NARRATION:-say}"

# Reference lengths, used only by `none`. Roughly what the script takes to read
# aloud, so a silent cut keeps the intended rhythm and leaves room for a VO.
TARGETS=(32 46 35 36 37 47 24)

if [[ "$MODE" == "say" ]]; then
  # `say -o` needs a real audio target, so probe into a temp file.
  if ! say -v "$VOICE" -o "$(mktemp -t voiceprobe).aiff" "test" 2>/dev/null; then
    echo "Voice '$VOICE' is not installed. Available:" >&2
    say -v '?' | awk '{print "  " $1}' | sort -u | head -40 >&2
    exit 1
  fi
  echo "narration: say — $VOICE @ ${RATE}wpm"
else
  echo "narration: $MODE"
fi

# Pacing: insert real breath pauses where a human would take them — after a
# sentence, and around the em-dashes and colons this script leans on. Keeping
# the markers out of the narration strings below leaves them readable and
# means pacing is tuned in exactly one place.
narrate() { # $1 index, $2 text
  [[ "$MODE" == "say" ]] || return 0
  local paced
  paced=$(printf '%s' "$2" \
    | sed -e 's/\. /. [[slnc 280]] /g' \
          -e 's/? /? [[slnc 280]] /g' \
          -e 's/! /! [[slnc 300]] /g' \
          -e 's/ — / — [[slnc 170]] /g' \
          -e 's/: /: [[slnc 170]] /g')
  say -v "$VOICE" -r "$RATE" -o "audio/s$1.aiff" "$paced"
}

narrate 0 "Meet MangWalo. Maang lo — just ask! A local-first noticeboard where neighbors in one Mumbai locality rent luxury from each other — a Chanel flap bag, a Sabyasachi lehenga, a full cricket kit. Every listing carries a daily rate, a photo gallery, and reviews. Built in Flutter for M A L Lab One, and live at mangwalo dot vercel dot app. No account, no server — everything stays on your device."

narrate 1 "So how do you use it? On your very first visit, a five-step tour walks you around the real board — search, filters, posting, requests, your account — and you can replay it any time from the How It Works menu. The board is scoped to your locality: switch from Bandra West to Powai and the listings genuinely change, with one tap to browse every locality at once. Filter by category, then narrow again by sub-category. And your profile shows what neighbors have said about you, and what of yours is currently out on loan — because reputation is what makes a stranger willing to hand over a four thousand rupee bag."

narrate 2 "First, product thinking. The niche is deliberately sharp: designer bags, event and party wear, jewellery, watches, and sports kits — priced per day, right on the card, and only from your locality. Renters leave star reviews that speak to the item and the person. And the personal feature — return date tracking — means every rented piece remembers who has it, and when it is due. Overdue rentals flag themselves, and jump to the top of the board."

narrate 3 "Second, accessibility. Every listing card is one single, meaningful screen reader announcement — not five fragments. Errors pair icons with text, never color alone. Every touch target is at least forty eight pixels. And the layout survives two hundred percent text scaling — what you see here is the feed at nearly double size, with nothing broken. Dark mode is a choice, not a guess: three palettes, every one contrast-checked to W C A G double A."

narrate 4 "Third, local A I. Type — sabyasachi lehenga, worn once and dry cleaned — and the on-device helper suggests a title, a category, condition tags, a rental window, and a rate: six thousand rupees a day, because it knows Sabyasachi is a premium label and doubles the base. It is a deterministic rules engine that understands Hinglish, needs no cloud and no A P I keys, and works fully offline — behind a swappable Local A I Service boundary, ready for a real on-device model."

narrate 5 "Fourth, security. MangWalo practices data minimization. Type a phone number, or a flat number, and it warns you instantly — showing the exact text it found. The landmark field hard-rejects addresses. Every gallery photo is re-encoded on the device, stripping location metadata before it is stored. The strongest move was deletion: the free-text contact note — the field most likely to carry a phone number — was removed from the app entirely, and old values are dropped rather than migrated. Renter names are first names only. And one tap in settings resets every byte of local data."

narrate 6 "That is MangWalo. Product thinking. Accessibility. Local A I. And security. One hundred and seven passing tests, a clean analyzer, and a deployed build you can open right now. Try it at mangwalo dot vercel dot app. Maang lo — luxury, from your locality!"

# First existing audio file for a segment, whatever container it came in.
find_audio() { # $1 index
  local f
  for ext in aiff wav mp3 m4a aac flac; do
    f="audio/s$1.$ext"
    [[ -f "$f" ]] && { printf '%s' "$f"; return 0; }
  done
  return 1
}

SLIDES=(s0_intro s0b_tour s1_product s2_a11y s3_ai s4_security s5_outro)
> segments/list.txt

for i in 0 1 2 3 4 5 6; do
  slide="slides/${SLIDES[$i]}.png"

  if [[ "$MODE" == "none" ]]; then
    total="${TARGETS[$i]}"
    aud=""
  else
    if ! aud=$(find_audio "$i"); then
      echo "Missing audio for segment $i — expected audio/s$i.{aiff,wav,mp3,m4a}" >&2
      exit 1
    fi
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$aud")
    # Tail padding so the slide does not cut the moment the voice stops.
    total=$(echo "$dur + 1.2" | bc)
  fi

  frames=$(echo "($total * 30 + 1)/1" | bc)
  fadeout=$(echo "$total - 0.6" | bc)
  # Slow push-in keeps a still slide feeling alive.
  VF="[0:v]scale=2880:1620,zoompan=z='min(zoom+0.00013,1.055)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=${frames}:s=1920x1080:fps=30,fade=t=in:st=0:d=0.7,fade=t=out:st=${fadeout}:d=0.6,format=yuv420p[v]"

  if [[ -z "$aud" ]]; then
    # Silent cut: video only, so an editor can drop a voice track underneath.
    ffmpeg -y -loglevel error -i "$slide" -filter_complex "$VF" \
      -map "[v]" -t "$total" \
      -c:v libx264 -preset medium -crf 21 "segments/s$i.mp4"
  else
    ffmpeg -y -loglevel error -i "$slide" -i "$aud" -filter_complex \
      "${VF};[1:a]apad=pad_dur=1.4,afade=t=in:st=0:d=0.25,afade=t=out:st=${fadeout}:d=0.6[a]" \
      -map "[v]" -map "[a]" -t "$total" \
      -c:v libx264 -preset medium -crf 21 -c:a aac -b:a 160k -ar 44100 -ac 2 \
      "segments/s$i.mp4"
  fi
  echo "file 's$i.mp4'" >> segments/list.txt
  echo "segment s$i: ${total}s${aud:+  <- $aud}"
done

mkdir -p ../../docs/media
OUT="${MANGWALO_OUT:-../../docs/media/mangwalo-demo.mp4}"
[[ "$MODE" == "none" && -z "${MANGWALO_OUT:-}" ]] \
  && OUT=../../docs/media/mangwalo-demo-silent.mp4

# Smooth joins: cross-dissolve video and cross-fade audio at every boundary
# instead of butt-splicing. Each segment already fades to and from its own
# background, so a hard cut reads as a flicker; xfade absorbs it.
#
# Built as a chain because xfade takes exactly two inputs. Each join consumes
# XF seconds of overlap, so the running length is tracked to place the next one.
XF=0.5
COUNT=${#SLIDES[@]}

if (( COUNT < 2 )); then
  ffmpeg -y -loglevel error -f concat -safe 0 -i segments/list.txt -c copy "$OUT"
else
  inputs=(); for ((i=0;i<COUNT;i++)); do inputs+=(-i "segments/s$i.mp4"); done

  dur() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1"; }

  # First join.
  offset=$(echo "$(dur segments/s0.mp4) - $XF" | bc)
  filter="[0:v][1:v]xfade=transition=fade:duration=$XF:offset=$offset[v1]"
  if [[ "$MODE" != "none" ]]; then
    filter="$filter;[0:a][1:a]acrossfade=d=$XF[a1]"
  fi
  running=$(echo "$(dur segments/s0.mp4) + $(dur segments/s1.mp4) - $XF" | bc)

  for ((i=2;i<COUNT;i++)); do
    offset=$(echo "$running - $XF" | bc)
    filter="$filter;[v$((i-1))][$i:v]xfade=transition=fade:duration=$XF:offset=$offset[v$i]"
    if [[ "$MODE" != "none" ]]; then
      filter="$filter;[a$((i-1))][$i:a]acrossfade=d=$XF[a$i]"
    fi
    running=$(echo "$running + $(dur segments/s$i.mp4) - $XF" | bc)
  done

  last=$((COUNT-1))
  if [[ "$MODE" == "none" ]]; then
    ffmpeg -y -loglevel error "${inputs[@]}" -filter_complex "$filter" \
      -map "[v$last]" -c:v libx264 -preset medium -crf 21 -pix_fmt yuv420p "$OUT"
  else
    ffmpeg -y -loglevel error "${inputs[@]}" -filter_complex "$filter" \
      -map "[v$last]" -map "[a$last]" \
      -c:v libx264 -preset medium -crf 21 -pix_fmt yuv420p \
      -c:a aac -b:a 160k -ar 44100 -ac 2 "$OUT"
  fi
  echo "joined $COUNT segments with ${XF}s cross-dissolves"
fi
echo "---"
echo "wrote $OUT"
ffprobe -v error -show_entries format=duration,size -of default=noprint_wrappers=1 "$OUT"
