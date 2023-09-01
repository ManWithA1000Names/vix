pkgs: [
  {
    type = "language-server";
    pkg = pkgs.clang-tools_16;
    exe = "clangd";
  }

  {
    type = "diagnostics";
    pkg = pkgs.cppcheck;
    exe = "cppcheck";
  }
]
