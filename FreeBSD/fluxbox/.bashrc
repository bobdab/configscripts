# Set VIM as default
alias vi='vim'
alias lsl='ls -lotrG|tail -n 20'
alias ls='ls -G'

# a simple command prompt:
PS1=" \u\$ "

# linux:
#LS_COLORS='di=1;31;42:fi=5:ln=31:pi=5:so=5:bd=5:cd=5:or=31:mi=0:ex=35:*.rpm=90'
#
LSCOLORS='haafxbxEabxDgxGxxxxexdxg'


export LSCOLORS
export COLOR_FORCE='1'

# Enable color for git diffs
MORE="-erX" ; export MORE

tst=$(xset q|tr -s ' '|grep bell|cut -d ' ' -f 4)
if [ "$tst" != "20" ]; then
	echo "Fixing the bell now."
  sleep .5; xset b 20 7000
  xset -dpms
  xset s off
  xset s noblank

  # display options
  xset q
else
	echo "The bell was already fixed."
fi
