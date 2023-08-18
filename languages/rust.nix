{ pkgs }: {
  language = "rust";
  setup_ls = ''
        local ok, rust = pcall(require, "rust-tools")
        if not ok then
          return
        end
        rust.setup({
    			tools = {
    				executor = require("rust-tools/executors").termopen, -- can be quickfix or termopen
    				reload_workspace_from_cargo_toml = true,
    				runnables = {
    					use_telescope = true,
    				},
    				inlay_hints = {
    					auto = false,
    				},
    				hover_actions = {
    					border = "rounded",
    				},
    				on_initialized = function()
    					vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "CursorHold", "InsertLeave" }, {
    						pattern = { "*.rs" },
    						callback = function()
    							local _, _ = pcall(vim.lsp.codelens.refresh)
    						end,
    					})
    				end,
    			},
    			dap = {
    				adapter = codelldb_adapter,
    			},
    			server = {
            cmd = {"${pkgs.lib.getExe pkgs.rust-analyzer}"},
    				settings = {
    					["rust-analyzer"] = {
    						lens = {
    							enable = true,
    						},
    						checkOnSave = {
    							enable = true,
    							command = "clippy",
    						},
    					},
    				},
    			},
        })
  '';
}
