#module ACTION
include("./board2x3.jl")


struct Action
    opcode::Int
    Action() = new(-1)
    Action(x::Int) = new(x)
    Action(a::Action) = Action(a.opcode)
end


function (a::Action)()::Int
    return a.opcode
end

Base.:<(a::Action, b::Action) = <(a.opcode, b.opcode)
Base.:<=(a::Action, b::Action) = <=(a.opcode, b.opcode)
Base.:>(a::Action, b::Action) = >(a.opcode, b.opcode)
Base.:>=(a::Action, b::Action) = >=(a.opcode, b.opcode)
Base.:!=(a::Action, b::Action) = !=(a.opcode, b.opcode)
Base.:(==)(a::Action, b::Action) =  ==(a.opcode, b.opcode)


function apply(a::Action, b::Board)::Int
    if a.opcode == -1
        return -1
    elseif (a.opcode & 0b11 ) == a.opcode
        return move(b,a.opcode)
    elseif b(a.opcode & 0x0f) == 0
        i,j = fldmod((a.opcode & 0x0f), 3)
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
