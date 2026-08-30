vim.o.termguicolors = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.mouse = "a"
vim.o.clipboard = "unnamedplus"
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.signcolumn = "yes"
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }
vim.o.pumheight = 12
vim.o.wildmode = "noselect:lastused,full"
vim.o.swapfile = false
vim.o.backup = false
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.wrap = true
vim.o.linebreak = true
vim.o.winborder = "rounded"
vim.o.pumborder = "rounded"
vim.o.incsearch = true
vim.o.undofile = true
vim.o.autoread = true
vim.o.laststatus = 3
vim.o.cmdheight = 0

vim.diagnostic.config({ virtual_text = true })
vim.keymap.set("n", "<leader>d", function()
	vim.diagnostic.setloclist()
end, { silent = true, desc = "Diagnostics → loclist" })

local options_augroup = vim.api.nvim_create_augroup("config-options-autocmds", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = options_augroup,
	pattern = "qf",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
	end,
})

require("vim._core.ui2").enable({
	msg = { targets = "msg" },
})

local ui2 = require("vim._core.ui2")
local messages = require("vim._core.ui2.messages")
local set_pos = messages.set_pos
function messages.set_pos(tgt)
	set_pos(tgt)
	local win = ui2.wins.msg
	if not (win and vim.api.nvim_win_is_valid(win)) then
		return
	end
	local cfg = vim.api.nvim_win_get_config(win)
	if cfg.hide then
		return
	end
	vim.api.nvim_win_set_config(win, {
		relative = cfg.relative,
		anchor = "SW",
		row = cfg.row,
		col = 0,
	})
end

--- Auto-show wildmenu popup while typing in :, /, and ?
vim.api.nvim_create_autocmd("CmdlineChanged", {
	group = options_augroup,
	pattern = { ":", "/", "?" },
	callback = function()
		vim.fn.wildtrigger()
	end,
})

--------------
--- MACROS ---
--------------
local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
vim.fn.setreg("l", "yoconsole.log('" .. esc .. "pa: '" .. esc .. "a, " .. esc .. "pa)" .. esc .. "l")
