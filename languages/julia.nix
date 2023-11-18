pkgs:
let
  start-file = pkgs.writeText "stat.jl" ''
    @info "Starting language server..."
    if ! isdir(joinpath(DEPOT_PATH[1],"packages/LanguageServer"))
      @info "Setting up..."
      using Pkg
      Pkg.instantiate()
      Pkg.add("LanguageServer")
    else
      @info "Skipping setup..."
    end

    using LanguageServer
    depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
    project_path = let
        dirname(something(
            ## 1. Finds an explicitly set project (JULIA_PROJECT)
            Base.load_path_expand((
                p = get(ENV, "JULIA_PROJECT", nothing);
                p === nothing ? nothing : isempty(p) ? nothing : p
            )),
            ## 2. Look for a Project.toml file in the current working directory,
            ##    or parent directories, with $HOME as an upper boundary
            Base.current_project(),
            ## 3. First entry in the load path
            get(Base.load_path(), 1, nothing),
            ## 4. Fallback to default global environment,
            ##    this is more or less unreachable
            Base.load_path_expand("@v#.#"),
        ))
    end
    @info "Running language server" VERSION pwd() project_path depot_path
    server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path, depot_path)
    server.runlinter = true
    run(server)
  '';
in [{
  type = "language-server";
  pkg = pkgs.writeScriptBin "jlls" ''
    if [ -z "$JULIA_DEPOT_PATH" ]; then
        depot=~/.julia
    else
        depot="$JULIA_DEPOT_PATH"
    fi
    ${pkgs.julia}/bin/julia --startup-file=no --history-file=no --project=$depot/environments/vix-jlls/ ${start-file}
  '';
  name = "julials";
  exe = "jlls";
}]
