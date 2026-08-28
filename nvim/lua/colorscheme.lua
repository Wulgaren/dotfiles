local frappe = {
	surface0 = "#414559",
	surface1 = "#51576d",
	text = "#c6d0f5",
	subtext1 = "#b5bfe2",
	overlay0 = "#737994",
	lavender = "#babbf1",
}

local function apply_readability_overrides()
	local fg = "#e8ecff"
	local fg_nc = "#a7b0cc"
	local line_nr = "#cfd5f2"
	local comment_fg = "#737994"
	local border = "#6c7086"
	local cursorline_bg = "#3b3f52"

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

local function apply_frappe_menu_overrides()
	local c = frappe
	local menu_groups = {
		Pmenu = { fg = c.text, bg = c.surface0 },
		PmenuSel = { fg = c.lavender, bg = c.surface1, bold = true },
		PmenuSbar = { bg = c.surface1 },
		PmenuThumb = { bg = c.overlay0 },
		PmenuMatch = { fg = c.text, bold = true },
		PmenuExtra = { fg = c.subtext1, bg = c.surface0 },
		PmenuExtraSel = { fg = c.subtext1, bg = c.surface1, bold = true },
	}
	for group, spec in pairs(menu_groups) do
		vim.api.nvim_set_hl(0, group, spec)
	end
end

local function set_catppuccin_dark()
	vim.o.background = "dark"
	vim.cmd.colorscheme("catppuccin")
	apply_readability_overrides()
	apply_frappe_menu_overrides()
end

vim.api.nvim_create_user_command("CatppuccinDark", set_catppuccin_dark, {})

set_catppuccin_dark()
