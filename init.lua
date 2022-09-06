local util = require("util")

-- Load the configuration file, falling back on the default config if it doesn't exist
CONFIG = util.load_config()

-- load packages
util.packer_load(function(use)
    -- packer.nvim itself
    use "wbthomason/packer.nvim"

    -- various editing tasks
    use "godlygeek/tabular" -- tables
    use "romainl/vim-cool" -- :noh automatically after search is stopped
    use "ojroques/vim-oscyank" -- yank using OSC character, interop with clipboard
    -- use "m4xshen/autoclose.nvim" -- auto-close delimiters
    use {
        "karb94/neoscroll.nvim",
        config = function()
            require("neoscroll").setup {}
            local t = {}

            -- Syntax: t[keys] = {function, {function arguments}}
            t['<C-u>'] = { 'scroll', { '-vim.wo.scroll', 'true', '80' } }
            t['<C-d>'] = { 'scroll', { 'vim.wo.scroll', 'true', '80' } }
            t['<C-b>'] = { 'scroll', { '-vim.api.nvim_win_get_height(0)', 'true', '160' } }
            t['<C-f>'] = { 'scroll', { 'vim.api.nvim_win_get_height(0)', 'true', '160' } }
            t['<C-y>'] = { 'scroll', { '-0.10', 'false', '50' } }
            t['<C-e>'] = { 'scroll', { '0.10', 'false', '50' } }
            t['zt']    = { 'zt', { '80' } }
            t['zz']    = { 'zz', { '80' } }
            t['zb']    = { 'zb', { '80' } }

            require('neoscroll.config').set_mappings(t)
        end
    }
    use {
        "phaazon/hop.nvim",
        branch = "v2",
        config = function()
            require("hop").setup {}
        end
    }
    use {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup {}
        end
    }

    -- Tab-completion
    use "hrsh7th/vim-vsnip"
    use { "hrsh7th/cmp-vsnip", after = "vim-vsnip" }
    use "hrsh7th/cmp-nvim-lsp"
    use "hrsh7th/cmp-buffer"
    use "hrsh7th/cmp-path"
    use { "hrsh7th/nvim-cmp",
        after = { "cmp-vsnip", "cmp-nvim-lsp", "cmp-buffer", "cmp-path" },
        config = function()
            local cmp = require("cmp")
            cmp.setup {
                snippet = {
                    expand = function(args)
                        vim.fn["vsnip#anonymous"](args.body)
                    end
                },
                mapping = cmp.mapping.preset.insert {
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                },
                sources = cmp.config.sources {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                },
                formatting = {
                    format = function(entry, vim_item)
                        local kind_icons = {
                            Text = "", Method = "", Function = "", Constructor = "",
                            Field = "", Variable = "", Class = "ﴯ", Interface = "",
                            Module = "", Property = "ﰠ", Unit = "", Value = "",
                            Enum = "", Keyword = "", Snippet = "", Color = "",
                            File = "", Reference = "", Folder = "", EnumMember = "",
                            Constant = "", Struct = "", Event = "", Operator = "",
                            TypeParameter = ""
                        }

                        vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind], vim_item.kind)

                        vim_item.menu = ({
                            buffer   = "[Buf]",
                            nvim_lsp = "[LSP]",
                            nvim_lua = "[Lua]",
                        })[entry.source.name]

                        return vim_item
                    end
                }
            }
        end }

    if CONFIG.langs["lua"] then
        use { "folke/lua-dev.nvim" }
    end

    -- package (LSP, linter, etc) management with Mason
    use {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end
    }
    use {
        "williamboman/mason-lspconfig.nvim",
        after = "mason.nvim",
        config = function()
            require("mason-lspconfig").setup()
        end
    }

    -- Floating LSP status notifications at bottom of screen
    use {
        "j-hui/fidget.nvim",
        config = function()
            require("fidget").setup {}
        end
    }

    -- LSP
    use {
        "neovim/nvim-lspconfig",
        after = {
            "mason-lspconfig.nvim",
            "cmp-nvim-lsp",
            "telescope.nvim",
            "nvim-navic",
            unpack(CONFIG.langs["lua"] and { "lua-dev.nvim" } or {})
        },
        config = function()
            vim.lsp.stop_client(vim.lsp.get_active_clients(), true)

            local cmp_capabilities = require("cmp_nvim_lsp").update_capabilities(
                vim.lsp.protocol.make_client_capabilities()
            )

            local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

            for lang, cfg in pairs(CONFIG.lsp_configs) do
                if not CONFIG.langs[lang] then
                    goto continue
                end

                local ls_name = cfg[1]
                local ls_settings = cfg[2]

                if lang == "lua" then
                    ls_settings = vim.tbl_extend(
                        "keep",
                        require("lua-dev").setup({}) or {},
                        ls_settings or {}
                    )
                end

                ls_settings.capabilities = vim.tbl_extend(
                    "keep",
                    ls_settings.capabilities or {},
                    cmp_capabilities or {}
                )

                ls_settings["on_attach"] = function(client, bufnr)
                    require("nvim-navic").attach(client, bufnr)

                    if client.supports_method("textDocument/formatting") then
                        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = augroup,
                            buffer = bufnr,
                            callback = function()
                                -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead

                                ---@diagnostic disable-next-line: missing-parameter
                                vim.lsp.buf.formatting_sync()
                            end,
                        })
                    end

                    local bufopts = function(a)
                        return vim.tbl_extend("keep", a, { noremap = true, silent = true, buffer = bufnr })
                    end
                    local telescope_builtin = require("telescope.builtin")

                    vim.keymap.set('n', 'gd', telescope_builtin.lsp_definitions,
                        bufopts { desc = "[LSP] got to definition" })
                    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration,
                        bufopts { desc = "[LSP] go to declaration" })
                    vim.keymap.set('n', 'gi', telescope_builtin.lsp_implementations,
                        bufopts { desc = "[LSP] go to implementation" })
                    vim.keymap.set('n', 'gr', telescope_builtin.lsp_references,
                        bufopts { desc = "[LSP] go to references" })

                    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts {})
                    vim.keymap.set('n', '<leader>s', vim.lsp.buf.signature_help, bufopts {})
                    -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
                    -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
                    -- vim.keymap.set('n', '<space>wl', function()
                    --     print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                    -- end, bufopts)
                    vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts {})
                    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts { desc = "[LSP] rename" })
                    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts { desc = "[LSP] code actions" })
                    vim.keymap.set('n', '<leader>f', vim.lsp.buf.formatting, bufopts { desc = "[LSP] format buffer" })
                    vim.keymap.set('v', '<leader>f', vim.lsp.buf.range_formatting,
                        bufopts { desc = "[LSP] format range" })
                end

                require("lspconfig")[ls_name].setup(ls_settings)

                ::continue::
            end
        end
    }

    use { "simrat39/symbols-outline.nvim",
        config = function()
            require("symbols-outline").setup {}
        end
    }

    -- Telescope
    use { "nvim-telescope/telescope-ui-select.nvim", config = function()
        require("telescope").load_extension("ui-select")
    end }

    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } },
        -- after = { "telescope-ui-select.nvim" },
        config = function()
            -- local themes = require("telescope.themes")
            require('telescope').setup {
                pickers = {
                    -- live_grep={theme=require("telescope.themes").get_dropdown{}},
                    -- lsp_references={theme=require("telescope.themes").get_dropdown{}},
                    lsp_definitions = { theme = "cursor" },
                    diagnostics = { theme = "ivy" },
                    buffers = {
                        theme = "ivy",
                        sort_mru = true,
                        ignore_current_buffer = true,
                    },
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_cursor {}
                    }
                }
            }

        end
    }

    -- Git
    use "tpope/vim-fugitive"
    use {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup {
                current_line_blame = true,
                current_line_blame_opts = {
                    delay = 700,
                }
            }
        end
    }

    -- Treesitter
    use {
        "nvim-treesitter/nvim-treesitter",
        run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
        config = function()
            local feats_to_lang = {
                lang_lua = "lua",
                lang_python = "python",
                lang_go = "go",
                lang_rust = "rust",
            }

            local langs_to_install = {}
            for feat, lang in pairs(feats_to_lang) do
                if CONFIG.langs[feat] then
                    table.insert(langs_to_install, lang)
                end
            end

            require("nvim-treesitter.configs").setup {
                ensure_installed = langs_to_install,
                highlight = { enable = true },
                indent = { enable = true },
            }
        end
    }

    use {
        "nvim-treesitter/nvim-treesitter-context",
        requires = { "nvim-treesitter/nvim-treesitter" },
        opt = true,
        config = function() require("treesitter-context").setup {} end
    }


    -- lualine
    use {
        "SmiteshP/nvim-navic",
        requires = "neovim/nvim-lspconfig",
        config = function()
            require("nvim-navic").setup {
                separator = "  "
            }
        end
    }

    use {
        "nvim-lualine/lualine.nvim",
        requires = { "kyazdani42/nvim-web-devicons", opt = true },
        after = { "nvim-navic" },
        config = function()
            require("lualine").setup {
                options = {
                    icons_enabled = true,
                    theme = 'auto',
                    section_separators = { left = '', right = '' },
                    component_separators = "|",
                    disabled_filetypes = {},
                    always_divide_middle = true,
                },
                tabline = {
                    lualine_c = { function()
                        return require("nvim-navic").get_location {}
                    end }
                },
                sections = {
                    lualine_a = { 'mode' },
                    lualine_b = { 'diff', 'diagnostics' },
                    lualine_c = { 'filename' },
                    lualine_x = { 'filetype' },
                    lualine_y = { 'branch' },
                    lualine_z = { 'location' },
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { 'filename' },
                    lualine_x = {},
                    lualine_y = {},
                    lualine_z = { 'location' },
                },
            }
        end
    }

    -- null-ls
    -- use {"jose-elias-alvarez/null-ls.nvim", config= function()
    --     require("null-ls").setup({
    --         sources = {
    --             require("null-ls").builtins.formatting.stylua,
    --         },
    --     })
    -- end}
    --

    use {
        "folke/which-key.nvim",
        config = function()
            require("which-key").setup {
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
                triggers = { "<leader>", "g", "z" }
            }
        end
    }


    -- color schemes
    use {
        "folke/tokyonight.nvim",
        cond = function() return CONFIG.colorscheme == "tokyonight" end,
        config = function()
            vim.cmd 'colorscheme tokyonight'
        end
    }
    use {
        "savq/melange",
        cond = function() return CONFIG.colorscheme == "melange" end,
        config = function()
            vim.cmd 'colorscheme melange'
        end
    }
    use {
        "EdenEast/nightfox.nvim",
        cond = function() return CONFIG.colorscheme == "nightfox" end,
        config = function()
            vim.cmd 'colorscheme nightfox'
        end
    }

    -- neovim-remote: custom loaders to install pip package in venv
    -- Then, nvr_scripts/ will be added to PATH so that nvr can do the right thing
    use {
        "mhinz/neovim-remote",
        url = "N/A",
        installer = util.install_nvr,
        updater = util.update_nvr,
        config = function()
            vim.fn.setenv("NVIM_LISTEN_ADDRESS", vim.v.servername)
            vim.fn.setenv("PATH", vim.fn.getenv("PATH") .. ":" .. (vim.fn.stdpath("config") .. "/nvr-scripts"))
            vim.fn.setenv("EDITOR", "nvr")
            vim.fn.setenv("EDITOR", "nvr -cc split --remote-wait")
        end
    }

    use {
        "numToStr/FTerm.nvim",
        config = function()
            require "FTerm".setup {}
        end
    }


end)

-- options
-- (use `:Tab /=` to align everything nicely)
util.set_options({
    go = vim.tbl_extend("keep", CONFIG.editor_opts.go or {}, {
        encoding       = "utf-8",
        scrolloff      = 2, -- keep 2 rows between cursor and end of screen
        mouse          = "a", -- correct mouse interaction
        modeline       = true,
        pastetoggle    = "<Insert>", -- use <Insert> to enter paste mode
        termguicolors  = true, -- do colors good
        completeopt    = "menu,menuone,noselect",
        expandtab      = true, -- convert tab character to spaces
        shiftwidth     = 4,
        tabstop        = 4,
        softtabstop    = 4,
        hidden         = true, -- Allows you to switch buffers without writing
        signcolumn     = "yes", -- leave column on left for signs
        -- directory  = here
        wrap           = false, -- don't text-wrap by default
        -- improve V
        listchars      = "tab: ,extends:>,precedes:>",
        list           = true,
        shortmess      = vim.o.shortmess .. "c",
        number         = true, -- line numbers
        relativenumber = true, -- relative line numbers
        cursorline     = true, -- line to indicate where cursor is
        colorcolumn    = "99", -- colorcolumn to indicate when code is getting wide
    }),
    g = vim.tbl_extend("keep", CONFIG.editor_opts.g or {}, {
        enable_bold_font = 1,
        enable_italic_font = 1,
        mapleader = " ",
        ["fern#renderer"] = "nerdfont",
    })
})


local function keymap_set(mode, from, to, overrides)
    if type(mode) == "table" then
        for _, m in ipairs(mode) do
            keymap_set(m, from, to, overrides)
        end
        return
    end

    vim.keymap.set(mode, from, to, vim.tbl_extend("keep", overrides or {}, {
        noremap = true,
        silent = true,
    }))
end

keymap_set({ "i", "t", "v" }, "fd", "<Esc>")
keymap_set({ "n", "v" }, ";", ":")
keymap_set({ "n", "v" }, ";;", require("telescope.builtin").buffers, { desc = "Select buffer" })
keymap_set({ "n", "i", "t" }, "<C-p>", require("telescope.builtin").find_files, { desc = "Find Files" })
keymap_set({ "n", "i", "t" }, "<C-f>", require("telescope.builtin").live_grep, { desc = "Grep Files" })

keymap_set("n", "<C-h>", "<C-w><C-h>")
keymap_set("n", "<C-j>", "<C-w><C-j>")
keymap_set("n", "<C-k>", "<C-w><C-k>")
keymap_set("n", "<C-l>", "<C-w><C-l>")

keymap_set({ "n", "t" }, "<C-t>", require("FTerm").toggle, { desc = "Toggle FTerm" })

keymap_set("n", "<leader>ps", require("packer").sync, { desc = "Packer Sync" })
keymap_set("n", "<leader>pc", require("packer").compile, { desc = "Packer Compile" })
keymap_set("n", "<leader>px", require("packer").clean, { desc = "Packer Clean" })
keymap_set("n", "<leader>p?", require("packer").status, { desc = "Packer Status" })

keymap_set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show Diagnostic" })
keymap_set("n", "<leader>q", require("telescope.builtin").diagnostics, { desc = "Show All Diagnostics" })
keymap_set("n", "<leader>v", "<cmd>G<CR>", { desc = "Git menu" })
keymap_set("n", "<leader>h", require 'hop'.hint_char2, { desc = "Hop" })

-- override fFtT to use Hop intead
keymap_set('', 'f', function()
    require 'hop'.hint_char1({
        direction = require 'hop.hint'.HintDirection.AFTER_CURSOR,
        current_line_only = true
    })
end)
keymap_set('', 'F', function()
    require 'hop'.hint_char1({
        direction = require 'hop.hint'.HintDirection.BEFORE_CURSOR,
        current_line_only = true
    })
end)
keymap_set('', 't', function()
    require 'hop'.hint_char1({
        direction = require 'hop.hint'.HintDirection.AFTER_CURSOR,
        current_line_only = true,
        hint_offset = -1,
    })
end)
keymap_set('', 'T', function()
    require 'hop'.hint_char1({
        direction = require 'hop.hint'.HintDirection.BEFORE_CURSOR,
        current_line_only = true,
        hint_offset = 1,
    })
end)


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
            vim.cmd [[ OSCYankReg " ]]
        end
    end,
})

-- Abbreviations
vim.cmd [[ cnoreabbrev <expr> W getcmdtype() == ":" && getcmdline() == "W" ? "w" : "W" ]]
