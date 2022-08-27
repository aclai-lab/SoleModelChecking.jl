using SoleModelChecking
using Test
using Random

@testset "Shunting yard and formula tree" begin
    # Formula tree testing is further explained in "Formula tree generation" testset

    #          ∨
    #    ┌─────┴─────┐
    #    ¬           ∧
    #    │           │
    #    ┴─┐       ┌─┴─┐
    #      ∧       □   ◊
    #      │       │   │
    #     ┌┴┐      ┴┐  ┴┐
    #     p q       r   s

    exp1 = "(¬(p∧q)∨(□r∧◊s))"
    sh1 = shunting_yard(exp1)
    f1  = tree(sh1)
    @test sh1 == ["p", "q", CONJUNCTION, NEGATION, "r", BOX, "s", DIAMOND, CONJUNCTION, DISJUNCTION]
    @test inorder(f1.tree) == "((¬((p)∧(q)))∨((□(r))∧(◊(s))))"

    #     ∧
    # ┌───┴────┐
    # p        ∧
    #    ┌─────┴─────┐
    #    q           ∧
    #                │
    #              ┌─┴─┐
    #              r   ∧
    #                  │
    #                 ┌┴┐
    #                 s t
    exp2 = "(p∧q∧r∧s∧t)"
    sh2 = shunting_yard(exp2)
    f2 = tree(sh2)
    @test sh2 == ["p", "q", "r", "s", "t", fill(CONJUNCTION, (1,4))...]
    @test inorder(f2.tree) == "((p)∧((q)∧((r)∧((s)∧(t)))))"

    #             ∧
    #     ┌───────┴─────────────┐
    #     │                     ∧
    #     ∧                 ┌───┴───┐
    #     │                 ∧       ◊
    # ┌───┴───┐         ┌───┴───┐   ┴┐
    # p       q         r       s    t

    exp3 = "(p∧q)∧(r∧s)∧(◊t)"
    sh3 = shunting_yard(exp3)
    f3 = tree(sh3)
    @test sh3 == ["p", "q", CONJUNCTION, "r", "s", CONJUNCTION, "t", DIAMOND, CONJUNCTION, CONJUNCTION]
    @test inorder(f3.tree) == "(((p)∧(q))∧(((r)∧(s))∧(◊(t))))"
end

@testset "Checker" begin

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

    worlds = Worlds([PointWorld(i) for i in 1:5])

    adjs = Adjacents{PointWorld}()
    setindex!(adjs, Worlds([worlds[2], worlds[5]]), worlds[1])
    setindex!(adjs, Worlds([worlds[3], worlds[4]]), worlds[2])
    setindex!(adjs, worlds[5], worlds[3])
    setindex!(adjs, Worlds([worlds[2], worlds[3]]), worlds[4])
    setindex!(adjs, Worlds{PointWorld}([]), worlds[5])

    evaluations = Dict{PointWorld, Vector{String}}()
    setindex!(evaluations, ["p","q"] , worlds[1])
    setindex!(evaluations, ["p","q","r"] , worlds[2])
    setindex!(evaluations, ["s"] , worlds[3])
    setindex!(evaluations, ["p","s"] , worlds[4])
    setindex!(evaluations, ["p","q","r"] , worlds[5])

    formula = tree(shunting_yard("◊(¬(s)∧(r))"))
    km = KripkeModel{PointWorld}(worlds, adjs, evaluations)

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

    worlds = Worlds([PointWorld(i) for i in 1:4])

    adjs = Adjacents{PointWorld}()
    setindex!(adjs, worlds[2], worlds[1])
    setindex!(adjs, Worlds([worlds[1], worlds[3], worlds[4]]), worlds[2])
    setindex!(adjs, worlds[2], worlds[3])
    setindex!(adjs, Worlds{PointWorld}([]), worlds[4])

    evaluations = Dict{PointWorld, Vector{String}}()
    setindex!(evaluations, ["q","r"] , worlds[1])
    setindex!(evaluations, ["s"] , worlds[2])
    setindex!(evaluations, ["p"] , worlds[3])
    setindex!(evaluations, ["s"] , worlds[4])

    formula = tree(shunting_yard("□(p ∨ (¬(◊r)))"))
    km = KripkeModel{PointWorld}(worlds, adjs, evaluations)

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

@testset "Formula tree generation" begin

    function fxtest_general(dim::Int64)
        formula = fgen(dim)
        @test height(formula.tree) == dim
        @test SoleLogics.size(formula.tree) >= dim
        @test SoleLogics.size(formula.tree) <= 2^dim - 1

        for node in subformulas(formula.tree, sorted=false)
            lsize = isdefined(node, :leftchild) ? SoleLogics.size(leftchild(node)) : 0
            rsize = isdefined(node, :rightchild) ? SoleLogics.size(rightchild(node)) : 0
            @test SoleLogics.size(node) == lsize + rsize + 1
        end
    end

    function fxtest_modal(dim::Int64)
        error("TODO expand code")
    end

    # P = SoleLogics.alphabet(MODAL_LOGIC)
    # C = SoleLogics.operators(MODAL_LOGIC)

    for i in 1:20
        fxtest_general(i)
    end

end

@testset "Model generation" begin

    function test_km(dim::Int64, id::Int64, od::Int64)
        error("TODO expand code")
    end

end
