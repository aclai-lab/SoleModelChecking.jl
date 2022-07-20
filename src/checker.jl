struct KripkeFrame
    𝑊::Vector{AbstractWorld}
    𝑅::Dict{AbstractWorld, Vector{AbstractWorld}}

    function KripkeFrame()
        𝑊 = AbstractWorld[]
        𝑅 = Dict{Pair{AbstractWorld, AbstractWorld}, Bool}()
        return new(𝑊, 𝑅)
    end
end

struct KripkeModel
    𝑊::Vector{AbstractWorld}
    𝑅::Dict{Pair{AbstractWorld, AbstractWorld}, Bool}
    𝑉::Dict{AbstractWorld, Vector{String}}

    function KripkeModel()
        𝑊 = AbstractWorld[]
        𝑅 = Dict{Pair{AbstractWorld, AbstractWorld}, Bool}()
        𝑉 = Dict{AbstractWorld, Vector{String}}()
        return new(𝑊, 𝑅, 𝑉)
    end
end

function check(km::KripkeModel, formula::Formula)
    L = Dict{Pair{String, AbstractWorld}, Bool}()

    for ψ in subformulas(formula.tree)
        if ψ.token ∈ alphabet
            for w ∈ km.𝑊
                L[Pair{ψ, w}] = (ψ ∈ km.𝑉[w]) ? true : false
            end
        end

        if Symbol(ψ.token) ∈ binary_operator
            # Todo - Consider a generic binary operator
            for w ∈ km.𝑊
                L[Pair{ψ, w}] = (L[Pair{ψ.leftchild, w}] && L[Pair{ψ.rightchild, w}]) ? true : false
            end
        end

        if Symbol(ψ.token) ∈ unary_operator
            for w ∈ km.W
                for v ∈ km.w
                    # Todo
                end
            end
        end

    end

    return L
end

#= Just for REPL testing
expression = "(¬(a∧b)∨(□c∧◊d))"
sh = shunting_yard(expression)
f  = tree(sh)
check(KripkeModel(), f)
=#
