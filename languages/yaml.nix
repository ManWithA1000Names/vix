{ pkgs, rename }: rec {
  language = "yaml";
  ls = rename { pkg = pkgs.yaml-language-server; name = "yamlls"; exe = "yaml-language-server"; };
  ls_options = {
    cmd = [ (pkgs.lib.getExe ls) ];
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
  linters = [ pkgs.actionlint pkgs.yamllint ];
}
