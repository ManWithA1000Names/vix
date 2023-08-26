{
  description = "A very basic flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nilm.url = "github:manwitha1000names/nilm";
  };

  outputs = { self, nixpkgs, flake-utils, nilm }: {
    tool_presets_per_language = {
      nix = import ./languages/nix.nix;
      "c/cpp" = import ./languages/c_cpp.nix;
      elm = import ./languages/elm.nix;
      go = import ./languages/go.nix;
      lua = import ./languages/lua.nix;
      python = import ./languages/python.nix;
      sh = import ./languages/sh.nix;
      tailwindcss = import ./languages/tailwindcss.nix;
      "ts/js" = import ./languages/ts_js.nix;
      haskell = import ./languages/haskell.nix;
      json = import ./languages/json.nix;
      yaml = import ./languages/yaml.nix;
      toml = import ./languages/toml.nix;
    };

    mkFlake = args:
      flake-utils.lib.eachDefaultSystem (system:
        let theDerivation = self.mkDerivation (args // { inherit system; });
        in
        {
          packages = {
            ${theDerivation.name} = theDerivation;
            default = theDerivation;
          };
        });

    mkDerivation =
      { system, name ? "vix", config ? { }, plugins ? { }, sources ? { }, less ? [ ], tools ? [ ] }:
      let
        pkgs = import nixpkgs { inherit system; };
        lua = import ./lib/lua.nix { inherit nilm; };
        util = import ./lib/util.nix;

        transformed-neovim-config = import ./transforms/neovim-config.nix
          {
            inherit pkgs lua name nilm;
            which-key-in-plugins =
              nilm.Dict.member "which-key" plugins || nilm.Dict.member "which-key" sources;
          }
          config;

        transformed-plugins = import ./transforms/pluginsV2.nix { inherit pkgs lua nilm; app-name = name; }
          { args = sources; configs = plugins; inherit less; };

        transformed-tooling = import ./transforms/tooling.nix { inherit pkgs lua name nilm; }
          tools;

        complete_config = pkgs.runCommand "${name}-configuration" { } ''
          mkdir -p $out/${name}/lua/;
          mkdir -p $out/${name}/plugin/;
          mkdir -p $out/${name}/after/plugin/;
          mkdir -p $out/${name}/pack/${name}-plugins/start/;
          mkdir -p $out/${name}/pack/${name}-plugins/opt/;
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
      in
      pkgs.writeScriptBin name ''
        #!/bin/sh
         export OG_XDG_CONFIG_HOME=$XDG_CONFIG_HOME;
         export XDG_CONFIG_HOME="${complete_config}";
         export NVIM_APPNAME="${name}";
         if [ "$1" = "remove-files" ]; then
           rm -rf ~/.local/share/${name}/;
           rm -rf ~/.local/state/${name}/;
           rm -rf ~/.cache/${name}/;
           echo 'removed all associated files'
           exit 0;
         fi
         exec ${pkgs.neovim}/bin/nvim -u ${complete_config}/${name}/init.lua "$@";
      '';

  };
}
