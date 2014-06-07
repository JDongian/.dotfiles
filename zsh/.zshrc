# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=8000
SAVEHIST=8000
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install
setopt HIST_IGNORE_DUPS
# The following lines were added by compinstall
zstyle :compinstall filename '/home/joshua/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

autoload -U promptinit
promptinit
prompt walters

export EDITOR=vim
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus

alias l="ls -ltsahF --color=auto"
alias ll="ls -lhF --color=auto"
alias ls="ls -hF --color=auto"

alias vol='amixer set Master'

alias qwerty='setxkbmap us; xmodmap ~/.Xmodmap;'
alias dvorak='setxkbmap dvorak; xmodmap ~/.Xmodmap;'

alias prvw='head -n 8'
alias :q='exit'

alias grep='grep --color=auto'
alias copy='xclip -sel clip <'

alias cd..='cd ..'
alias cd../..='cd ../..'

alias cgit='cd ~/Documents/git/'

alias p='python'
alias p2='python2'
alias i='ipython'
alias i2='ipython2'

alias gcc='gcc -Wall'
alias g++='g++ -Wall -ansi'

alias rjar='java -jar'
alias mkjar='jar cmf manifest.mf'

alias fire='firefox'

alias screenshot='import -window root'
