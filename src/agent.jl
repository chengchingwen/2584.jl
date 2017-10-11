# #module AGENT
include("./action.jl")

abstract type AbstractAgent end

struct Agent <: AbstractAgent
    property::Dict{String, Union{Int, Symbol}}
    function Agent(arg::String = "")
        property = Dict{String, Union{Int, Symbol}}()
        for prop ∈ split(arg)
            pair = split(prop, "=")
            property[pair[1]] = parse(pair[2])
        end
        return new(property)
    end
end

function name(A::AbstractAgent)
    return get(A.property, "name", "unknown")
end

open_episode(A::AbstractAgent, flag::String) = ()
close_episode(A::AbstractAgent, flag::String) = ()
check_for_win(A::AbstractAgent, b::Board)::Bool = false

#function take_action(A::Agent, b::Board)

struct RndEnv <: AbstractAgent
    property::Dict{String, Union{Int, String}}
    rng::MersenneTwister
    function RndEnv(arg::String = "")
        property = Dict{String, Union{Int, String}}()
        arg= "name=rndenv " * arg
        for prop ∈ split(arg)
            pair = split(prop, "=")
            t = parse(pair[2])
            if typeof(t) == Symbol
                t = String(t)
            end
            property[pair[1]] = t
        end
        seed = get(property, "seed", -1)
        rng =  seed == -1 ? srand() : MersenneTwister(seed)
        return new(property, rng)
    end
    RndEnv(::Void) = RndEnv()
end

struct Player <: AbstractAgent
    property::Dict{String, Union{Int, String}}
    rng::MersenneTwister
    function Player(arg::String = "")
        property = Dict{String, Union{Int, String}}()
        arg= "name=player " * arg
        for prop ∈ split(arg)
            pair = split(prop, "=")
            t = parse(pair[2])
            if typeof(parse(pair[2])) == Symbol
                t = String(t)
            else
                property[pair[1]] = t
            end
        end
        seed = get(property, "seed", -1)
        rng =  seed == -1 ? srand() : MersenneTwister(seed)
        return new(property, rng)
    end
    Player(::Void) = Player()
end

function take_action(A::RndEnv, b::Board)
    space = 0:15
    shuffle!(A.rng, collect(space))
    for pos ∈ space
        if b(pos) == 0
            tile = rand(A.rng, 0:9) != 0 ? 1 : 2
            return place(tile, pos)
        end
    end
    return Action()
end

function take_action(A::Player, b::Board)
    opcode = 0:3
    shuffle!(A.rng, collect(opcode))
    MaxOP = MaxVal = -1
    for op ∈ opcode
        before = Board(b)
        try_move = move(before, op)
        # println(op)
        if  try_move > MaxVal
            MaxVal = try_move
            MaxOP = op
        end
    end
    return MaxOP != -1 ? Action(MaxOP) : Action()
end


#end
