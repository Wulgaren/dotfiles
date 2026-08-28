# Windows SSH: wmux session picker (sourced from ~/.zshrc before p10k instant prompt).
_wmux_menu() {
  emulate -L zsh

  local sessions choice action row name project program required_path line key output
  local -a items command_to_run fzf_cmd
  local -A existing_sessions
  local -i still_running next_id
  local -x FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--no-sort --info=hidden --color=fg:#d4d4d4,bg:#1e1e1e,hl:#ffd75f,fg+:#ffffff,bg+:#005faf,hl+:#ffffaf,pointer:#5fd7ff,prompt:#5fd7ff,border:#5f87af"

  if ! command -v wmux >/dev/null 2>&1 || ! command -v fzf >/dev/null 2>&1; then
    print -u2 'wmux or fzf is unavailable; opening a normal shell.'
    return 0
  fi

  fzf_cmd=(fzf --delimiter=$'\t' --with-nth=2.. --layout=reverse --border --height=40%
    --prompt='wmux> ' --header='Enter attach/new · Ctrl-D kill · Esc normal shell')
  if [[ -x "$HOME/scoop/shims/fzf.exe" ]]; then
    fzf_cmd[1]="$HOME/scoop/shims/fzf.exe"
  fi

  _wmux_program_command() {
    local pick=$1
    required_path=''
    command_to_run=()
    case "$pick" in
      terminal)
        required_path='/c/Program Files/Git/bin/bash.exe'
        command_to_run=("$required_path" -l)
        ;;
      codex)
        required_path="$HOME/scoop/apps/nodejs-lts/current/bin/codex.cmd"
        command_to_run=(cmd.exe /d /c "$required_path")
        ;;
      agent)
        required_path="$HOME/AppData/Local/cursor-agent/agent.cmd"
        command_to_run=(cmd.exe /d /c "$required_path")
        ;;
      nvim)
        required_path="$HOME/scoop/shims/nvim.exe"
        command_to_run=("$required_path")
        ;;
      *)
        print -u2 "wmux: unknown program: $pick"
        return 1
        ;;
    esac
    if [[ -n "$required_path" && ! -f "$required_path" ]]; then
      print -u2 "wmux: program does not exist: $required_path"
      return 1
    fi
  }

  _wmux_next_session_name() {
    next_id=1
    while (( ${+existing_sessions[$next_id]} )); do
      (( next_id++ ))
    done
    name=$next_id
  }

  _wmux_start_session() {
    project="${WMUX_NEW_PROJECT:-$HOME}"
    program="${WMUX_NEW_PROGRAM:-terminal}"
    if [[ ! -d "$project" ]]; then
      print -u2 "wmux: directory does not exist: $project"
      return 1
    fi
    _wmux_program_command "$program" || return 1

    _wmux_next_session_name

    print "Starting session $name in $project"
    (builtin cd -- "$project" && wmux new -s "$name" "${command_to_run[@]}")
  }

  while true; do
    sessions=$(wmux ls) || {
      print -u2 'wmux could not list sessions; opening a normal shell.'
      return 1
    }

    items=($'new\tNew session (Terminal @ ~)')
    existing_sessions=()
    if [[ "$sessions" != 'no sessions' ]]; then
      while IFS= read -r line; do
        name="${line%%$'\t'*}"
        existing_sessions[$name]=1
        items+=("attach"$'\t'"$line")
      done <<< "$sessions"
    fi
    items+=($'shell\tNormal shell' $'logout\tDisconnect')

    output=$(printf '%s\n' "${items[@]}" | "${fzf_cmd[@]}" --expect=ctrl-d) || return 0
    output="${output//$'\r'/}"
    key=''
    choice=''

    if [[ -z "$output" ]]; then
      continue
    fi

    if [[ "${output%%$'\n'*}" == ctrl-d ]]; then
      key=ctrl-d
      choice="${output#*$'\n'}"
      [[ -n "$choice" ]] || continue
    else
      # --expect adds a blank first line when Enter is used without an expect key.
      choice="${output##*$'\n'}"
      [[ -n "$choice" ]] || choice="$output"
    fi

    action="${choice%%$'\t'*}"

    if [[ "$key" == ctrl-d ]]; then
      if [[ "$action" != attach ]]; then
        print -u2 'wmux: select a running session to kill'
        continue
      fi
      row="${choice#*$'\t'}"
      name="${row%%$'\t'*}"
      if read -q "REPLY?Kill $name and its program? [y/N] "; then
        print
        if wmux kill "$name"; then
          repeat 20; do
            still_running=0
            while IFS= read -r line; do
              [[ "${line%%$'\t'*}" == "$name" ]] && still_running=1
            done <<< "$(wmux ls)"
            (( still_running )) || break
            sleep 0.1
          done
        fi
      else
        print
      fi
      continue
    fi

    case "$action" in
      new)
        _wmux_start_session
        return 0
        ;;
      attach)
        row="${choice#*$'\t'}"
        name="${row%%$'\t'*}"
        wmux attach "$name" 2>/dev/null || print -u2 "wmux: could not attach to $name"
        return 0
        ;;
      shell)
        return 0
        ;;
      logout)
        exit 0
        ;;
      *)
        print -u2 "wmux: unknown choice: ${(q)action}"
        return 0
        ;;
    esac
  done
}

_wmux_menu
unfunction _wmux_menu

alias agent=agent.cmd
alias varioweb='cd VarioWeb/VarioWeb.App'
alias repo='cd D:/source/repos'
