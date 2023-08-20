pkgs: [
  {
    type = "language-server";
    pkg = pkgs.nil;
    name = "nil_ls";
    exe = "nil";
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
