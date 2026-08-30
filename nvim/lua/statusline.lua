local function theme_fg(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
end

local function apply_segment_hls()
	local pms = vim.api.nvim_get_hl(0, { name = "PmenuSel", link = false })
	local dir = vim.api.nvim_get_hl(0, { name = "Directory", link = false })
	local fg = vim.api.nvim_get_hl(0, { name = "Cursor", link = false }).fg
	local bar_fg = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false }).fg
	vim.api.nvim_set_hl(0, "StlNormal", { fg = fg, bg = pms.fg })
	vim.api.nvim_set_hl(0, "StlInsert", { fg = fg, bg = theme_fg("String") })
	vim.api.nvim_set_hl(0, "StlVisual", { fg = fg, bg = theme_fg("Statement") })
	vim.api.nvim_set_hl(0, "StlCommand", { fg = fg, bg = theme_fg("WarningMsg") })
	vim.api.nvim_set_hl(0, "StlReplace", { fg = fg, bg = theme_fg("ErrorMsg") })
	vim.api.nvim_set_hl(0, "StlTerminal", { fg = fg, bg = dir.fg })
	vim.api.nvim_set_hl(0, "StlGit", { fg = dir.fg, bg = pms.bg })
	vim.api.nvim_set_hl(0, "StlRight", { fg = bar_fg, bg = pms.bg })
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

function _G._statusline()
	local spec = modes[vim.fn.mode()]
	local mode = spec and spec[1] or vim.fn.mode():upper()
	local hl = spec and spec[2] or "StlNormal"
	local head = vim.fn.FugitiveHead()
	local git = head ~= "" and ("%#StlGit# " .. head .. " %*") or ""
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

	return "%#" .. hl .. "# " .. mode .. " %*" .. git .. " " .. path .. "%m%=" .. diag .. "%#StlRight# %{&filetype} %l:%c "
end

vim.api.nvim_create_autocmd("DiagnosticChanged", {
	callback = function()
		vim.cmd.redrawstatus()
	end,
})

vim.o.statusline = "%!v:lua._statusline()"
