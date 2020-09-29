#!/bin/zsh
set -ex

DVD=/dev/sr1
mkdir -p ${OUTPUT:h}

local info="$(lsdvd -x $DVD -Ox | sed 's|Pan&Scan|Pan\&amp;Scan|g')"
local lengths=($(xmllint --xpath '/lsdvd/track/length/text()' <(print $info)))
local maxLength=${${(On)lengths}[1]}
local track=${lengths[(i)$maxLength]}
TRACK=$track exec ./rip_track.zsh


