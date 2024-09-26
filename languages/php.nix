pkgs:
let
  phpcs = pkgs.writeScriptBin "phpcs" ''
    if [ -e vendor/bin/phpcs ]; then
      exec ./vendor/bin/phpcs "$@"
    else
      exec ${pkgs.php83Packages.php-codesniffer}/bin/phpcs "$@"
    fi
  '';

  phpcbf = pkgs.writeScriptBin "phpcbf" ''
    if [ -e vendor/bin/phpcbf ]; then
      exec ./vendor/bin/phpcbf "$@"
    else
      exec ${pkgs.php83Packages.php-codesniffer}/bin/phpcbf "$@"
    fi
  '';
in [
  {
    type = "language-server";
    pkg = pkgs.phpactor;
    disable_ls_formatting = true;
  }
  {
    type = "diagnostics";
    pkg = phpcs;
    exe = "phpcs";
  }
  {
    type = "diagnostics";
    pkg = pkgs.php;
    exe = "php";
  }
  {
    type = "formatting";
    pkg = phpcbf;
    exe = "phpcbf";
  }
]
