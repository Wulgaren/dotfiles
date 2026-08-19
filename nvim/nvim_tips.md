# Neovim tips

## Motion & editing

| Key | Action |
|-----|--------|
| `gf` / `gF` | open **file path** under cursor (`gF`: line number suffix if `:line:` form exists) |
| `gx` | open URL under cursor |
| `gd` | go to definition (LSP when available) |
| `Ctrl+^` | alternate buffer |
| `Ctrl+o` / `Ctrl+i` | jump backward / forward (jump list) |
| `f{char}` / `F{char}` | find char forward / backward on line |
| `;` / `,` | repeat previous `f`/`t`/`F`/`T` |
| `^` / `$` | Start/end of line |
| `R` | Replace mode until `Esc` |
| `o` | insert on line below |
| `ggVG` | select all |
| `ge` / `gE` | backward to **end** of `[count]` previous word / WORD (`dge`, `3cge`, …) |
| `g&` | repeat last `:substitute` on whole buffer (`:help :&`) |
| `J` | Join **next** line into current |
| `C-o` | Add "enter" in Insert Mode|
| `C-u / C-d` | Move up/down by half a page |
| `{ / }` | Move by paragraphs |
| `/ or ?` | Search forwards/backwards |
| `<C-v> then <I/A>` | Visual **block** mode then insert |
| `gi` | Insert in the last place you edited |
| `:g/your_string/d` | delete strings with specific text (:g! - delete ones that don't include the string) |
| `:w !sudo tee %` | write file with sudo privileges |

## Change operators

| Key | Action |
|-----|--------|
| `c` | change (operator) |
| `ciw` | change inner word |
| `cib` / `ciB` | change inside `()` / `{}` |
| `g~` + motion | toggle case (`g~W` — whole WORD) |
| `_` | whole-line motion (with `d`/`c`/`y`, etc.) |

## Undo, redo & repeat

| Key | Action |
|-----|--------|
| `u` | undo |
| `Ctrl+r` | redo |
| `.` | repeat last change (`:help .`) |

## Indent & `=`

| Key | Action |
|-----|--------|
| `>ib` | indent inner `()` |
| `>at` | indent tag block (`<>`) |
| `gg=G` | re-indent buffer |

## Search

| Key | Action |
|-----|--------|
| `*` | search forward for word under cursor |
| `g*` | search forward for word under cursor (includes when word is part of other word) |
| `gn` / `gN` | operate on **next/previous occurrence** (`dgn`, `.`; see `g*` section) |
| — | after search: `ciw`, then `n` and `.` to repeat on next matches |

## Marks

| Key | Action |
|-----|--------|
| `m` + letter | lowercase: buffer mark; uppercase: global mark |
| `'` + letter | jump to mark |
| `<C-h>` | list of marks |

## Save & quit

| Key | Action |
|-----|--------|
| `ZZ` | write (prompt path if unnamed) and quit |
| `ZQ` | quit window without writing |
| `ZX` | quit Neovim without writing everywhere (`:qa!`) |

---

## Window splits

| Key | Action |
|-----|--------|
| `<C-w><C-w>` | cycle windows |
| `<C-w>q` | close window |
| `:bd` | close buffer |
| `<C-w>h` / `j` / `k` / `l` | focus left / down / up / right |
| `<C-w>s` | split current buffer horizontal (top/bottom) |
| `<C-w>v` | split current buffer vertical (left/right) |
| `<C-w>n` | **new empty buffer**, horizontal split |
| `<C-w>_` | maximizing vertically |

Non-focused windows use dimmer **NormalNC** so active split stands out.

---

## Other custom keymaps

| Key | Action |
|-----|--------|
| `<C-s>` | write (Normal & Insert) |
| `<Esc>` (Normal) | clear search highlight |
| `Q` | disabled |
| `<Leader>sr` | `:substitute` whole buffer / selection |
| `<Leader>pv` / `<Leader>e` | netrw `Lexplore` — see **File explorer** below |
| `<C-u>` / `<C-d>` / `<C-f>` / `<C-b>` | scroll, cursor centered |
| `n` / `N` | next/prev match, cursor centered |
| Visual `J` / `K` | move selection down/up |
| `=ap` | reindent paragraph; mark `a` restores cursor |
| `<leader>t` | terminal in Vim — quit with `Esc` then `q` |
| Visual `@l` | add console.log |

---

## Commands, navigation, Git, more

### Commands

| Command | Action |
|---------|--------|
| `:MyTips` | open this file below |
| `:wq` | like `ZZ` (write or prompt, then quit) |

### File explorer (Netrw / `:Lexplore`)

Open with `<Leader>pv` or `<Leader>e`.

| Key | Action |
|-----|--------|
| `%` | create **file** (opens in previous window) |
| `d` | create **folder** (`mkdir`) |
| `Enter` / `o` | open file or directory |
| `D` | delete file or directory |
| `R` | rename |
| `-` | go up one directory |
| `lcd %` | set current path in Vim |

### find / grep / pickers

| Key | Action |
|-----|--------|
| `<C-p>` | go to file |
| `<C-t>` / `<Leader>fg` | find text in directory |
| `<C-j>` / `<Leader>b` | list of buffers |
| `<Leader>fs` | LSP document symbols |

### LSP (server attached)

| Key | Action |
|-----|--------|
| `gd` | definition |
| `K` | hover docs |
| `gr` | references |
| `<Leader>rn` | rename |
| `<Leader>ca` | code actions |
| `<Leader>f` | format buffer / selection |
| `<Leader>d` | buffer diagnostics |

### Git — vim-fugitive

**From any repo buffer**

| Key | Action |
|-----|--------|
| `<Leader>gs` | `:Git` status |
| `<Leader>gd` | vertical git diff split |
| `<Leader>gb` | `Git blame` (file) |
| `<Leader>gB` | blame current line |
| `<Leader>gl` | log current file |
| `<Leader>gL` | log / history for current line |
| `<Leader>gc` | git branch switching, unknown name creates |

**In `:Git` status — staging**

| Key | Action |
|-----|--------|
| `s` | stage |
| `u` | unstage |
| `-` | toggle stage/unstage |
| `U` | unstage all |
| `X` | discard change under cursor |
| `=` | toggle inline diff |
| `dv` / `ds` | vertical / horizontal diff vs index |
| `cc` | commit (edit message buffer; `wq` to finish) |

| Key | Action |
|-----|--------|
| **`P`** (Unpushed commit line) | pre-fills `:Git push` |
| `:Git push` / `:Git pull` | anytime |
| `gp` / `gP` | jump Unpushed / Unpulled (`:h fugitive_gp`) |

### Git merge (`nvimdiff`)

Four buffers: **LOCAL**, **BASE**, **REMOTE**, **MERGED**. Work in **MERGED**.

| Command | Meaning |
|---------|---------|
| `:diffg LO` | take hunk from LOCAL |
| `:diffg RE` | take from REMOTE |
| `:diffput MERGED` | from LOCAL/REMOTE/BASE → push into MERGED |

`[c / ]c` - to jump between changes.
`search for <<<<<<<` - to jump between merge conflicts.
Save **MERGED**, exit with `:qa`; abort with `:cq`.

### NeoCodeium (Windsurf ghost text)

| Key | Action |
|-----|--------|
| `<Leader>ko` | toggle (`:NeoCodeium! toggle` stops server) |
| `<M-Tab>` (Alt+Tab) | accept **full** suggestion |
| `<M-w>` / `<Tab>` | accept word |
| `<M-l>` | accept line |
