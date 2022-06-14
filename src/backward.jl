# swipe backward, processing events at the outputs layer by layer until inputs

Event{V} = @NamedTuple {from::Int, to::Int, msg::V}
Buffer{T,V} = Dict{T,Vector{Union{Nothing,V}}}

"""
Sieve events from outputs to inputs
"""
struct SieveEventsIterator{T,Itr}
    graph::DAGSieve{T}
    events_itr::Itr
end

Base.IteratorSize(::Type{<:SieveEventsIterator}) = Base.SizeUnknown()
Base.eltype(::Type{SieveEventsIterator{T,Itr}}) where {T,Itr} = msgtype(eltype(Itr))
msgtype(::Type{E}) where {E<:Event} = fieldtype(E, :msg)

"""
State for SieveEventsIterator iterations
"""
mutable struct SieveEventsState{T,V}
    buffers::Vector{Buffer{T,V}}
    events::Queue{Event{V}}
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

function Base.iterate(iter::SieveEventsIterator{T,Itr}) where {T,Itr}
    V = msgtype(eltype(Itr))
    buffers = [Buffer{T,V}() for i in 1:nv(iter.graph)]
    events = Queue{Event{V}}()
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
        (; from, to, msg) = dequeue!(state.events)

        if from == 0
            # add fake outedge for events at outputs
            nout = 1
            fromind = 1
        else
            nout = length(outneighbors(graph, to))
            fromind = portnb(graph, to, from)
        end

        buffer = state.buffers[to]
        currnode = graph.nodes[to]
        prevnode = from > 0 ? graph.nodes[from] : InputNode{T}()

        msgs = inmsg(currnode, msg, prevnode)

        for msg in msgs
            id = getid(currnode, msg)
            if !(id in keys(buffer))
                buffer[id] = fill(nothing, nout)
            end

            if isnothing(buffer[id][fromind])
                buffer[id][fromind] = msg
            elseif buffer[id][fromind] != msg
                error("conflicting messages!")
            end

            if !any(isnothing, buffer[id])
                allmsgs = convert(Vector{V}, buffer[id])
                newmsg = outmsg(currnode, allmsgs)

                if isempty(inneighbors(graph, to))
                    # we found a match!
                    enqueue!(state.matches, newmsg)
                else
                    # propagate msg upstream
                    for v in inneighbors(graph, to)
                        newe = (from=to, to=v, msg=newmsg)
                        enqueue!(state.events, newe)
                    end
                end

                delete!(buffer, id)
            end
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
