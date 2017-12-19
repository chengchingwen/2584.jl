# #module AGENT
include("./action.jl")
include("./weight.jl")

struct State
    before::UInt128
    after::UInt128
    move::Action
    reward::Int
end

function ftuple(s::T)::Int where T<:SubArray
    return s[1]*20^3 + s[2]*20^2 + s[3]*20 + s[4] + 1
end

function ftuple(s::UInt32)::Int
    return Int((s >> 24) & 0xff) *20^3 + Int((s >> 16) & 0xff) *20^2 + Int((s >> 8) & 0xff) *20^1 + Int(s  & 0xff)  + 1
end

function ftuple(b::Board)::NTuple{8,Tuple{Int64,Int64}}
    a1 = (ftuple(@view b[:, 1]), 1)
    a2 = (ftuple(@view b[:, 2]), 2)
    a3 = (ftuple(@view b[:, 3]), 2)
    a4 = (ftuple(@view b[:, 4]), 1)
    a5 = (ftuple(@view b[1, :]), 1)
    a6 = (ftuple(@view b[2, :]), 2)
    a7 = (ftuple(@view b[3, :]), 2)
    a8 = (ftuple(@view b[4, :]), 1)
    return (a1,a2,a3,a4,a5,a6,a7,a8)
end

function ftuple(b::BitBoard)::NTuple{8,Tuple{Int64,Int64}}
    b′ = transpose(b)::BitBoard
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

ftuple(x::UInt128) = ftuple(BitBoard(x))

function stuple(s::T)::Int where T<:SubArray
    return s[1]*20^5 + s[2]*20^4 + s[3]*20^3 + s[4]*20^2 + s[5]*20 + s[6] + 1
end

function stuple(b::Board)::NTuple{12,Tuple{Int64,Int64}}
    a1 = (stuple(@view b[[1 2 3 4 8 7]]), 1)
    a2 = (stuple(@view b[[5 6 7 8 12 11]]), 2)
    a3 = (stuple(@view b[[9 10 11 12 16 15]]), 3)
    a4 = (stuple(@view b[[13 14 15 16 12 11]]), 1)
    a5 = (stuple(@view b[[9 10 11 12 8 7]]), 2)
    a6 = (stuple(@view b[[5 6 7 8 4 3]]), 3)
    a7 = (stuple(@view b[[1 5 9 13 14 10]]), 1)
    a8 = (stuple(@view b[[2 6 10 14 15 11]]), 2)
    a9 = (stuple(@view b[[3 7 11 15 16 12]]), 3)
    a10 = (stuple(@view b[[4 8 12 16 15 11]]), 1)
    a11 = (stuple(@view b[[3 7 11 15 14 10]]), 2)
    a12 = (stuple(@view b[[2 6 10 14 13 9]]), 3)
    return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12)
end

function stuple(x::UInt32, y::UInt32)::Int
    return ftuple(x) + Int(y & 0xff) * 20^4 + Int((y >> 8) & 0xff) * 20^5
end


function stuple(b::BitBoard)::NTuple{12,Tuple{Int64,Int64}}
    b′ = transpose(b)::BitBoard
    a1  = (stuple(GetRow(b′, 0), GetRow(b′, 1)), 1)
    a2  = (stuple(GetRow(b′, 1), GetRow(b′, 2)), 2)
    a3  = (stuple(GetRow(b′, 2), GetRow(b′, 3)), 3)
    a4  = (stuple(GetRow(b′, 3), GetRow(b′, 2)), 1)
    a5  = (stuple(GetRow(b′, 2), GetRow(b′, 1)), 2)
    a6  = (stuple(GetRow(b′, 1), GetRow(b′, 0)), 3)
    a7  = (stuple(GetRow(b , 0), GetRow(b , 1)), 1)
    a8  = (stuple(GetRow(b , 1), GetRow(b , 2)), 2)
    a9  = (stuple(GetRow(b , 2), GetRow(b , 3)), 3)
    a10 = (stuple(GetRow(b , 3), GetRow(b , 2)), 1)
    a11 = (stuple(GetRow(b , 2), GetRow(b , 1)), 2)
    a12 = (stuple(GetRow(b , 1), GetRow(b , 0)), 3)
    # a13 = (stuple(GetRow(b′, 0), GetRow(b′, 1) >> 16), 1)
    # a14 = (stuple(GetRow(b′, 1), GetRow(b′, 2) >> 16), 2)
    # a15 = (stuple(GetRow(b′, 2), GetRow(b′, 3) >> 16), 3)
    # a16 = (stuple(GetRow(b′, 3), GetRow(b′, 2) >> 16), 1)
    # a17 = (stuple(GetRow(b′, 2), GetRow(b′, 1) >> 16), 2)
    # a18 = (stuple(GetRow(b′, 1), GetRow(b′, 0) >> 16), 3)
    # a19 = (stuple(GetRow(b , 0), GetRow(b , 1) >> 16), 1)
    # a20 = (stuple(GetRow(b , 1), GetRow(b , 2) >> 16), 2)
    # a21 = (stuple(GetRow(b , 2), GetRow(b , 3) >> 16), 3)
    # a22 = (stuple(GetRow(b , 3), GetRow(b , 2) >> 16), 1)
    # a23 = (stuple(GetRow(b , 2), GetRow(b , 1) >> 16), 2)
    # a24 = (stuple(GetRow(b , 1), GetRow(b , 0) >> 16), 3)
    #return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16 , a17, a18, a19, a20, a21, a22, a23, a24)
    return (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12)
end

stuple(x::UInt128) = stuple(BitBoard(x))

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


const jobs = RemoteChannel(()->Channel{Int}(32));
const QuestBoard = RemoteChannel(()->Channel{Tuple{BitBoard, Int}}(0));
const AnswerBoard = RemoteChannel(()->Channel{Int}(0));
const QuestWeight = RemoteChannel(()->Channel{BitBoard}(0));
const AnswerWeight = RemoteChannel(()->Channel{Float64}(0));
const results = RemoteChannel(()->Channel{Tuple}(32));

function WhatsNext()
    while true
        b, m = take!(QuestBoard)::Tuple{BitBoard, Int}
        k = apply(Action(m), b)::Int
        put!(AnswerBoard, k)
    end
end


@everywhere function papply(a::Action, b::BitBoard, QuestBoard ,AnswerBoard)::Int
    put!(QuestBoard, (b, a.opcode))
    return take!(AnswerBoard)::Int
end

@schedule WhatsNext()

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
            resize!(P.weights, 7)
            MAXTILE = 20
            P.weights[1] = Weight(MAXTILE^4)
            P.weights[2] = Weight(MAXTILE^4)
            P.weights[3] = Weight(MAXTILE^4)
            P.weights[4] = Weight(MAXTILE^4)
            P.weights[5] = Weight(MAXTILE^6)
            P.weights[6] = Weight(MAXTILE^6)
            P.weights[7] = Weight(MAXTILE^6)
            # P.weights[6] = Weight(25^6)
            # P.weights[7] = Weight(25^6)
            # P.weights[8] = Weight(25^6)
        end
        @schedule WhatsWeight(P)
        return P
    end
    Player(::Void) = Player()
end

function WhatsWeight(A::Player)
    while true
        b = take!(QuestWeight)::BitBoard
        k = get_weight(A, b)::Float64
        put!(AnswerWeight, k)
    end
end

@everywhere function pget_weight(B::BitBoard, QuestWeight ,AnswerWeight)::Float64
    put!(QuestWeight, B)
    return take!(AnswerWeight)
end


function get_weight(A::Player, ntuple::NTuple{8,Tuple{Int64,Int64}})
    Sum = 0.0
    for st ∈ ntuple
        Sum+= A.weights[st[2]][st[1]]
    end
    return Sum
end

function get_weight(A::Player, ntuple::NTuple{12,Tuple{Int,Int}})
    Sum = 0.0
    for st ∈ ntuple
        Sum+= A.weights[st[2]+4][st[1]]
    end
    return Sum
end

function get_weight(A::Player, B::T) where T <: AbstractBoard
    return get_weight(A, ftuple(B)) + get_weight(A, stuple(B))
end

get_weight(A::Player, x::UInt128) = get_weight(A, BitBoard(x))

function open_episode(A::Player, flag::String)
    A.episode = Vector{State}(0)
end

function close_episode(A::Player, flag::String)
    w = A.weights
    for V ∈ ftuple(A.episode[end].after)
        w[V[2]][V[1]] += A.α * (0  + 0 - w[V[2]][V[1]] )
    end
    for V ∈ stuple(A.episode[end].after)
        w[V[2]+4][V[1]] += A.α * (0  + 0 - w[V[2]+4][V[1]] )
    end
    for i ∈ size(A.episode,1)-1:-1:1
        # W  = get_weight(A, ftuple(A.episode[i+1].after))
        # wi = get_weight(A, ftuple(A.episode[i].after))
        W  = get_weight(A, A.episode[i+1].after)
        wi = get_weight(A, A.episode[i].after)
        for Vn ∈ ftuple(A.episode[i].after)
            w[Vn[2]][Vn[1]]+= A.α * (A.episode[i+1].reward + W - wi)
        end
        # W  = get_weight(A, stuple(A.episode[i+1].after))
        # wi = get_weight(A, stuple(A.episode[i].after))
        for Vn ∈ stuple(A.episode[i].after)
            w[Vn[2]+4][Vn[1]]+= A.α * (A.episode[i+1].reward + W - wi)
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



@everywhere abstract type  StateType end

@everywhere struct Before <: StateType end
@everywhere struct After <: StateType end



@everywhere function expectmax(B::BitBoard, d::Int, ::Type{After}, QuestBoard ,AnswerBoard ,QuestWeight ,AnswerWeight)::Float64
    #    println(B)
    #println(d)
    if d == 0
        return pget_weight(B, QuestWeight ,AnswerWeight)
    end
    α = 0.
    s = empty(B)
    pc::Float64 = 1. / float(length(s))
    tmp = Future[]
    for p ∈ s
        b::BitBoard = BitBoard(B)
        papply(place(1, p), b, QuestBoard ,AnswerBoard)
        b::BitBoard
        expect::Future = @spawn expectmax(b, d-1, Before, QuestBoard ,AnswerBoard ,QuestWeight ,AnswerWeight)
        M::Future = @spawn 0.75 * pc * fetch(expect)
        # println(typeof(expect))
        # println(typeof(M))
        push!(tmp, M)
        b′::BitBoard = BitBoard(B)
        papply(place(3, p), b′, QuestBoard ,AnswerBoard)
        b′::BitBoard
        expect = @spawn expectmax(b′, d-1, Before, QuestBoard ,AnswerBoard ,QuestWeight ,AnswerWeight)
        M = @spawn 0.25 * pc * fetch(expect)
        # println(typeof(expect))
        # println(typeof(M))
        push!(tmp, M)
    end
    #println(tmp)
    if isempty(tmp)
        return 0.
    end
    V::Vector{Float64} = map(fetch, tmp)
    #println(V)
    return sum(V)
end

@everywhere function expectmax(B::BitBoard, d::Int , ::Type{Before}, QuestBoard ,AnswerBoard ,QuestWeight ,AnswerWeight)::Float64
    #    println(B)
    if d == 0
        return 0.
    end
    #println(d)
    α = -Inf
    tmp = Future[]
    for m ∈ 0:3
        b = BitBoard(B)
        k = papply(Action(m), b, QuestBoard ,AnswerBoard)
        if k == -1
            continue
        end
        e = @spawn expectmax(b, d-1, After, QuestBoard ,AnswerBoard ,QuestWeight ,AnswerWeight)
        M = @spawn k + fetch(e)
        push!(tmp, M)
    end
    if isempty(tmp)
        return 0.
    end
    V::Vector{Float64} = map(fetch, tmp)
    #println(V)
    α::Float64 = maximum(V)
    # if isinf(α)
    #     return 0.
    # end
    return α
end


#::Type{After}
function expectmax(A::Player, B::T, d::Int, ::Type{After})::Float64 where T <: AbstractBoard
    if d == 0
        return get_weight(A, B)
    end
    α = 0.
    s = empty(B)

    # ignore1 = false

    # if length(s) < 3
    #     d+=1
    # end
    #else
    # if length(s) > 8
    #     ignore1 = true
    # end

    pc = 1. / float(length(s))
    # if !ignore1
    #     for p ∈ s
    #         b = T(B)
    #         apply(place(1, p), b)
    #         α += 0.75 * pc * expectmax(A, b, d-1, Before)
    #     end
    # end

    for p ∈ s
        b = T(B)
        apply(place(1, p), b)
        α += 0.75 * pc * expectmax(A, b, d-1, Before)
        b′ = T(B)
        apply(place(3, p), b′)
        α += 0.25 * pc * expectmax(A, b′, d-1, Before)
        #α += pc * expectmax(A, b′, d-1,Before)
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
function expectmax(A::Player, B::T, d::Int, ::Type{Before})::Float64 where T <: AbstractBoard
    if d == 0
        return 0.
    end
    α = -Inf
    for m ∈ 0:3
        b = T(B)
        k = apply(Action(m), b)
        if k == -1
            continue
        end
        # ntuple = ftuple(b)
        # α = max(α, k + get_weight(A, ntuple))
        α = max(α, k + expectmax(A, b, d-1, After))
    end
    if isinf(α)
        return 0.
    end
    return α
end




function take_action(A::Player, b::T) where T <: AbstractBoard
    R = MaxOP = -1
    MaxVal = -Inf
    old = after = tobit(b)
    for op ∈ 0:3
        before = T(b)
        reward = move(before, op)
        if reward == -1
            continue
        end
        #V = float(reward) + get_weight(A, ntuple) + expectmax(A, before, After)
        #V = float(reward) + expectmax(A, before, 1, After)
        V = float(reward) + get_weight(A, before) + expectmax(before, 3, After, QuestBoard ,AnswerBoard ,QuestWeight ,AnswerWeight)
        #println(V)
        # push!(a, V)
        if V > MaxVal
            MaxVal = V
            MaxOP = op
            after = tobit(before)
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


