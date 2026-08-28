~/ :
.aerospace.toml
.gitconfig
.gitconfig.local → `dotfiles/.gitconfig.local` (per-machine; gitignored — copy from `.gitconfig.local.example`)
.zshrc
.p10k.zsh

~/.config
all the folders + starship.toml + mimeapps.list

~/.config/git
`~/.config/git` → `dotfiles/git` (global gitignore lives at `git/ignore`)

swaylock:
`~/.config/swaylock` → `dotfiles/swaylock` (lock screen; `config` read by swayidle)

discordo:
"~/Library/Application Support/discordo/config.toml"

qutebrowser/catppuccin:
git clone https://github.com/catppuccin/qutebrowser.git qutebrowser/catppuccin

~/.cursor (rules, skills, cli-config):
`~/.cursor/rules` → `dotfiles/.cursor/rules`
`~/.cursor/skills` → `dotfiles/.cursor/skills`
`~/.cursor/cli-config.json` → `dotfiles/.cursor/cli-config.json`

Codex (skills + global agent md):
`~/.agents/skills` → `dotfiles/.cursor/skills` (same tree as `~/.cursor/skills`)
`~/.agents/AGENT.md` → `dotfiles/AGENT.md`
`~/.codex/AGENTS.md` → `dotfiles/AGENT.md` (Codex reads this name under `~/.codex`)

## Windows (AppData / MSYS2)

Use PowerShell `New-Item -ItemType SymbolicLink` (no elevation needed with Developer Mode on).

`~/.zshrc` → `dotfiles/.zshrc`
`~/.zsh/wmux-ssh.zsh` → `dotfiles/zsh/windows/wmux-ssh.zsh`
`~/.gitconfig` → `dotfiles/.gitconfig`
`$env:LOCALAPPDATA\nvim` → `dotfiles/nvim`
`~/.cursor/rules` → `dotfiles/.cursor/rules`
`~/.cursor/skills` → `dotfiles/.cursor/skills`
`~/.cursor/cli-config.json` → `dotfiles/.cursor/cli-config.json`
`~/.agents/skills` → `dotfiles/.cursor/skills`
`~/.agents/AGENT.md` → `dotfiles/AGENT.md`
`~/.codex/AGENTS.md` → `dotfiles/AGENT.md`
