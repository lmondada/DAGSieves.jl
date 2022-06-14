struct DAGSieve{T}
    graph::SimpleDiGraph
    nodes::Vector{AbstractSieveNode{T}}
end

underlying(sieve::DAGSieve) = sieve.graph
Graphs.outneighbors(sieve::DAGSieve, v) = outneighbors(sieve.graph, v)
Graphs.inneighbors(sieve::DAGSieve, v) = inneighbors(sieve.graph, v)
Graphs.vertices(sieve::DAGSieve) = vertices(sieve.graph)
Graphs.nv(sieve::DAGSieve) = nv(sieve.graph)
