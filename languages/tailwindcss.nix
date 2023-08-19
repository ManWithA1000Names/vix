{ pkgs, rename }:
let
  ls = pkgs.stdenv.mkDerivation rec {
    name = "tailwindcss";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@tailwindcss/language-server/-/language-server-0.0.13.tgz";
      hash = "sha512-C5OKPG8F6IiSbiEgXMxskMsOnbzSGnZvKBxEGHUhBGIB/tlX5rc7Iv/prdwYrUj2Swhjj5TrXuxZgACo+blB4A==";
    };
    installPhase = ''
      mkdir -p $out
      cp -R ./bin/ $out
      chomd +x $out/bin/tailwindcss-language-server
    '';
    meta.mainProgram = "tailwindcss-language-server";
  };
in
{
  language = "tailwindcss";
  inherit ls;
  ls_options = {
    cmd = [ (pkgs.lib.getExe ls) "--stdio" ];
    filetypes = _: ''(function()
      local types = {"elm"};
      for _,type in ipairs(lspconfig.tailwindcss.document_config.default_config.filetypes) do
        table.insert(types, type)
      end
      return types
    end)()'';
    settings = {
      tailwindCSS = {
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
