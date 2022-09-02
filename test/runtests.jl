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
    s = subf[1]
    @test memo(km, s) == Set{PointWorld}([worlds[3], worlds[4]])
    r = subf[2]
    @test memo(km, r) == Set{PointWorld}([worlds[2], worlds[5]])
    nots = subf[3]
    @test memo(km, nots) == Set{PointWorld}([worlds[1], worlds[2], worlds[5]])
    and = subf[4]
    @test memo(km, and) == Set{PointWorld}([worlds[2], worlds[5]])
    formula = subf[5]
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

    p = subf[1]
    @test memo(km, p) == Set{PointWorld}([worlds[3]])
    r = subf[2]
    @test memo(km, r) == Set{PointWorld}([worlds[1]])
    dr = subf[3]
    @test memo(km, dr) == Set{PointWorld}([worlds[2]])
    ndr = subf[4]
    @test memo(km, ndr) == Set{PointWorld}([worlds[1], worlds[3], worlds[4]])
    por = subf[5]
    @test memo(km, por) == Set{PointWorld}([worlds[1], worlds[3], worlds[4]])
    formula = subf[6]
    @test memo(km, formula) == Set{PointWorld}([worlds[2], worlds[4]])
end

@testset "Formula tree generation" begin

    function fxtest_general(height::Integer)
        formula = gen_formula(height)
        @test SoleLogics.height(formula.tree) == height
        @test SoleLogics.size(formula.tree) >= height
        @test SoleLogics.size(formula.tree) <= 2^height - 1

        for node in subformulas(formula.tree, sorted=false)
            lsize = isdefined(node, :leftchild) ? SoleLogics.size(leftchild(node)) : 0
            rsize = isdefined(node, :rightchild) ? SoleLogics.size(rightchild(node)) : 0
            @test SoleLogics.size(node) == lsize + rsize + 1
        end
    end

    function fxtest_modal(height::Integer, max_modepth::Integer)
        root = gen_formula(height, max_modepth=max_modepth).tree
        @test SoleLogics.modal_depth(root) <= max_modepth
    end

    for i in 1:20
        fxtest_general(i)
        fxtest_modal(i, i-rand(1:i))
    end

end

@testset "Model generation" begin


end
