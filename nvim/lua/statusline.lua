local function theme_fg(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
end

local SEP_R, SEP_L = "", ""

local function apply_segment_hls()
	local pms = vim.api.nvim_get_hl(0, { name = "PmenuSel", link = false })
	local dir = vim.api.nvim_get_hl(0, { name = "Directory", link = false })
	local fg = vim.api.nvim_get_hl(0, { name = "Cursor", link = false }).fg
	local bar_fg = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false }).fg
	local function chip(name, bg)
		vim.api.nvim_set_hl(0, name, { fg = fg, bg = bg })
		vim.api.nvim_set_hl(0, name .. "Sep", { fg = bg })
		vim.api.nvim_set_hl(0, name .. "SepGit", { fg = bg, bg = pms.bg })
	end
	chip("StlNormal", theme_fg("Normal"))
	chip("StlInsert", theme_fg("String"))
	chip("StlVisual", theme_fg("Boolean"))
	chip("StlCommand", theme_fg("WarningMsg"))
	chip("StlReplace", theme_fg("ErrorMsg"))
	chip("StlTerminal", dir.fg)
	vim.api.nvim_set_hl(0, "StlGit", { fg = dir.fg, bg = pms.bg })
	vim.api.nvim_set_hl(0, "StlGitSep", { fg = pms.bg })
	vim.api.nvim_set_hl(0, "StlRight", { fg = bar_fg, bg = pms.bg })
	vim.api.nvim_set_hl(0, "StlRightSep", { fg = pms.bg })
end

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("config-statusline-hls", { clear = true }),
	callback = apply_segment_hls,
})
apply_segment_hls()

local modes = {
	n = { "NORMAL", "StlNormal" },
	i = { "INSERT", "StlInsert" },
	v = { "VISUAL", "StlVisual" },
	V = { "V-LINE", "StlVisual" },
	["\22"] = { "V-BLOCK", "StlVisual" },
	c = { "COMMAND", "StlCommand" },
	t = { "TERMINAL", "StlTerminal" },
	R = { "REPLACE", "StlReplace" },
	s = { "SELECT", "StlVisual" },
	S = { "S-LINE", "StlVisual" },
	["\19"] = { "S-BLOCK", "StlVisual" },
}

local diag_label = { " ", " ", " ", " " }
local diag_hl = { "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint" }

local BRANCH_MAX = 32
local BRANCH_KEEP = 12

local function trim_branch(name)
	name = vim.trim(name)
	if #name <= BRANCH_MAX then
		return name
	end
	return name:sub(1, BRANCH_KEEP) .. "…" .. name:sub(-BRANCH_KEEP)
end

function _G._statusline()
	local rec = vim.fn.reg_recording()
	local spec = modes[vim.fn.mode()]
	local mode = spec and spec[1] or vim.fn.mode():upper()
	local hl = spec and spec[2] or "StlNormal"
	if rec ~= "" then
		mode = "REC @" .. rec
		hl = "StlCommand"
	end
	local head = trim_branch(vim.fn.FugitiveHead())
	local has_git = head ~= ""
	local git = has_git and ("%#StlGit# " .. head .. " %#StlGitSep#" .. SEP_R) or ""
	local root = vim.fn.FugitiveWorkTree()
	local name = vim.api.nvim_buf_get_name(0)
	local path = (root ~= "" and name ~= "" and vim.fs.relpath(root, name))
		or (name ~= "" and vim.fn.expand("%:p:~") or "%f")

	local diag = ""
	local counts = vim.diagnostic.count(0) or {}
	for i = 1, 4 do
		if counts[i] and counts[i] > 0 then
			diag = diag .. "%#" .. diag_hl[i] .. "#" .. diag_label[i] .. counts[i] .. "%* "
		end
	end

	local mode_sep = has_git and "SepGit#" or "Sep#"
	return "%#" .. hl .. "# " .. mode .. " %#" .. hl .. mode_sep .. SEP_R .. git
		.. "%#StatusLine# "
		.. path
		.. "%m%= "
		.. diag
		.. "%#StlRightSep#"
		.. SEP_L
		.. "%#StlRight# %S %{&filetype} %l:%c "
end

vim.o.showcmdloc = "statusline"

vim.api.nvim_create_autocmd("DiagnosticChanged", {
	callback = function()
		vim.cmd.redrawstatus()
	end,
})

vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
	callback = function()
		vim.cmd.redrawstatus()
	end,
})

vim.o.statusline = "%!v:lua._statusline()"
