local function apply_segment_hls()
	local pms = vim.api.nvim_get_hl(0, { name = "PmenuSel", link = false })
	local dir = vim.api.nvim_get_hl(0, { name = "Directory", link = false })
	local vis = vim.api.nvim_get_hl(0, { name = "Visual", link = false })
	vim.api.nvim_set_hl(0, "StlMode", { fg = pms.fg, bg = vis.bg })
	vim.api.nvim_set_hl(0, "StlGit", { fg = dir.fg, bg = pms.bg })
end

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("config-statusline-hls", { clear = true }),
	callback = apply_segment_hls,
})
apply_segment_hls()

local modes = {
	n = "NORMAL",
	i = "INSERT",
	v = "VISUAL",
	V = "V-LINE",
	["\22"] = "V-BLOCK",
	c = "COMMAND",
	t = "TERMINAL",
	R = "REPLACE",
	s = "SELECT",
	S = "S-LINE",
	["\19"] = "S-BLOCK",
}

function _G._statusline()
	local mode = modes[vim.fn.mode()] or vim.fn.mode():upper()
	local head = vim.fn.FugitiveHead()
	local branch = head ~= "" and "%#StlGit# " .. head .. " %*" or ""
	local root = vim.fn.FugitiveWorkTree()
	local bufname = vim.api.nvim_buf_get_name(0)
	local path = (root ~= "" and bufname ~= "" and vim.fs.relpath(root, bufname))
		or (bufname ~= "" and vim.fn.expand("%:p:~") or "%f")
	local modified = vim.bo.modified and " [+]" or ""

	local diag = ""
	local labels = { " ", " ", " ", " " }
	local hls = { "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint" }
	local counts = vim.diagnostic.count(0) or {}
	for i = 1, 4 do
		if counts[i] and counts[i] > 0 then
			diag = diag .. "%#" .. hls[i] .. "#" .. labels[i] .. counts[i] .. "%* "
		end
	end

	return "%#StlMode# " .. mode .. " %*" .. branch .. " " .. path .. modified .. "%=" .. diag .. vim.bo.filetype .. " %l:%c"
end


vim.api.nvim_create_autocmd("DiagnosticChanged", {
	callback = function()
		vim.cmd.redrawstatus()
	end,
})

vim.o.statusline = "%!v:lua._statusline()"
