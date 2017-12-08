include("./board2x3.jl")
include("./action2x3.jl")
include("./type.jl")

struct Solver
    ans::Float64
    tt::Dict{Type{<:StateType}, Dict{NTuple{6, Int}, Float64}}
    function Solver()
        println("Initializing...")
        s = new(0., Dict(Before=>Dict(), After=>Dict()))
        solve2x3(s)
        println("Done")
        return s
    end
end

function Query(tt::Dict{NTuple{6, Int}, Float64}, b::Board)::Float64
    V = get(tt, Tuple(reflect_vertical(b).tile), -1.)
    if V ≠ -1.
        return V
    end
    V = get(tt, Tuple(reflect_horizontal(b).tile), -1.)
    if V ≠ -1.
        return V
    end
    V = get(tt, Tuple(reflect_vertical(b).tile), -1.)
    if V ≠ -1.
        return V
    end
    V = get(tt, Tuple(reflect_horizontal(b).tile), -1.)
    if V ≠ -1.
        return V
    end
    return -1.
end

Query(S::Solver, b::Board, ::Type{Before}) = Query(S.tt[Before], b)
Query(S::Solver, b::Board, ::Type{After}) = Query(S.tt[After], b)

function solve2x3(S::Solver)
    B = Board()
    for p1 ∈ 0:5
        for t1 = (1,2)
            b = Board(copy(B.tile))
            apply(place(t1, p1), b)
            for p2 ∈ 0:5
                for t2 = (1,2)
                    b2 = Board(copy(b.tile))
                    if apply(place(t2, p2), b2) == -1
                        continue
                    end
                    S.tt[Before][Tuple(b2.tile)] = solve2x3(S, b2, Before)
                end
            end
        end
    end
end

# function expectimax(B::Board, depth::Int)
function solve2x3(S::Solver, B::Board, ::Type{Before})
    q = Query(S, B, Before)
    if q ≠ -1.
        return q
    end
    α = -Inf
    for m ∈ 0:3
        b = Board(copy(B.tile))
        k = apply(Action(m), b)
        if k == -1
            continue
        end
        α = max(α, k + solve2x3(S, b, After))
    end
    if isinf(α)
        S.tt[Before][Tuple(B.tile)] = 0.
        return 0.
    end
    S.tt[Before][Tuple(B.tile)] = α
    return α
end

function solve2x3(S::Solver, B::Board, ::Type{After})
    q = Query(S, B, After)
    if q ≠ -1.
        return q
    end
    α = 0.
    s = collect(p for p in 0:5 if B(p) == 0)
    pc = 1. / length(s)
    for p ∈ s
        b = Board(copy(B.tile))
        apply(place(1, p), b)
        α += 0.9 * pc * solve2x3(S, b, Before)
        b′ = Board(copy(B.tile))
        apply(place(2, p), b′)
        α += 0.1 * pc * solve2x3(S, b′, Before)
    end
    S.tt[After][Tuple(B.tile)] = α
    return α
end

