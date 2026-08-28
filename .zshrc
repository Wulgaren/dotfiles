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

# aliases
alias daudio="bash ~/Coding/Scripts/download thumbnail.sh"
alias daudio="bash ~/Coding/Scripts/download\ thumbnail.sh"
alias dvideo="bash ~/Coding/Scripts/download\ video.sh"
alias daudio="bash ~/Coding/Scripts/download\ audio.sh"
alias dthumbnail="bash ~/Coding/Scripts/download\ thumbnail.sh"
alias bluetooth_silence="bash ~/Coding/Scripts/bluetoothsilence.sh"
alias dvideo="bash ~/Coding/Scripts/download\ video.sh"
alias dvideo="bash ~/Coding/Scripts/download\ vid.sh"
alias dphoto="bash ~/Coding/Scripts/download\ photos.sh"

alias ai="bash ~/Coding/instant-ai-cli/ask-groq.sh"
alias ais="bash ~/Coding/instant-ai-cli/ask-cursor.sh"

alias discordo="$HOME/Coding/discordo-repo/discordo/discordo"
alias music="~/Coding/Apple-Music-CLI-Player/src/am.sh np -t"
alias am="~/Coding/Apple-Music-CLI-Player/src/am.sh"
alias mega-cmd="/Applications/MEGAcmd.app/Contents/MacOS/MEGAcmdShell"
alias mega-upload='_mega_upload_func'

alias iina="/Applications/IINA.app/Contents/MacOS/iina-cli --mpv-af='lavfi=[dynaudnorm=f=250:g=15:p=0.95:r=0.25:m=12]'"

# zsh only: *~*.(#i)db = not *.db, (om[1,20]) = newest 20. No /usr/bin or grep=rg; `!` avoided (history)
alias recent-wallpapers='( setopt null_glob extended_glob; cd ~/Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches/com.apple.wallpaper.caches/extension-com.apple.wallpaper.extension.image/ || exit; f=(*~*.(#i)db(om[1,20]N)); (( $#f )) && open -- $f; )'

alias bun='npm'

alias clear="clear && printf '\e[3J'"

_nvim_sync_cwd() {
        [[ -n "$NVIM" ]] || return 0
        local dir
        dir=$(pwd)
        nvim --server "$NVIM" --remote-expr "nvim_set_current_dir('${dir//\'/\\\'}')" >/dev/null 2>&1
}
dt() {
        cd "${DOTFILES_DIR:-$HOME/Coding/.dotfiles}" || return
        _nvim_sync_cwd
}
coding() {
        cd ~/Coding || return
        _nvim_sync_cwd
}

alias music-backup='~/Coding/scripts/mega-sync-missing.sh'

alias insta-dl="node ~/Coding/insta-downloader/src/fastdl.ts"

#alias agent='safehouse --add-dirs-ro=~/Coding agent'

alias newrepo="bash ~/Coding/Scripts/newrepo.sh"

alias grep='rg -i'

alias grouplinks='python3 ~/Coding/Scripts/group_links.py ~/Desktop/Archive && trash ~/Desktop/Archive'

alias tree="ls -R"

alias nano='nvim'
alias vi='nvim'
alias vim='nvim'

_mega_upload_func() {
  source ~/Coding/Scripts/mega-upload.zsh
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


# apfel scripts
alias oneliner='~/Coding/instant-ai-cli/oneliner.sh'
alias summarize='pbpaste | apfel "summarize in 3 bullets"'
alias internet_listeners='lsof -iTCP -sTCP:LISTEN -n -P | head -15 | apfel "list which apps own which ports as a table"'
alias most_cpu_usage='ps aux | sort -k 3 -nr | head -5 | awk '{print $11, $3"%"}' | apfel "which app is using the most CPU"'

alias concord='~/Coding/concord/target/release/concord'
