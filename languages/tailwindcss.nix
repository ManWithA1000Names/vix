pkgs:
let
  ls = pkgs.stdenv.mkDerivation {
    name = "tailwindcss";
    src = pkgs.fetchurl {
      url =
        "https://registry.npmjs.org/@tailwindcss/language-server/-/language-server-0.0.13.tgz";
      hash =
        "sha512-C5OKPG8F6IiSbiEgXMxskMsOnbzSGnZvKBxEGHUhBGIB/tlX5rc7Iv/prdwYrUj2Swhjj5TrXuxZgACo+blB4A==";
    };
    installPhase = ''
      mkdir -p $out
      cp -R ./bin/ $out
      chmod +x $out/bin/tailwindcss-language-server
    '';
    meta.mainProgram = "tailwindcss-language-server";
  };
in [{
  type = "language-server";
  pkg = pkgs.writeScriptBin "twls" ''
    ${pkgs.nodejs}/bin/node ${ls}/bin/tailwindcss-language-server
  '';
  name = "tailwindcss";
  exe = "twls";
  options = {
    filetypes = [
      "aspnetcorerazor"
      "astro"
      "astro-markdown"
      "blade"
      "clojure"
      "django-html"
      "htmldjango"
      "edge"
      "eelixir"
      "elixir"
      "ejs"
      "erb"
      "eruby"
      "elm"
      "gohtml"
      "haml"
      "handlebars"
      "hbs"
      "html"
      "html-eex"
      "heex"
      "jade"
      "leaf"
      "liquid"
      "markdown"
      "mdx"
      "mustache"
      "njk"
      "nunjucks"
      "php"
      "razor"
      "slim"
      "twig"
      "css"
      "less"
      "postcss"
      "sass"
      "scss"
      "stylus"
      "sugarss"
      "javascript"
      "javascriptreact"
      "reason"
      "rescript"
      "typescript"
      "typescript"
      "typescriptreact"
      "vue"
      "svelte"
    ];
    settings = {
      tailwindCSS = {
        includeLanguages.elm = "html";
        experimental.classRegex = [
          ''\bclass[\s(<|]+"([^"]*)"''
          ''\bclass[\s(]+"[^"]*"[\s+]+"([^"]*)"''
          ''\bclass[\s<|]+"[^"]*"\s*\+{2}\s*" ([^"]*)"''
          ''\bclass[\s<|]+"[^"]*"\s*\+{2}\s*" [^"]*"\s*\+{2}\s*" ([^"]*)"''
          ''
            \bclass[\s<|]+"[^"]*"\s*\+{2}\s*" [^"]*"\s*\+{2}\s*" [^"]*"\s*\+{2}\s*" ([^"]*)"''
          ''\bclassList[\s\[\(]+"([^"]*)"''
          ''\bclassList[\s\[\(]+"[^"]*",\s[^\)]+\)[\s\[\(,]+"([^"]*)"''
          ''
            \bclassList[\s\[\(]+"[^"]*",\s[^\)]+\)[\s\[\(,]+"[^"]*",\s[^\)]+\)[\s\[\(,]+"([^"]*)"''
        ];
      };
    };
  };
}]
