pkgs: [
  {
    type = "language-server";
    pkg = pkgs.nil;
    name = "nil_ls";
    exe = "nil";
    options = {
      settings = {
        nil = {
          auto-fetch = true;
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
