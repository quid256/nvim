local M = {}

local function parse_stderr(stderr, bufnr)
	local diagnostics = {}
	for _, linenr_str, message in stderr:gmatch("([^\n]):(%d+):%s([^\n]+)\n") do
		local linenr = tonumber(linenr_str) - 1
		local line_contents = vim.api.nvim_buf_get_lines(bufnr, linenr, linenr + 1, false)[1]

		table.insert(diagnostics, {
			bufnr = bufnr,
			lnum = linenr,
			col = 0,
			end_col = #line_contents,
			message = message,
		})
	end
	return diagnostics
end

local function lines_iterator()
	local G = {}
	local resid = ""

	function G.feed(s)
		local i = 1
		s = resid .. s

		return function()
			local indexstart, indexend = s:find("\r*\n", i)
			if indexstart == nil then
				resid = s:sub(i)
				return nil
			end

			local res = s:sub(i, indexstart - 1)
			i = indexend + 1

			return res
		end
	end

	function G.resid()
		return resid
	end

	return G
end

function M.bean_check(bufnr, set_qflist)
	local handle
	local stderr_chunks = {}

	local ns = vim.api.nvim_create_namespace("cwinkler.beancount")

	local on_exit = function(status)
		vim.loop.close(handle)

		local full_stderr = table.concat(stderr_chunks)

		vim.schedule(function()
			local diags = parse_stderr(full_stderr, bufnr)
			vim.diagnostic.set(ns, bufnr, diags)

			if set_qflist ~= nil then
				vim.diagnostic.setqflist(vim.tbl_extend("force", { namespace = ns }, set_qflist))
			end
		end)
	end

	local stderr = vim.loop.new_pipe()

	handle = vim.loop.spawn("venv/bin/bean-check", {
		args = { vim.api.nvim_buf_get_name(bufnr) },
		stdio = { nil, nil, stderr },
	}, on_exit)

	vim.loop.read_start(stderr, function(err, data)
		assert(not err, err)
		if data then
			table.insert(stderr_chunks, data)
		end
	end)
end

function M.bean_report(bufnr)
	local handle
	local lines = {}

	local on_exit = function(status)
		vim.loop.close(handle)

		vim.schedule(function()
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
			vim.cmd("write!")
			M.bean_format(bufnr)
		end)
	end

	local stdout = vim.loop.new_pipe()

	handle = vim.loop.spawn("venv/bin/bean-report", {
		args = { vim.api.nvim_buf_get_name(bufnr), "print" },
		stdio = { nil, stdout, nil },
	}, on_exit)

	local liter = lines_iterator()

	vim.loop.read_start(stdout, function(err, data)
		assert(not err, err)
		if data then
			for line in liter.feed(data) do
				table.insert(lines, line)
			end
		end
	end)
end

function M.bean_format(bufnr)
	local handle
	local cur_buf_lines_iter, t, i = ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))

	local diff_start = -1
	local diffed_line_chunk = {}
	local all_diffs = {}

	local on_exit = function(status)
		vim.loop.close(handle)

		if #diffed_line_chunk > 0 then
			table.insert(all_diffs, {
				index = diff_start,
				new_lines = diffed_line_chunk,
			})
		end

		vim.schedule(function()
			for _, k in ipairs(all_diffs) do
				vim.api.nvim_buf_set_lines(bufnr, k.index - 1, k.index - 1 + #k.new_lines, false, k.new_lines)
			end
			print("Beancount formatted!")
		end)
	end

	local stdout = vim.loop.new_pipe()

	handle = vim.loop.spawn("venv/bin/bean-format", {
		args = { vim.api.nvim_buf_get_name(bufnr) },
		stdio = { nil, stdout, nil },
	}, on_exit)

	local liter = lines_iterator()

	vim.loop.read_start(stdout, function(err, data)
		assert(not err, err)
		if data then
			for next_formatted in liter.feed(data) do
				local next_existing
				i, next_existing = cur_buf_lines_iter(t, i)

				if next_formatted == next_existing then
					if #diffed_line_chunk > 0 then
						table.insert(all_diffs, {
							index = diff_start,
							new_lines = diffed_line_chunk,
						})
						diff_start = -1
						diffed_line_chunk = {}
					end
				else
					if #diffed_line_chunk == 0 then
						diff_start = i
					end

					table.insert(diffed_line_chunk, next_formatted)
				end
			end
		end
	end)
end

M.ident_set = {}

function M.bean_load_idents(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for _, line in ipairs(lines) do
		for m in line:gmatch("[^%s]+:[^%s]+") do
			M.ident_set[m] = true
		end
	end
end

function M.bean_clear_idents()
	M.ident_set = {}
end

function M.bean_pick_ident(callback)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local ident_table = {}
	for k, _ in pairs(M.ident_set) do
		table.insert(ident_table, k)
	end

	-- our picker function: colors
	local colors = function(opts)
		opts = opts or {}
		pickers
			.new(opts, {
				prompt_title = "colors",
				finder = finders.new_table({
					results = ident_table,
				}),
				sorter = conf.generic_sorter(opts),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = action_state.get_selected_entry()
						if callback == nil then
							vim.api.nvim_put({ selection[1] }, "", false, true)
						else
							callback(selection[1])
						end
					end)
					return true
				end,
			})
			:find()
	end

	-- to execute the function
	colors()
end

function M.setup()
	local augroup = vim.api.nvim_create_augroup("beancount_utils", { clear = true })

	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		group = augroup,
		pattern = { "*.beancount", "*.bean" },
		callback = function()
			vim.keymap.set("n", "<leader>bc", function()
				M.bean_check(0, { open = true })
			end)

			vim.keymap.set("n", "<leader>bf", function()
				vim.cmd("write!")
				M.bean_format(0)
			end)

			vim.keymap.set("n", "<leader>br", function()
				vim.cmd("write!")
				M.bean_report(0)
			end)

			vim.keymap.set("n", "<leader>bi", function()
				M.bean_load_idents(0)
			end)

			vim.keymap.set("n", "<leader>bp", function()
				M.bean_pick_ident()
			end)
		end,
	})

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		pattern = { "*.beancount", "*.bean" },
		callback = function(t)
			M.bean_check(t["buf"], { open = false })
		end,
	})
end

return M
