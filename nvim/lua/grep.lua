local ignores = require("ignores")

vim.opt.grepprg = ignores.grepprg()
vim.opt.grepformat = "%f:%l:%c:%m"

local preview_group = vim.api.nvim_create_augroup("config-grep-preview", { clear = true })
local preview_opened = false

local function close_preview()
	if preview_opened then
		vim.cmd("pclose")
		preview_opened = false
	end
end

local function list_info(win)
	return vim.fn.getwininfo(win)[1]
end

local function preview_qf_item()
	local win = vim.api.nvim_get_current_win()
	local info = list_info(win)
	if not info or info.quickfix ~= 1 or info.loclist == 1 then
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
		local info = list_info(vim.api.nvim_get_current_win())
		if not info or info.quickfix ~= 1 then
			return
		end

		-- Loclist (diagnostics, LSP symbols): native jump via :ll
		if info.loclist == 1 then
			vim.keymap.set("n", "<CR>", ":ll<CR>", {
				buffer = ev.buf,
				silent = true,
				desc = "Jump to loclist item (:ll)",
			})
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

		local cmd = ignores.rg_vimgrep_argv({ "-F" }, pattern)

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
