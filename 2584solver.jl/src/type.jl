abstract type  StateType end

struct Before <: StateType end
struct After <: StateType end
struct Illegal <: StateType end

GetName(::Type{Before}) = "before"
GetName(::Type{After}) = "after"
GetName(::Type{Illegal}) = "illegal"
GetName(::Any) = "unknown"

function Base.write(stream::IO, T::Type{<:StateType})
    write(stream, GetName(T))
    return stream
end

is_before(::Type{Before}) = true
is_before(::Type{<:StateType}) = false
is_after(::Type{After}) = true
is_after(::Type{<:StateType}) = false
is_illegal(::Type{Illegal}) = true
is_illegal(::Type{<:StateType}) = false

function read_type(si::Char)
    if si == 'b'
        return Before
    elseif si == 'a'
        return After
    else
        return Illegal
    end
end
