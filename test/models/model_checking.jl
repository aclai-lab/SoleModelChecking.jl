@testset "Handmade tests about Model Checking" begin
    #  Formula to check: ◊(¬(s)∧(r))
    #
    #  p,q,r
    #   (5) <─────────────────────────┐
    #    ^                            │
    #    │            p,q,r           │
    #   (1)  ────────> (2) ────────> (3) s
    #   p,q             ∧             ^
    #                   │             │
    #                   v             │
    #                  (4) ───────────┘
    #                  p,s

    worlds = Worlds([PointWorld(i) for i = 1:5])

    adjs = Adjacents{PointWorld}()
    setindex!(adjs, Worlds([worlds[2], worlds[5]]), worlds[1])
    setindex!(adjs, Worlds([worlds[3], worlds[4]]), worlds[2])
    setindex!(adjs, worlds[5], worlds[3])
    setindex!(adjs, Worlds([worlds[2], worlds[3]]), worlds[4])
    setindex!(adjs, Worlds{PointWorld}([]), worlds[5])

    evaluations = Dict{PointWorld,Vector{String}}()
    setindex!(evaluations, ["p", "q"], worlds[1])
    setindex!(evaluations, ["p", "q", "r"], worlds[2])
    setindex!(evaluations, ["s"], worlds[3])
    setindex!(evaluations, ["p", "s"], worlds[4])
    setindex!(evaluations, ["p", "q", "r"], worlds[5])

    formula = build_tree(shunting_yard("◊(¬(s)∧(r))"))
    km = KripkeModel{PointWorld}(worlds, adjs, evaluations)

    L = check(km, formula)
    subf = subformulas(tree(formula))
    s = fhash(subf[1])
    @test memo(km, s) == Set{PointWorld}([worlds[3], worlds[4]])
    r = fhash(subf[2])
    @test memo(km, r) == Set{PointWorld}([worlds[2], worlds[5]])
    nots = fhash(subf[3])
    @test memo(km, nots) == Set{PointWorld}([worlds[1], worlds[2], worlds[5]])
    and = fhash(subf[4])
    @test memo(km, and) == Set{PointWorld}([worlds[2], worlds[5]])
    formula = fhash(subf[5])
    @test memo(km, formula) == Set{PointWorld}([worlds[1], worlds[3], worlds[4]])

    #  Formula to check: □(p ∨ (¬(◊r)))
    #
    #                   p
    #                  (3)
    #                   ∧
    #                   │
    #                   v
    #                   s
    #   (1) <────────> (2) ────────> (4)
    #   q,r                           s

    worlds = Worlds([PointWorld(i) for i = 1:4])

    adjs = Adjacents{PointWorld}()
    setindex!(adjs, worlds[2], worlds[1])
    setindex!(adjs, Worlds([worlds[1], worlds[3], worlds[4]]), worlds[2])
    setindex!(adjs, worlds[2], worlds[3])
    setindex!(adjs, Worlds{PointWorld}([]), worlds[4])

    evaluations = Dict{PointWorld,Vector{String}}()
    setindex!(evaluations, ["q", "r"], worlds[1])
    setindex!(evaluations, ["s"], worlds[2])
    setindex!(evaluations, ["p"], worlds[3])
    setindex!(evaluations, ["s"], worlds[4])

    formula = build_tree(shunting_yard("□(p ∨ (¬(◊r)))"))
    km = KripkeModel{PointWorld}(worlds, adjs, evaluations)

    L = check(km, formula)
    subf = subformulas(tree(formula))

    p = fhash(subf[1])
    @test memo(km, p) == Set{PointWorld}([worlds[3]])
    r = fhash(subf[2])
    @test memo(km, r) == Set{PointWorld}([worlds[1]])
    dr = fhash(subf[3])
    @test memo(km, dr) == Set{PointWorld}([worlds[2]])
    ndr = fhash(subf[4])
    @test memo(km, ndr) == Set{PointWorld}([worlds[1], worlds[3], worlds[4]])
    por = fhash(subf[5])
    @test memo(km, por) == Set{PointWorld}([worlds[1], worlds[3], worlds[4]])
    formula = fhash(subf[6])
    @test memo(km, formula) == Set{PointWorld}([worlds[2], worlds[4]])
end

@testset "Multiple models, multiple formulas model, model checking" begin

    for i = 2:10
        kms = [gen_kmodel(i, rand(1:rand(1:i)), rand(1:rand(1:i))) for _ = 1:i]
        fdim = rand(2:i)
        fxs = [gen_formula(fdim) for _ = 1:i]

        outcomes = [
            check(kms, fxs, PointWorld(1), max_fheight_memo = max_memo) for
            max_memo = 1:fdim
        ]
        @test all(y -> y == outcomes[1], outcomes)
    end

end
