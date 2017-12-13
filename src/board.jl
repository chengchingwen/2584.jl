
struct Fibonacci <: AbstractArray{Int, 1}
    count::Int
    Fibo::Array{Int, 1}

    function Fibonacci(count::Int)
        Fibo = Array{Int,1 }(count)
        Fibo[1] = 1
        Fibo[2] = 1
        for i ∈ 3:count
            Fibo[i] = Fibo[i-1] + Fibo[i-2]
        end
        new(count-1, Fibo[2:end])
    end
end

Base.size(F::Fibonacci) = (F.count,)
Base.getindex(F::Fibonacci, i::Int) = F.Fibo[i]
Base.getindex(F::Fibonacci, i::Number) = F[convert(Int, i)]

Fib = Fibonacci(25)

mutable struct Board
    tile::Array{Int,2}
    Board() = new(zeros(Int, 4,4))
    Board(b::Board) = new(copy(b.tile))
    Board(t::Array{Int,2}) = new(t)
end

function (b::Board)(i::Int)
    x,y = fldmod(i, 4)
    return b(x, y)
end

function (b::Board)(i::Int, j::Int)
    return b.tile[i+1, j+1]
end

Base.start(b::Board) = Base.start(b.tile)
Base.next(b::Board) = Base.next(b.tile)
Base.done(b::Board) = Base.done(b.tile)
Base.eltype(::Type{Board}) = Base.eltype(b.tile)
Base.length(b::Board) = Base.length(b.tile)
Base.size(b::Board) = Base.size(b.tile)
Base.size(b::Board, i::Int) = Base.size(b.tile, i)
Base.ndims(b::Board) = Base.ndims(b.tile)
# Base.transpose(b::Board) = Base.transpose!(b.tile)
function Base.transpose(b::Board)
    t = b.tile
    t[1,2], t[1,3],t[1,4],t[2,1],t[3,1],t[4,1] = t[2,1],t[3,1],t[4,1],t[1,2], t[1,3],t[1,4]
    t[2,3], t[2,4], t[3,2], t[4,2] = t[3,2], t[4,2], t[2,3], t[2,4]
    t[3,4], t[4,3] = t[4,3],t[3,4]
    return b
end

function reflect_horizontal(b::Board)
    # b.tile = rotl90(b.tile)'
    t = b.tile
    t[1],t[2],t[3],t[4],t[13],t[14],t[15],t[16] = t[13],t[14],t[15],t[16],t[1],t[2],t[3],t[4]
    t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12] = t[9],t[10],t[11],t[12],t[5],t[6],t[7],t[8]
    return b
end

function reflect_vertical(b::Board)
    t = b.tile
    t[1],t[5],t[9],t[13],t[4],t[8],t[12],t[16] = t[4],t[8],t[12],t[16],t[1],t[5],t[9],t[13]
    t[2],t[6],t[10],t[14],t[3],t[7],t[11],t[15] = t[3],t[7],t[11],t[15],t[2],t[6],t[10],t[14]
    return b
end

function move(b::Board, opcode::Int)
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

# function check(a::Int, b::Int)
#     if a == 0 || b == 0
#         return 0
#     elseif abs(a - b) == 1 || a == b == 1
#         return max(a, b) + 1
#     else
#         return 0
#     end
# end

# function sert_0(f::Array{Int,1})::Array{Int,1}
#     z = -1
#     for i ∈ 1:4
#         if z == -1 && f[i] == 0
#             z = i
#         elseif z ≠ -1 && f[i] ≠ 0
#             f[i], f[z] = f[z], f[i]
#             z += 1
#         end
#     end
#     return f
# end

# function move_line(b::Array{Int,2}, l::Int)::Int
#     score::Int = 0
#     f = sert_0(b[l:l+3])
#     # println(f)
#     i = 1
#     while i < 4
#         z = check(f[i], f[i+1])
#         i+=1
#         if z ≠ 0
#             f[i-1], f[i] = z, 0
#             score+=Fib[z]
#             i+=1
#         end
#     end
#     # println(score)
#     if b[l:l+3] == sert_0(f)
#         return -1
#     end
#     b[l:l+3] = f
#     return score
# end

# function my_move_up(b::Array{Int,2})::Int
#     score::Int = 0
#     flag = 4
#     for i ∈ 1:4:16
#         s = move_line(b, i)
#         if s == -1
#             flag -= 1
#         else
#             score+= s
#         end
#     end
#     return flag==0 ? -1 : score
# end
# my_move_up(b::Board)::Int = my_move_up(b.tile)

function move_left(b::Array{Int,2})::Int
    prev = copy(b)
    new = b
    score = 0
    for i ∈ 1:4
        top = 1
        hold = 0
        for j ∈ 1:4
            tile = new[i,j]::Int
            if tile != 0
                new[i,j] = 0
                if hold != 0
                    top+=1
                    if abs(tile - hold) == 1 || tile === hold === 1
                        tile=max(tile, hold) + 1
                        new[i,top-1] = tile
                        score+= Fib[tile]
                        hold = 0
                    else
                        new[i,top-1] = hold
                        hold = tile
                    end
                else
                    hold = tile
                end
            end
        end
        if hold != 0
            new[i,top] = hold
        end
    end
    return (new != prev) ? score : -1
end

function move_left(b::Board)::Int
    return move_left(b.tile)
end

function move_right(b::Board)::Int
    reflect_horizontal(b)
    score::Int = move_left(b)
    reflect_horizontal(b)
    return score
end

function move_up(b::Board)::Int
    rotate_left(b)
    score::Int = move_left(b)
    rotate_right(b)
    return score
end

function move_down(b::Board)::Int
    rotate_right(b)
    score::Int = move_left(b)
    rotate_left(b)
    return score
end

function rotate_right(b::Board)
    transpose(b)
    reflect_horizontal(b)
    return b
    # b.tile = rotr90(b.tile)
end

function rotate_left(b::Board)
    transpose(b)
    reflect_vertical(b)
    return b
    # b.tile = rotl90(b.tile)
end

function empty(b::Board)::Vector{Int}
    a = Vector{Int}()
    for i in 0:15
        if b(i) == 0
            push!(a, i)
        end
    end
    return a
end

function tobit(b::Board)
    v = UInt128(0)
    for i in 1:4
        k = view(b, i, :)
        t = (UInt128(k[1]) << 24) | (UInt128(k[2]) << 16) | (UInt128(k[3]) << 8) | UInt128(k[4])
        v |= t << (4-i) * 32
    end
    return v
end

function toboard(k::UInt128)
    v=  Board()
    for i in 1:4
        m = (k >> 32 * (4-i)) & 0xffffffff
        v.tile[i,1] = (m >> 8*3) & 0xff
        v.tile[i,2] = (m >> 8*2) & 0xff
        v.tile[i,3] = (m >> 8) & 0xff
        v.tile[i,4] = m & 0xf
    end
    return v
end

function Base.show(io::IO, a::Board)
    println(io,"+------------------------+")
    for i ∈ 1:4
        @printf io "|%6d%6d%6d%6d|\n" map((x)-> x == 0 ? 0 : Fib[x] ,a.tile[i,1:4])...
    end
    println(io,"+------------------------+")
end


function Base.view(B::Board, I::Vararg{Any,N}) where {N}
    return view(B.tile, I...)
end
