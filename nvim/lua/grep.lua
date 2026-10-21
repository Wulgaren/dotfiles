local ignores = require("ignores")
local pickers = require("pickers")

vim.opt.grepprg = ignores.grepprg()
vim.opt.grepformat = "%f:%l:%c:%m"

local function run_grep()
	vim.ui.input({ prompt = "Grep: " }, function(pattern)
		if not pattern or pattern == "" then
			return
		end

		local lines = vim.fn.systemlist(ignores.rg_vimgrep_argv({ "-F" }, pattern))
		if vim.v.shell_error > 1 then
			vim.notify(table.concat(lines, "\n"), vim.log.levels.ERROR)
			return
		end

		pickers.open({
			title = "grep " .. pattern,
			lines = lines,
			efm = vim.o.grepformat,
		})
	end)
end

vim.keymap.set("n", "<C-t>", run_grep, { silent = true, desc = "Grep" })
