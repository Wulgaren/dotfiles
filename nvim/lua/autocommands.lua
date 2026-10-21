vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
	desc = "Highlight yanked text",
	callback = function()
		vim.hl.on_yank({ timeout = 200, visual = true })
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		local row, col = unpack(vim.api.nvim_buf_get_mark(args.buf, '"'))
		if row < 1 or row > vim.api.nvim_buf_line_count(args.buf) then
			return
		end
		vim.api.nvim_win_set_cursor(0, { row, col })
		vim.schedule(function()
			vim.cmd.normal({ "zz", bang = true })
		end)
	end,
})

local conflict_words = "^<<<<<<<.*:^=======.*:^>>>>>>>.*"
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("conflict_match_words", { clear = true }),
	callback = function()
		local existing = vim.b.match_words
		if existing and existing ~= "" and not existing:find(conflict_words, 1, true) then
			vim.b.match_words = existing .. "," .. conflict_words
		elseif not existing or existing == "" then
			vim.b.match_words = conflict_words
		end
	end,
})

--- Rename :terminal buffers from b:term_title (zsh OSC) so :b can find them by command.
vim.api.nvim_create_autocmd({ "TermRequest", "TermLeave" }, {
	callback = function(ev)
		local buf = ev.buf
		local title = vim.b[buf].term_title
		if not title or vim.bo[buf].buftype ~= "terminal" then
			return
		end
		pcall(vim.api.nvim_buf_set_name, buf, title)
		for _, b in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_valid(b) and not vim.bo[b].buflisted and vim.bo[b].buftype == "terminal" then
				pcall(vim.api.nvim_buf_delete, b, { force = true })
			end
		end
	end,
})
