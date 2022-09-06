local vim = vim

local a = require "packer.async"
local result = require "packer.result"
local jobs = require "packer.jobs"

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

function M.install_nvr(display)
    local pkg_dir = vim.fn.stdpath("config") .. "/pack/packer/start/neovim-remote"
    if vim.fn.empty(vim.fn.glob(pkg_dir)) > 0 then
        vim.fn.mkdir(pkg_dir, "p")
    end
    local venv_dir = pkg_dir .. "/venv"


    local output = jobs.output_table()
    local callbacks = {
        stdout = jobs.logging_callback(output.err.stdout, output.data.stdout),
        stderr = jobs.logging_callback(output.err.stderr, output.data.stderr, nil, display, "mhinz/neovim-remote"),
    }

    local installer_opts = {
        capture_output = callbacks,
    }


    return a.sync(function()
        if vim.fn.empty(vim.fn.glob(venv_dir)) > 0 then
            display:task_update("creating venv...", "mhinz/neovim-remote")
            local r = a.wait(jobs.run({ "python3", "-m", "venv", venv_dir }, installer_opts))
            r:and_then(a.wait,
                jobs.run({ venv_dir .. "/bin/python3", "-m", "pip", "install", "--upgrade", "pip" }, installer_opts))
            r:and_then(a.wait,
                jobs.run({ venv_dir .. "/bin/python3", "-m", "pip", "install", "neovim-remote" }, installer_opts))
            return r
        end
        return result.ok()
    end)
end

function M.update_nvr(display)
    local venv_dir = vim.fn.stdpath("config") .. "/pack/packer/start/neovim-remote/venv"

    local output = jobs.output_table()
    local callbacks = {
        stdout = jobs.logging_callback(output.err.stdout, output.data.stdout),
        stderr = jobs.logging_callback(output.err.stderr, output.data.stderr, nil, display, "mhinz/neovim-remote"),
    }

    local installer_opts = {
        capture_output = callbacks,
    }

    return a.sync(function()
        local r = a.wait(jobs.run({ venv_dir .. "/bin/python3", "-m", "pip", "install", "--upgrade", "neovim-remote" },
            installer_opts))
        return r
    end)
end

return M
