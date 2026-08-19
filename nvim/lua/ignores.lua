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

return M
