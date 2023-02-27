local M = {}

function M.lsp_settings()
	return {
		lua_ls = {},
		pyright = {
			root_dir = require("lspconfig").util.root_pattern(".git"),
			settings = {
				python = {
					analysis = {
						typeCheckingMode = "off",
						autoSearchPaths = false,
						useLibraryCodeForTypes = false,
						diagnosticMode = "openFilesOnly",
					},
					workspaceSymbols = {
						enabled = true,
					},
				},
			},
		},
	}
end

M.treesitter_settings = { "lua", "python", "cpp" }

function M.shorten_path(path)
	return path
end

return M
