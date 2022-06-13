using DAGSieves
using Test
using Graphs: edges, nv, outneighbors

@testset "DAGSieves.jl" begin
    # Write your tests here.
    include("forward.jl")
    include("backward.jl")
end
