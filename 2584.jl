using ArgParse
include("./board.jl")
include("./action.jl")
include("./agent.jl")
include("./statistic.jl")

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--total"
          help = "how many games to play."
          arg_type = Int
          default = 1000
        "--block"
          arg_type = Int
          default = 0
        "--play"
          help = "The arguments of player initialization."
          arg_type = String
        "--evil"
          help = "The arguments of evil (environment) initialization."
          arg_type = String
        "--load"
          help = "Path to load statistic data."
        "--save"
          help = "Path to save statistic data."
        "--summary"
          action = :store_true
    end
    return parse_args(s)
end

function main()
    println("2584 Demo: $(@__FILE__) $(join(ARGS, ' '))")
    parsed_args = parse_commandline()
    println("Parsed args:")
    total = parsed_args["total"]
    block = parsed_args["block"]
    play_args = parsed_args["play"]
    evil_args = parsed_args["evil"]
    load = parsed_args["load"]
    save = parsed_args["save"]
    summary = parsed_args["summary"]
    for (arg,val) in parsed_args
        println("  $arg  =>  $val")
    end
    stat = Statistic(total, block)
    if load != nothing
        #load something
    end
    play = Player(play_args)
    evil = RndEnv(evil_args)
    while !is_finished(stat)
        open_episode(evil, "~:" * name(evil))
        open_episode(play, name(play) * ":~" )

        open_episode(stat, "$(name(play)):$(name(evil))")
        game = make_empty_board(stat)
        while true
            # println(game)
            who = take_turns(stat, play, evil)
            move = take_action(who, game)
            if apply(move, game) == -1
                break
            end
#            println(game)
            save_action(stat, move)
            if check_for_win(who, game)
                break
            end
        end
        win = last_turns(stat, play, evil)
        close_episode(stat, name(win))
        close_episode(play, name(win))
        close_episode(evil, name(win))
#        println(game)
    end
    if summary
        Summary(stat)
    end
    if save != nothing
        open(save, "w") do f
            if !isopen(f)
                return -1
            end
            write(f, stat)
            flush(f)
            close(f)
        end
    end
end



main()
