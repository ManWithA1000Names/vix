# Vix, declarative, reproducible, shareable neovim configuration.

If you are curious what nix actually is you can find great learning meterials here:

- [nix.dev](https://nix.dev), new all in one documentation and learning center.
- [Official website](https://nixos.org).
- [Nix manual](https://nixos.org/manual/nix).
- [Nixpkgs manual](https://nixos.org/manual/nixpgs), the most useful one after you've got the hang of nix.
- [NixOS manual](https://nixos.org/manual/nixos), if you are using the operating system.

> Honestly it's quite a lot if your starting out, but its well worth it!

Use the power of nix to create independant neovim configurations.

Check out the [getting started](./docs/getting-started.md) or the [docs](???), if you don't want the sales pitch.

Features of [vix](https://github.com/manwtiha1000names/vix):

- ⛰️S Stable.
- 🏭️ Reproducible.
- ❄️ Shareable. Share you configuration through nix flakes.
- 🛸 Isolated. Vix does not mess with your existing systems neovim configuration.
- 🤖 Autocongifuation for plugins.
- 🔧 Configure linters, formatters, language servers, plugins and more.
- 📋️ Specify the actual linter, formatter and language server programs to be used.
- 🇪 Configure language specific keybindings.
- 🗃️ No more dotfile management! Just install with one command `nix profile install <your flake path>`.
- 🌙 Easily inject lua code wherever/whenever you need it.
- 📦️ Easily update your plugins, associated programs and neovim it self.

Lets break the features down one by one:

## Stable

If you wan't you can make it unstable... but, by default vix and nix will try to make your configuration as stable as it gets.
The nature of its stability lies within its reproducibility, and the fact that all the '[inputs](doc???inputs)' of your configuration are pinned to that specific
version, all the dependencies of the programs you specified are also pinned. Thus if your configuration works, it will continue to work no matter
how many times your uninstall / reinstall it. As long as you don't change your `flake.lock` file your configuration will continue to work as expected
untill the end of either nix, github, the internet or the world it self! (Given that the future version of nix don't introduce any breaking changes)

If you update the [inputs](doc???inputs) of your configuration, with `nix flake update` then you must assure your self again that the updated inptus are stable and
that the update (to ex. neovim) did not introduce any breaking changes.

As long as your don't touch the `flake.lock` file you can change your configuration freely, keeping the stability guarantee.

Also once the configuration is built, it becomes immutable! So the only way to update your configuration is to bulid a new version.

Thus, as long a configuration is built it can never be changed again! Not even if you tried. Not even with sudo 🦹.

## Reproducible

Since the everything from start to finish is built through [nix](https://nixos.org),
including neovim it self, all the configured language servers, formatters, linters, debuggers, plugins, even your configuration,
the resulting files are 100%, byte for byte, reproducible on any system that supports nix.

When you actually install your vix powered configuration, your not only installing the generated files, by a sperate installion of neovim
and all the third party programs your configuration specifies.

Thus when you are on a new system you can simple run the command `nix profile install <your flake path>` and you have your configuration ready to go!
Including neovim and all the other programs your configuration specifies. With one single command, no dependecy and or version management, you're good to go.

## Shareable

With the introduction of [nix flakes](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html) as long as you upload your nix flake somewhere public,
anyone can instantly download and get the exact same setup and configuration (and even the exact same neovim version) on their system.

All a user that wants the same configuration as you needs to do, is what you yourself do, `nix profile install <your flake path>`. And done nows the EXACT SAME setup is on theri system.
And as will you see later, since the install is isolated, there are no clashed with system wide installions of neovim.

## Isolated

Vix under the hood creates what is called a 'neovim distribution' with your configuration.
Basically it points neovim to very specific and sperated folders that do not interfere with any of your 'system wide' neovim.
Vix also goes a step beyong that, installing and using a sperate version of neovim that does not even share the same runtime folder and your systems installed neovim.
This is also the case for all the other programs installed.

## Autocongifuation for plugins

Many plugins follow the same setup procedures:

1. require in the plugin byt is name.
2. call the setup function.
3. pass it a table of arguments.

Since this convention is so popular vix will do it automatically for you if you want to of course.
You can also only specify the table of arguments if you want to. See [the docs](docs???) for more information.

## Configure linters, formatters, language servers and more / Specify the actual programs

Vix has a bulitins mechanism to setup a 'language configuration', basically an attribute set describing how to setup the tooling for each language your wish to
support with 'advanced tooling' (meaning linters, formatters, and language servers).

Vix also provides many preconfigured 'language configurations' so you can get up and running fast!

All the programs you specify in these configuration will be built and included in your configuration (through nix of course).

See [the docs](docs???) for more information on language configuration.

## 🇪 Configure language specific keybindings.

In these langauge configuration you can also include keybindings that will be available only when you are editing a buffer poplulated with the given language.

## No more dotfile management

Once you have created your flake (see [getting stated](docs???)), and hosted as a git repo on some provider or a simple tarball (see [flake reference attributes](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-reference-attributes)) on your own server,
you can simple install your complete neovim configuration including neovim it self and all the formatters,linters,language servers with a single command:

`nix profile install <your flake path>`

## Easily inject lua code wherever/whenever you need it.

Vix allows you at various places to always escape the nix language and configure some parts of your neovim in plain old lua.
While reading through [the docs](docs???) you will come across all of these escape hatches.

## 📦️ Easily update your plugins, associated programs and neovim it self.

Since everything in your configuration is technically an 'input' to your 'nix flake', nix has a bulitin method to update this input.
Either all of them at once or a specific 'input'.

See the [updating section in the docs](docs???) 

# Vix is still a Work In Progress!!
