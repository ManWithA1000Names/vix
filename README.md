# Vix, declarative, reproducible, shareable neovim configuration.

# ⚠️ Vix is still a Work In Progress!!

If you are curious what nix actually is, you can find great learning meterials here:

- [nix.dev](https://nix.dev), new all in one documentation and learning center.
- [Official website](https://nixos.org).
- [Nix manual](https://nixos.org/manual/nix).
- [Nixpkgs manual](https://nixos.org/manual/nixpgs), the most useful one after you've got the hang of nix.
- [NixOS manual](https://nixos.org/manual/nixos), if you are using the operating system.

> Honestly it's quite a lot if your starting out, but its well worth it!

Use the power of nix to create independant neovim configurations.

Check out the [getting started](./docs/getting-started.md) or the [docs](???), if you don't want the sales pitch.

Features of [vix](https://github.com/manwtiha1000names/vix):

- ⛰️ Stable.
- 🏭️ Reproducible.
- ❄️ Shareable. Share you configuration through nix flakes.
- 🛸 Isolated. Vix does not mess with your existing systems neovim configuration.
- 🤖 Auto-configuration for plugins.
- 🔧 Configure linters, formatters, language servers, plugins and more.
- 📋️ Specify the actual linter, formatter and language server programs to be used.
- 🇬🇷 Configure language specific keybindings.
- 🗃️ No more dotfile management! Just install with one command `nix profile install <your flake reference>`.
- 🌙 Easily inject lua code wherever/whenever you need it.
- 📦️ Easily update your plugins, associated programs and neovim it self.

Lets break the features down one by one:

First some terminology:

- An 'input' is either: a plugin, a formatter, a linter, a language server, a debugger and or neovim it self.
- With the term 'associated programs' I mean 'inputs' - (plugins, neovim) + other programs executed by neovim.
- 'your flake' means: the nix flake that contains your configuration of neovim.
- '\<your flake reference\>': a valid flake reference to 'your flake'. See [flake reference attributes](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-reference-attributes)

## ⛰️ Stable

If you wan't to make it unstable you can... But! By default vix and nix will try to make your configuration as stable as it gets.
The source of this stability lies within nix's reproducibility, and the fact that all the 'inputs' of your configuration are pinned to a specific
version. All the dependencies of the 'inputs' are also pinned, recursively. Thus if your configuration works, it will continue to work no matter
how many times you install / uninstall it. As long as you don't change your `flake.lock` file your configuration will continue to work as expected
untill the end of either nix, github, the internet or the world it self! (Given that the future versions of nix don't introduce any breaking changes)

If you update the 'inputs', with `nix flake update`, then you must assure yourself that the updated inputs are stable and that the update (to ex. neovim) did not introduce any breaking changes.

As long as you don't touch the `flake.lock` file you can change your configuration freely, keeping the stability guarantee.

Also, once the configuration is built it becomes immutable! So the only way to update your configuration is to bulid a new version.

Meaning when a configuration is built its output should never be changed again!

## 🏭️ Reproducible

Since everything, from start to finish, is built with [nix](https://nixos.org),
including neovim, all the 'associated programs' and even your configuration,
the resulting files are 100%, byte for byte, reproducible on any system that supports nix.

When you actually install your vix powered configuration, your not only installing the generated files but also all the 'inputs'.

Thus when you are on a new system you can simple run the command `nix profile install <your flake reference>` and you have your configuration ready to go! Including neovim and all the 'associated programs'.

One command, no dependecy and or version management, you're good to go.

## ❄️ Shareable

With the introduction of [nix flakes](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html) as long as you upload 'your flake' somewhere public, anyone can instantly download and get the exact same setup and configuration (and even the exact same neovim version) on their system.

All a user, that wants the same configuration as you, needs to do is what you yourself do, `nix profile install <your flake reference>`. And done! Now the EXACT SAME setup is on their system.
And as will you see later, since the installation is isolated, there are no clashes with system's pre-existing installion of neovim.

## 🛸 Isolated

Vix under the hood creates what is called a 'neovim distribution' with your configuration.
Basically it points neovim to very specific and sperate folders that do not interfere with any of your system's neovim folders. Vix also goes a step beyong that, installing and using a sperate version of neovim that does not even share the same runtime folder. This is also the case for all the 'associated programs' installed.

## 🤖 Auto-configuration for plugins

Many plugins follow the same setup procedures:

1. require in the plugin by its name.
2. call the setup function.
3. pass it a table of arguments.

Since this convention is so popular, vix offers a way to do it automatically. You can also only specify the table of arguments. See [the docs](docs???) for more information.

## 🔧 Configure linters, formatters, language servers and more / 📋️ Specify the actual programs

Vix has a bulitin mechanism to setup a 'language configuration'. This is basically an attribute set describing how to setup the tooling around each language you wish to extensively support.

In these attribute sets you can utelize the [nixpkgs](https://github.com/nixos/nixpks) to specify the exact program you whish to be run.

Vix also provides many preconfigured 'language configurations' so you can get up and running fast!

All the programs you specify in these configuration will be built and included in your configuration (through the magic of nix of course).

See [the docs](docs???) for more information on language configuration.

## 🇬🇷 Configure language specific keybindings.

In these langauge configurations you can also include keybindings that will be available only when you are editing a buffer that matches the given language.

## 🗃️ No more dotfile management

Once you have created 'your flake' (see [getting stated](docs???)), and hosted it as a git repo on some provider or a simple tarball (see [flake reference attributes](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-reference-attributes)) on your own server,
you can simply install your complete neovim configuration including neovim it self and all the 'associated programs' with a single command:

`nix profile install <your flake path>`

## 🌙 Easily inject lua code wherever/whenever you need it.

Vix allows you at various places to escape the nix language and configure some parts of your neovim in plain old lua. While reading through [the docs](docs???) you will come across all of these escape hatches.

## 📦️ Easily update your plugins, 'associated programs' and neovim it self.

Since everything in your configuration is technically an 'input' to 'your flake', nix has a bulitin method to update these 'inputs'. Either all of them at once or a specific 'input'.

See the [updating section in the docs](docs???)
