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

function ftuple(s::UInt32)::Int
    return Int((s >> 24) & 0xff) *25^3 + Int((s >> 16) & 0xff) *25^2 + Int((s >> 8) & 0xff) *25^1 + Int(s  & 0xff)  + 1
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

function ftuple(b::BitBoard)::NTuple{8,Tuple{Int64,Int64}}
    b′ = b'
    a1 = (ftuple(GetRow(b′ , 0)), 1)
    a2 = (ftuple(GetRow(b′ , 1)), 2)
    a3 = (ftuple(GetRow(b′ , 2)), 2)
    a4 = (ftuple(GetRow(b′ , 3)), 1)
    a5 = (ftuple(GetRow(b , 0)), 3)
    a6 = (ftuple(GetRow(b , 1)), 4)
    a7 = (ftuple(GetRow(b , 2)), 4)
    a8 = (ftuple(GetRow(b , 3)), 3)
    return (a1,a2,a3,a4,a5,a6,a7,a8)
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
check_for_win(A::AbstractAgent, b::T) where T <: AbstractBoard = false


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

function take_action(A::RndEnv, b::T) where T <: AbstractBoard
    space = collect(0:15)
    shuffle!(A.rng, space)
    for pos ∈ space
        if b(pos) == 0
            tile = rand(A.rng, 0:3) != 0 ? 1 : 3
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



abstract type  StateType end

struct Before <: StateType end
struct After <: StateType end

#::Type{After}
function expectmax(A::Player, B::Board, ::Type{After})::Float64
    α = 0.
    s = empty(B)
    # if length(s) > 8
    #     return α
    # end
    pc = 1. / float(length(s))
    
    for p ∈ s
        b = Board(copy(B.tile))
        apply(place(1, p), b)
        α += 0.75 * pc * expectmax(A, b, Before)
        b′ = Board(copy(B.tile))
        apply(place(3, p), b′)
        α += 0.25 * pc * expectmax(A, b′, Before)
    end
    
    #=
    for p ∈ s
        b = Board(copy(B.tile))
        apply(place(1, p), b)
        ntuple = ftuple(b)
        α += 0.75 * pc * get_weight(A, ntuple)
        b′ = Board(copy(B.tile))
        apply(place(3, p), b′)
        ntuple = ftuple(b′)
        α += 0.25 * pc * get_weight(A, ntuple)
    end
    =#

    #=
    #parallelized
    α += (@parallel (+) for p ∈ s
          b = Board(copy(B.tile))
          apply(place(1, p), b)
          ntuple = ftuple(b)
          0.75 * pc * get_weight(A, ntuple)#expectmax(A, b, Before)
          end)::Float64

    α += (@parallel (+) for p ∈ s
          b = Board(copy(B.tile))
          apply(place(3, p), b)
          ntuple = ftuple(b)
          0.25 * pc * get_weight(A, ntuple)#expectmax(A, b, Before)
          end)::Float64
    =#
    #S.tt[After][Tuple(B.tile)] = α
    return α
end

#::Type{Before}
function expectmax(A::Player, B::Board, ::Type{Before})::Float64
    α = -Inf
    for m ∈ 0:3
        b = Board(copy(B.tile))
        k = apply(Action(m), b)
        if k == -1
            continue
        end
        ntuple = ftuple(b)
        α = max(α, k + get_weight(A, ntuple))
    end
    if isinf(α)
        #S.tt[Before][Tuple(B.tile)] = 0.
        return 0.
    end
    #S.tt[Before][Tuple(B.tile)] = α
    return α
end




function take_action(A::Player, b::T) where T <: AbstractBoard
    R = MaxOP = -1
    MaxVal = -Inf
    old = after = ftuple(b)
    for op ∈ 0:3
        before = T(b)
        reward = move(before, op)
        if reward == -1
            continue
        end
        ntuple = ftuple(before)
        #V = float(reward) + get_weight(A, ntuple) + expectmax(A, before, After)
        V = float(reward) + expectmax(A, before, After)
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


