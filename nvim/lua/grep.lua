local ignores = require("ignores")

-- Quote each -g pattern: zsh/bash otherwise expand `!**/.git/**` and rg gets nothing.
local grep_parts = { "rg", "--vimgrep", "--smart-case", "--hidden" }
for _, g in ipairs(ignores.EXCLUDE_GLOBS) do
	grep_parts[#grep_parts + 1] = "-g"
	grep_parts[#grep_parts + 1] = vim.fn.shellescape(g)
end
vim.opt.grepprg = table.concat(grep_parts, " ")
vim.opt.grepformat = "%f:%l:%c:%m"

local preview_group = vim.api.nvim_create_augroup("config-grep-preview", { clear = true })
local preview_opened = false

local function close_preview()
	if preview_opened then
		vim.cmd("pclose")
		preview_opened = false
	end
end

local function preview_qf_item()
	local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
	if not wininfo or wininfo.quickfix ~= 1 or wininfo.loclist == 1 then
		return
	end

	local idx = vim.fn.line(".")
	local item = vim.fn.getqflist()[idx]
	if not item or item.bufnr == 0 then
		return
	end

	local fname = vim.api.nvim_buf_get_name(item.bufnr)
	if fname == "" then
		return
	end

	local lnum = math.max(item.lnum or 1, 1)
	vim.cmd("silent! pedit +" .. lnum .. " " .. vim.fn.fnameescape(fname))
	preview_opened = true

	for _, info in ipairs(vim.fn.getwininfo()) do
		if info.winid ~= vim.api.nvim_get_current_win() and vim.wo[info.winid].previewwindow then
			pcall(vim.api.nvim_win_set_cursor, info.winid, { lnum, math.max((item.col or 1) - 1, 0) })
			break
		end
	end
end

--- Jump target: first non-qf, non-preview window (prefer alternate).
local function main_edit_win(qf_win)
	local alt = vim.fn.win_getid(vim.fn.winnr("#"))
	local fallback
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if win ~= qf_win and not vim.wo[win].previewwindow then
			local info = vim.fn.getwininfo(win)[1]
			if info and info.quickfix ~= 1 then
				if win == alt then
					return win
				end
				fallback = fallback or win
			end
		end
	end
	return fallback
end

local function open_qf_in_main()
	local qf_win = vim.api.nvim_get_current_win()
	local item = vim.fn.getqflist()[vim.fn.line(".")]
	if not item or item.bufnr == 0 then
		return
	end

	local fname = vim.api.nvim_buf_get_name(item.bufnr)
	if fname == "" then
		return
	end

	close_preview()

	local target = main_edit_win(qf_win)
	if target then
		vim.api.nvim_set_current_win(target)
	end

	vim.cmd("edit " .. vim.fn.fnameescape(fname))
	-- pedit may already have loaded this buf; plain :edit then skips BufRead/FileType.
	-- Empty filetype → no LSP attach. Force detect when missing.
	if vim.bo.filetype == "" then
		vim.cmd("filetype detect")
	end
	local lnum = math.max(item.lnum or 1, 1)
	local col = math.max((item.col or 1) - 1, 0)
	local line_count = vim.api.nvim_buf_line_count(0)
	if lnum > line_count then
		lnum = line_count
	end
	pcall(vim.api.nvim_win_set_cursor, 0, { lnum, col })
	vim.cmd("cclose")
end

vim.api.nvim_create_autocmd("FileType", {
	group = preview_group,
	pattern = "qf",
	callback = function(ev)
		local win = vim.api.nvim_get_current_win()
		local info = vim.fn.getwininfo(win)[1]
		if not info or info.loclist == 1 then
			return
		end

		vim.keymap.set("n", "<CR>", open_qf_in_main, {
			buffer = ev.buf,
			silent = true,
			desc = "Open qf item in main window",
		})

		vim.api.nvim_create_autocmd("CursorMoved", {
			group = preview_group,
			buffer = ev.buf,
			callback = preview_qf_item,
		})

		vim.api.nvim_create_autocmd({ "BufWipeout", "BufWinLeave" }, {
			group = preview_group,
			buffer = ev.buf,
			once = true,
			callback = close_preview,
		})
	end,
})

--- UI grep via argv (not :grep): avoids Vim `#`/`%` cmdline expand poisoning rg,
--- and -F so pasted code (`cy.get("…")`) is literal, not broken regex.
local function run_grep()
	vim.ui.input({ prompt = "Grep: " }, function(pattern)
		if not pattern or pattern == "" then
			return
		end

		local cmd = { "rg", "--vimgrep", "--smart-case", "--hidden", "-F" }
		vim.list_extend(cmd, ignores.rg_glob_args())
		cmd[#cmd + 1] = "--"
		cmd[#cmd + 1] = pattern

		local lines = vim.fn.systemlist(cmd)
		local code = vim.v.shell_error
		-- rg: 0 matches, 1 no match, ≥2 error
		if code > 1 then
			vim.notify(table.concat(lines, "\n"), vim.log.levels.ERROR)
			return
		end

		vim.fn.setqflist({}, "r", {
			title = "grep " .. pattern,
			lines = lines,
			efm = vim.o.grepformat,
		})
		vim.cmd("copen")
	end)
end

vim.keymap.set("n", "<C-t>", run_grep, { silent = true, desc = "Grep" })
vim.keymap.set("n", "<leader>fg", run_grep, { silent = true, desc = "Grep" })
