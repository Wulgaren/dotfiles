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
vim.o.updatetime = 250
vim.o.signcolumn = "yes"
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }
vim.o.pumheight = 12
vim.o.swapfile = false
vim.o.backup = false
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.wrap = false
vim.o.winborder = "rounded"
vim.o.incsearch = true
vim.o.undofile = true
vim.o.autoread = true
vim.o.laststatus = 3
vim.o.cmdheight = 0

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("config-options-autocmds", { clear = true }),
	pattern = "qf",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
	end,
})

--------------
--- MACROS ---
--------------
local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
vim.fn.setreg("l", "yoconsole.log('" .. esc .. "pa: '" .. esc .. "a, " .. esc .. "pa)" .. esc .. "l")
