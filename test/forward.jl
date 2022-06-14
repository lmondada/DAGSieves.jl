struct TestNode <: AbstractSieveNode{String}
    id::Int
end

Base.show(io::IO, tn::TestNode) = print(io, tn.id)

@testset "generate.jl" begin
    lift(f) = tn -> TestNode.(f(tn.id))
    l1(x) = [2x, 3x]
    l2(x) = [x + 1, x]
    l3(x) = [x ÷ 2, 0]
    inputs = TestNode.([1, 2, 3])
    fs = [lift(l1), lift(l2), lift(l3)]
    sieve = generate(fs, inputs)

    g = DAGSieves.underlying(sieve)
    @test nv(g) == 3 + 5 + 8 + 6

    layer = Set(eachindex(inputs))
    for l in 1:3
        newlayer = typeof(layer)()
        for v in layer
            succ = fs[l](sieve.nodes[v])
            @test Set(map(i -> sieve.nodes[i], outneighbors(g, v))) == Set(succ)
            push!(newlayer, outneighbors(g, v)...)
        end
        layer = newlayer
    end
end
