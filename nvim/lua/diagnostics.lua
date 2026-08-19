vim.diagnostic.config({
	virtual_text = true,
})

vim.keymap.set("n", "<leader>d", function()
	vim.diagnostic.setloclist()
end, { silent = true, desc = "Diagnostics → loclist" })
