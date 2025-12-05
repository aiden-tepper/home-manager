return {
	'mrcjkb/rustaceanvim',
	version = '^6', -- Recommended
	lazy = false,  -- This plugin is already lazy
	config = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "rust",
			callback = function()
				local bufnr = vim.api.nvim_get_current_buf()
				-- who needs code actions!!
				-- vim.keymap.set(
				-- 	"n",
				-- 	"<leader>a",
				-- 	function()
				-- 		vim.cmd.RustLsp('codeAction') -- supports rust-analyzer's grouping
				-- 	end,
				-- 	{ silent = true, buffer = bufnr }
				-- )
				vim.keymap.set(
					"n",
					"K", -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
					function()
						vim.cmd.RustLsp({ 'hover', 'actions' })
					end,
					{ silent = true, buffer = bufnr }
				)
			end,
		})
		vim.g.rustaceanvim = {
			tools = {
				-- Enable or disable specific tools/features
				debuggables = true,
				runnables = true,
				testables = true,
				code_actions = {
					grouped = true,
					ui_select_fallback = false,
				},
				hover = {
					auto_focus = false,
				},
			},
			server = {
				on_attach = function(client, bufnr)
					-- Additional keybindings or settings can be added here
					vim.keymap.set("n", "<leader>c", "<cmd>RustLsp flyCheck<CR>", { silent = true, buffer = bufnr })
				end,
				default_settings = {
					['rust-analyzer'] = {
						linkedProjects = {
							"/workspaces/mono-repo/rust-project.json",
						},
						cargo = {
							allFeatures = true,
						},
						procMacro = {
							enable = true,
						},
						checkOnSave = false,
						check = {
							-- command = "clippy",
							overrideCommand = { "/workspaces/mono-repo/.devcontainer/localconfig/nvim/bazel-clippy-driver.sh" },
						},
						inlayHints = {
							typeHints = {
								enable = true,
							},
							chainingHints = {
								enable = true,
							},
						},
					},
				},
			},
			dap = {
				-- DAP configuration if using debugging features
			},
		}
		-- toggle inlay hints
		vim.keymap.set("n", "<leader>h", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
		end, { desc = "Toggle Inlay Hints" })
	end,
}
