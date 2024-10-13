{
  description = "A very basic flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nilm.url = "github:manwitha1000names/nilm";
  };

  outputs = { self, flake-utils, nilm, ... }: {
    tools-for = {
      go = import ./languages/go.nix;
      sh = import ./languages/sh.nix;
      nix = import ./languages/nix.nix;
      elm = import ./languages/elm.nix;
      lua = import ./languages/lua.nix;
      json = import ./languages/json.nix;
      yaml = import ./languages/yaml.nix;
      toml = import ./languages/toml.nix;
      ocaml = import ./languages/ocaml.nix;
      "ts/js" = import ./languages/ts_js.nix;
      "c/cpp" = import ./languages/c_cpp.nix;
      python = import ./languages/python.nix;
      haskell = import ./languages/haskell.nix;
      tailwindcss = import ./languages/tailwindcss.nix;
      zig = import ./languages/zig.nix;
      julia = import ./languages/julia.nix;
      elixir = import ./languages/elixir.nix;
      java = import ./languages/java.nix;
      php = import ./languages/php.nix;
      gleam = import ./languages/gleam.nix;
    };

    filetypes-for = {
      sh = [ "sh" ];
      vue = [ "vue" ];
      vim = [ "vim" ];
      nix = [ "nix" ];
      ada = [ "ada" ];
      elm = [ "elm" ];
      lua = [ "lua" ];
      nim = [ "nim" ];
      awk = [ "awk" ];
      php = [ "php" ];
      dart = [ "dart" ];
      rust = [ "rust" ];
      toml = [ "toml" ];
      java = [ "java" ];
      csharp = [ "cs" ];
      haxe = [ "haxe" ];
      helm = [ "helm" ];
      html = [ "html" ];
      perl = [ "perl" ];
      qml = [ "qmljs" ];
      R = [ "r" "rmd" ];
      raku = [ "raku" ];
      julia = [ "julia" ];
      cobol = [ "cobol" ];
      astro = [ "astro" ];
      cmake = [ "cmake" ];
      ocaml = [ "ocaml" ];
      svelte = [ "svelte" ];
      racket = [ "racket" ];
      reason = [ "reason" ];
      kotlin = [ "kotlin" ];
      scheme = [ "scheme" ];
      groovy = [ "groovy" ];
      fsharp = [ "fsharp" ];
      erlang = [ "erlang" ];
      python = [ "python" ];
      zig = [ "zig" "zir" ];
      V = [ "v" "vsh" "vv" ];
      powershell = [ "ps1" ];
      asm = [ "asm" "vasm" ];
      protobuf = [ "proto" ];
      sql = [ "sql" "mysql" ];
      arduino = [ "arduino" ];
      "c/cpp" = [ "c" "cpp" ];
      crystal = [ "crystal" ];
      docker = [ "dockefile" ];
      vala = [ "vala" "genie" ];
      ruby = [ "ruby" "eruby" ];
      solidity = [ "solidity" ];
      json = [ "json" "jsonc" ];
      markdown = [ "markdown" ];
      guile = [ "scheme.guile" ];
      ansible = [ "yaml.ansible" ];
      css = [ "css" "scss" "less" ];
      clojure = [ "clojure" "end" ];
      haskell = [ "haskell" "lhaskell" ];
      go = [ "go" "gomod" "gowork" "gotmpl" ];
      starlark = [ "star" "bzl" "BUILD.bazel" ];
      elixir = [ "elixir" "eelixir" "heex" "surface" ];
      terraform = [ "terraform" "terraform-vars" "hcl" ];
      yaml = [ "yaml" "yaml.docker-compse" "yaml.ansible" ];
      typescript = [ "typescript" "typescriptreact" "typescript.tsx" ];
      javascript = [ "javascript" "javascriptreact" "javascript.jsx" ];
      flow = [ "javascript" "javascriptreact" "javascript.jsx" ];
      gleam = [ "gleam" ];
    };

    mkFlake = args:
      flake-utils.lib.eachDefaultSystem (system:
        let theDerivation = self.mkDerivation (args // { inherit system; });
        in {
          packages = {
            ${theDerivation.name} = theDerivation;
            default = theDerivation;
          };
        });

    mkDerivation = { system, nixpkgs, app-name ? "vix", config ? { }
      , plugin-setups ? { }, plugin-sources ? { }, less ? [ ], tools ? [ ] }:
      let
        inherit (nilm) List;
        pkgs = import nixpkgs { inherit system; };
        lua = import ./lib/lua.nix { inherit nilm pkgs; };
        tooling = List.flatten (List.map (nilm.Basics."|>" pkgs) tools);

        importCall = path: import path { inherit pkgs lua nilm app-name; };

        transformed-plugins = importCall ./transforms/plugins.nix {
          inherit plugin-setups plugin-sources less;
        };

        transformed-tooling = importCall ./transforms/tooling.nix tooling;

        transformed-neovim-config = importCall ./transforms/neovim-config.nix {
          inherit tooling;
          which-key-in-plugins = nilm.Dict.member "which-key" plugin-sources;
        } config;

        complete_config = pkgs.stdenv.mkDerivation {
          name = "${app-name}-configuration";
          src = ./.;
          buildInputs = nilm.List.map (nilm.Dict.get "pkg") tooling;
          installPhase = ''
            mkdir -p $out/${app-name}/lua/;
            mkdir -p $out/${app-name}/plugin/;
            mkdir -p $out/${app-name}/after/plugin/;
            mkdir -p $out/${app-name}/pack/${app-name}-plugins/start/;
            mkdir -p $out/${app-name}/pack/${app-name}-plugins/opt/;
            echo "Beginning to generate the configurtion."
            echo "1/4 Created neccessary directories..." 
            ${transformed-neovim-config}
            echo "2/4 Created neovim config..." 
            ${transformed-plugins}
            echo "3/4 Created the plugins..." 
            ${transformed-tooling}
            echo "4/4 Created the tooling configurations..." 
            echo "Done generating the configurtion."
          '';
        };

        neovim-wihtout-parsers = pkgs.neovim.passthru.unwrapped.overrideAttrs
          (final: prev: {
            postInstall = ''
              echo "yes"
              rm -rf $out/lib/nvim/parser
            '';
          });

      in pkgs.writeScriptBin app-name ''
        #!/bin/sh
         export OG_XDG_CONFIG_HOME=$XDG_CONFIG_HOME;
         export XDG_CONFIG_HOME="${complete_config}";
         export NVIM_APPNAME="${app-name}";
         if [ "$1" = "remove-files" ]; then
           echo "removing..."
           rm -rf ~/.local/share/${app-name}/;
           rm -rf ~/.local/state/${app-name}/;
           rm -rf ~/.cache/${app-name}/;
           echo 'removed all associated files'
           exit 0;
         fi
         exec ${neovim-wihtout-parsers}/bin/nvim -u ${complete_config}/${app-name}/init.lua "$@";
      '';

  };
}
