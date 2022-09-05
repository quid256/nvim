local util = require("util")

-- Load the configuration file, falling back on the default config if it doesn't exist
CONFIG = util.load_config()

-- load packages
util.packer_load(function(use)
    -- packer.nvim itself
    use "wbthomason/packer.nvim"

    -- table alignment
    use "godlygeek/tabular"

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
    use { "neovim/nvim-lspconfig",
        after = { "mason-lspconfig.nvim", "cmp-nvim-lsp", "lua-dev.nvim", "telescope.nvim" },
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
                    if client.supports_method("textDocument/formatting") then
                        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = augroup,
                            buffer = bufnr,
                            callback = function()
                                -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
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
                    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts {})
                    -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
                    -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
                    -- vim.keymap.set('n', '<space>wl', function()
                    --     print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                    -- end, bufopts)
                    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts {})
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

    -- Telescope
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } },
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
                }
            }
        end
    }


    -- Git
    use { "lewis6991/gitsigns.nvim", config = function()
        require("gitsigns").setup()
    end }

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
        config = function()
            require("treesitter-context").setup {}
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

    --
    use {
        "folke/which-key.nvim",
        config = function()
            require("which-key").setup {}
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
end)

-- options
-- (use `:Tab /=` to align everything nicely)
util.set_options({
    go = vim.tbl_extend("keep", CONFIG.editor_opts.go or {}, {
        encoding      = "utf-8",
        scrolloff     = 2,
        mouse         = "a", -- correct mouse interaction
        modeline      = true,
        pastetoggle   = "<Insert>", -- use <Insert> to enter paste mode
        termguicolors = true, -- do colors good
        completeopt   = "menu,menuone,noselect",
        expandtab     = true, -- convert tab character to spaces
        shiftwidth    = 4,
        tabstop       = 4,
        softtabstop   = 4,
        hidden        = true, -- Allows you to switch buffers without writing
        signcolumn    = "yes",
        -- directory  = here
        wrap          = false,
        -- improve V
        listchars     = "tab: ,extends:>,precedes:>",
        list          = true,
        shortmess     = vim.o.shortmess .. "c",
        number        = true,
        cursorline    = true,
        colorcolumn   = "99",
    }),
    g = vim.tbl_extend("keep", CONFIG.editor_opts.g or {}, {
        enable_bold_font = 1,
        enable_italic_font = 1,
        mapleader = " ",
        ["fern#renderer"] = "nerdfont",
    })
})


vim.cmd [[inoremap fd <Esc>]]
