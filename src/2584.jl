using ArgParse
include("./statistic.jl")

function parse_commandline(ARGS)
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
    return parse_args(ARGS, s)
end


function Run(stat::Statistic, game::Board ,play::Player, evil::RndEnv)
    while true
        who = take_turns(stat, play, evil)
        move = take_action(who, game)
        if apply(move, game) == -1
            break
        end
        save_action(stat, move)
        if check_for_win(who, game)
            break
        end
    end
    win = last_turns(stat, play, evil)
    return win
end


function run_game(stat::Statistic, play::Player, evil::RndEnv)
    open_episode(evil, "~:" * name(evil))
    open_episode(play, name(play) * ":~" )
    open_episode(stat, "$(name(play)):$(name(evil))")
    game = make_empty_board(stat)
    win = Run(stat, game, play, evil)
    close_episode(stat, name(win))
    close_episode(play, name(win))
    close_episode(evil, name(win))
    return
end


Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    println("2584 Demo: $(basename(@__FILE__)) $(join(ARGS, ' '))\n")
    parsed_args = parse_commandline(ARGS)
    #println(ARGS)
    # println("Parsed args:")
    total = parsed_args["total"]
    block = parsed_args["block"]
    play_args = parsed_args["play"]
    evil_args = parsed_args["evil"]
    load = parsed_args["load"]
    save = parsed_args["save"]
    summary = parsed_args["summary"]
    # for (arg,val) in parsed_args
    #     println("  $arg  =>  $val")
    # end
    stat = Statistic(total, block)
    if load != nothing
        #load something
        open(load, "r") do f
            if !isopen(f)
                return -1
            end
            read(f, stat)
            close(f)
        end
    end
    play = Player(play_args)
    evil = RndEnv(evil_args)

    while !is_finished(stat)
        run_game(stat, play, evil)
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
    return 0;
end

# main()
