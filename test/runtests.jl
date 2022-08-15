using SoleModelChecking
using Test

@testset "Shunting yard and formula tree" begin

    #          ∨
    #    ┌─────┴─────┐
    #    ¬           ∧
    #    │           │
    #    ┴─┐       ┌─┴─┐
    #      ∧       []   ⟨⟩
    #      │       │   │
    #     ┌┴┐      ┴┐  ┴┐
    #     a b       c   d

    exp1 = "(¬(a∧b)∨([]c∧⟨⟩d))"
    sh1 = shunting_yard(exp1)
    f1  = tree(sh1)
    @test sh1 == ["a", "b", CONJUNCTION, NEGATION, "c", BOX, "d", DIAMOND, CONJUNCTION, DISJUNCTION]
    @test inorder(f1.tree) == "((¬((a)∧(b)))∨(([](c))∧(⟨⟩(d))))"

    #     ∧
    # ┌───┴────┐
    # a        ∧
    #    ┌─────┴─────┐
    #    b           ∧
    #                │
    #              ┌─┴─┐
    #              c   ∧
    #                  │
    #                 ┌┴┐
    #                 d e
    exp2 = "(a∧b∧c∧d∧e)"
    sh2 = shunting_yard(exp2)
    f2 = tree(sh2)
    @test sh2 == ["a", "b", "c", "d", "e", fill(CONJUNCTION, (1,4))...]
    @test inorder(f2.tree) == "((a)∧((b)∧((c)∧((d)∧(e)))))"

    #             ∧
    #     ┌───────┴─────────────┐
    #     │                     ∧
    #     ∧                 ┌───┴───┐
    #     │                 ∧       ⟨⟩
    # ┌───┴───┐         ┌───┴───┐   ┴┐
    # a       b         c       d    e

    exp3 = "(a∧b)∧(c∧d)∧(⟨⟩e)"
    sh3 = shunting_yard(exp3)
    f3 = tree(sh3)
    @test sh3 == ["a", "b", CONJUNCTION, "c", "d", CONJUNCTION, "e", DIAMOND, CONJUNCTION, CONJUNCTION]
    @test inorder(f3.tree) == "(((a)∧(b))∧(((c)∧(d))∧(⟨⟩(e))))"
end

@testset "Checker" begin

    #  Formula to check: ⟨⟩(¬(s)∧(r))
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

    worlds = Worlds([PointWorld(i) for i in 1:5])

    adjacents = Dict{PointWorld, Worlds{PointWorld}}()
    setindex!(adjacents, Worlds([worlds[2], worlds[5]]), worlds[1])
    setindex!(adjacents, Worlds([worlds[3], worlds[4]]), worlds[2])
    setindex!(adjacents, Worlds([worlds[5]]), worlds[3])
    setindex!(adjacents, Worlds([worlds[2], worlds[3]]), worlds[4])
    setindex!(adjacents, Worlds{PointWorld}([]), worlds[5])

    evaluations = Dict{PointWorld, Vector{String}}()
    setindex!(evaluations, ["p","q"] , worlds[1])
    setindex!(evaluations, ["p","q","r"] , worlds[2])
    setindex!(evaluations, ["s"] , worlds[3])
    setindex!(evaluations, ["p","s"] , worlds[4])
    setindex!(evaluations, ["p","q","r"] , worlds[5])

    formula = tree(shunting_yard("⟨⟩(¬(s)∧(r))"))
    km = KripkeModel{PointWorld}(worlds, adjacents, evaluations)

    L = check(km, formula)
    subf = subformulas(formula.tree)

    s_hash = hash(SoleLogics.formula(subf[1]))
    @test L[(s_hash, worlds[1])] == false
    @test L[(s_hash, worlds[2])] == false
    @test L[(s_hash, worlds[3])] == true
    @test L[(s_hash, worlds[4])] == true
    @test L[(s_hash, worlds[5])] == false

    r_hash = hash(SoleLogics.formula(subf[2]))
    @test L[(r_hash, worlds[1])] == false
    @test L[(r_hash, worlds[2])] == true
    @test L[(r_hash, worlds[3])] == false
    @test L[(r_hash, worlds[4])] == false
    @test L[(r_hash, worlds[5])] == true

    nots_hash = hash(SoleLogics.formula(subf[3]))
    @test L[(nots_hash, worlds[1])] == true
    @test L[(nots_hash, worlds[2])] == true
    @test L[(nots_hash, worlds[3])] == false
    @test L[(nots_hash, worlds[4])] == false
    @test L[(nots_hash, worlds[5])] == true

    and_hash = hash(SoleLogics.formula(subf[4]))
    @test L[(and_hash, worlds[1])] == false
    @test L[(and_hash, worlds[2])] == true
    @test L[(and_hash, worlds[3])] == false
    @test L[(and_hash, worlds[4])] == false
    @test L[(and_hash, worlds[5])] == true

    formula_hash = hash(SoleLogics.formula(subf[5]))
    @test L[(formula_hash, worlds[1])] == true
    @test L[(formula_hash, worlds[2])] == false
    @test L[(formula_hash, worlds[3])] == true
    @test L[(formula_hash, worlds[4])] == true
    @test L[(formula_hash, worlds[5])] == false

    #  Formula to check: [](p ∨ (¬(⟨⟩r)))
    #
    #                   p
    #                  (3)
    #                   ∧
    #                   │
    #                   v
    #                   s
    #   (1) <────────> (2) ────────> (4)
    #   q,r                           s

    worlds = Worlds([PointWorld(i) for i in 1:4])

    adjacents = Dict{PointWorld, Worlds{PointWorld}}()
    setindex!(adjacents, Worlds([worlds[2]]), worlds[1])
    setindex!(adjacents, Worlds([worlds[1], worlds[3], worlds[4]]), worlds[2])
    setindex!(adjacents, Worlds([worlds[2]]), worlds[3])
    setindex!(adjacents, Worlds{PointWorld}([]), worlds[4])

    evaluations = Dict{PointWorld, Vector{String}}()
    setindex!(evaluations, ["q","r"] , worlds[1])
    setindex!(evaluations, ["s"] , worlds[2])
    setindex!(evaluations, ["p"] , worlds[3])
    setindex!(evaluations, ["s"] , worlds[4])

    formula = tree(shunting_yard("[](p ∨ (¬(⟨⟩r)))"))
    km = KripkeModel{PointWorld}(worlds, adjacents, evaluations)

    L = check(km, formula)
    subf = subformulas(formula.tree)

    p_hash = hash(SoleLogics.formula(subf[1]))
    @test L[(p_hash, worlds[1])] == false
    @test L[(p_hash, worlds[2])] == false
    @test L[(p_hash, worlds[3])] == true
    @test L[(p_hash, worlds[4])] == false

    r_hash = hash(SoleLogics.formula(subf[2]))
    @test L[(r_hash, worlds[1])] == true
    @test L[(r_hash, worlds[2])] == false
    @test L[(r_hash, worlds[3])] == false
    @test L[(r_hash, worlds[4])] == false

    dr_hash = hash(SoleLogics.formula(subf[3]))
    @test L[(dr_hash, worlds[1])] == false
    @test L[(dr_hash, worlds[2])] == true
    @test L[(dr_hash, worlds[3])] == false
    @test L[(dr_hash, worlds[4])] == false

    ndr_hash = hash(SoleLogics.formula(subf[4]))
    @test L[(ndr_hash, worlds[1])] == true
    @test L[(ndr_hash, worlds[2])] == false
    @test L[(ndr_hash, worlds[3])] == true
    @test L[(ndr_hash, worlds[4])] == true

    por_hash = hash(SoleLogics.formula(subf[5]))
    @test L[(por_hash, worlds[1])] == true
    @test L[(por_hash, worlds[2])] == false
    @test L[(por_hash, worlds[3])] == true
    @test L[(por_hash, worlds[4])] == true

    formula_hash = hash(SoleLogics.formula(subf[6]))
    @test L[(formula_hash, worlds[1])] == false
    @test L[(formula_hash, worlds[2])] == true
    @test L[(formula_hash, worlds[3])] == false
    @test L[(formula_hash, worlds[4])] == true

end
