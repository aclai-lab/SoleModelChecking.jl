@testset "Formula construction from input" begin

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

end
