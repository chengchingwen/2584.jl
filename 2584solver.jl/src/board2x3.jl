
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
    Board() = new(zeros(Int, 2,3))
    Board(b::Board) = new(copy(b.tile))
    Board(t::Array{Int,2}) = new(t)
end

function (b::Board)(i::Int)
    x,y = fldmod(i, 3)
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

function reflect_horizontal(b::Board)
    t = b.tile
    t[1],t[2],t[5],t[6] = t[5],t[6],t[1],t[2]
    return b
end

function reflect_vertical(b::Board)
    t = b.tile
    t[1],t[3],t[5],t[2],t[4],t[6] = t[2],t[4],t[6],t[1],t[3],t[5]
    return b
end

function move(b::Board, opcode::Int)
    before = Board(copy(b.tile))
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



function move_left(b::Array{Int,2})::Int
    prev = copy(b)
    new = b
    score = 0
    for i ∈ 1:2
        top = 1
        hold = 0
        for j ∈ 1:3
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

function move_up(b::Array{Int,2})::Int
    prev = copy(b)
    new = b
    score = 0
    for i ∈ 1:3
        top = 1
        hold = 0
        for j ∈ 1:2
            tile = new[j,i]::Int
            if tile != 0
                new[j,i] = 0
                if hold != 0
                    top+=1
                    if abs(tile - hold) == 1 || tile === hold === 1
                        tile=max(tile, hold) + 1
                        new[top-1,i] = tile
                        score+= Fib[tile]
                        hold = 0
                    else
                        new[top-1,i] = hold
                        hold = tile
                    end
                else
                    hold = tile
                end
            end
        end
        if hold != 0
            new[top,i] = hold
        end
    end
    return (new != prev) ? score : -1
end

function move_up(b::Board)::Int
    return move_up(b.tile)
end

function move_down(b::Board)::Int
    reflect_vertical(b)
    score::Int = move_up(b)
    reflect_vertical(b)
    return score
end


function Base.show(io::IO, a::Board)
    println(io,"+------------------+")
    for i ∈ 1:2
        @printf io "|%6d%6d%6d|\n" map((x)-> x == 0 ? 0 : Fib[x] ,a.tile[i,:])...
    end
    println(io,"+------------------+")
end

function build_board(B::Board, i::SubArray{SubString{String},1,Array{SubString{String},1},Tuple{UnitRange{Int64}},true})
    for ind in 1:6
        B.tile[map((x)->x+1, divrem(ind-1,3))...]  = parse(Int,i[ind])
    end
end


function Base.view(B::Board, I::Vararg{Any,N}) where {N}
    return view(B.tile, I...)
end
