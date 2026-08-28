local M = {}

--- Shared exclude globs (from Telescope TELESCOPE_RG_EXCLUDE_GLOBS).
M.EXCLUDE_GLOBS = {
	"!.git",
	"!**/.git/**",
	"!**/node_modules/**",
	"!**/dist/**",
	"!**/build/**",
	"!**/.cache/**",
	"!**/bin/**",
	"!**/obj/**",
	"!**/*.min.*",
	"!**/*.d.ts",
	"!**/*.g.cs",
	"!**/wwwroot/lib/**",
	"!**/*syncfusion*",
	"!**/jquery*.js",
	"!**/jquery*.map",
	"!**/bootstrap/**",
	"!**/tests/mocks/**",
	"!**/Extrernal DLLs/**",
	"!**/*.map",
}

--- Flat list of `-g`, pattern pairs for the rg CLI.
function M.rg_glob_args()
	local args = {}
	for _, g in ipairs(M.EXCLUDE_GLOBS) do
		args[#args + 1] = "-g"
		args[#args + 1] = g
	end
	return args
end

--- Base rg vimgrep argv. Flags first, then `-g` globs, then optional `-- pattern`.
function M.rg_vimgrep_argv(flags, pattern)
	local cmd = { "rg", "--vimgrep", "--smart-case", "--hidden" }
	vim.list_extend(cmd, flags or {})
	vim.list_extend(cmd, M.rg_glob_args())
	if pattern then
		cmd[#cmd + 1] = "--"
		cmd[#cmd + 1] = pattern
	end
	return cmd
end

--- 'grepprg' string with shell-escaped globs.
function M.grepprg()
	local parts = M.rg_vimgrep_argv()
	for i = 2, #parts do
		if parts[i - 1] == "-g" then
			parts[i] = vim.fn.shellescape(parts[i])
		end
	end
	return table.concat(parts, " ")
end

return M
