pkgs: [
  {
    type = "language-server";
    pkg = pkgs.llvmPackages_16.clang;
    exe = "clangd";
  }

  {
    type = "diagnostics";
    pkg = pkgs.cppcheck;
    exe = "cppcheck";
  }
]
