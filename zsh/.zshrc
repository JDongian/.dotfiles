export EDITOR=vim
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus

HISTFILE=~/.histfile
HISTSIZE=8000
SAVEHIST=8000
unsetopt beep
bindkey -e
setopt HIST_IGNORE_DUPS

# menu-driven completion
zstyle ':completion:*' menu select

# partial color completion
# http://linuxshellaccount.blogspot.com/2008/12/color-completion-using-zsh-modules-on.html
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# formatting and messages
# http://www.masterzen.fr/2009/04/19/in-love-with-zsh-part-one/
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format "$fg[yellow]%B--- %d%b"
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format "$fg[red]No matches for:$reset_color %d"
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''

autoload -Uz compinit
compinit

autoload -U promptinit
promptinit
prompt walters

alias l="ls -ltsahF --color=auto"
alias ll="ls -lhF --color=auto"
alias ls="ls -hF --color=auto"

alias grep='grep --color=auto'

alias gcc='gcc -Wall'
alias g++='g++ -Wall -ansi'
alias rjar='java -jar'
alias mkjar='jar cmf manifest.mf'
alias p='python'
alias p2='python2'
alias i='ipython'
alias i2='ipython2'

alias vol='amixer set Master'

alias qwerty='setxkbmap us; xmodmap ~/.Xmodmap;'
alias dvorak='setxkbmap dvorak; xmodmap ~/.Xmodmap;'

alias prvw='head -n 8'
alias :q='exit'

alias copy='xclip -sel clip <'

alias cd..='cd ..'
alias cd../..='cd ../..'

alias cgit='cd ~/Documents/git/'

# Requires imagemagik
alias screenshot='import -window root'
