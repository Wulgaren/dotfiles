local YANK_RING_SIZE = 9

local function push_yank_ring()
	local event = vim.v.event
	if event.operator ~= "y" or event.regname ~= "" then
		return
	end

	local text = vim.fn.getreg('"')
	if text == "" then
		return
	end
	local regtype = vim.fn.getregtype('"')
	if text == vim.fn.getreg("1") and regtype == vim.fn.getregtype("1") then
		return
	end

	for i = YANK_RING_SIZE, 2, -1 do
		local prev = tostring(i - 1)
		local cur = tostring(i)
		vim.fn.setreg(cur, vim.fn.getreg(prev), vim.fn.getregtype(prev))
	end
	vim.fn.setreg("1", text, regtype)
end

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
	desc = "Highlight yanked text",
	callback = function()
		vim.hl.on_yank({ timeout = 200, visual = true })
		push_yank_ring()
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
