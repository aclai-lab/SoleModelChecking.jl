using SoleModelChecking
using Test

@testset "Shunting yard and formula tree" begin

    #          ∨
    #    ┌─────┴─────┐
    #    ¬           ∧
    #    │           │
    #    ┴─┐       ┌─┴─┐
    #      ∧       □   ◊
    #      │       │   │
    #     ┌┴┐      ┴┐  ┴┐
    #     a b       c   d

    exp1 = "(¬(a∧b)∨(□c∧◊d))"
    sh1 = shunting_yard(exp1)
    f1  = tree(sh1)
    @test sh1 == ["a", "b", CONJUNCTION, NEGATION, "c", BOX, "d", DIAMOND, CONJUNCTION, DISJUNCTION]
    @test inorder(f1.tree) == "((¬((a)∧(b)))∨((□(c))∧(◊(d))))"

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
    #     │                 ∧       ◊
    # ┌───┴───┐         ┌───┴───┐   ┴┐
    # a       b         c       d    e

    exp3 = "(a∧b)∧(c∧d)∧(◊e)"
    sh3 = shunting_yard(exp3)
    f3 = tree(sh3)
    @test sh3 == ["a", "b", CONJUNCTION, "c", "d", CONJUNCTION, "e", DIAMOND, CONJUNCTION, CONJUNCTION]
    @test inorder(f3.tree) == "(((a)∧(b))∧(((c)∧(d))∧(◊(e))))"
end

@testset "Checker" begin

end
