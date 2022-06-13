abstract type AbstractSieveNode end

function processid(currnode::AbstractSieveNode, id::T)::T where {T}
    return error("processid")
end
function processmsgs(currnode::AbstractSieveNode, msgs::Vector{V})::V where {V}
    return error("processmsgs")
end
