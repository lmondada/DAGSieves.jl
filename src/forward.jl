# swipe forward, generating layer by layer from input to output

"""
    generate(steps, inputs)

Generate a DAG layer by layer. `inputs` is the first layer, and `steps[i]` are maps from a
vertex in layer i to a vector of vertices in layer i+1.
"""
function generate(steps, inputs::Vector{<:AbstractSieveNode{T}}) where {T}
    g = SimpleDiGraph(length(inputs))
    nodes::Vector{AbstractSieveNode} = copy(inputs)
    layer = Dict{AbstractSieveNode,Int}(v => i for (i, v) in enumerate(inputs))
    for f in steps
        newlayer = typeof(layer)()
        for v in keys(layer)
            newvs = f(v)
            for newv in newvs
                if !(newv in keys(newlayer))
                    add_vertex!(g)
                    newlayer[newv] = nv(g)
                    push!(nodes, newv)
                end
                add_edge!(g, layer[v], newlayer[newv])
            end
        end
        layer = newlayer
    end
    return DAGSieve{T}(g, nodes)
end

"""
    tographviz([io], graph)
    tographviz(filename, graph)

Output graph in DOT format.
"""
function tographviz(io::IO, g::DAGSieve)
    println(io, "digraph sieve {")
    for i in vertices(g)
        println(io, "\t" * string(i) * " [label=\"$(g.nodes[i])\"]")
    end
    for u in vertices(g)
        out_nbrs = outneighbors(g, u)
        length(out_nbrs) == 0 && continue
        println(io, "\t" * string(u) * " -> {" * join(out_nbrs, ',') * "}")
    end
    println(io, "}")
    return nothing
end
tographviz(g::DAGSieve) = tographviz(stdout, g)
function tographviz(s::String, g::DAGSieve)
    open(s, "w") do io
        tographviz(io, g)
    end
end
