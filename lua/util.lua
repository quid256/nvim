local vim = vim

local M = {}

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
			install_path,
		})
	end

	-- install required packages
	vim.cmd([[packadd packer.nvim]])

	local packer = require("packer")
	packer.reset()
	packer.init({
		package_root = package_root,
	})

	fn(packer.use, packer.use_rocks)

	if packer_bootstrap then
		require("packer").sync()
	end
end

function M.set_options(t)
	for opt_type, maps in pairs(t) do
		for opt, val in pairs(maps) do
			vim[opt_type][opt] = val

			if opt_type == "go" then
				vim["o"][opt] = val
			end
			if opt_type == "g" then
				vim["v"][opt] = val
			end
		end
	end
end

function M.install_nvr(display)
	local a = require("packer.async")
	local result = require("packer.result")
	local jobs = require("packer.jobs")
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
			r:and_then(
				a.wait,
				jobs.run({ venv_dir .. "/bin/python3", "-m", "pip", "install", "--upgrade", "pip" }, installer_opts)
			)
			r:and_then(
				a.wait,
				jobs.run({ venv_dir .. "/bin/python3", "-m", "pip", "install", "neovim-remote" }, installer_opts)
			)
			return r
		end
		return result.ok()
	end)
end

function M.update_nvr(display)
	local a = require("packer.async")
	local jobs = require("packer.jobs")
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
		local r = a.wait(
			jobs.run(
				{ venv_dir .. "/bin/python3", "-m", "pip", "install", "--upgrade", "neovim-remote" },
				installer_opts
			)
		)
		return r
	end)
end

function M.substitute(path, shortens)
	local p = path
	for _, m in ipairs(shortens) do
		p = string.gsub(p, m[1], m[2], 1)
	end
	return p
end

function M.debounce(fn, ms)
	local timer = vim.loop.new_timer()
	if timer == nil then
		return nil, nil
	end

	local function wrapped_fn(...)
		local argv = { ... }
		local argc = select("#", ...)

		timer:start(
			ms,
			0,
			vim.schedule_wrap(function()
				pcall(fn, unpack(argv, 1, argc))
			end)
		)
	end

	return wrapped_fn
end

function M.setup_lsp_keymaps(bufnr)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "[LSP] hover" })
	vim.keymap.set("n", "<leader>s", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "[LSP] signature" })

	vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, { buffer = bufnr, desc = "[LSP] go to def" })
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "[LSP] rename" })
	vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "[LSP] code actions" })

	local telescope_builtin = require("telescope.builtin")

	vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, { desc = "[LSP] got to definition", buffer = bufnr })
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "[LSP] go to declaration", buffer = bufnr })
	vim.keymap.set(
		"n",
		"gi",
		telescope_builtin.lsp_implementations,
		{ desc = "[LSP] go to implementation", buffer = bufnr }
	)
	vim.keymap.set("n", "gr", telescope_builtin.lsp_references, { desc = "[LSP] go to references", buffer = bufnr })
end

return M
