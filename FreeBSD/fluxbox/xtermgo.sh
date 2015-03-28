#!/bin/sh

# this is for fluxbox
# the format of the geometry command
#  * width in characters
#  * height in characters
#  * x-axis position in pixels (use +100 to start 100 pixels
#    from the left or -10 to put the right edge ofthe box 
#    10 pixels from the right)
#  * y-axis position (0 is at the top, bigger values are farther
#    down).
xterm -geometry 90x20+1+450 &
xterm -geometry 90x30-1+1 &
xterm -geometry 90x30-20+20 &
xterm -geometry 90x30-40+40 &
xterm -geometry 70x4-1+500 &
xterm -geometry 60x4-1+580 &

## run vim in an xterm window:
#exec xterm -geometry 80x16+0+400 -e vim 

#exec xterm -geometry 80x16+0+0 -name login

