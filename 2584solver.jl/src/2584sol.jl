using ArgParse
include("./solver.jl")

function parse_commandline(ARGS)
    s = ArgParse.ArgParseSettings()
    ArgParse.@add_arg_table s begin
        "--solve"
        help = "Solver arguments"
        arg_type = String
        "--precision"
        arg_type = Int
    end
    return ArgParse.parse_args(ARGS,s)
end

function main(ARGS)
    println("2584-Solver: $(basename(@__FILE__)) $(join(ARGS, ' '))\n")
    parsed_args = parse_commandline(ARGS)
    solve_args = parsed_args["solve"]
    precision = parsed_args["precision"]

    solver = Solver()
    state = Board()

    while !eof(STDIN)
        input  = split(readline())
        build_board(state, view(input, 2:endof(input)))
        ans = Query(solver, state, read_type(input[1][1]))
        println("= $ans")
    end
    return 0
end


main(ARGS)
