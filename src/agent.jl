# #module AGENT
include("./action.jl")
include("./weight.jl")

struct State
    before::NTuple{8,Tuple{Int64,Int64}}
    after::NTuple{8,Tuple{Int64,Int64}}
    move::Action
    reward::Int
end

function ftuple(s::T)::Int where T<:SubArray
    return s[1]*25^3 + s[2]*25^2 + s[3]*25 + s[4] + 1
end

function ftuple(b::Board)::NTuple{8,Tuple{Int64,Int64}}
    a1 = (ftuple(@view b[:, 1]), 1)
    a2 = (ftuple(@view b[:, 2]), 2)
    a3 = (ftuple(@view b[:, 3]), 2)
    a4 = (ftuple(@view b[:, 4]), 1)
    a5 = (ftuple(@view b[1, :]), 3)
    a6 = (ftuple(@view b[2, :]), 4)
    a7 = (ftuple(@view b[3, :]), 4)
    a8 = (ftuple(@view b[4, :]), 3)
    return (a1,a2,a3,a4,a5,a6,a7,a8)
end

function stuple(s::T)::Int where T<:SubArray
    return s[1]*25^5 + s[2]*25^4 + s[3]*25^3 + s[4]*25^2 + s[5]*25 + s[6] + 1
end

function stuple(b::Board)
    a1 = (stuple(@view b[[1 2 3 4 8 7]]), 1)
    a2 = (stuple(@view b[[5 6 7 8 12 11]]), 2)
    a3 = (stuple(@view b[[9 10 11 12 16 15]]), 3)
    a4 = (stuple(@view b[[4 3 2 1 5 6]]), 4)
    a5 = (stuple(@view b[[8 7 6 5 9 10]]), 5)
    a6 = (stuple(@view b[[12 11 10 9 13 14]]), 6)
    a7 = (stuple(@view b[[1 5 9 13 14 10]]), 7)
    a8 = (stuple(@view b[[2 6 10 14 15 11]]), 8)
    a9 = (stuple(@view b[[3 7 11 15 16 12]]), 9)
    a10 = (stuple(@view b[[13 9 5 1 2 6 ]]), 10)
    a11 = (stuple(@view b[[14 10 6 2 3 7]]), 11)
    a12 = (stuple(@view b[[15 11 7 3 4 8]]), 12)
    a13 = (stuple(@view b[[13 14 15 16 12 11]]), 1)
    a14 = (stuple(@view b[[9 10 11 12 8 7]]), 2)
    a15 = (stuple(@view b[[5 6 7 8 4 3]]), 3)

    a16 = (stuple(@view b[[4 3 2 1 5 6]]), 4)
    a17 = (stuple(@view b[[8 7 6 5 9 10]]), 5)
    a18 = (stuple(@view b[[12 11 10 9 13 14]]), 6)

    a19 = (stuple(@view b[[1 5 9 13 14 10]]), 7)
    a20 = (stuple(@view b[[2 6 10 14 15 11]]), 8)
    a21 = (stuple(@view b[[3 7 11 15 16 12]]), 9)

    a22 = (stuple(@view b[[13 9 5 1 2 6 ]]), 10)
    a23 = (stuple(@view b[[14 10 6 2 3 7]]), 11)
    a24 = (stuple(@view b[[15 11 7 3 4 8]]), 12)
end

abstract type AbstractAgent end

function ParseProperty(arg::String = "")::Dict{String, Union{Int, String, Float64}}
    property = Dict{String, Union{Int, String, Float64}}()
    for prop ∈ split(arg)
        pair = split(prop, "=")
        t = parse(pair[2])
        if typeof(t) != Int && typeof(t) != Float64
            t = String(pair[2])
        end
        property[pair[1]] = t
    end
    return property
end


struct Agent <: AbstractAgent
    property::Dict{String, Union{Int, Symbol, Float64}}
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
    property::Dict{String, Union{Int, String, Float64}}
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
    property::Dict{String, Union{Int, String, Float64}}
    α::Float64
    rng::MersenneTwister
    weights::Vector{Weight}
    episode::Vector{State}
    function Player(arg::String = "")
        property = ParseProperty(arg)
        property["name"] = "player"
        seed = get(property, "seed", -1)
        rng =  seed == -1 ? srand() : MersenneTwister(seed)
        loaded = get(property, "load", nothing)
        α = get(property, "alpha", 0.0025)
        P = new(property, α ,rng, Vector{Weight}(0), Vector{State}(0))
        if loaded != nothing
            load_weights(P, loaded)
        else
            resize!(P.weights, 4)
            P.weights[1] = Weight(25^4)
            P.weights[2] = Weight(25^4)
            P.weights[3] = Weight(25^4)
            P.weights[4] = Weight(25^4)
        end
        return P
    end
    Player(::Void) = Player()
end

function get_weight(A::Player, ntuple::NTuple{8,Tuple{Int64,Int64}})
    Sum = 0.0
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
    for V ∈ A.episode[end].after
        w[V[2]][V[1]] += A.α * (0  + 0 - w[V[2]][V[1]] )
    end
    for i ∈ size(A.episode,1)-1:-1:1
        W = get_weight(A, A.episode[i+1].after)
        wi = get_weight(A, A.episode[i].after)
        for Vn ∈ A.episode[i].after
            w[Vn[2]][Vn[1]]+= A.α * (A.episode[i+1].reward + W - wi)
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
            A.weights[i] = Weight(0)
            read(f, A.weights[i])
        end
        close(f)
    end
end

function save_weights(A::Player, path::String)
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
    R = MaxOP = -1
    MaxVal = -Inf
    old = after = ftuple(b)
    for op ∈ 0:3
        before = Board(b)
        reward = move(before, op)
        if reward == -1
            continue
        end
        ntuple = ftuple(before)
        V = float(reward) + get_weight(A, ntuple)
        # push!(a, V)
        if V > MaxVal
            MaxVal = V
            MaxOP = op
            after = ntuple
            R = reward
        end
    end
    #println(a)
    if MaxOP != -1
        push!(A.episode, State(old, after,
                               Action(MaxOP), R))
        return A.episode[end].move
    end
    return Action()
end


#end
