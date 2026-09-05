vim.lsp.enable({
	"lua_ls",
	"ts_ls",
	"html",
	"cssls",
	"tailwindcss",
	"jsonls",
	"bashls",
	"pylsp",
	"roslyn",
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		-- Keep Treesitter colors; semantic tokens were washing params/funcs to grey.
		if client then
			client.server_capabilities.semanticTokensProvider = nil
		end
		if client and client:supports_method("textDocument/completion") then
			local provider = client.server_capabilities.completionProvider
			if provider then
				provider.triggerCharacters = vim.iter(vim.fn.range(32, 126)):map(string.char):totable()
			end
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end

		local opts = { buffer = ev.buf, silent = true }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

		vim.keymap.set({ "n", "v" }, "<leader>f", function()
			vim.lsp.buf.format({
				async = false,
				range = vim.fn.mode():match("^[vV\22]") and {
					start = vim.api.nvim_buf_get_mark(0, "<"),
					["end"] = vim.api.nvim_buf_get_mark(0, ">"),
				} or nil,
			})
		end, vim.tbl_extend("force", opts, { desc = "Format buffer or selection" }))
	end,
})
