{ pkgs, name, lua }:
languages_raw:
let
  languages = map (f: f { inherit pkgs; }) languages_raw;

  lang_has_setup = field: builtins.hasAttr "setup_${field}";
  lang_has_NO = field: lang: !(builtins.hasAttr field lang);
  lang_has_single = field: lang: builtins.hasAttr field lang && !(builtins.isList lang.${field}) && !(builtins.hasAttr "${field}_options" lang);
  lang_has_single_with_options = field: lang: builtins.hasAttr field lang && !(builtins.isList lang.${field}) && builtins.hasAttr "${field}_options" lang && !(builtins.isList "${field}_options" lang.${"${field}_options"});
  lang_has_mutliple = field: lang: builtins.hasAttr field lang && builtins.isList lang.${field} && !(builtins.hasAttr "${field}_options" lang);
  lang_has_mutliple_with_options = field: lang: builtins.hasAttr field lang && builtins.hasAttr "${field}_options" lang && builtins.isList lang.${field} && builtins.isList lang.${"${field}_options"};

  configure_lspconfig = { ls, options ? { cmd = [ (pkgs.lib.getExe ls) ]; } }: ''
    lspconfig.${pkgs.lib.getName ls}.setup(${lua.toLua options})
  '';

  compile_lspconfig = lang: ''
    --{{ Congifuring langauge servers for ${lang.language}
      ${if lang_has_setup "ls" lang then lua.toValidLuaInsert lang.setup_ls
      else if lang_has_NO "ls" lang then "-- No language servers were configured"
      else if lang_has_single "ls" lang then configure_lspconfig { inherit (lang) ls; }
      else if lang_has_single_with_options "ls" lang then configure_lspconfig { inherit (lang) ls; options = lang.ls_options; }
      else if lang_has_mutliple "ls" lang then pkgs.lib.strings.concatMapStrings (ls: configure_lspconfig { inherit ls; }) lang.ls
      else if lang_has_mutliple_with_options "ls" lang then assert builtins.length lang.ls == builtins.length lang.ls_options; pkgs.lib.strings.concatMapStrings configure_lspconfig (pkgs.lib.lists.zipListsWith (ls: options: {inherit ls options;}) lang.ls lang.ls_options)
      else builtins.abort ''
        Invalid language server configuration for ${lang.language}.
        Please choose one of the following configurations:
        0. { } # no ls at all
        1. { setup_ls = "...custom lua code"; }
        2. { ls = pkgs.<ls name>; }
        3. { ls = pkgs.<ls name>; ls_options = { ... }; }
        4. { ls = [ pkgs.<ls name #1> pkgs.<ls name #2> ]; }
        5. { ls = [ pkgs.<ls name #1> pkgs.<ls name #2> ]; ls_options = [ {...} {...} ] }
      '' # TODO: Maybe allow for lsp options by lsp name? So you can only configure the ones you wnat?
      }
    --}}
  '';

  configure_null_ls_linter = { linter, options ? { command = [ (pkgs.lib.getExe linter) ]; } }: ''
    table.insert(null_ls_sources, null_ls.builtins.diagnostics.${pkgs.lib.getName linter}.with(${lua.toLua options}))
  '';

  compile_null_ls_linters = lang: ''
    --{{ Setting up linters for ${lang.language}
      ${if lang_has_setup "linters" lang then lua.toValidLuaInsert lang.setup_linters
      else if lang_has_NO "linters" lang then "  -- No linters were configugred"
      else if lang_has_single "linters" lang then configure_null_ls_linter {linter =  lang.linters;}
      else if lang_has_single_with_options "linters" lang then configure_null_ls_linter {linter = lang.linters; options = lang.linters_options;}
      else if lang_has_mutliple "linters" lang then pkgs.lib.strings.concatMapStrings (linter: configure_null_ls_linter {inherit linter;}) lang.linters
      else if lang_has_mutliple_with_options "linters" lang then assert builtins.length lang.linters == builtins.length lang.linters_options; pkgs.lib.strings.concatMapstrings configure_lspconfig (pkgs.lib.lists.zipListsWith (linter: options: {inherit linter options;}) lang.linters lang.linters_options)
      else builtins.abort ''
        Invalid linters configuration for ${lang.language}.
        Please choose one of the following configurations:
        0. { } # no linters at all
        1. { setup_linters = "...custom lua code"; }
        2. { linters = pkgs.<linter name>; }
        3. { linters = pkgs.<linter name>; linters_options = { ... }; }
        4. { linters = [ pkgs.<linter name #1> pkgs.<linter name #2> ]; }
        5. { linters = [ pkgs.<linter name #1> pkgs.<linter name #2> ]; linters_options = [ {...} {...} ] }
      ''
      }
    --}}
  '';

  configure_null_ls_formatter = { formatter, options ? { command = [ (pkgs.lib.getExe formatter) ]; } }: ''
    table.insert(null_ls_sources, null_ls.builtins.formatting.${pkgs.lib.getName formatter}.with(${lua.toLua options}))
  '';

  compile_null_ls_formatters = lang: ''
    --{{ Setting up formatters for ${lang.language}
      ${if lang_has_setup "formatters" lang then lua.toValidLuaInsert lang.setup_formatters
      else if lang_has_NO "formatters" lang then "  -- No formatters were configugred"
      else if lang_has_single "formatters" lang then configure_null_ls_formatter {formatter =  lang.formatters;}
      else if lang_has_single_with_options "formatters" lang then configure_null_ls_formatter {formatter = lang.formatters; options = lang.formatters_options;}
      else if lang_has_mutliple "formatters" lang then pkgs.lib.strings.concatMapStrings (formatter: configure_null_ls_formatter {inherit formatter;}) lang.formatters
      else if lang_has_mutliple_with_options "formatters" lang then assert builtins.length lang.formatters == builtins.length lang.formatters_options; pkgs.lib.strings.concatMapstrings configure_lspconfig (pkgs.lib.lists.zipListsWith (formatter: options: {inherit formatter options;}) lang.formatters lang.formatters_options)
      else builtins.abort ''
        Invalid formatters configuration for ${lang.language}.
        Please choose one of the following configurations:
        0. { } # no formatters at all
        1. { setup_formatters = "...custom lua code"; }
        2. { formatters = pkgs.<formatter name>; }
        3. { formatters = pkgs.<formatters name>; formatters_options = { ... }; }
        4. { formatters = [ pkgs.<formatter name #1> pkgs.<formatter name #2> ]; }
        5. { formatters = [ pkgs.<formatter name #1> pkgs.<formatter name #2> ]; formatters_options = [ {...} {...} ] }
      ''
      }
    --}}
  '';

  compiled_lsp = pkgs.writeText "lsp.lua" ''
    local ok, lspconfig = pcall(require, "lspconfig");
    if not ok then
      print([[Requiering 'lspconfig' failed!]], lspconfig);
      return;
    end

    -- Setting up all the different language servers for all the different languages.
    ${pkgs.lib.strings.concatMapStrings compile_lspconfig languages}
  '';

  compiled_null_ls = pkgs.writeText "null-ls.lua" ''
    local ok, null_ls = pcall(require, "null-ls");
    if not ok then
      print([[Requiering 'null-ls' failed!]], null_ls)
      return;
    end

    local null_ls_sources = { }

    -- Setting up all the different formatters and linters.
    --{{ Linters
      ${pkgs.lib.strings.concatMapStrings compile_null_ls_linters languages}
    --}}

    --{{ Formatters
      ${pkgs.lib.strings.concatMapStrings compile_null_ls_formatters languages}
    --}}

    null_ls.setup({sources = null_ls_sources})
  '';

in
''
  cp ${compiled_lsp} $out/${name}/after/plugin/lsp.lua
  cp ${compiled_null_ls} $out/${name}/after/plugin/null-ls.lua
''