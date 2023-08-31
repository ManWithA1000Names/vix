pkgs: [
  {
    type = "language-server";
    pkg = pkgs.yaml-language-server;
    name = "yamlls";
    exe = "yaml-language-server";
    disable_ls_format = true;
    options = {
      settings = {
        yaml = {
          schemaStore = {
            enable = true;
            url = "";
          };
          schemas = _: ''(function()
            local ok, schemastore = pcall(require, "schemastore")
            if not ok then return {} end
            return schemastore.yaml.schemas()
          end)()'';
        };
      };
    };
  }
  {
    type = "diagnostics";
    pkg = pkgs.actionlint;
  }
  {
    type = "diagnostics";
    pkg = pkgs.yamllint;
  }
  {
    type = "formatting";
    pkg = pkgs.nodePackages.prettier;
    exe = "prettier";
  }
]
