{ pkgs, rename }: rec {
  language = "json";
  ls = rename { pkg = pkgs.nodePackages.vscode-json-languageserver; name = "jsonls"; exe = "json-languageserver"; };
  ls_options = {
    cmd = [ (pkgs.lib.getExe ls) ];
    settings = {
      json = {
        schemas = _: ''(function()
          local ok, schemastore = pcall(require, "schemastore")
          if not ok then return {} end
          return schemastore.json.schemas()
        end)()'';
        validate = { enable = true; };
      };
    };
  };
}
