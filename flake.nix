{
  description = "A very basic flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils }: {
    languages = {
      nix = import ./languages/nix.nix;
    };

    mkFlake = { name ? "vix", config ? { }, plugins ? [ ], languages ? [ ] }:
      flake-utils.lib.eachDefaultSystem (system:
        let theDerivation = self.mkDerivation { inherit system name config plugins languages; }; in
        { packages = { ${name} = theDerivation; default = theDerivation; }; }
      );

    mkDerivation = { system, name ? "vix", config ? { }, plugins ? [ ], languages ? [ ] }:
      let
        pkgs = import nixpkgs { inherit system; };
        lua = import ./lib/lua.nix { inherit pkgs; };

        complete_config = pkgs.runCommand "${name}-configuration" { } ''
          mkdir -p $out/${name}/lua/;
          mkdir -p $out/${name}/plugin/;
          mkdir -p $out/${name}/after/plugin/;
          mkdir -p $out/${name}/pack/${name}-plugins/start/;
          mkdir -p $out/${name}/pack/${name}-plugins/opt/;
          echo "Beginning to generate the configurtion."
          echo "1/4 Created neccessary directories..." 
          ${import ./transforms/neovim-config.nix {inherit pkgs lua name;} config}
          echo "2/4 Created neovim config..." 
          ${import ./transforms/plugins.nix {inherit pkgs lua name;} plugins}
          echo "3/4 Created the plugins..." 
          ${import ./transforms/languages.nix {inherit pkgs lua name;} languages}
          echo "4/4 Created the langauge presets..." 
          echo "Done generating the configurtion."
        '';
      in
      pkgs.writeScriptBin name ''
        #!/bin/sh
         # export XDG_CONFIG_HOME="${complete_config}";
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
