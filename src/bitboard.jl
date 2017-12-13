include("./board.jl")

mutable struct BitBoard
    tile::UInt128
    BitBoard() = new(UInt128(0))
    BitBoard(x::UInt128) = new(x)
    BitBoard(b::BitBoard) = new(b.tile)
end

function (b::BitBoard)(i::Int)
    return Int(b.tile >> (15 - i) * 8) & 0xff
end

function (b::BitBoard)(i::Int, j::Int)
    return b( i * 4 + j )
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

function move_left(B::BitBoard)::Int
    b = toboard(B)
    r = move_left(b)
    if r != -1
        B.tile = tobit(b)
    end
    return r
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





