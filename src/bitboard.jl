using JLD
include("./board.jl")
precompute = load("./precomputemove.jld", "PrecomputeLeft")

mutable struct BitBoard
    tile::UInt128
    BitBoard() = new(UInt128(0))
    BitBoard(x::UInt128) = new(x)
    BitBoard(b::BitBoard) = new(b.tile)
end

function (b::BitBoard)(i::Int)
    return Int((b.tile >> ((15 - i) * 8)) & 0xff)
end

function (b::BitBoard)(i::Int, j::Int)
    return b( (i * 4) + j )
end


function Base.transpose(b::BitBoard)
    x = b.tile
    t =  (x ⊻ (x >> 24)) & 0x00000000ff00ff0000000000ff00ff00
    x ⊻= t ⊻ (t << 24)
    t =  (x ⊻ (x >> 48)) & 0x0000000000000000ffff0000ffff0000
    x ⊻= t ⊻ (t << 48)
    return BitBoard(x)
end

function Base.transpose!(b::BitBoard)
    x = b.tile
    t =  (x ⊻ (x >> 24)) & 0x00000000ff00ff0000000000ff00ff00
    x ⊻= t ⊻ (t << 24)
    t =  (x ⊻ (x >> 48)) & 0x0000000000000000ffff0000ffff0000
    x ⊻= t ⊻ (t << 48)
    b.tile = x
    return b
end

function reflect_vertical(b::BitBoard)
    x = b.tile
    t = (x ⊻ (x >> 64)) & 0x0000000000000000ffffffffffffffff
    x ⊻= t ⊻ (t << 64)
    t = (x ⊻ (x >> 32)) & 0x00000000ffffffff00000000ffffffff
    x ⊻= t ⊻ (t << 32)
    b.tile = x
    return b
end

function reflect_horizontal(b::BitBoard)
    x = b.tile
    t = (x ⊻ (x >> 16)) & 0x0000ffff0000ffff0000ffff0000ffff
    x ⊻= t ⊻ (t << 16)
    t = (x ⊻ (x >> 8))  & 0x00ff00ff00ff00ff00ff00ff00ff00ff
    x ⊻= t ⊻ (t << 8)
    b.tile = x
    return b
end

function rotate_right(b::BitBoard)
    transpose!(b)
    reflect_horizontal(b)
    return b
end


function rotate_left(b::BitBoard)
    transpose!(b)
    reflect_vertical(b)
    return b
end


toboard(b::BitBoard) = toboard(b.tile)

GetRow(t::BitBoard, r::Int)::UInt32 = UInt32((t.tile >> (32 * (3 - r))) & 0xffffffff)

function move_left(b::BitBoard)::Int
    row1 = GetRow(b, 0)
    row2 = GetRow(b, 1)
    row3 = GetRow(b, 2)
    row4 = GetRow(b, 3)
    a1, r1 = get(precompute, row1, (row1, -1))::Tuple{UInt32, Int}
    a2, r2 = get(precompute, row2, (row2, -1))::Tuple{UInt32, Int}
    a3, r3 = get(precompute, row3, (row3, -1))::Tuple{UInt32, Int}
    a4, r4 = get(precompute, row4, (row4, -1))::Tuple{UInt32, Int}
    α = 0
    if r1 == -1
        r1 == 0
        α+=1
    end
    if r2 == -1
        r2 == 0
        α+=1
    end
    if r3 == -1
        r3 == 0
        α+=1
    end
    if r4 == -1
        r4 == 0
        α+=1
    end
    if  α != 4
        b.tile = (UInt128(a1) << 96) | (UInt128(a2) << 64) | (UInt128(a3) << 32) | UInt128(a4)
        return r1+r2+r3+r4
    else
        return -1
    end
end

function move_right(B::BitBoard)::Int
    reflect_horizontal(B)
    r = move_left(B)
    reflect_horizontal(B)
    return r
end

function move_up(B::BitBoard)::Int
    rotate_left(B)
    r = move_left(B)
    rotate_right(B)
    return r
end

function move_down(B::BitBoard)::Int
    rotate_right(B)
    r = move_left(B)
    rotate_left(B)
    return r
end

function move(b::BitBoard, opcode::Int)
    if opcode == 0
        r = move_up(b)
    elseif opcode == 1
        r = move_right(b)
    elseif opcode == 2
        r = move_down(b)
    elseif opcode == 3
        r = move_left(b)
    else
        r = -1
    end
    return r
end


function empty(b::BitBoard)::Vector{Int}
    a = Vector{Int}()
    for i in 0:15
        if b(i) == 0
            push!(a, i)
        end
    end
    return a
end

function Base.show(io::IO, b::BitBoard)
    println(io,"+------------------------+")
    for i in 0:3 
        @printf "|%6d%6d%6d%6d|\n" map((x)-> x==0?0:Fib[x], (t(i,0), t(i,1), t(i,2), t(i,3)))...
    end
    println(io,"+------------------------+")
end



