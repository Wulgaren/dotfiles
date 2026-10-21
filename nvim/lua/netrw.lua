vim.g.netrw_liststyle = 3
vim.g.netrw_banner = 0
vim.g.netrw_altfile = 1

local function toggle_explore()
	if vim.bo.filetype == "netrw" then
		vim.cmd("b#")
	else
		vim.cmd("Explore")
	end
end

vim.keymap.set("n", "<leader>e", toggle_explore, { silent = true, desc = "Toggle file explorer" })

-- Built-in `%` ignores netrw_browse_split; override so new files open for editing.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function()
		vim.keymap.set("n", "%", function()
			local fname = vim.fn.input("Enter filename: ")
			if fname == "" then
				return
			end

			local dir = vim.b.netrw_curdir or vim.fn.getcwd()
			local path = dir .. "/" .. fname

			if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
				vim.notify("Already exists: " .. fname, vim.log.levels.WARN)
				return
			end

			if fname:match("/$") then
				vim.fn.mkdir(path, "p")
				vim.cmd("edit")
				return
			end

			local f = io.open(path, "w")
			if not f then
				vim.notify("Failed to create: " .. fname, vim.log.levels.ERROR)
				return
			end
			f:close()
			vim.cmd("edit " .. vim.fn.fnameescape(path))
		end, { buffer = true, silent = true, noremap = true, desc = "Create file" })
	end,
})
