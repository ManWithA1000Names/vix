pkgs:
# let
#   phpcbf = pkgs.writeScriptBin "phpcbf" ''
#     # prefer project local install over global.
#     if [ -e vendor/bin/phpcbf ]; then
#       exec ./vendor/bin/phpcbf "$@"
#     else
#       exec phpcbf "$@"
#     fi
#   '';
# in
[
  {
    type = "language-server";
    # pkg = pkgs.phpactor;
    disable_ls_formatting = true;
  }
  {
    type = "diagnostics";
    # pkg = pkgs.php;
    exe = "php";
  }
  {
    type = "formatting";
    # pkg = phpcbf;
    exe = "phpcbf";
  }
]
