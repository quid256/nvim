package.loaded["util"] = nil
package.loaded["my_settings"] = nil
package.loaded["beancount_setup"] = nil

local util = require("util")

-- options
util.set_options({
	go = {
		encoding = "utf-8",
		scrolloff = 2, -- keep 2 rows between cursor and end of screen
		mouse = "a", -- correct mouse interaction
		modeline = true,
		pastetoggle = "<Insert>", -- use <Insert> to enter paste mode
		termguicolors = true, -- do colors good
		completeopt = "menu,menuone,noselect",
		expandtab = true, -- convert tab character to spaces
		tabstop = 4,
		shiftwidth = 4,
		softtabstop = 4,
		hidden = true, -- Allows you to switch buffers without writing
		signcolumn = "yes", -- leave column on left for signs
		wrap = false, -- don't text-wrap by default
		clipboard = "unnamedplus",
		listchars = "tab:  ,extends:>,precedes:>",
		list = true,
		shortmess = vim.o.shortmess .. "c",
		number = true, -- line numbers
		relativenumber = true, -- relative line numbers
		cursorline = true, -- line to indicate where cursor is
		colorcolumn = "100", -- colorcolumn to indicate when code is getting wide
		smartcase = true, -- case insensitive by default unless a capital letter is included
		ignorecase = true,
		backupcopy = "yes", -- makes vim play nice with inotify
		shell = "fish",
	},
	g = {
		enable_bold_font = 1,
		enable_italic_font = 1,
		mapleader = " ",
	},
})

vim.opt.shortmess:append({ i = true, c = true })

-- plugins
util.bootstrap_lazy()

require("lazy").setup({
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = { "NvimTreeToggle", "NvimTreeFindFileToggle" },
		keys = {
			{ "<leader>n", "<cmd>NvimTreeToggle<cr>", desc = "Toggle Nvim file tree" },
			{ "<leader>f", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Toggle Nvim file tree" },
		},
		opts = {
			update_focused_file = { enable = true },
			git = { ignore = false },
			view = {
				centralize_selection = true,
				width = 45,
			},
			trash = { cmd = "rm -rf" },
			actions = { change_dir = { enable = false } },
		},
	},

	"godlygeek/tabular", -- tables
	"romainl/vim-cool", -- :noh automatically after search is stopped
	"ojroques/nvim-osc52", -- yank using OSC character, interop with clipboard

	{ -- fast hopping
		"phaazon/hop.nvim",
		branch = "v2",
		config = true,
		keys = {
			{
				"<leader>h",
				function()
					require("hop").hint_char2()
				end,
				desc = "Hop",
			},
		},
	},
	-- Commenting support
	{ "numToStr/Comment.nvim", config = true },

	{ -- Code formatting
		"mhartington/formatter.nvim",
		config = function()
			require("formatter").setup({
				logging = true,
				log_level = vim.log.levels.WARN,
				filetype = {
					-- Lua formatting
					lua = {
						-- "formatter.filetypes.lua" defines default configurations for the
						-- "lua" filetype
						require("formatter.filetypes.lua").stylua,
						function()
							local futil = require("formatter.util")
							return {
								exe = "stylua",
								args = {
									"--search-parent-directories",
									"--stdin-filepath",
									futil.escape_path(futil.get_current_buffer_file_path()),
									"--",
									"-",
								},
								stdin = true,
							}
						end,
					},
					javascript = require("formatter.filetypes.javascript").prettier,
					typescript = require("formatter.filetypes.typescript").prettier,
					dart = require("formatter.filetypes.dart").dartformat,
				},
			})

			-- Autoformatting
			local grp = vim.api.nvim_create_augroup("formatter_postwrite_hook", { clear = true })
			vim.api.nvim_create_autocmd("BufWritePost", {
				group = grp,
				pattern = "*",
				command = "FormatWrite",
			})
		end,
		event = "BufWritePre",
	},

	"tpope/vim-sleuth",

	-- List of simple snippets
	{ "rafamadriz/friendly-snippets", lazy = true },

	-- Snippet library
	{
		"L3MON4D3/LuaSnip",
		lazy = true,
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()

			-- Set up keymaps for jumping between parts of snippets
			vim.keymap.set("i", "<Tab>", function()
				if require("luasnip").expand_or_jumpable() then
					require("luasnip").expand_or_jump()
				else
					vim.api.nvim_feedkeys("\t", "n", false)
				end
			end)
			vim.keymap.set("s", "<Tab>", function()
				require("luasnip").jump(1)
			end)
			vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
				require("luasnip").jump(-1)
			end)
		end,
	},
	"gpanders/editorconfig.nvim",

	-- packages for using nvim-cmp completion
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
		},
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<Tab>"] = cmp.mapping.select_next_item(),
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				}),
				formatting = {
					format = function(entry, vim_item)
						local kind_icons = {
							Namespace = "󰌗 ",
							Package = " ",
							Constructor = " ",
							Enum = "󰕘 ",
							String = "󰀬 ",
							Number = "󰎠 ",
							Boolean = "◩ ",
							Array = "󰅪 ",
							Object = "󰅩 ",
							Key = "󰌋 ",
							Null = "󰟢 ",
							Text = " ",
							Method = "󰆧 ",
							Function = "󰊕 ",
							Field = " ",
							Variable = "󰆧 ",
							Class = "󰌗 ",
							Interface = "󰕘 ",
							Module = " ",
							Property = " ",
							Unit = " ",
							Value = " ",
							Keyword = " ",
							Snippet = " ",
							Color = " ",
							File = "󰈙 ",
							Reference = "",
							Folder = " ",
							EnumMember = " ",
							Constant = "󰏿 ",
							Struct = "󰌗 ",
							Event = " ",
							Operator = "󰆕 ",
							TypeParameter = "󰊄 ",
						}

						vim_item.kind = string.format("%s%s", kind_icons[vim_item.kind], vim_item.kind)

						vim_item.menu = ({
							buffer = "[BUF]",
							nvim_lsp = "[LSP]",
							nvim_lua = "[LUA]",
						})[entry.source.name]

						return vim_item
					end,
				},
			})

			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ { name = "path" } },
					{ { name = "cmdline" } },
				}),
			})
		end,
	},

	-- (LSP, linter, etc) management with Mason
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		cmd = "Mason",
		config = true,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = true,
		depencies = { "mason.nvim" },
		config = true,
	},

	-- Floating LSP status notifications at bottom of screen
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		tag = "legacy", -- update this after the refactor is done!
		config = true,
	},

	-- Kinda janky plugin to show function signature information in LSP
	-- use({ "ray-x/lsp_signature.nvim" })

	-- LSP setup
	{
		"neovim/nvim-lspconfig",
		event = "BufEnter",
		dependencies = {
			"cmp-nvim-lsp",
			"telescope.nvim",
			"nvim-navic",
			"mason.nvim",
			"mason-lspconfig.nvim",
			{ "neodev.nvim", opts = {} },
		},
		config = function()
			require("neodev").setup({})

			vim.lsp.stop_client(vim.lsp.get_active_clients(), true)

			local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()

			for ls_name, ls_settings in pairs(require("my_settings").lsp_settings()) do
				ls_settings.capabilities = vim.tbl_extend("keep", ls_settings.capabilities or {}, cmp_capabilities)

				ls_settings["on_attach"] = function(client, bufnr)
					if client.server_capabilities.documentSymbolProvider then
						require("nvim-navic").attach(client, bufnr)
					end

					-- require("lsp_signature").on_attach({}, bufnr)

					require("util").setup_lsp_keymaps(bufnr)
				end

				-- ls_settings = require("coq").lsp_ensure_capabilities(ls_settings)
				ls_settings = require("lspconfig")[ls_name].setup(ls_settings)
			end
		end,
	},

	{
		"simrat39/symbols-outline.nvim",
		opts = {
			keymaps = { -- These keymaps can be a string or a table for multiple keys
				close = { "<Esc>", "q" },
				goto_location = "<Cr>",
				focus_location = "o",
				hover_symbol = "<C-space>",
				toggle_preview = "K",
				rename_symbol = "r",
				code_actions = "a",
				fold = "h",
				unfold = "l",
				fold_all = "H",
				unfold_all = "L",
			},
		},
		cmd = { "SymbolsOutline", "SymbolsOutlineClose", "SymbolsOutlineOpen" },
		keys = {
			{ "<leader>o", "<cmd>SymbolsOutline<cr>", desc = "Show symbols outline" },
		},
	},

	-- Telescope
	{
		"nvim-telescope/telescope-ui-select.nvim",
		event = "VeryLazy",
		dependencies = { "telescope.nvim" },
		config = function()
			require("telescope").load_extension("ui-select")
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			defaults = {
				layout_strategy = "vertical",
				layout_config = {
					preview_cutoff = 40,
					width = 0.85,
					height = 0.85,
				},
				border = {},
				borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
				mappings = {
					n = {
						["q"] = function()
							require("telescope.actions").close()
						end,
					},
				},
				prompt_prefix = "   ",
				selection_caret = " ",
				entry_prefix = " ",
			},
			pickers = {
				find_files = {
					layout_strategy = "vertical",
					layout_config = {
						width = 0.85,
						height = 0.85,
					},
					path_display = function(opts, name)
						return require("my_settings").shorten_path(name)
					end,
				},
				live_grep = {
					prompt_title = "Grep",
					path_display = function(opts, name)
						return require("my_settings").shorten_path(name)
					end,
				},
				lsp_definitions = { theme = "cursor" },
				diagnostics = { theme = "ivy" },
				buffers = {
					sort_mru = true,
					layout_config = {
						width = 0.9,
						height = 0.9,
						preview_cutoff = 120,
					},
					mappings = {
						i = {
							["<c-d>"] = "delete_buffer",
						},
						n = {
							["<c-d>"] = "delete_buffer",
							["dd"] = "delete_buffer",
						},
					},
					path_display = function(opts, name)
						return require("my_settings").shorten_path(name)
					end,
				},
			},
			extensions = {
				["ui-select"] = {
					function()
						require("telescope.themes").get_cursor({})()
					end,
				},
			},
		},
		keys = {
			{ ";;", util.telescope("buffers"), mode = { "n", "v" }, desc = "[TS] Select buffer" },
			{ "<leader>q", util.telescope("diagnostics"), desc = "[TS] Show diagnostics" },
			{ "<C-p>", util.telescope("find_files"), mode = { "n", "i", "t" }, desc = "[TS] Find Files" },
			{ "<C-g>", util.telescope("live_grep"), mode = { "n", "i", "t" }, desc = "[TS] Grep Files" },
		},
	},

	-- Git
	"tpope/vim-fugitive",
	{ "junegunn/gv.vim", cmd = "GV" },
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			current_line_blame = true,
			current_line_blame_opts = {
				delay = 700,
			},
			signs = {
				add = { text = "▍" },
				change = { text = "▍" },
				delete = { text = "▁" },
				topdelete = { text = "▔" },
				changedelete = { text = "~" },
			},
		},
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		event = "BufEnter",
		build = function()
			local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
			ts_update()
		end,
		-- event = {"LazyFile", "VeryLazy"},
		init = function(plugin)
			-- per lazyvim config
			require("lazy.core.loader").add_to_rtp(plugin)
			require("nvim-treesitter.query_predicates")
		end,
		cmd = { "TSUpdateSync", "TSUpdate", "TSInstal" },
		opts = {
			ensure_installed = require("my_settings").treesitter_settings,
			highlight = { enable = true },
			-- indent = { enable = true },
		},
		config = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				---@type table<string, boolean>
				local added = {}
				opts.ensure_installed = vim.tbl_filter(function(lang)
					if added[lang] then
						return false
					end
					added[lang] = true
					return true
				end, opts.ensure_installed)
			end
			require("nvim-treesitter.configs").setup(opts)
		end,
	},

	"Vimjas/vim-python-pep8-indent",

	-- {
	-- 	"nvim-treesitter/nvim-treesitter-context",
	-- 	dependencies = { "nvim-treesitter/nvim-treesitter" },
	-- 	config = true,
	-- },

	{
		"nvim-treesitter/playground",
		cmd = { "TSPlaygroundToggle" },
		requires = { "nvim-treesitter/nvim-treesitter" },
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		requires = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("nvim-treesitter.configs").setup({
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							-- You can use the capture groups defined in textobjects.scm
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
							["ak"] = "@conditional.outer",
							["ik"] = "@conditional.inner",
							["al"] = "@loop.outer",
							["il"] = "@loop.inner",
						},
						selection_modes = {
							["@parameter.outer"] = "v",
							["@function.outer"] = "V",
							["@class.outer"] = "V",
						},
						include_surrounding_whitespace = false,
					},
				},
			})
		end,
	},

	{
		"SmiteshP/nvim-navic",
		opts = {
			highlight = true,
			separator = "  ",
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
		after = { "nvim-navic" },
		config = function()
			local function is_not_util_buffer()
				return not (vim.bo.filetype == "NvimTree" or vim.bo.filetype == "Outline")
			end

			require("lualine").setup({
				options = {
					icons_enabled = true,
					theme = "auto",
					section_separators = { left = "", right = "" },
					component_separators = "|",
					disabled_filetypes = {},
					always_divide_middle = true,
				},
				tabline = {
					lualine_c = {
						function()
							return require("my_settings").shorten_path(vim.fn.expand("%"))
						end,
					},
				},
				sections = {
					lualine_a = {
						{ "mode", cond = is_not_util_buffer },
					},
					lualine_b = {
						{ "diff", cond = is_not_util_buffer },
						{ "diagnostics", cond = is_not_util_buffer },
					},
					lualine_c = {
						{
							function()
								return require("nvim-navic").get_location({})
							end,
							cond = is_not_util_buffer,
						},
					},
					lualine_x = { "filetype" },
					lualine_y = {
						{ "branch", cond = is_not_util_buffer },
					},
					lualine_z = {
						{ "location", cond = is_not_util_buffer },
					},
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = {
						{
							function()
								return require("nvim-navic").get_location({})
							end,
							cond = is_not_util_buffer,
						},
					},
					lualine_x = { "filetype" },
					lualine_y = {},
					lualine_z = {
						{ "location", cond = is_not_util_buffer },
					},
				},
			})
		end,
	},

	{
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({
				presets = {
					operators = false,
					motions = false,
					text_objects = false,
					windows = false,
				},
				icons = {
					breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
					separator = "➜ ", -- symbol used between a key and it's label
					group = "+",
				},
				triggers = { "<leader>", "g", "z" },
			})
		end,
	},

	{
		"rose-pine/neovim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd([[ colorscheme rose-pine-moon ]])

			local function clamp(component)
				return math.min(math.max(component, 0), 255)
			end
			function LightenDarkenColor(col, amt)
				local num
				if type(col) == "number" then
					num = col
				else
					num = tonumber(col:sub(2), 16)
				end
				local r = math.floor(num / 0x10000) + amt
				local g = (math.floor(num / 0x100) % 0x100) + amt
				local b = (num % 0x100) + amt
				return clamp(r) * 0x10000 + clamp(g) * 0x100 + clamp(b)
			end

			local normal_cols = vim.api.nvim_get_hl_by_name("Normal", true)
			local dark_bg = LightenDarkenColor(normal_cols.background, -10)
			local mid_bg = LightenDarkenColor(normal_cols.background, -5)
			local light_bg = LightenDarkenColor(normal_cols.background, 10)
			local green = vim.api.nvim_get_hl_by_name("@function", true).foreground
			local blue = vim.api.nvim_get_hl_by_name("@class", true).foreground
			-- local red = vim.api.nvim_get_hl_by_name("Red", true).foreground
			-- local orange = vim.api.nvim_get_hl_by_name("Orange", true).foreground

			for k, v in pairs({
				TelescopeNormal = { bg = dark_bg, fg = normal_cols.foreground },
				TelescopeBorder = { bg = dark_bg, fg = normal_cols.foreground },
				TelescopePromptNormal = { bg = light_bg, fg = normal_cols.foreground },
				TelescopePromptBorder = { bg = light_bg, fg = normal_cols.foreground },
				TelescopeResultsNormal = { bg = mid_bg, fg = normal_cols.foreground },
				TelescopeResultsBorder = { bg = mid_bg, fg = normal_cols.foreground },
				TelescopeTitle = { fg = dark_bg, bg = blue },
				TelescopePromptTitle = { fg = dark_bg, bg = green },
				TelescopePromptPrefix = { fg = green },
			}) do
				vim.api.nvim_set_hl(0, k, v)
			end
		end,
	},
	-- { "folke/tokyonight.nvim", lazy = true },
	-- { "savq/melange", lazy = true },
	-- { "rafamadriz/neon", lazy = true },
	-- { "rose-pine/neovim", lazy = true },
	-- { "sainnhe/everforest", lazy = true },
	-- { "rebelot/kanagawa.nvim", lazy = true },
	-- { "olivercederborg/poimandres.nvim", lazy = true },

	-- for _, entry in ipairs({
	-- }) do
	-- 	local pack_name, scheme_name = unpack(entry)
	-- 	if scheme_name == "rose-pine" then
	-- 		use({
	-- 			pack_name,
	-- 			after = { "git-conflict.nvim" },
	-- 			config = function()
	-- 				vim.cmd([[ colorscheme rose-pine-moon ]])
	--
	-- 			end,
	-- 		})
	-- 	else
	-- 		use(pack_name)
	-- 	end
	-- end

	-- neovim-remote: custom loaders to install pip package in venv
	-- Then, nvr_scripts/ will be added to PATH so that nvr can do the right thing
	-- use({
	-- 	"mhinz/neovim-remote",
	-- 	url = "N/A",
	-- 	installer = util.install_nvr,
	-- 	updater = util.update_nvr,
	-- 	config = function()
	-- 	end,
	-- })

	{
		"lukas-reineke/indent-blankline.nvim",
		event = "VeryLazy",
		config = function()
			require("ibl").setup({
				indent = {
					tab_char = "▏",
					char = "▏",
				},
				scope = {
					char = "▌",
					show_start = false,
					show_end = false,
				},
			})
		end,
	},

	{
		"brettanomyces/nvim-editcommand",
		config = function()
			vim.keymap.set("t", "<c-x>", "<Plug>EditCommand")
		end,
	},

	-- pretty quickfix
	{
		"https://gitlab.com/yorickpeterse/nvim-pqf",
		config = function()
			require("pqf").setup()
		end,
	},

	-- pretty git conflicts
	-- {
	-- 	"akinsho/git-conflict.nvim",
	-- 	tag = "*",
	-- 	config = function()
	-- 		require("git-conflict").setup({
	-- 			highlights = {
	-- 				incoming = "DiffChange",
	-- 				current = "DiffAdd",
	-- 				parent = "DiffDelete",
	-- 			},
	-- 		})
	-- 	end,
	-- },
	{
		"folke/zen-mode.nvim",
		opts = {},
		cmd = "Zen",
		keys = {
			{ "<leader>z", "<cmd>Zen<cr>", desc = "Activate zen mode" },
		},
	},
	{
		"akinsho/flutter-tools.nvim",
		after = {
			"cmp-nvim-lsp",
			"telescope.nvim",
			"nvim-navic",
		},
		requires = "nvim-lua/plenary.nvim",
		ft = "flutter",
		config = function()
			require("flutter-tools").setup({
				lsp = {
					color = {
						enabled = true,
					},
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
					on_attach = function(client, bufnr)
						if client.server_capabilities.documentSymbolProvider then
							require("nvim-navic").attach(client, bufnr)
						end

						require("util").setup_lsp_keymaps(bufnr)
					end,
				},
			})
		end,
	},
})

vim.keymap.set({ "i" }, "fd", "<Esc>")
vim.keymap.set({ "t" }, "fd", "<c-\\><c-n>")
vim.keymap.set({ "n", "v" }, ";", ":")

-- window navigation
vim.keymap.set("n", "<C-h>", "<C-w><C-h>")
vim.keymap.set("n", "<C-j>", "<C-w><C-j>")
vim.keymap.set("n", "<C-k>", "<C-w><C-k>")
vim.keymap.set("n", "<C-l>", "<C-w><C-l>")
vim.keymap.set("t", "<C-S-t>", "<C-t>")
vim.keymap.set({ "n", "t" }, "<C-t>", function()
	local cur_bufnr = vim.api.nvim_get_current_buf()

	if vim.api.nvim_buf_get_option(cur_bufnr, "buftype") == "terminal" then
		vim.cmd([[ b # ]])
		return
	end

	local to_buf = -1
	for _, nr in ipairs(vim.api.nvim_list_bufs()) do
		local ft = vim.api.nvim_buf_get_option(nr, "buftype")

		if ft == "terminal" then
			to_buf = nr
			break
		end
	end

	if to_buf > -1 then
		vim.api.nvim_set_current_buf(to_buf)
	else
		vim.cmd([[ term ]])
	end
	vim.cmd([[ startinsert ]])
end, { desc = "Go to primary terminal" })

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show Diagnostic" })
vim.keymap.set("n", "<leader>v", "<cmd>G<CR>", { desc = "Git menu" })
vim.keymap.set("n", "<leader>mc", function()
	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1

	local comment_str = vim.bo.commentstring:gsub("%%s", "NOCOMMIT")

	local cur_line = vim.api.nvim_get_current_line()
	local mstart, mend = cur_line:find(" " .. comment_str:gsub("%-", "%%-") .. "$")

	if mstart ~= nil then
		vim.api.nvim_buf_set_text(0, row, mstart - 1, row, mend, { "" })
	else
		local col = cur_line:len()
		vim.api.nvim_buf_set_text(0, row, col, row, col, { " " .. comment_str })
	end
end, { desc = "NOCOMMIT" })

-- don't apply smartcase for * and #
vim.keymap.set({ "n" }, "*", "/\\<<C-R>=expand('<cword>')<CR>\\><CR>")
vim.keymap.set({ "n" }, "#", "?\\<<C-R>=expand('<cword>')<CR>\\><CR>")

-- Autocommands
local augroup = vim.api.nvim_create_augroup("default", { clear = true })

vim.api.nvim_create_autocmd("TermOpen", {
	group = augroup,
	command = "setlocal nonumber norelativenumber",
})

vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		-- highlight on yank
		vim.highlight.on_yank()

		-- OSC-yank if necessary
		if vim.v.event.operator == "y" and vim.v.event.regname == "+" then
			require("osc52").copy_register("+")
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = "gitcommit",
	callback = function()
		vim.cmd([[ norm! cc ]])
	end,
})

-- auto-save files after 1min. This is only meant to catch files you meant to save but didn't
-- local _debounced_write = util.debounce(function()
-- 	vim.cmd("wa")
-- end, 60000)
--
-- vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
-- 	group = augroup,
-- 	callback = function(t)
-- 		if vim.api.nvim_buf_get_option(t["buf"], "buftype") == "" then
-- 			_debounced_write()
-- 		end
-- 	end,
-- })

require("beancount_setup").setup()

-- Abbreviations
vim.cmd([[ cnoreabbrev <expr> W getcmdtype() == ":" && getcmdline() == "W" ? "w" : "W" ]])

vim.fn.setenv("NVIM_LISTEN_ADDRESS", vim.v.servername)
-- vim.fn.setenv("PATH", vim.fn.getenv("PATH") .. ":" .. (vim.fn.stdpath("config") .. "/nvr-scripts"))
vim.fn.setenv("EDITOR", "nvr -cc split --remote-wait")
vim.fn.setenv("GIT_EDITOR", "nvr -cc split --remote-wait")

-- overwrite the standard diagnostic signs for prettier utf-8 ones
local diagnostic_signs = {
	DiagnosticSignError = " ",
	DiagnosticSignWarn = " ",
	DiagnosticSignHint = " ",
	DiagnosticSignInfo = " ",
}

for sign_name, sign in pairs(diagnostic_signs) do
	vim.fn.sign_define(sign_name, { texthl = sign_name, text = sign, numhl = sign_name })
end
