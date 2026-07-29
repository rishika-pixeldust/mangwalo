#!/bin/bash
# MangWalo demo-video assembly:
#   golden frames (capture_screens_test.dart) -> slides (make_slides.py)
#   -> narration (macOS `say`, Rishi en-IN) -> segments -> docs/demo-video.mp4
set -euo pipefail
cd "$(dirname "$0")"

VOICE=Rishi
RATE=170
mkdir -p audio segments

narrate() { # $1 index, $2 text
  say -v "$VOICE" -r "$RATE" -o "audio/s$1.aiff" "$2"
}

narrate 0 "Meet MangWalo. Maang lo — just ask! A local-first noticeboard where neighbors in one Mumbai locality rent luxury from each other — a Chanel flap bag, a Sabyasachi lehenga, a full cricket kit. Every listing carries a daily rate, a photo gallery, and reviews. Built in Flutter for M A L Lab One, and live at mangwalo dot vercel dot app. No account, no server — everything stays on your device."

narrate 1 "So how do you use it? On your very first visit, a five-step tour walks you around the real board — search, filters, posting, requests, your account — and you can replay it any time from the How It Works menu. The board is scoped to your locality: switch from Bandra West to Powai and the listings genuinely change, with one tap to browse every locality at once. Filter by category, then narrow again by sub-category. And your profile shows what neighbors have said about you, and what of yours is currently out on loan — because reputation is what makes a stranger willing to hand over a four thousand rupee bag."

narrate 2 "First, product thinking. The niche is deliberately sharp: designer bags, event and party wear, jewellery, watches, and sports kits — priced per day, right on the card, and only from your locality. Renters leave star reviews that speak to the item and the person. And the personal feature — return date tracking — means every rented piece remembers who has it, and when it is due. Overdue rentals flag themselves, and jump to the top of the board."

narrate 3 "Second, accessibility. Every listing card is one single, meaningful screen reader announcement — not five fragments. Errors pair icons with text, never color alone. Every touch target is at least forty eight pixels. And the layout survives two hundred percent text scaling — what you see here is the feed at nearly double size, with nothing broken. Dark mode is a choice, not a guess: three palettes, every one contrast-checked to W C A G double A."

narrate 4 "Third, local A I. Type — sabyasachi lehenga, worn once and dry cleaned — and the on-device helper suggests a title, a category, condition tags, a rental window, and a rate: six thousand rupees a day, because it knows Sabyasachi is a premium label and doubles the base. It is a deterministic rules engine that understands Hinglish, needs no cloud and no A P I keys, and works fully offline — behind a swappable Local A I Service boundary, ready for a real on-device model."

narrate 5 "Fourth, security. MangWalo practices data minimization. Type a phone number, or a flat number, and it warns you instantly — showing the exact text it found. The landmark field hard-rejects addresses. Every gallery photo is re-encoded on the device, stripping location metadata before it is stored. The strongest move was deletion: the free-text contact note — the field most likely to carry a phone number — was removed from the app entirely, and old values are dropped rather than migrated. Renter names are first names only. And one tap in settings resets every byte of local data."

narrate 6 "That is MangWalo. Product thinking. Accessibility. Local A I. And security. One hundred and seven passing tests, a clean analyzer, and a deployed build you can open right now. Try it at mangwalo dot vercel dot app. Maang lo — luxury, from your locality!"

SLIDES=(s0_intro s0b_tour s1_product s2_a11y s3_ai s4_security s5_outro)
> segments/list.txt

for i in 0 1 2 3 4 5 6; do
  slide="slides/${SLIDES[$i]}.png"
  aud="audio/s$i.aiff"
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$aud")
  total=$(echo "$dur + 1.2" | bc)
  frames=$(echo "($total * 30 + 1)/1" | bc)
  fadeout=$(echo "$total - 0.6" | bc)
  ffmpeg -y -loglevel error -i "$slide" -i "$aud" -filter_complex \
    "[0:v]scale=2880:1620,zoompan=z='min(zoom+0.00022,1.09)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=${frames}:s=1920x1080:fps=30,fade=t=in:st=0:d=0.5,fade=t=out:st=${fadeout}:d=0.6,format=yuv420p[v];[1:a]apad=pad_dur=1.4,afade=t=in:st=0:d=0.25,afade=t=out:st=${fadeout}:d=0.6[a]" \
    -map "[v]" -map "[a]" -t "$total" \
    -c:v libx264 -preset medium -crf 21 -c:a aac -b:a 160k -ar 44100 -ac 2 \
    "segments/s$i.mp4"
  echo "file 's$i.mp4'" >> segments/list.txt
  echo "segment s$i: ${total}s"
done

mkdir -p ../../docs/media
ffmpeg -y -loglevel error -f concat -safe 0 -i segments/list.txt -c copy \
  ../../docs/media/mangwalo-demo.mp4
echo "---"
ffprobe -v error -show_entries format=duration,size -of default=noprint_wrappers=1 \
  ../../docs/media/mangwalo-demo.mp4
