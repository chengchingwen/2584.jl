#module ACTION
include("./board.jl")


struct Action
    opcode::Int
    Action() = new(-1)
    Action(x) = new(x)
    Action(a::Action) = Action(a.opcode)
end


function (a::Action)()::Int
    return a.opcode
end

function apply(a::Action, b::Board)::Int
    if mod(a.opcode,4) == a.opcode
        return move(b,a.opcode)
    elseif b(mod(a.opcode, 16)) == 0
        i,j = fldmod(a.opcode & 0x0f,4)
        b.tile[i+1,j+1] = a.opcode >> 4
        return 0
    else
        return -1
    end
end

function name(a::Action)
    if mod(a.opcode,4) == a.opcode
        if op == 0
            return "slide up"
        elseif op == 1
            return "slide right"
        elseif op == 2
            return "slide down"
        else
            return "slide left"
        end
    else
        return "place $(opcode >> 4))-index at position $(opcode & 0x0f))"
    end
end

function move(i::Int)
    return Action(i)
end

function place(tile::Int, pos::Int)
    return Action((tile << 4) | (pos))
end

#end
