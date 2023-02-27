package.loaded["util"] = nil
local util = require("util")

-- load packages
util.packer_load(function(use, use_rocks)
	-- Packer.nvim itself
	use({
		"wbthomason/packer.nvim",
		config = function()
			vim.keymap.set("n", "<leader>ps", require("packer").sync, { desc = "Packer Sync" })
			vim.keymap.set("n", "<leader>pc", require("packer").compile, { desc = "Packer Compile" })
			vim.keymap.set("n", "<leader>px", require("packer").clean, { desc = "Packer Clean" })
			vim.keymap.set("n", "<leader>p?", require("packer").status, { desc = "Packer Status" })

			-- Stolen from kickstart.nvim. auto-compile ewhen written
			local packer_group = vim.api.nvim_create_augroup("Packer", { clear = true })
			vim.api.nvim_create_autocmd("BufWritePost", {
				command = "source <afile> | PackerCompile",
				group = packer_group,
				pattern = vim.fn.expand("$MYVIMRC"),
			})
		end,
	})

	-- File tree
	use({
		"nvim-tree/nvim-tree.lua",
		requires = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup({
				view = {
					centralize_selection = true,
					width = 45,
				},
				trash = {
					cmd = "rm -rf",
				},
				actions = {
					change_dir = {
						enable = false,
					},
				},
			})

			vim.keymap.set("n", "<leader>n", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle Nvim file tree" })
			vim.keymap.set("n", "<leader>f", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle Nvim file tree" })
		end,
	})

	-- various editing tasks
	use("godlygeek/tabular") -- tables
	use("romainl/vim-cool") -- :noh automatically after search is stopped
	use("ojroques/vim-oscyank") -- yank using OSC character, interop with clipboard
	-- use "m4xshen/autoclose.nvim" -- auto-close delimiters

	-- smooth scrolling
	-- use({
	-- 	"karb94/neoscroll.nvim",
	-- 	config = function()
	-- 		require("neoscroll").setup({})
	-- 		local t = {}
	--
	-- 		t["<C-u>"] = { "scroll", { "-vim.wo.scroll", "true", "80" } }
	-- 		t["<C-d>"] = { "scroll", { "vim.wo.scroll", "true", "80" } }
	-- 		t["<C-b>"] = { "scroll", { "-vim.api.nvim_win_get_height(0)", "true", "160" } }
	-- 		t["<C-f>"] = { "scroll", { "vim.api.nvim_win_get_height(0)", "true", "160" } }
	-- 		t["<C-y>"] = { "scroll", { "-0.10", "false", "50" } }
	-- 		t["<C-e>"] = { "scroll", { "0.10", "false", "50" } }
	-- 		t["zt"] = { "zt", { "80" } }
	-- 		t["zz"] = { "zz", { "80" } }
	-- 		t["zb"] = { "zb", { "80" } }
	--
	-- 		require("neoscroll.config").set_mappings(t)
	-- 	end,
	-- })

	use({ -- fast hopping
		"phaazon/hop.nvim",
		branch = "v2",
		config = function()
			require("hop").setup({})

			vim.keymap.set("n", "<leader>h", require("hop").hint_char2, { desc = "Hop" })
		end,
	})

	use({ -- Commenting support
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})

	use({ -- Code formatting
		"mhartington/formatter.nvim",
		config = function()
			local futil = require("formatter.util")
			require("formatter").setup({
				logging = true,
				log_level = vim.log.levels.WARN,
				filetype = {
					-- Lua formatting
					lua = {
						-- "formatter.filetypes.lua" defines default configurations for the
						-- "lua" filetype
						require("formatter.filetypes.lua").stylua,

						-- You can also define your own configuration
						function()
							-- Full specification of configurations is down below and in Vim help
							-- files
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
	})

	-- List of simple snippets
	use("rafamadriz/friendly-snippets")
	use({ -- Snippet library
		"L3MON4D3/LuaSnip",
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
	})

	-- packages for using nvim-cmp completion
	use({ "saadparwaiz1/cmp_luasnip", after = "LuaSnip" })
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")
	use({
		"hrsh7th/nvim-cmp",
		after = {
			"cmp_luasnip",
			"cmp-nvim-lsp",
			"cmp-buffer",
			"cmp-path",
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
							Text = "",
							Method = "",
							Function = "",
							Constructor = "",
							Field = "",
							Variable = "",
							Class = "ﴯ",
							Interface = "",
							Module = "",
							Property = "ﰠ",
							Unit = "",
							Value = "",
							Enum = "",
							Keyword = "",
							Snippet = "",
							Color = "",
							File = "",
							Reference = "",
							Folder = "",
							EnumMember = "",
							Constant = "",
							Struct = "",
							Event = "",
							Operator = "",
							TypeParameter = "",
						}

						vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind], vim_item.kind)

						vim_item.menu = ({
							buffer = "[Buf]",
							nvim_lsp = "[LSP]",
							nvim_lua = "[Lua]",
						})[entry.source.name]

						return vim_item
					end,
				},
			})
		end,
	})

	use({ -- Special utilities for nvim lua development
		"folke/neodev.nvim",
	})

	-- (LSP, linter, etc) management with Mason
	use({
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	})
	use({
		"williamboman/mason-lspconfig.nvim",
		after = "mason.nvim",
		config = function()
			require("mason-lspconfig").setup()
		end,
	})

	-- Floating LSP status notifications at bottom of screen
	use({
		"j-hui/fidget.nvim",
		config = function()
			require("fidget").setup({})
		end,
	})

	-- Kinda janky plugin to show function signature information in LSP
	use({ "ray-x/lsp_signature.nvim" })

	-- LSP setup
	use({
		"neovim/nvim-lspconfig",
		after = {
			"mason-lspconfig.nvim",
			"cmp-nvim-lsp",
			"lsp_signature.nvim",
			"telescope.nvim",
			"nvim-navic",
			"neodev.nvim",
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

					require("lsp_signature").on_attach({}, bufnr)

					vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "[LSP] hover" })
					vim.keymap.set(
						"n",
						"<leader>s",
						vim.lsp.buf.signature_help,
						{ buffer = bufnr, desc = "[LSP] signature" }
					)

					vim.keymap.set(
						"n",
						"<leader>D",
						vim.lsp.buf.type_definition,
						{ buffer = bufnr, desc = "[LSP] go to def" }
					)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "[LSP] rename" })
					vim.keymap.set(
						"n",
						"<leader>ca",
						vim.lsp.buf.code_action,
						{ buffer = bufnr, desc = "[LSP] code actions" }
					)

					local telescope_builtin = require("telescope.builtin")

					vim.keymap.set(
						"n",
						"gd",
						telescope_builtin.lsp_definitions,
						{ desc = "[LSP] got to definition", buffer = bufnr }
					)
					vim.keymap.set(
						"n",
						"gD",
						vim.lsp.buf.declaration,
						{ desc = "[LSP] go to declaration", buffer = bufnr }
					)
					vim.keymap.set(
						"n",
						"gi",
						telescope_builtin.lsp_implementations,
						{ desc = "[LSP] go to implementation", buffer = bufnr }
					)
					vim.keymap.set(
						"n",
						"gr",
						telescope_builtin.lsp_references,
						{ desc = "[LSP] go to references", buffer = bufnr }
					)
				end

				require("lspconfig")[ls_name].setup(ls_settings)
			end
		end,
	})

	use({
		"simrat39/symbols-outline.nvim",
		opt = true,
		keys = { "<leader>o" },
		cmd = { "SymbolsOutline", "SymbolsOutlineClose", "SymbolsOutlineOpen" },
		config = function()
			require("symbols-outline").setup({
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
			})

			vim.keymap.set({ "n" }, "<leader>o", "<cmd>SymbolsOutline<cr>")
		end,
	})

	-- Telescope
	use({
		"nvim-telescope/telescope-ui-select.nvim",
		after = { "telescope.nvim" },
		config = function()
			require("telescope").load_extension("ui-select")
		end,
	})

	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.1",
		requires = { { "nvim-lua/plenary.nvim" } },
		config = function()
			require("telescope").setup({
				pickers = {
					find_files = {
						layout_strategy = "vertical",
						layout_config = {
							width = 0.8,
							height = 0.8,
						},
						path_display = function(opts, name)
							return require("my_settings").shorten_path(name)
						end,
					},
					live_grep = {
						layout_strategy = "vertical",
						layout_config = {
							width = 0.8,
							height = 0.8,
						},
						path_display = function(opts, name)
							return require("my_settings").shorten_path(name)
						end,
					},
					lsp_definitions = { theme = "cursor" },
					diagnostics = { theme = "ivy" },
					buffers = {
						theme = "ivy",
						sort_mru = true,
						mappings = {
							i = {
								["<c-d>"] = "delete_buffer",
							},
							n = {
								["<c-d>"] = "delete_buffer",
								["d"] = "delete_buffer",
							},
						},
						path_display = function(opts, name)
							return require("my_settings").shorten_path(name)
						end,
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_cursor({}),
					},
				},
			})
		end,
	})

	-- Git
	use("tpope/vim-fugitive")
	use("junegunn/gv.vim")
	use({
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
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
			})
		end,
	})

	-- Treesitter
	use({
		"nvim-treesitter/nvim-treesitter",
		run = function()
			require("nvim-treesitter.install").update({ with_sync = true })
		end,
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = require("my_settings").treesitter_settings,
				highlight = { enable = true },
				-- indent = { enable = true },
			})
		end,
	})

	use({
		"Vimjas/vim-python-pep8-indent",
	})

	use({
		"nvim-treesitter/nvim-treesitter-context",
		requires = { "nvim-treesitter/nvim-treesitter" },
		opt = true,
		config = function()
			require("treesitter-context").setup({})
		end,
	})

	use({
		"nvim-treesitter/playground",
		opt = true,
		cmd = { "TSPlaygroundToggle" },
		requires = { "nvim-treesitter/nvim-treesitter" },
	})

	use({
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
	})

	-- lualine
	use({
		"SmiteshP/nvim-navic",
		requires = "neovim/nvim-lspconfig",
		config = function()
			require("nvim-navic").setup({
				highlight = true,
				separator = "  ",
			})
		end,
	})

	use({
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
	})

	use({
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
	})

	for _, entry in ipairs({
		{ "folke/tokyonight.nvim", "tokyonight" },
		{ "savq/melange", "melange" },
		{ "rafamadriz/neon", "neon" },
		{ "rose-pine/neovim", "rose-pine" },
		{ "sainnhe/everforest", "everforest" },
		{ "rebelot/kanagawa.nvim", "kanagawa" },
		{ "olivercederborg/poimandres.nvim", "poimandres" },
	}) do
		local pack_name, scheme_name = unpack(entry)
		if scheme_name == "everforest" then
			use({
				pack_name,
				config = function()
					vim.cmd([[ colorscheme everforest ]])
				end,
			})
		else
			use(pack_name)
		end
	end

	-- neovim-remote: custom loaders to install pip package in venv
	-- Then, nvr_scripts/ will be added to PATH so that nvr can do the right thing
	use({
		"mhinz/neovim-remote",
		url = "N/A",
		installer = util.install_nvr,
		updater = util.update_nvr,
		config = function()
			vim.fn.setenv("NVIM_LISTEN_ADDRESS", vim.v.servername)
			vim.fn.setenv("PATH", vim.fn.getenv("PATH") .. ":" .. (vim.fn.stdpath("config") .. "/nvr-scripts"))
			vim.fn.setenv("EDITOR", "nvr -cc split --remote-wait")
			vim.fn.setenv("GIT_EDITOR", "nvr -cc split --remote-wait")
		end,
	})

	use({
		"numToStr/FTerm.nvim",
		config = function()
			require("FTerm").setup({})
		end,
	})

	use({
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("indent_blankline").setup({
				char = "▏",
			})
		end,
	})

	use({
		"brettanomyces/nvim-editcommand",
		config = function()
			vim.keymap.set("t", "<c-x>", "<Plug>EditCommand")
		end,
	})

	-- pretty quickfix
	use({
		"https://gitlab.com/yorickpeterse/nvim-pqf",
		config = function()
			require("pqf").setup()
		end,
	})

	-- pretty git conflicts
	use({
		"akinsho/git-conflict.nvim",
		tag = "*",
		config = function()
			require("git-conflict").setup()
		end,
	})

	-- fast fd for escape
	use({
		"max397574/better-escape.nvim",
		config = function()
			-- lua, default settings
			require("better_escape").setup({
				mapping = { "fd" }, -- a table with mappings to use
				timeout = vim.o.timeoutlen, -- the time in which the keys must be hit in ms. Use option timeoutlen by default
				clear_empty_lines = false, -- clear line after escaping if there is only whitespace
				keys = "<Esc>", -- keys used for escaping, if it is a function will use the result everytime
			})
		end,
	})

	-- use({
	-- 	"ThePrimeagen/harpoon",
	-- 	requires = { { "nvim-lua/plenary.nvim" } },
	-- 	opt = true,
	-- 	after = { "telescope.nvim" },
	-- 	keys = { "<leader>j", "<leader>k" },
	-- 	config = function()
	-- 		require("harpoon").setup({})
	-- 		require("telescope").load_extension("harpoon")
	--
	-- 		vim.keymap.set(
	-- 			"n",
	-- 			"<leader>j",
	-- 			require("harpoon.ui").toggle_quick_menu,
	-- 			{ desc = "Toggle Nvim file tree" }
	-- 		)
	-- 		vim.keymap.set("n", "<leader>k", require("harpoon.mark").add_file, { desc = "Toggle Nvim file tree" })
	-- 	end,
	-- })

	-- use_rocks("lunajson")
end)

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
		shiftwidth = 4,
		tabstop = 4,
		softtabstop = 4,
		hidden = true, -- Allows you to switch buffers without writing
		signcolumn = "yes", -- leave column on left for signs
		directory = "/usr/scratch/cwinkler/swapfiles",
		wrap = false, -- don't text-wrap by default
		-- improve V
		listchars = "tab: ,extends:>,precedes:>",
		list = true,
		shortmess = vim.o.shortmess .. "c",
		number = true, -- line numbers
		relativenumber = true, -- relative line numbers
		cursorline = true, -- line to indicate where cursor is
		colorcolumn = "100", -- colorcolumn to indicate when code is getting wide
		smartcase = true, -- case insensitive by default unless a capital letter is included
	},
	g = {
		enable_bold_font = 1,
		enable_italic_font = 1,
		mapleader = " ",
		["fern#renderer"] = "nerdfont",
	},
})

-- vim.keymap.set({ "i" }, "fd", "<Esc>") -- done by a plugin
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
vim.keymap.set("n", "<leader>m", function()
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
		if vim.v.event.operator == "y" and vim.v.event.regname == "" then
			vim.cmd([[ OSCYankReg " ]])
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

-- autosave files
local _debounced_write = util.debounce(function()
	vim.cmd("wa")
end, 5000)

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	group = augroup,
	callback = function(t)
		if vim.api.nvim_buf_get_option(t["buf"], "buftype") == "" then
			_debounced_write()
		end
	end,
})

vim.keymap.set({ "n", "v" }, ";;", require("telescope.builtin").buffers, { desc = "Select buffer" })
vim.keymap.set("n", "<leader>q", require("telescope.builtin").diagnostics, { desc = "Show All Diagnostics" })
vim.keymap.set({ "n", "i", "t" }, "<C-p>", require("telescope.builtin").find_files, { desc = "Find Files" })
vim.keymap.set({ "n", "i", "t" }, "<C-g>", require("telescope.builtin").live_grep, { desc = "Grep Files" })

-- Abbreviations
vim.cmd([[ cnoreabbrev <expr> W getcmdtype() == ":" && getcmdline() == "W" ? "w" : "W" ]])

-- overwrite the standard diagnostic signs for prettier utf-8 ones
local diagnostic_signs = {
	DiagnosticSignError = "",
	DiagnosticSignWarn = "",
	DiagnosticSignHint = "",
	DiagnosticSignInfo = "",
}

for sign_name, sign in pairs(diagnostic_signs) do
	vim.fn.sign_define(sign_name, { texthl = sign_name, text = sign, numhl = sign_name })
end
