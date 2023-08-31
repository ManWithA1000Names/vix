pkgs: [
  {
    type = "language-server";
    pkg = pkgs.nil;
    name = "nil_ls";
    exe = "nil";
    disable_ls_format = true;
    options = {
      settings = {
        nil = {
          nix = {
            flake = {
              autoArchive = true;
            };
          };
        };
      };
    };
  }

  {
    type = "diagnostics";
    pkg = pkgs.statix;
    exe = "statix";
  }

  {
    type = "formatting";
    pkg = pkgs.nixfmt;
  }
]
