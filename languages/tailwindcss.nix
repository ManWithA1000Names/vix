pkgs:
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
      chmod +x $out/bin/tailwindcss-language-server
    '';
    meta.mainProgram = "tailwindcss-language-server";
  };
in
[{
  type = "language-server";
  pkg = ls;
  options = {
    filetypes = _: ''(function()
      local ft = vim.deepcopy(lspconfig.tailwindcss.document_config.default_config.filetypes)
      table.insert(ft, "elm")
      return ft
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
}]
