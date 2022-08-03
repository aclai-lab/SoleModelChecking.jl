#=
    TODO:
    * Find a way to memoize "a DISJUNCTION b" with the same hash as "b  DISJUNCTION a"
    * Compare performances (Dict vs SwissDict)
=#

struct KripkeFrame
    worlds::Vector{AbstractWorld}
    relations::Dict{AbstractWorld, Vector{AbstractWorld}}
    # relations::Dict{Tuple{AbstractWorld, AbstractWorld}, Bool}
end

struct KripkeModel
    frame::KripkeFrame
    evaluations::Dict{AbstractWorld, Vector{String}}
end

function _check_alphabet(
    L::Dict{Tuple{UInt64, AbstractWorld}, Bool},
    km::KripkeModel,
    psi::Node
)
    for w in km.frame.worlds
        formula_id = hash(formula(psi))
        if !haskey(L, (formula_id, w))
            L[(formula_id, w)] = (token(psi) in km.evaluations[w]) ? true : false
        end
    end
end

function _check_unary(
    L::Dict{Tuple{UInt64, AbstractWorld}, Bool},
    km::KripkeModel,
    psi::Node
)
    @assert token(psi) in values(operators) "Error - $(token(psi)) is an invalid token"

    psi_hash = hash(formula(psi))
    right_hash = hash(formula(rightchild(psi)))

    # TODO: Refactoring here
    for w in km.frame.worlds
        if haskey(L, (psi_hash, w))
            continue
        end

        if typeof(token(psi)) == SoleLogics.UnaryOperator{:¬}
            L[(psi_hash, w)] = token(psi)(L[(right_hash, w)])
        elseif typeof(token(psi)) <: AbstractModalOperator
            # ⟨◊⟩ -> "◊" -> becomes :◊
            fx = Symbol(chop(String(Symbol(token(psi))), head=1, tail=1))
            # eval(:◊)(args)
            L[(psi_hash, w)] = dispatch_modop(psi, L, km.frame.relations[w], right_hash, fx)
            # previous solution
            # L[(psi_hash, w)] = token(psi)(L, km.frame.relations[w], right_hash)
        end
    end
end

function _check_binary(
    L::Dict{Tuple{UInt64, AbstractWorld}, Bool},
    km::KripkeModel,
    psi::Node
)
    @assert psi.token in values(operators) "Error - $(psi.token) is an invalid token"

    psi_hash = hash(formula(psi))
    left_hash = hash(formula(leftchild(psi)))
    right_hash = hash(formula(rightchild(psi)))

    for w in km.frame.worlds
        if !haskey(L, (psi_hash, w))
            # token(psi) works as a function call
            # e.g. ∧(a, b) returns "a && b"
            L[(psi_hash, w)] = token(psi)(L[(left_hash, w)], L[(right_hash, w)]) ? true : false
        end
    end
end

function check(km::KripkeModel, formula::Formula)
    L = Dict{Tuple{UInt64, AbstractWorld}, Bool}()

    # For each subformula in ascending order by size
    # evaluate L entry (hash(subformula), world) for each world.
    for psi in subformulas(formula.tree)
        if psi.token in alphabet
            _check_alphabet(L, km, psi)
        elseif typeof(token(psi)) <: AbstractUnaryOperator
            _check_unary(L, km, psi)
        elseif typeof(token(psi)) <: AbstractBinaryOperator
            _check_binary(L, km, psi)
        end
    end

    return L
end
