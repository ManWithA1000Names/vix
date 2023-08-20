pkgs: [
  {
    type = "language-server";
    pkg = pkgs.nodePackages.vscode-json-languageserver;
    name = "jsonls";
    exe = "vscode-json-languageserver";
    options = {
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
  {
    type = "formatting";
    pkg = pkgs.nodePackages.prettier;
    exe = "prettier";
  }
]
