abstract type AbstractSieveNode{T} end

struct InputNode{T} <: AbstractSieveNode{T} end

"""
    inmsg(node, msg, from)

Process a message `msg` coming from `from`, return a vector of messages.
"""
inmsg(::AbstractSieveNode, msg, ::AbstractSieveNode) = [msg]

"""
    outmsg(node, msgs, from)

Merge a full set of messages `msgs` from inputs into a single output message.
"""
function outmsg(::AbstractSieveNode, msgs::Vector)
    length(msgs) == 1 || error("Not implemented: outmsg")
    return first(msgs)
end

"""
    getid(node, msg)

Get ID to identify `msg`. If `msg` has the same ID type T, then defaults to `msg`.
"""
getid(::AbstractSieveNode{T}, msg::T) where {T} = msg
getid(::AbstractSieveNode, msg) = error("Not implemented: getid")
