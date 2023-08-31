pkgs: [
  {
    type = "language-server";
    pkg = pkgs.lua-language-server;
    name = "lua_ls";
    exe = "lua-language-server";
    disable_ls_format = true;
    options = {
      settings = {
        Lua = {
          diagnostics = { globals = [ "vim" ]; };
          workspace = {
            library = {
              ${''[vim.fn.expand("$VIMRUNTIME/lua")]''} = true;
              ${''[vim.fn.stdpath("config") .. "/lua"]''} = true;
              ${''[vim.fn.stdpath("config") .. "/plugin"]''} = true;
              ${''[vim.fn.stdpath("config") .. "/after/plugin"]''} = true;
            };
          };
        };
      };
    };
  }
  {
    type = "diagnostics";
    pkg = pkgs.selene;
    exe = "selene";
  }
  {
    type = "formatting";
    pkg = pkgs.stylua;
    exe = "stylua";
  }
]
