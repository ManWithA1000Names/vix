{ pkgs }:
let
  ls = pkgs.lua-language-server.overrideAttrs
    (finalAttrs: previousAttrs: { name = "lua_ls"; });
in {
  inherit ls;
  language = "lua";
  ls_options = {
    cmd = [ (pkgs.lib.getExe ls) ];
    settings = {
      Lua = {
        diagnostics = { globals = [ "vim" ]; };
        workspace = {
          library = {
            ${"[vim.fn.expand($VIMRUNTIME/lua)]"} = true;
            ${''[vim.fn.stdpath("config") .. /lua]''} = true;
            ${''[vim.fn.stdpath("config") .. /plugin]''} = true;
            ${''[vim.fn.stdpath("config") .. /after/plugin]''} = true;
          };
        };
      };
    };
  };

  linters = pkgs.selene;
  formatters = pkgs.stylua;
}
