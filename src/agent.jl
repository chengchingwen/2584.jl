# #module AGENT
include("./action.jl")
include("./weight.jl")

struct State
    before::NTuple{8,Tuple{Int64,Int64}}
    after::NTuple{8,Tuple{Int64,Int64}}
    move::Action
    reward::Int
end

function ftuple(s::T) where T<:SubArray
    return s[1]*25^3 + s[2]*25^2 + s[3]*25 + s[4] + 1
end

function ftuple(b::Board)::NTuple{8,Tuple{Int64,Int64}}
    a1 = (ftuple(@view b[:, 1]), 1)
    a2 = (ftuple(@view b[:, 2]), 2)
    a3 = (ftuple(@view b[end:-1:1, 3]), 2)
    a4 = (ftuple(@view b[end:-1:1, 4]), 1)
    a5 = (ftuple(@view b[1, end:-1:1]), 1)
    a6 = (ftuple(@view b[2, end:-1:1]), 2)
    a7 = (ftuple(@view b[3, :]), 2)
    a8 = (ftuple(@view b[4, :]), 1)
    return (a1,a2,a3,a4,a5,a6,a7,a8)
end

abstract type AbstractAgent end

function ParseProperty(arg::String = "")::Dict{String, Union{Int, String}}
    property = Dict{String, Union{Int, String}}()
     for prop ∈ split(arg)
         pair = split(prop, "=")
         t = parse(pair[2])
         if typeof(t) == Symbol
             t = String(t)
         end
         property[pair[1]] = t
     end
    return property
end


struct Agent <: AbstractAgent
    property::Dict{String, Union{Int, Symbol}}
    function Agent(arg::String = "")
        property = ParseProperty(arg)
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
        property = ParseProperty(arg)
        property["name"] = "rndenv"
        seed = get(property, "seed", -1)
        rng =  seed == -1 ? srand() : MersenneTwister(seed)
        return new(property, rng)
    end
    RndEnv(::Void) = RndEnv()
end

function take_action(A::RndEnv, b::Board)
    space = collect(0:15)
    shuffle!(A.rng, space)
    for pos ∈ space
        if b(pos) == 0
            tile = rand(A.rng, 0:9) != 0 ? 1 : 2
            return place(tile, pos)
        end
    end
    return Action()
end


mutable struct Player <: AbstractAgent
    property::Dict{String, Union{Int, String}}
    α::Float32
    rng::MersenneTwister
    weights::Vector{Weight}
    episode::Vector{State}
    function Player(arg::String = "")
        property = ParseProperty(arg)
        property["name"] = "player"
        seed = get(property, "seed", -1)
        rng =  seed == -1 ? srand() : MersenneTwister(seed)
        loaded = get(property, "load", nothing)
        α = get(property, "alpha", 0.0025f0)
        P = new(property, α ,rng, Vector{Weight}(0), Vector{State}(0))
        if loaded != nothing
            load_weights(P, loaded)
        else
            resize!(P.weights, 2)
            P.weights[1] = Weight(25^4)
            P.weights[2] = Weight(25^4)
        end
        return P
    end
    Player(::Void) = Player()
end

function get_weight(A::Player, ntuple::NTuple{8,Tuple{Int64,Int64}})
    Sum = 0.0f0
    for st ∈ ntuple
        Sum+= A.weights[st[2]][st[1]]
    end
    return Sum
end

function open_episode(A::Player, flag::String)
    A.episode = Vector{State}(0)
end

function close_episode(A::Player, flag::String)
    w = A.weights
    for i ∈ size(A.episode,1):-1:1
        for Vn ∈ zip(A.episode[i].before, A.episode[i].after)
            w[Vn[1][2]][Vn[1][1]]+= A.α * (A.episode[i].reward + w[Vn[2][2]][Vn[2][1]] - w[Vn[1][2]][Vn[1][1]])
        end
    end
end

function load_weights(A::Player, path::String)
    open(path, "r") do f
        if !isopen(f)
            error("cat not open $path")
        end
        s = read(f, Int)
        resize!(A.weights, s)
        for i ∈ 1:s
            A.weights[i] = read(f, Weight)
        end
        close(f)
    end
end

function save_weights(A::Player, parg::String)
    open(path, "w") do f
        if !isopen(f)
            error("cat not open $path")
        end
        write(f, size(A.weights,1))
        for w ∈ A.weights
            write(f, w)
        end
        flush(f)
        close(f)
    end
end

function take_action(A::Player, b::Board)
    R = MaxOP = MaxVal = -1
    old = after = ftuple(b)
    for op ∈ 0:3
        before = Board(b)
        reward = move(before, op)
        if reward == -1
            continue
        end
        ntuple = ftuple(before)
        V = reward + get_weight(A, ntuple)
        if V > MaxVal
            MaxVal = V
            MaxOP = op
            after = ntuple
            R = reward
        end
    end
    if MaxOP != -1
        push!(A.episode, State(old, after,
                               Action(MaxOP), R))
        return A.episode[end].move
    end
    return Action()
end


#end
