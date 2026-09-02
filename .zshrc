# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# path (shared)
export PATH="$HOME/.local/bin:$PATH"

# OS-specific: theme and extra PATH
if [[ "$OSTYPE" == darwin* ]]; then
  source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
  export PATH=/Applications/MEGAcmd.app/Contents/MacOS:$PATH
  export PATH="$HOME/.dotnet/tools:$PATH"
elif [[ "$OSTYPE" == linux-gnu* ]]; then
  if [[ -r /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]]; then
    source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
  else
    source "${XDG_DATA_HOME:-$HOME/.local/share}/powerlevel10k/powerlevel10k.zsh-theme"
  fi
elif [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then
    # Windows (MSYS2 / Git Bash / WSL-zsh)
  source ~/powerlevel10k/powerlevel10k.zsh-theme
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source <(fzf --zsh)
fi

export EDITOR=vim
export VISUAL=vim

# Line editing: emacs keys (C-a/C-e, M-f/M-b, C-k, …). Vi-style: bindkey -v
bindkey -e

WORDCHARS=''

# Completion: run once, before plugins
autoload -Uz compinit 

if [[ -n ~/.zcompdump(#qNmh-24) ]]; then
  compinit -C
else
  compinit
fi

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Plugins (after compinit). syntax-highlighting must be last.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
if [[ "$OSTYPE" == darwin* ]]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source <(fzf --zsh)
elif [[ "$OSTYPE" == linux-gnu* ]]; then
  if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  else
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  fi
  source <(fzf --zsh)
fi

(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none

if [[ "$OSTYPE" == darwin* ]]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ "$OSTYPE" == linux-gnu* ]]; then
  if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  else
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  fi
fi

#history stuff and not having to type in cd
export HISTSIZE=1000000000
export SAVEHIST=$HISTSIZE
HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY
setopt autocd

setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Private per-machine config (IPs, SSH hosts, work paths). See .zshrc.local.example.
[[ -r "${${(%):-%x}:A:h}/.zshrc.local" ]] && source "${${(%):-%x}:A:h}/.zshrc.local"

# aliases
alias daudio='bash ~/Coding/scripts/download/download\ audio.sh'
alias dvideo='bash ~/Coding/scripts/download/download\ vid.sh'
alias dphoto='bash ~/Coding/scripts/download/download\ photos.sh'
alias dthumbnail='bash ~/Coding/scripts/download/download\ thumbnail.sh'
alias bluetooth_silence='bash ~/Coding/scripts/misc/bluetoothsilence.sh'
alias pick='~/Coding/scripts/pick.sh'

alias ai='~/Coding/scripts/ai/instant-ai.sh -g'

alias discordo="$HOME/Coding/discordo-repo/discordo/discordo"
alias music="~/Coding/Apple-Music-CLI-Player/src/am.sh np -t"
alias am="~/Coding/Apple-Music-CLI-Player/src/am.sh"
alias mega-cmd="/Applications/MEGAcmd.app/Contents/MacOS/MEGAcmdShell"
alias mega-upload='_mega_upload_func'

alias iina="/Applications/IINA.app/Contents/MacOS/iina-cli --mpv-af='lavfi=[dynaudnorm=f=250:g=15:p=0.95:r=0.25:m=12]'"

alias clear="clear && printf '\e[3J'"

# Terminal tab/window title = running command (OSC 0; Neovim uses this for :b names)
autoload -Uz add-zsh-hook
add-zsh-hook preexec '_term_title_preexec'
_term_title_preexec() { print -nr -- $'\e]0;'"$1"$'\a' }

alias dt='cd ~/Coding/.dotfiles'
alias coding='cd ~/Coding'

alias music-backup='~/Coding/scripts/mega/mega-sync-missing.sh'

alias insta-dl="node ~/Coding/insta-downloader/src/fastdl.ts"

alias newrepo='bash ~/Coding/scripts/git/newrepo.sh'

alias grep='rg -i'

alias grouplinks='python3 ~/Coding/scripts/misc/group_links.py ~/Desktop/Archive && trash ~/Desktop/Archive'

alias tree="ls -R"

alias nano='nvim'
alias vi='nvim'
alias vim='nvim'

_mega_upload_func() {
  source ~/Coding/scripts/mega/mega-upload.zsh
  megaupload "$@"
}

permute() {
  "$HOME/Coding/permute/.venv/bin/python" "$HOME/Coding/permute/permute.py" "$@"
}
alias musiclibrary='python3 ~/Coding/Music\ Library\ Script/python/main.py'

gallery-dl() { "/Users/natios/Coding/gallerydl/.venv/bin/python" -m gallery_dl "$@"; }

twitter-curator() {
  ~/Coding/PhotoScanner/venv/bin/python3 ~/Coding/PhotoScanner/src/twitter_curator.py --no-listen --hours "${1:-28}"
}

alias photoscanner='~/Coding/PhotoScanner/photoscanner.sh'
alias music-catchifier='~/Coding/music-catchifier/music-catchifier.sh'

alias recent-wallpapers='~/Coding/PhotoScanner/venv/bin/python3 ~/Coding/PhotoScanner/src/find_wallpaper.py'

# fzf → vim: current directory
fzv() {
  local file
  file=$(find . -type f \
    ! -path "*/.git/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -path "*/.cache/*" \
    ! -path "*/obj/*" \
    ! -path "*/bin/*" \
    | fzf) && vim "$file"
}

# fzf → vim: ~/Coding
fzve() {
  local file
  file=$(find "$HOME/Coding" -type f \
    ! -path "*/.git/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -path "*/.cache/*" \
    ! -path "*/obj/*" \
    ! -path "*/bin/*" \
    | fzf) && vim "$file"
}

# git status inside nvim
alias gs='nvim -c "Gedit :"'
alias botany='python3 ~/Coding/botany/botany.py'

mega-drive() {
        RCLONE_MEGA_2FA="$1" rclone mount mega: ~/MEGA --vfs-cache-mode full --daemon
}

alias mega-drive-unmount='umount ~/MEGA'


# instant-ai (apfel)
alias oneliner='~/Coding/scripts/ai/instant-ai.sh oneliner'
alias summarize='~/Coding/scripts/ai/instant-ai.sh summarize'
alias internet_listeners='~/Coding/scripts/ai/instant-ai.sh listeners'
alias most_cpu_usage='~/Coding/scripts/ai/instant-ai.sh cpu'

alias concord='~/Coding/concord/target/release/concord'
