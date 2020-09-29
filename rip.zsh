#!/bin/zsh
set -ex

DVD=/dev/sr1
MINLENGTH=$((15*60.))
OUTPATH='/mnt/tvshows/Boston Legal'

local info="$(lsdvd -x $DVD -Ox)"
cat <<< $info

local tracksCnt=$(xmllint --xpath 'count(/lsdvd/track)' <(print $info))
local tracks=($(xmllint --xpath '/lsdvd/track/ix/text()' <(print $info)))

for track ($tracks) {
	cmdline=()
	local length=$(xmllint --xpath "/lsdvd/track[$track]/length/text()" <(print $info))
	[[ $length -lt $MINLENGTH ]] && continue
	print "@ track $track @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

	## audio streams
	local streamId="$(xmllint --xpath "/lsdvd/track[$track]/audio[langcode = 'en']/streamid/text()" <(print $info))"
	cmdline+=("-map" "0:#$streamId")
        cmdline+=("-metadata:s:1" "language=eng")

	## subtitle streams
	local streamId="$(xmllint --xpath "/lsdvd/track[$track]/subp[langcode = 'en']/streamid/text()" <(print $info))"
	cmdline+=("-map" "0:#$streamId")
        cmdline+=("-metadata:s:2" "language=eng")

	exit 0
	local tmpout="$(mktemp -p .)"
	mplayer dvd://$track//dev/sr1 -dumpstream -dumpfile $tmpout
	ffmpeg -analyzeduration $((5*60*1000000)) -probesize 100M -fflags +genpts -i $tmpout -c:a copy -c:s copy -c:v copy -map 0:v:0 ${cmdline} "$OUTPATH/S${(l:2::0:)SEASON}E${(l:2::0:)EPISODE}.mkv"
	((EPISODE++))
	rm $tmpout
	sleep 20
}

