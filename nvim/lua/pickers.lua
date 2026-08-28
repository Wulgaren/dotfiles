local M = {}

-- ── Quickfix pickers (preview on cursor, <CR> opens in main window) ─────────

local preview_group = vim.api.nvim_create_augroup("config-qf-preview", { clear = true })
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

local function preview_item()
	local info = list_info(vim.api.nvim_get_current_win())
	if not info or info.quickfix ~= 1 or info.loclist == 1 then
		return
	end

	local item = vim.fn.getqflist()[vim.fn.line(".")]
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

	for _, win in ipairs(vim.fn.getwininfo()) do
		if win.winid ~= vim.api.nvim_get_current_win() and vim.wo[win.winid].previewwindow then
			pcall(vim.api.nvim_win_set_cursor, win.winid, { lnum, math.max((item.col or 1) - 1, 0) })
			break
		end
	end
end

local function main_edit_win(qf_win)
	local alt = vim.fn.win_getid(vim.fn.winnr("#"))
	local fallback
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if win ~= qf_win and not vim.wo[win].previewwindow then
			local info = list_info(win)
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

local function open_in_main()
	local qf_win = vim.api.nvim_get_current_win()
	local item = vim.fn.getqflist()[vim.fn.line(".")]
	if not item or item.bufnr == 0 then
		return
	end

	close_preview()

	local target = main_edit_win(qf_win)
	if target then
		vim.api.nvim_set_current_win(target)
	end

	local fname = vim.api.nvim_buf_get_name(item.bufnr)
	if fname == "" then
		vim.api.nvim_win_set_buf(0, item.bufnr)
		vim.cmd("cclose")
		return
	end

	vim.cmd("edit " .. vim.fn.fnameescape(fname))
	if vim.bo.filetype == "" then
		vim.cmd("filetype detect")
	end
	local lnum = math.min(math.max(item.lnum or 1, 1), vim.api.nvim_buf_line_count(0))
	local col = math.max((item.col or 1) - 1, 0)
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

		if info.loclist == 1 then
			vim.keymap.set("n", "<CR>", ":ll<CR>", {
				buffer = ev.buf,
				silent = true,
				desc = "Jump to loclist item (:ll)",
			})
			return
		end

		vim.keymap.set("n", "<CR>", open_in_main, {
			buffer = ev.buf,
			silent = true,
			desc = "Open qf item in main window",
		})

		vim.api.nvim_create_autocmd("CursorMoved", {
			group = preview_group,
			buffer = ev.buf,
			callback = preview_item,
		})

		vim.api.nvim_create_autocmd({ "BufWipeout", "BufWinLeave" }, {
			group = preview_group,
			buffer = ev.buf,
			once = true,
			callback = close_preview,
		})
	end,
})

function M.open(spec)
	vim.fn.setqflist({}, "r", spec)
	vim.cmd("copen")
end

function M.buffers()
	local cur = vim.api.nvim_get_current_buf()
	local items = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
			local name = vim.api.nvim_buf_get_name(buf)
			local label = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":~:.")
			local prefix = buf == cur and "» " or "  "
			local modified = vim.bo[buf].modified and " [+]" or ""
			items[#items + 1] = {
				bufnr = buf,
				lnum = 1,
				col = 1,
				text = prefix .. label .. modified,
			}
		end
	end
	table.sort(items, function(a, b)
		return a.text:lower() < b.text:lower()
	end)
	M.open({ title = "Buffers", items = items })
end

-- ── Git branches ────────────────────────────────────────────────────────────

local POLISH_ASCII = {
	["ą"] = "a",
	["ć"] = "c",
	["ę"] = "e",
	["ł"] = "l",
	["ń"] = "n",
	["ó"] = "o",
	["ś"] = "s",
	["ź"] = "z",
	["ż"] = "z",
	["Ą"] = "A",
	["Ć"] = "C",
	["Ę"] = "E",
	["Ł"] = "L",
	["Ń"] = "N",
	["Ó"] = "O",
	["Ś"] = "S",
	["Ź"] = "Z",
	["Ż"] = "Z",
}

local function sanitize_branch(name)
	local s = vim.trim(name or ""):gsub("%s+", "_")
	for from, to in pairs(POLISH_ASCII) do
		s = s:gsub(from, to)
	end
	return s
end

local function git_branch_names()
	local lines = vim.fn.systemlist({ "git", "branch", "-a", "--format=%(refname:short)" })
	if vim.v.shell_error ~= 0 then
		return {}
	end

	local seen = {}
	local branches = {}
	for _, ref in ipairs(lines) do
		local name = ref:gsub("^remotes/origin/", ""):gsub("^origin/", "")
		if name ~= "" and name ~= "HEAD" and not seen[name] then
			seen[name] = true
			branches[#branches + 1] = name
		end
	end
	table.sort(branches)
	return branches
end

local function git(args)
	local out = vim.fn.system(args)
	return vim.v.shell_error == 0, vim.trim(out)
end

local function git_switch(name)
	local branch = sanitize_branch(name):gsub("^origin/", "")
	if branch == "" then
		vim.notify("Git: empty branch name", vim.log.levels.WARN)
		return
	end

	local ok, err = git({ "git", "switch", branch })
	if not ok then
		if not err:find("invalid reference", 1, true) then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
		ok, err = git({ "git", "switch", "-c", branch })
		if not ok then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
		vim.notify("Created and switched to: " .. branch, vim.log.levels.INFO)
	end

	local has_upstream = git({ "git", "rev-parse", "--abbrev-ref", "@{upstream}" })
	if not has_upstream then
		git({ "git", "branch", "-u", "origin/" .. branch, branch })
	end
end

vim.api.nvim_create_user_command("GitSwitch", function(opts)
	git_switch(opts.args)
end, {
	nargs = 1,
	complete = function(arglead)
		local branches = git_branch_names()
		if arglead == "" then
			return branches
		end
		return vim.fn.matchfuzzy(branches, arglead)
	end,
})

-- ── Keymaps ─────────────────────────────────────────────────────────────────

vim.keymap.set("n", "<C-h>", "<cmd>marks<CR>", { silent = true, desc = "List marks (:marks)" })
vim.keymap.set("n", "<C-j>", M.buffers, { silent = true, desc = "Buffer list (qf preview)" })
vim.keymap.set("n", "<leader>gc", ":GitSwitch ", { silent = false, desc = "Git switch/create branch" })

return M
