# swipe backward, processing events at the outputs layer by layer until inputs

Event{T,V} = @NamedTuple {from::Int, to::Int, id::T, msg::V}
Buffer{T,V} = Dict{T,Vector{Union{Nothing,V}}}

"""
Sieve events from outputs to inputs
"""
struct SieveEventsIterator{Itr}
    graph::DAGSieve
    events_itr::Itr
end

Base.IteratorSize(::Type{<:SieveEventsIterator}) = Base.SizeUnknown()
Base.eltype(T::Type{<:SieveEventsIterator}) = msgtype(T)
function gettype(::Type{SieveEventsIterator{Itr}}, sym) where {Itr}
    E = eltype(Itr)
    E <: Event || error("expected Event iterator")
    return fieldtype(E, sym)
end
msgtype(T::Type{<:SieveEventsIterator}) = gettype(T, :msg)
idtype(T::Type{<:SieveEventsIterator}) = gettype(T, :id)

"""
State for SieveEventsIterator iterations
"""
mutable struct SieveEventsState{T,V}
    buffers::Vector{Buffer}
    events::Queue{Event{T,V}}
    matches::Queue{V}
    done::Bool
end

"""
    trickledown(sieve, events)

Send events through the sieve DAG from outputs to inputs.
Given an iterator of events at outputs, return an iterator over events at inputs
"""
function trickledown(n::DAGSieve, events_itr)
    return SieveEventsIterator(n, Iterators.Stateful(events_itr))
end

function Base.iterate(iter::SieveEventsIterator)
    T = idtype(typeof(iter))
    V = msgtype(typeof(iter))
    buffers = [Buffer{T,V}() for i in 1:nv(iter.graph)]
    events = Queue{Event{T,V}}()
    matches = Queue{V}()
    return iterate(iter, SieveEventsState{T,V}(buffers, events, matches, false))
end

function Base.iterate(iter::SieveEventsIterator, state::SieveEventsState)
    while isempty(state.matches)
        if state.done
            return nothing
        end

        newevent = iterate(iter.events_itr)
        if isnothing(newevent)
            state.done = true
        else
            enqueue!(state.events, first(newevent))
        end

        events_to_matches!(state, iter.graph)
    end

    return (dequeue!(state.matches), state)
end

"""
Pops on the queue of events to push to the queue of matches
"""
function events_to_matches!(state::SieveEventsState{T,V}, graph) where {T,V}
    while !isempty(state.events)
        (; from, to, id, msg) = dequeue!(state.events)

        if from == 0
            # add fake outedge for events at outputs
            nout = 1
            fromind = 1
        else
            nout = length(outneighbors(graph, to))
            fromind = portnb(graph, to, from)
        end

        buffer = state.buffers[to]
        if !(id in keys(buffer))
            buffer[id] = fill(nothing, nout)
        end

        if isnothing(buffer[id][fromind])
            buffer[id][fromind] = msg
        elseif buffer[id][fromind] != msg
            error("conflicting messages!")
        end

        if !any(isnothing, buffer[id])
            currnode = graph.nodes[to]
            allmsgs = convert(Vector{V}, buffer[id])
            newid = processid(currnode, id)
            newmsg = processmsgs(currnode, allmsgs)

            if isempty(inneighbors(graph, to))
                # we found a match!
                enqueue!(state.matches, newmsg)
            else
                # propagate msg upstream
                for v in inneighbors(graph, to)
                    newe = (from=to, to=v, id=newid, msg=newmsg)
                    enqueue!(state.events, newe)
                end
            end

            delete!(buffer, id)
        end
    end
end

"""
    portnb(graph, v, next)

Return index of `adjlist[v]` that points to neighbour `next`
"""
function portnb(g, v, nei)
    ind = 1
    outn = outneighbors(g, v)
    while (outn[ind] < nei)
        ind += 1
    end
    outn[ind] == nei || error("could not find edge ($v, $nei)")
    return ind
end
