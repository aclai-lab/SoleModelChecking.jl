#=
TODO:
    * Think about types involved (KripkeFrame and other structures)
    * Hashing and memoization
    * Think about other check implementative details
    (...ψ.token could represent some other binary_operator, apart from &&)
=#

struct KripkeFrame
    worlds::Vector{AbstractWorld}
    relations::Dict{Pair{AbstractWorld, AbstractWorld}, Bool}

    function KripkeFrame()
        worlds = AbstractWorld[]
        relations = Dict{Pair{AbstractWorld, AbstractWorld}, Bool}()
        return new(worlds, relations)
    end
end

struct KripkeModel
    frame::KripkeFrame
    evaluations::Dict{AbstractWorld, Vector{String}}

    function KripkeModel()
        evaluations = Dict{AbstractWorld, Vector{String}}()
        return new(KripkeFrame(), evaluations)
    end
end

function check(km::KripkeModel, formula::Formula)
    L = Dict{Pair{String, AbstractWorld}, Bool}()

    for ψ in subformulas(formula.tree)
        if ψ.token ∈ alphabet
            for w ∈ km.frame.worlds
                L[Pair{ψ, w}] = (ψ ∈ km.evaluations[w]) ? true : false
            end
        end

        if Symbol(ψ.token) ∈ binary_operator
            for w ∈ km.frame.worlds
                # memoization here
                L[Pair{ψ, w}] = (L[Pair{ψ.leftchild, w}] && L[Pair{ψ.rightchild, w}]) ? true : false
                # ψ.token could represent some other binary_operator, apart from &&
            end
        end

        if Symbol(ψ.token) ∈ unary_operator
            for w ∈ km.frame.worlds
                for v ∈ km.frame.worlds
                    # incomplete
                end
            end
        end

    end

    return L
end

#= Just for REPL testing
using SoleModelChecking
expression = "(¬(a∧b)∨(□c∧◊d))"
sh = shunting_yard(expression)
f  = tree(sh)
check(KripkeModel(), f)
=#
