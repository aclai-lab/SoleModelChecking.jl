#=
TODO:
    * Think about types involved (KripkeFrame and other structures)
    * Hashing and memoization
    * Think about other check implementative details
    (...psi.token could represent some other binary_operator, apart from &&)
    * Find a way to memoize "a DISJUNCTION b" with the same hash as "b  DISJUNCTION a"
    * Check performances (Dict vs SwissDict)
=#

struct KripkeFrame
    worlds::Vector{AbstractWorld}
    relations::Dict{Tuple{AbstractWorld, AbstractWorld}, Bool}

    function KripkeFrame()
        worlds = AbstractWorld[]
        relations = Dict{Tuple{AbstractWorld, AbstractWorld}, Bool}()
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

function _check_alphabet(
    L::Dict{Tuple{Int, AbstractWorld}, Bool},
    km::KripkeModel,
    psi::Node
)
    for w in km.frame.worlds
        token_id = hash(psi.token)
        if !haskey(L, (token_id, w))
            L[(token_id, w)] = (psi ∈ km.evaluations[w]) ? true : false
        end
    end
end

function _check_unary(
    L::Dict{Tuple{Int, AbstractWorld}, Bool},
    km::KripkeModel,
    psi::Node
)
    @assert psi.token in values(operators) "Error - $(psi.token) is an invalid token"

    #=
    for w in km.frame.worlds
        for v in km.frame.worlds
            # incomplete
        end
    end
    =#
end

function _check_binary(
    L::Dict{Tuple{Int, AbstractWorld}, Bool},
    km::KripkeModel,
    psi::Node
)
    @assert psi.token in values(operators) "Error - $(psi.token) is an invalid token"

    #=
    for w in km.frame.worlds
        token_id = hash(psi.token)
        if !haskey(L, (token_id, w))
            L[(psi, w)] = (L[(psi.leftchild, w)] && L[(psi.rightchild, w)]) ? true : false
        end
    end
    =#
end

function check(km::KripkeModel, formula::Formula)
    L = Dict{Tuple{Int, AbstractWorld}, Bool}()     # memoization dictionary

    for psi in subformulas(formula.tree)
        if psi.token ∈ alphabet
            _check_alphabet(L, km, psi)
        elseif typeof(psi.token) <: SoleLogics.UnaryOperator
            _check_unary(L, km, psi)
        elseif typeof(psi.token) <: SoleLogics.BinaryOperator
            _check_binary(L, km, psi)
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
