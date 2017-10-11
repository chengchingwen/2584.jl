include("./agent.jl")


mutable struct Record <: AbstractArray{Action, 1}
    actions::Array{Action,1}
    time0::Int
    time1::Int
    Record() = new(Action[], 0, 0)
    Record(arg::Action...) = new([arg...], 0,0)
end

Base.size(r::Record) = Base.size(r.actions)
Base.getindex(r::Record, i::Int) = r.actions[i]
Base.getindex(r::Record, i::Number) = r[convert(Int, i)]
Base.setindex!(r::Record, a::Action, i::Int) = (r.actions[i] = a)
Base.push!(r::Record, x::Action)::Array{Action,1} = Base.push!(r.actions, x)

function milli()
    return round(Int, time_ns() / 1e6)
end

function tick(r::Record)
    r.time0 = milli()
end

function tock(r::Record)
    r.time1 = milli()
end

tick_time(r::Record) = r.time0
tock_time(r::Record) = r.time1

function Base.write(stream::IO, r::Record)
    s = size(r,1)
    write(stream, s)
    for act ∈ r
        write(stream, Int16(act.opcode))
    end
    write(stream, r.time0) + write(stream, r.time1)
    return stream
end


function Base.read(stream::IO, r::Record)
    s = read(stream, Int)
    for i ∈ 1:s
        a = Int(read(stream, Int16))
        push!(r, Action(a))
    end
    r.time0 = read(stream, Int)
    r.time1 = read(stream, Int)
    return stream
end


mutable struct Statistic
    total::Int
    block::Int
    data::Array{Record, 1}
    Statistic(t::Int, b::Int = 0) = new(t, b≠0?b:t , [])
end

function Base.show(s::Statistic)
    b = min(size(s.data,1), s.block)
    Duration = Sum = Max = Opc = 0
    stat = zeros(Int,25)
    it = size(s.data,1)
    for i ∈ 1:b
        path = s.data[it]
        game = Board()
        score = 0
        for act ∈ path
            score += apply(act, game)
        end
        Sum += score
        Max = max(score, Max)
        Opc += (size(path,1) -2) >> 1
        tile = 0
        for j ∈ 0:15
            tile = max(tile, game(j))
        end
        if tile != 0
            stat[tile]+=1
        end
        Duration += tock_time(path) - tick_time(path)
        it-=1
    end
    avg = Sum / b
    coef = 100.0 / b
    Ops = Opc * 1000.0 / Duration
    # println("Opc = $(Opc)")
    # println("Dur = $(Duration)")
    println("$(size(s.data,1))\tavg = $(round(Int,avg)), max = $(round(Int,Max)), ops = $(round(Int,Ops))")
    t = 1
    c = 0
    while c < b
        if stat[t] != 0
            accu = sum(stat[t:end])
            println("\t$(Fib[t])\t$(round((accu * coef),1))%\t($(round((stat[t] * coef),1))%)")
        end
        c+=stat[t]
        t+=1
    end
    println()
end



function Summary(s::Statistic)
    block_tmp = s.block
    s.block = size(s.data,1)
    show(s)
    s.block = block_tmp
end


is_finished(s::Statistic) = size(s.data, 1) >= s.total


function open_episode(s::Statistic ,flag::String = "")
    push!(s.data, Record())
    tick(s.data[end])
end

function close_episode(s::Statistic, flag::String = "")
    tock(s.data[end])
    if mod(size(s.data, 1), s.block) == 0
        show(s)
    end
end


make_empty_board(s::Statistic) = Board()
save_action(s::Statistic, a::Action) = push!(s.data[end]::Record, a)::Array{Action,1}


function take_turns(s::Statistic,play::AbstractAgent, evil::AbstractAgent)
    return  max(size(s.data[end],1) + 1, 2) % 2 != 0 ? play : evil
end

function last_turns(s::Statistic, play::AbstractAgent, evil::AbstractAgent)
    return take_turns(s, evil, play)
end



function Base.write(stream::IO, s::Statistic)
    si = size(s.data,1)
    write(stream, si)
    for rec ∈ s.data
        write(stream, rec)
    end
    return stream
end


function Base.read(stream::IO, s::Statistic)
    si = read(stream, Int)
    s.total = s.block = si
    resize!(s.data::Array{Record}, si)
    for i ∈ 1:si
        s.data[i] = Record()
        read(stream, s.data[i])
    end
    return stream
end
