local vim = vim

local M = {}

-- Attempt to load the configuration from config.lua.
-- If not found, will load default_config.lua instead.
function M.load_config()
    package.loaded["config"] = nil
    package.loaded["default_config"] = nil

    local ok, cfg = pcall(require, "config")
    if not ok then
        if string.find(cfg, "module 'config' not found") then
            cfg = require("default_config")
        else
            error(cfg)
        end
    end
    return cfg
end

-- Bootstraps a packer.nvim installation and installs the specified packages.
-- Inspired by:
--      https://github.com/wbthomason/packer.nvim#bootstrapping
function M.packer_load(fn)
    -- bootstrap packer.nvim
    local package_root = vim.fn.stdpath("config") .. "/pack"
    local install_path = package_root .. "/packer/start/packer.nvim"
    local packer_bootstrap

    if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
        packer_bootstrap = vim.fn.system({
            "git",
            "clone",
            "--depth",
            "1",
            "https://github.com/wbthomason/packer.nvim",
            install_path
        })
    end

    -- install required packages
    vim.cmd [[packadd packer.nvim]]

    local packer = require("packer")
    packer.reset()
    packer.init({
        package_root = package_root
    })

    fn(packer.use)
    
    if packer_bootstrap then
        require("packer").sync()
    end
    
end

function M.set_options(t)
    for opt_type, maps in pairs(t) do
        for opt, val in pairs(maps) do
             vim[opt_type][opt] = val
	end
    end
end

return M

