{ pkgs, rename }:
let
  ls = rename { pkg = pkgs.lua-language-server; name = "lua_ls"; exe = "lua-language-server"; };
in
{
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
