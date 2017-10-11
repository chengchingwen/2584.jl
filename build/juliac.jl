using ArgParse

function parse_commandline(ARGS)
    s = ArgParseSettings()
    @add_arg_table s begin
        "--cfile", "-c"
          help = "C file"
          default = joinpath(@__DIR__, "program2.c")
        "--builddir", "-b"
          help = "build directory"
          default = joinpath(pwd(), "builddir")
        "julia_file"
          help = "julia_program_file"
          required = true
    end
    return parse_args(ARGS, s)
end





## Assumptions:
## 1. gcc / x86_64-w64-mingw32-gcc is available and is in path

function julia_compile(julia_program_file, build_dir, C_FILE)
    julia_program_file = abspath(julia_program_file)
    if !isfile(julia_program_file)
        error("Cannot find file: \"$julia_program_file\"")
    end

    # dir_name = dirname(julia_program_file)
    file_name = splitext(basename(julia_program_file))[1]
    O_FILE = "$file_name.o"
    SO_FILE = "lib$file_name.$(Libdl.dlext)"
    # C_FILE = joinpath(@__DIR__, "program2.c")
    E_FILE = file_name * (is_windows() ? ".exe" : "")

    # build_dir = joinpath(dir_name, "builddir")
    if !isdir(build_dir)
        println("Make directory:\n\"$build_dir\"")
        mkdir(build_dir)
    end
    if pwd() != build_dir
        println("Change directory:\n\"$build_dir\"")
        cd(build_dir)
    end

    julia_pkglibdir = joinpath(dirname(Pkg.dir()), "lib", basename(Pkg.dir()))

    if is_windows()
        julia_program_file = replace(julia_program_file, "\\", "\\\\")
        julia_pkglibdir = replace(julia_pkglibdir, "\\", "\\\\")
    end

    command = `"$(Base.julia_cmd())" "--startup-file=no" "--output-o" "$O_FILE" "-e"
               "include(\"$julia_program_file\"); push!(Base.LOAD_CACHE_PATH, \"$julia_pkglibdir\"); empty!(Base.LOAD_CACHE_PATH)"`
    println("Running command:\n$command")
    run(command)

    command = `$(Base.julia_cmd()) $(joinpath(dirname(JULIA_HOME), "share", "julia", "julia-config.jl"))`
    cflags = Base.shell_split(readstring(`$command --cflags`))
    ldflags = Base.shell_split(readstring(`$command --ldflags`))
    ldlibs = Base.shell_split(readstring(`$command --ldlibs`))

    command = `gcc -m64 -shared -o $SO_FILE $O_FILE $cflags $ldflags $ldlibs -Wl,-rpath,\$ORIGIN`
    if is_windows()
        command = `$command -Wl,--export-all-symbols`
    end
    println("Running command:\n$command")
    run(command)

    command = `gcc -m64 $C_FILE -o $E_FILE $SO_FILE $cflags $ldflags $ldlibs -Wl,-rpath,\$ORIGIN`
    println("Running command:\n$command")
    run(command)
end

function main()
    parsed_args = parse_commandline(ARGS)
    println(ARGS)
    println("Parsed args:")
    JULIA_PROGRAM_FILE = parsed_args["julia_file"]
    BUILDDIR = parsed_args["builddir"]
    C_FILE = parsed_args["cfile"]
    # for (arg,val) in parsed_args
    #     println("  $arg  =>  $val")
    # end
    
    println("Program file:\n$(abspath(JULIA_PROGRAM_FILE))")
    julia_compile(JULIA_PROGRAM_FILE, BUILDDIR, C_FILE)
end

main()
