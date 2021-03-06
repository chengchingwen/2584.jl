type Weight <: AbstractArray{Float64, 1}
    length::Int
    value::Array{Float64, 1}
    Weight() = new(0, Float64[])
    Weight(len::Int) = new( len, zeros(Float64, len))
    function Weight(w::Weight)
        W = new( w.length, w.value)
        w.value = Float64[]
        return W
    end
end


Base.size(w::Weight) = Base.size(w.value)
Base.getindex(w::Weight, i::Int) = w.value[i]
Base.getindex(w::Weight, i::Number) = w[conver(Int, i)]
Base.setindex!(w::Weight, f::Float64, i::Int) = (w.value[i] = f)


function Base.write(stream::IO, w::Weight)
    s = size(w, 1)
    write(stream, s)
    for val ∈ w
        write(stream, val)
    end
    return stream
end

function Base.read(stream::IO, w::Weight)
    if size(w,1) > 0
        error("reading to a non-empty weight")
    end
    s = read(stream, Int)
    w.length = s
    resize!(w.value, s)
    for i ∈ 1:s
        w[i] = read(stream, Float64)
    end
    return stream
end
