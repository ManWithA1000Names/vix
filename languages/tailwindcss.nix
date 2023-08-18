{ pkgs }:
let
  ls = pkgs.nodePackages.tailwindcss.overrideAttrs (final: prev: { name = "tailwindcss"; });
in
{
  language = "tailwindcss";
  inherit ls;
  ls_options = {
    cmd = [ ls "--stdio" ];
    filetypes = _: ''(function()
      local types = {"elm"};
      for _,type in ipairs(lspconfig.tailwindcss.filetypes) do
        table.insert(types, type)
      end
      return types
    end)()'';
    settings = {
      tailwindcss = {
        experimental = {
          classRegex = [
            "\\bclass[\\s(<|]+\"([^\"]*)\""
            "\\bclass[\\s(]+\"[^\"]*\"[\\s+]+\"([^\"]*)\""
            "\\bclass[\\s<|]+\"[^\"]*\"\\s*\\+{2}\\s*\" ([^\"]*)\""
            "\\bclass[\\s<|]+\"[^\"]*\"\\s*\\+{2}\\s*\" [^\"]*\"\\s*\\+{2}\\s*\" ([^\"]*)\""
            "\\bclass[\\s<|]+\"[^\"]*\"\\s*\\+{2}\\s*\" [^\"]*\"\\s*\\+{2}\\s*\" [^\"]*\"\\s*\\+{2}\\s*\" ([^\"]*)\""
            "\\bclassList[\\s\\[\\(]+\"([^\"]*)\""
            "\\bclassList[\\s\\[\\(]+\"[^\"]*\",\\s[^\\)]+\\)[\\s\\[\\(,]+\"([^\"]*)\""
            "\\bclassList[\\s\\[\\(]+\"[^\"]*\",\\s[^\\)]+\\)[\\s\\[\\(,]+\"[^\"]*\",\\s[^\\)]+\\)[\\s\\[\\(,]+\"([^\"]*)\""
          ];
        };
      };
    };
  };
}
