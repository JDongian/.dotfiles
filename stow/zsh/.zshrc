HISTFILE=~/.histfile
HISTSIZE=8000
SAVEHIST=8000
setopt HIST_IGNORE_DUPS


autoload -Uz compinit
compinit

autoload -U promptinit
promptinit
prompt walters

export EDITOR=vim
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus



unsetopt beep
bindkey -e


if [ "$TERM" = "linux" ]; then
    echo -en "\e]P7B0ADB0" #lightgrey
    # echo -en "\e]PEA4B9B9" #cyan
    echo -en "\e]P6009090" #darkcyan
    # echo -en "\e]P81B1B1B" #darkgrey
fi
eval $(dircolors ~/.dircolors)


## autocompletion
# Do menu-driven completion.
zstyle ':completion:*' menu select

# Color completion for some things.
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


man() {
    env LESS_TERMCAP_mb=$'\E[01;31m' \
    LESS_TERMCAP_md=$'\E[01;38;5;74m' \
    LESS_TERMCAP_me=$'\E[0m' \
    LESS_TERMCAP_se=$'\E[0m' \
    LESS_TERMCAP_so=$'\E[38;5;246m' \
    LESS_TERMCAP_ue=$'\E[0m' \
    LESS_TERMCAP_us=$'\E[04;38;5;146m' \
    man "$@"
}


alias l="ls -F --color=auto"
alias ls="ls -F --color=auto"
alias ll="ls -shaF --color=auto"
alias lll="ls -lthF --color=auto"

alias vol='amixer set Master'

alias qwerty='setxkbmap us; xmodmap ~/.Xmodmap;'
alias dvorak='setxkbmap dvorak; xmodmap ~/.Xmodmap;'
alias rus='setxkbmap ru; xmodmap ~/.Xmodmap;'

alias :q='exit'

alias grep='grep --color=auto'
alias copy='xclip -sel clip <'

alias cd..='cd ..'
alias cd../..='cd ../..'
alias cdwine='cd ~/.wine/drive_c'

alias p='python'
alias p2='python2'
alias i='ipython'
alias i2='ipython2'

alias gcc='gcc -Wall -Wfatal-errors'
alias g++='g++ -Wall -ansi'

alias rjar='java -jar'
alias mkjar='jar cmf manifest.mf'

alias screenshot='sleep 10; import -window'
alias screenshot2='sleep 1; import -window'

alias sync='sudo ntpd -qg'

alias rest='xset dpms force standby; xset dpms force standby'

alias ocaml='rlwrap ocaml'

alias octave='octave-cli'

