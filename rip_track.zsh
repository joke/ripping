#!/bin/zsh
set -ex
setopt extendedglob

DVD=/dev/sr0
MINLENGTH=$((15*60.))
# OUTPUT
mkdir -p ${OUTPUT:h}


local info="$(lsdvd -t $TRACK -x $DVD -Ox | sed 's|Pan&Scan|Pan\&amp;Scan|g')"
local yuvPalette=($(xmllint --xpath '/lsdvd/track/palette/color/text()' <(print $info)))

local rgbPalette=()
for p ($yuvPalette) {
	local -i 16 y=$((0x${p[1,2]} - 16))
	local -i 16 u=$((0x${p[3,4]} - 128))
	local -i 16 v=$((0x${p[5,6]} - 128))
	local -i 16 r=$(( (1.164 * $y) + (1.596 * $v) ))
	local -i 16 g=$(( (1.164 * $y) - (0.813 * $v) - (0.391 * $u) ))
	local -i 16 b=$(( (1.164 * $y) + (2.018 * $u) ))
	(( $r < 0 )) && r=0; (( $r > 255 )) && r=255
	(( $g < 0 )) && g=0; (( $g > 255 )) && g=255
	(( $b < 0 )) && b=0; (( $b > 255 )) && b=255
	rgbPalette+="${(l:2::0:)$(([##16]r)):l}${(l:2::0:)$(([##16]g)):l}${(l:2::0:)$(([##16]b)):l}"
}

cmdline=()
streamIdx=0 ## idx 0 => video
## audio streams
local streamIds=($(xmllint --xpath "/lsdvd/track/audio[langcode = 'en']/streamid/text()" <(print $info)))
for streamId ($streamIds) {
	cmdline+=("-map" "0:#$streamId")
	cmdline+=("-metadata:s:$((++streamIdx))" "language=eng")
}

## subtitle streams
local streamIds=($(xmllint --xpath "/lsdvd/track/subp[langcode = 'en']/streamid/text()" <(print $info)))
for streamId ($streamIds) {
	cmdline+=("-map" "0:#$streamId")
	cmdline+=("-metadata:s:$((++streamIdx))" "language=eng")
}

local tmpout="$(mktemp -d -p .)"
cd $tmpout
TRAPEXIT() { rm -rf "$PWD" }
TRAPZERR() { rm -rf "$PWD" }
dvdbackup -t $TRACK -i $DVD -p -o .
vobs=(**/*VOB(#qOc))
ffmpeg -analyzeduration $((20*60*1000000)) -probesize 512M -fflags +igndts -fflags +genpts -palette ${(j:,:)rgbPalette} -i "concat:${(j:|:)vobs}" -c:v copy -c:a copy -c:s dvdsub -map 0:v:0 ${cmdline} $OUTPUT
