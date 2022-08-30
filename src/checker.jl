#################################
#           Wrappers            #
#################################

# Adjacents is the simplest type of
struct Adjacents{T<:AbstractWorld} <: AbstractDict{T, Worlds}
    adjacents::Dict{T, Worlds{T}}

    function Adjacents{T}() where {T<:AbstractWorld}
        return new{T}(Dict{T, Worlds{T}}());
    end

    function Adjacents{T}(adjacents::Dict{T, Worlds{T}}) where {T<:AbstractWorld}
        return new{T}(adjacents);
    end
end
Base.iterate(adj::Adjacents, state=1) = state < length(adj.adjacents) ? Base.iterate(adj, state+1) : nothing
Base.keys(adj::Adjacents) = keys(adj.adjacents)
Base.values(adj::Adjacents) = values(adj.adjacents)
Base.length(adj::Adjacents) = length(adj.adjacents)

Base.isassigned(adj::Adjacents, w::AbstractWorld) = (w in adj.adjacents)
Base.getindex(adj::Adjacents, key::AbstractWorld) = adj.adjacents[key]
Base.setindex!(adj::Adjacents, value::Worlds, key::AbstractWorld) = adj.adjacents[key] = value
Base.setindex!(adj::Adjacents, value::AbstractWorld, key::AbstractWorld) = adj.adjacents[key] = Worlds([value])

Base.push!(adj::Adjacents, key::AbstractWorld, value::AbstractWorld) = push!(adj.adjacents[key].worlds, value)
Base.push!(adj::Adjacents, key::AbstractWorld, value::Worlds) = push!(adj.adjacents[key].worlds, value...)

Base.print(io::IO, adj::Adjacents) = print(adj.adjacents)
Base.show(io::IO, adj::Adjacents) = show(adj.adjacents)

struct KripkeModel{T<:AbstractWorld}
    worlds::Worlds{T}                   # worlds in the model
    adjacents::Adjacents{T}             # neighbors of a given world
    evaluations::Dict{T, Vector{String}} # list of prop. letters satisfied by a world

    # Generalize this using an abstract type, with a common interface
    # with two different types of memoization
    # 1) (Formula, mondo) -> Bool               # memo type 1
    # 2) Formula -> mondi in cui vale Formula   # memo type 2

    # Nel caso senza memoizzazione in realtà ce l'ho ma la resetto ad ogni formula
    L::Dict{Tuple{UInt64, T}, Bool}     # memoization collection associated with this model

    function KripkeModel{T}() where {T<:AbstractWorld}
        worlds = Worlds{T}([])
        adjacents = Dict{T, Worlds{T}}([])
        evaluations = Dict{T, Vector{String}}()
        L = Dict{Tuple{UInt64, T}, Bool}()

        return new{T}(worlds, adjacents, evaluations, L)
    end

    function KripkeModel{T}(
        worlds::Worlds{T},
        adjacents::Adjacents{T},
        evaluations::Dict{T, Vector{String}}
    ) where {T<:AbstractWorld}
        L = Dict{Tuple{UInt64, T}, Bool}()
        return new{T}(worlds, adjacents, evaluations, L)
    end
end
worlds(km::KripkeModel) = km.worlds

adjacents(km::KripkeModel) = km.adjacents
adjacents(km::KripkeModel, w::AbstractWorld) = km.adjacents[w]

evaluations(km::KripkeModel) = km.evaluations
evaluations(km::KripkeModel, w::AbstractWorld) = km.evaluations[w]

memo(km::KripkeModel) = km.L
memo(km, key::Tuple{UInt64, AbstractWorld}) = km.L[key]
memo!(km::KripkeModel, key::Tuple{UInt64, AbstractWorld}, val::Bool) = km.L[key] = val

#################################
#         Model Checking        #
#################################
function _check_alphabet(
    km::KripkeModel,
    psi::Node
)
    for w in worlds(km)
        formula_id = hash(formula(psi))
        if !haskey(memo(km), (formula_id, w))
            memo!(km, (formula_id, w), (token(psi) in evaluations(km,w)) ? true : false)
        end
    end
end

function _check_unary(
    km::KripkeModel,
    psi::Node,
)
    @assert token(psi) in values(operators) "Error - $(token(psi)) is an invalid token"

    psi_hash = hash(formula(psi))
    right_hash = hash(formula(rightchild(psi)))

    for w in worlds(km)
        # If current key is already associated with a value, avoid computing it again
        current_key = (psi_hash, w)
        if haskey(memo(km), current_key)
            continue
        end

        # token(psi) acts like an operator (see op_behaviour.jl)
        if typeof(token(psi)) == SoleLogics.UnaryOperator{:¬}
            memo_value = memo(km, (right_hash, w))
            memo!(km, current_key, token(psi)(memo_value))
        elseif is_modal_operator(token(psi))
            # Visit w's neighbors (see op_behaviour.jl)
            memo!(km, current_key, dispatch_modop(token(psi), km, w, right_hash))
        else
            error("TODO expand code")
        end
    end
end

function _check_binary(
    km::KripkeModel,
    psi::Node
)
    @assert token(psi) in values(operators) "Error - $(token(psi)) is an invalid token"

    psi_hash = hash(formula(psi))
    left_hash = hash(formula(leftchild(psi)))
    right_hash = hash(formula(rightchild(psi)))

    for w in worlds(km)
        current_key = (psi_hash, w)
        if !haskey(memo(km), current_key)
            left_key = (left_hash, w)
            right_key = (right_hash, w)
            # token(psi) works as a function call
            # e.g. ∧(a, b) returns "a && b"
            memo!(km, current_key, token(psi)(memo(km, left_key), memo(km, right_key)))
        end
    end
end

function _process_node(km::KripkeModel, psi::Node)
    # When alphabets will be well-defined for each logic, use Traits here
    # "token(psi) in alphabet" -> "is_proposition(token(psi))"
    if token(psi) in alphabet
        _check_alphabet(km, psi)
    elseif is_unary_operator(token(psi))
        _check_unary(km, psi)
    elseif is_binary_operator(token(psi))
        _check_binary(km, psi)
    end
end

function check(km::KripkeModel, formula::Formula)
    # For each subformula in ascending order by size
    # evaluate L entry (hash(subformula), world) for each world.
    for psi in subformulas(formula.tree)
        _process_node(km, psi)
    end

    return memo(km)
end

#=
    provo le varie funzioni che accettano Φ ed 𝑀 (vedi tesi di Eduard)
    for alg in algs
=#
