local function apply_readability_overrides(is_light)
	local fg = is_light and "#3f455e" or "#e8ecff"
	local fg_nc = is_light and "#7a8199" or "#a7b0cc"
	local line_nr = is_light and "#525a76" or "#cfd5f2"
	local comment_fg = is_light and line_nr or "#737994"
	local border = is_light and "#59627f" or "#6c7086"
	local cursorline_bg = is_light and "#e9ecf6" or "#3b3f52"

	local groups = {
		Normal = { fg = fg, bg = "NONE" },
		NormalNC = { fg = fg_nc, bg = "NONE" },
		NormalFloat = { fg = fg, bg = "NONE" },
		SignColumn = { bg = "NONE" },
		EndOfBuffer = { fg = line_nr, bg = "NONE" },
		LineNr = { fg = line_nr, bg = "NONE" },
		CursorLine = { bg = cursorline_bg, bold = true },
		FloatBorder = { fg = border, bg = "NONE" },
		WinSeparator = { fg = border, bg = "NONE" },
		Comment = { fg = comment_fg, italic = true },
		NonText = { fg = line_nr },
		Whitespace = { fg = line_nr },
		StatusLine = { fg = fg, bg = "NONE" },
		StatusLineNC = { fg = fg_nc, bg = "NONE" },
	}

	for group, spec in pairs(groups) do
		vim.api.nvim_set_hl(0, group, spec)
	end

	-- Builtin catppuccin has no Diagnostic* groups → default #FF0000. Steal theme hues.
	local function theme_fg(name)
		return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
	end
	local diag = {
		Error = theme_fg("Error"),
		Warn = theme_fg("WarningMsg"),
		Info = theme_fg("MoreMsg"),
		Hint = theme_fg("Character"),
	}
	for sev, fg in pairs(diag) do
		vim.api.nvim_set_hl(0, "Diagnostic" .. sev, { fg = fg })
		vim.api.nvim_set_hl(0, "DiagnosticVirtualText" .. sev, { fg = fg })
		vim.api.nvim_set_hl(0, "DiagnosticFloating" .. sev, { fg = fg })
		vim.api.nvim_set_hl(0, "DiagnosticSign" .. sev, { fg = fg })
		vim.api.nvim_set_hl(0, "DiagnosticUnderline" .. sev, { undercurl = true, sp = fg })
	end
end

local function set_catppuccin_light()
	vim.o.background = "light"
	vim.cmd.colorscheme("catppuccin")
	apply_readability_overrides(true)
end

local function set_catppuccin_dark()
	vim.o.background = "dark"
	vim.cmd.colorscheme("catppuccin")
	apply_readability_overrides(false)
end

vim.api.nvim_create_user_command("CatppuccinLight", set_catppuccin_light, {})
vim.api.nvim_create_user_command("CatppuccinDark", set_catppuccin_dark, {})

if vim.o.background == "light" then
	set_catppuccin_light()
else
	set_catppuccin_dark()
end
