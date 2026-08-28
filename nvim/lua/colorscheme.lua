local frappe = {
	surface0 = "#414559",
	surface1 = "#51576d",
	text = "#c6d0f5",
	subtext1 = "#b5bfe2",
	overlay0 = "#737994",
	lavender = "#babbf1",
}

local function apply_overrides()
	local fg = "#e8ecff"
	local fg_nc = "#a7b0cc"
	local line_nr = "#cfd5f2"
	local groups = {
		Normal = { fg = fg, bg = "NONE" },
		NormalNC = { fg = fg_nc, bg = "NONE" },
		NormalFloat = { fg = fg, bg = "NONE" },
		SignColumn = { bg = "NONE" },
		EndOfBuffer = { fg = line_nr, bg = "NONE" },
		LineNr = { fg = line_nr, bg = "NONE" },
		CursorLine = { bg = "#3b3f52", bold = true },
		FloatBorder = { fg = "#6c7086", bg = "NONE" },
		WinSeparator = { fg = "#6c7086", bg = "NONE" },
		Comment = { fg = "#737994", italic = true },
		NonText = { fg = line_nr },
		Whitespace = { fg = line_nr },
		StatusLine = { fg = fg, bg = "NONE" },
		StatusLineNC = { fg = fg_nc, bg = "NONE" },
		Pmenu = { fg = frappe.text, bg = frappe.surface0 },
		PmenuSel = { fg = frappe.lavender, bg = frappe.surface1, bold = true },
		PmenuSbar = { bg = frappe.surface1 },
		PmenuThumb = { bg = frappe.overlay0 },
		PmenuMatch = { fg = frappe.text, bold = true },
		PmenuExtra = { fg = frappe.subtext1, bg = frappe.surface0 },
		PmenuExtraSel = { fg = frappe.subtext1, bg = frappe.surface1, bold = true },
	}
	for group, spec in pairs(groups) do
		vim.api.nvim_set_hl(0, group, spec)
	end

	local function theme_fg(name)
		return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
	end
	for sev, src in pairs({ Error = "Error", Warn = "WarningMsg", Info = "MoreMsg", Hint = "Character" }) do
		local color = theme_fg(src)
		local base = "Diagnostic" .. sev
		vim.api.nvim_set_hl(0, base, { fg = color })
		for _, suffix in ipairs({ "VirtualText", "Floating", "Sign" }) do
			vim.api.nvim_set_hl(0, base .. suffix, { fg = color })
		end
		vim.api.nvim_set_hl(0, "DiagnosticUnderline" .. sev, { undercurl = true, sp = color })
	end
end

local function set_catppuccin_dark()
	vim.o.background = "dark"
	vim.cmd.colorscheme("catppuccin")
	apply_overrides()
end

vim.api.nvim_create_user_command("CatppuccinDark", set_catppuccin_dark, {})
set_catppuccin_dark()
