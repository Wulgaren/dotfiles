local M = {}

-- ── Quickfix pickers (preview on cursor, <CR> opens in source window) ───────

local preview_group = vim.api.nvim_create_augroup("config-qf-preview", { clear = true })
local term_preview_buf
local source_win

local function qf_item()
	local line = vim.fn.line(".")
	return line, vim.fn.getqflist()[line]
end

local function is_qf_win(win)
	local info = vim.fn.getwininfo(win)[1]
	return info and info.quickfix == 1 and info.loclist ~= 1
end

local function ensure_loaded(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "" then
		return bufnr
	end
	vim.fn.bufload(bufnr)
	if vim.bo[bufnr].filetype == "" then
		local ft = vim.filetype.match({ filename = vim.api.nvim_buf_get_name(bufnr) })
		if ft then
			vim.bo[bufnr].filetype = ft
		end
	end
	return bufnr
end

local function open_in_main()
	local line, item = qf_item()
	vim.cmd("silent! pclose | cclose")
	if not item then
		return
	end
	if source_win and vim.api.nvim_win_is_valid(source_win) then
		vim.api.nvim_set_current_win(source_win)
	else
		for _, w in ipairs(vim.fn.getwininfo()) do
			if not is_qf_win(w.winid) and not vim.wo[w.winid].previewwindow then
				vim.api.nvim_set_current_win(w.winid)
				break
			end
		end
	end
	source_win = nil
	if item.bufnr > 0 and vim.api.nvim_buf_is_valid(item.bufnr) then
		vim.api.nvim_set_current_buf(ensure_loaded(item.bufnr))
		if vim.bo[item.bufnr].buftype ~= "terminal" then
			local lnum = math.max(item.lnum or 1, 1)
			pcall(vim.api.nvim_win_set_cursor, 0, { lnum, math.max((item.col or 1) - 1, 0) })
		end
	else
		vim.cmd(line .. "cc!")
	end
end

local function preview_buf(src)
	if vim.bo[src].buftype ~= "terminal" then
		return src
	end
	if not term_preview_buf or not vim.api.nvim_buf_is_valid(term_preview_buf) then
		term_preview_buf = vim.api.nvim_create_buf(false, true)
	end
	vim.api.nvim_buf_set_lines(term_preview_buf, 0, -1, false, vim.api.nvim_buf_get_lines(src, 0, -1, false))
	return term_preview_buf
end

local function preview_item()
	if not is_qf_win(vim.api.nvim_get_current_win()) then
		return
	end
	local line, item = qf_item()
	if not item or item.bufnr == 0 then
		return
	end

	vim.schedule(function()
		if not is_qf_win(vim.api.nvim_get_current_win()) then
			return
		end
		local _, current = qf_item()
		if not current or current.bufnr ~= item.bufnr or vim.fn.line(".") ~= line then
			return
		end
		ensure_loaded(item.bufnr)
		vim.cmd("silent! pedit")
		for _, w in ipairs(vim.fn.getwininfo()) do
			if vim.wo[w.winid].previewwindow then
				local buf = preview_buf(item.bufnr)
				vim.api.nvim_win_set_buf(w.winid, buf)
				local lnum = buf == item.bufnr and math.max(item.lnum or 1, 1) or vim.api.nvim_buf_line_count(buf)
				local col = buf == item.bufnr and math.max((item.col or 1) - 1, 0) or 0
				pcall(vim.api.nvim_win_set_cursor, w.winid, { math.max(lnum, 1), col })
				break
			end
		end
	end)
end

vim.api.nvim_create_autocmd("FileType", {
	group = preview_group,
	pattern = "qf",
	callback = function(ev)
		if not is_qf_win(vim.api.nvim_get_current_win()) then
			return
		end
		vim.keymap.set("n", "<CR>", open_in_main, { buffer = ev.buf, silent = true })
		vim.keymap.set("n", "<Esc>", "<cmd>silent! pclose | cclose<CR>", { buffer = ev.buf, silent = true })
		vim.keymap.set("n", "<C-n>", "j", { buffer = ev.buf, silent = true, desc = "Next quickfix item" })
		vim.keymap.set("n", "<C-p>", "k", { buffer = ev.buf, silent = true, desc = "Previous quickfix item" })
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = preview_group,
			buffer = ev.buf,
			callback = preview_item,
		})
	end,
})

function M.open(spec)
	source_win = vim.api.nvim_get_current_win()
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

local function sanitize_branch(name)
	local s = vim.trim(name or ""):gsub("%s+", "_")
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
