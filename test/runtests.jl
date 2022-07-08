using SoleModelChecking
using Test

@testset "SoleModelChecking.jl" begin

    #=
        the idea bheind the testing is the following:
            - testing if the expression without parenthesis is equal length of the one
                obtained by shouting_yard
            - testing if the symbols obtained by shouting_yard are in the expression
            - testing if the combination of the symbols are int the expression
    =#

    @testset "Fisrt expression check" begin
        expression = "(¬(a∧b)∨(□c∧◊d))"

        #testing length of the formulas without parenthesis
        expressionNoPar = replace(expression,['(',')'] => "");
        resultExpr = shunting_yard(expression)
        @test length(resultExpr) == length(expressionNoPar)

        #testing if all the symbol obtained by shouting_yard are in the expression
        for symbol in resultExpr
            @test occursin(symbol,expression)
        end

        formula = tree(resultExpr)

        #testing if all the subformulas are contained in the expression
        subf_array = String[]
        φ = subformulas(formula.tree, subf_array)
        for subformula in φ
            @test occursin(subformula,expression)
        end
    end

    @testset "Second expression check" begin
        expression = "((((((((((((a))))))))))))"

        #testing length of the formulas without parenthesis
        expressionNoPar = replace(expression,['(',')'] => "");
        resultExpr = shunting_yard(expression)
        @test length(resultExpr) == length(expressionNoPar)

        #testing if all the symbol obtained by shouting_yard are in the expression
        for symbol in resultExpr
            @test occursin(symbol,expression)
        end

        formula = tree(resultExpr)

        #testing if all the subformulas are contained in the expression
        subf_array = String[]
        φ = subformulas(formula.tree, subf_array)
        for subformula in φ
            @test occursin(subformula,expression)
        end
    end

    #testing some operators here

end
