#module BOARD
import Base.show

#export Board, move, rotate, show

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

Fib = Fibonacci(17)

mutable struct Board
    tile::Array{Int,2}
    Board() = new(zeros(Int, 4,4))
    Board(b::Board) = new(copy(b.tile))
end

function (b::Board)(i::Int)
    return b.tile'[i+1]
end

function (b::Board)(i::Int, j::Int)
    return b.tile[i+1, j+1]
end

Base.start(b::Board) = Base.start(b.tile)
Base.next(b::Board) = Base.next(b.tile)
Base.done(b::Board) = Base.done(b.tile)
Base.eltype(::Type{Board}) = Base.eltype(b.tile)
Base.length(b::Board) = Base.length(b.tile)
Base.transpose(b::Board) = Base.transpose!(b.tile)

function reflect_horizontal(b::Board)
    b.tile[1:4,1], b.tile[1:4,4] = b.tile[1:4,4], b.tile[1:4,1]
    b.tile[1:4,2], b.tile[1:4,3] = b.tile[1:4,3], b.tile[1:4,2]
    return b
end

function reflect_vertical(b::Board)
    b.tile[1,1:4], b.tile[4,1:4] = b.tile[4,1:4], b.tile[1,1:4]
    b.tile[2,1:4], b.tile[3,1:4] = b.tile[3,1:4], b.tile[2,1:4]
    return b
end

function move(b::Board, opcode::Int)
    action = [opcode==0 && move_up(b),
              opcode==1 && move_right(b),
              opcode==2 && move_down(b),
              opcode==3 && move_left(b)
              ]
    if opcode ∈ 0:3
        return action[opcode+1]
    end
    return -1
end

function move_left(b::Board)
    prev = copy(b.tile)
    new = b.tile
    score = 0
    for i ∈ 1:4
        top = 1
        hold = 0
        for j ∈ 1:4
            tile = new[i,j]
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

function move_right(b::Board)
    reflect_horizontal(b)
    score = move_left(b)
    reflect_horizontal(b)
    return score
end

function move_up(b::Board)
    rotate_right(b)
    score = move_right(b)
    rotate_left(b)
    return score
end

function move_down(b::Board)
    rotate_right(b)
    score = move_left(b)
    rotate_left(b)
    return score
end

# function transpose(b::Board)
#     b.tile = b.tile'
# end

function rotate_right(b::Board)
    b.tile = rotr90(b.tile)
end

function rotate_left(b::Board)
    b.tile = rotl90(b.tile)
end

function rotate(b::Board ; r=1)
    r = mod(r, 4)
    [r == 1 && rotate_right(b),
     r == 2 && (b.tile = rot180(b.tile)),
     r == 3 && rotate_left(b)
     ]
    return b
end

function show(io::IO, a::Board)
    println(io,"+------------------------+")
    for i ∈ 1:4
        @printf io "|%6d%6d%6d%6d|\n" map((x)-> x == 0 ? 0 : Fib[x] ,a.tile[i,1:4])...
    end
    println(io,"+------------------------+")
end

#end

