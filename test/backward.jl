struct TemplateNode <: AbstractSieveNode{String}
    id::Int
end

Msg = String

function DAGSieves.outmsg(tn::TestNode, msgs::Vector{Msg})
    return Msg("")
end

DAGSieves.getid(::TestNode, ::Msg) = ""

function DAGSieves.outmsg(tn::TemplateNode, msgs::Vector{Msg})
    return Msg("T$(tn.id)")
end

@testset "nodes.jl" begin
    lift(f) = tn -> TestNode.(f(tn.id))
    l1(x) = [2x, 3x]
    l2(x) = [x + 1, x]
    l3(x) = [x ÷ 2, 0]
    inputs = TemplateNode.([1, 2, 3])
    fs = [lift(l1), lift(l2), lift(l3)]
    sieve = generate(fs, inputs)

    events = [
        # (from=0, to=22, msg=Msg("")),
        (from=0, to=21, msg=Msg("")),
        (from=0, to=20, msg=Msg("")),
        (from=0, to=19, msg=Msg("")),
        (from=0, to=18, msg=Msg("")),
        (from=0, to=17, msg=Msg("")),
    ]

    it = trickledown(sieve, events)
    @test collect(it) == [Msg("T1")]

    events = [
        (from=0, to=22, msg=Msg("")),
        (from=0, to=21, msg=Msg("")),
        (from=0, to=20, msg=Msg("")),
        (from=0, to=19, msg=Msg("")),
        (from=0, to=18, msg=Msg("")),
        (from=0, to=17, msg=Msg("")),
    ]

    it = trickledown(sieve, events)
    @test Set(it) == Set(Msg("T$i") for i in 1:3)

    events = [
        (from=0, to=22, msg=Msg("")),
        (from=0, to=21, msg=Msg("")),
        (from=0, to=20, msg=Msg("")),
        (from=0, to=19, msg=Msg("")),
        # (from=0, to=18, msg=Msg("")),
        (from=0, to=17, msg=Msg("")),
    ]

    it = trickledown(sieve, events)
    @test isempty(it)

    events = [
        (from=0, to=22, msg=Msg("")),
        (from=0, to=21, msg=Msg("")),
        # (from=0, to=20, msg=Msg("")),
        (from=0, to=19, msg=Msg("")),
        (from=0, to=18, msg=Msg("")),
        (from=0, to=17, msg=Msg("")),
    ]

    it = trickledown(sieve, events)
    @test collect(it) == [Msg("T3")]
end
