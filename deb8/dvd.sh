#!/bin/sh
echo "This is an example of how to play a DVD that did not work with the"
echo "default video player in Debian 8."
echo "The argument to this script is the 'title number.'"
echo "You might not know which title is which, but when you read the"
echo "text output on the screen as mplayer starts, you might see"
echo "a message indicating how many 'titles' there are on the disk."
echo "In one case, there were previews and other things, and there were"
echo "21 titles on the DVD.  To see the real movie, I had to play "
echo "title 5 and beyond."
echo "The options for --chapter might not work for you if you are playing"
echo "the wrong title."

DVDTitle="$1"
if [ -z "${DVDTitle}" ]; then
    DVDTitle="1"
fi
echo "I am playing title ${DVDTitle}"
#mplayer dvd://${DVDTitle} --chapter=0-40
mplayer dvd://${DVDTitle}  --chapter=0-40

