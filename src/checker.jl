#=
    TODO:
    * Find a way to memoize "a DISJUNCTION b" with the same hash as "b  DISJUNCTION a"
    * Compare performances (Dict vs SwissDict)
    * see Base.print_array to correctly print Worlds and Relations in REPL
    * add is_modal , is_existential_modal , is_universal_modal traits from SoleTraits
    * adjust worlds and relations (<:AbstractWorld). Also, Worlds wrapper is in SoleWorlds!
    * maybe L could operate through intersection between sets
    * rename relations with adjacents
    * generalize frames to multi-modal case
    * remove hashing (just access dictionaries with strings)
=#

#################################
#          Wrappers             #
#################################
struct Worlds <: AbstractArray{AbstractWorld,1}
    ws::AbstractArray{AbstractWorld,1}
end

Base.size(ws::Worlds) = (length(ws.ws))
Base.IndexStyle(::Type{<:Worlds}) = IndexLinear()
Base.getindex(ws::Worlds, i::Int) = ws.ws[i]
Base.setindex!(ws::Worlds, w::AbstractWorld, i::Int) = ws.ws[i] = w

Base.print_array(io, X::Type{<:Worlds}) = print(X.ws)

struct Relations <: AbstractDict{AbstractWorld, Worlds}
    rels::AbstractDict{AbstractWorld, Worlds}
end

Base.size(rs::Relations) = (length(rs.rels))
Base.IndexStyle(::Type{<:Relations}) = IndexLinear()
Base.getindex(rs::Relations, key::AbstractWorld) = rs.rels[key]
Base.setindex!(rs::Relations, value::Worlds, key::AbstractWorld) = rs.rels[key] = value

#################################
#          KripkeFrame          #
#        and KripkeModel        #
#################################
struct KripkeFrame
    worlds::Vector{AbstractWorld}
    relations::Dict{AbstractWorld, Vector{AbstractWorld}}
    # relations::Dict{Tuple{AbstractWorld, AbstractWorld}, Bool}
end
worlds(kf::KripkeFrame) = kf.worlds
relations(kf::KripkeFrame) = kf.relations
relations(kf::KripkeFrame, w::AbstractWorld) = kf.relations[w]

struct KripkeModel
    frame::KripkeFrame
    valuations::Dict{AbstractWorld, Vector{String}}
end
frame(km::KripkeModel) = km.frame
worlds(km::KripkeModel) = worlds(frame(km))
relations(km::KripkeModel) = relations(frame(km))
relations(km::KripkeModel, w::AbstractWorld) = relations(frame(km), w)
valuations(km::KripkeModel) = km.valuations
valuations(km::KripkeModel, w::AbstractWorld) = km.valuations[w]

#################################
#         Model Checking        #
#################################
function _check_alphabet(
    L::Dict{Tuple{UInt64, AbstractWorld}, Bool},
    km::KripkeModel,
    psi::Node
)
    for w in worlds(km)
        formula_id = hash(formula(psi))
        if !haskey(L, (formula_id, w))
            L[(formula_id, w)] = (token(psi) in valuations(km,w)) ? true : false
        end
    end
end

function _check_unary(
    L::Dict{Tuple{UInt64, AbstractWorld}, Bool},
    km::KripkeModel,
    psi::Node,
)
    @assert token(psi) in values(operators) "Error - $(token(psi)) is an invalid token"

    psi_hash = hash(formula(psi))
    right_hash = hash(formula(rightchild(psi)))

    # TODO: Refactoring here
    for w in worlds(km)
        current_key = (psi_hash, w)
        if haskey(L, current_key)
            continue
        end

        if typeof(token(psi)) == SoleLogics.UnaryOperator{:¬}
            L[current_key] = token(psi)(L[(right_hash, w)])
        elseif typeof(token(psi)) <: AbstractModalOperator # use traits here
            # Symbol(token(psi)) -> :⟨OLL⟩
            # chop(String(:⟨OLL⟩), head=1, tail=1) -> "OLL"
            # Symbol("OLL") -> :OLL
            # Now it's possible to call a function with: eval(:OLL)(args)
            # fx = Symbol(chop(String(Symbol(token(psi))), head=1, tail=1))
            # Currently, only ◊ and □ operators are managed.
            # In the future, "fx" (for example the OLL function if we consider HS3)
            # should be passed to dispatch_modop
            L[current_key] = dispatch_modop(token(psi), L, relations(km, w), right_hash)
        else
            error("TODO expand code")
        end
    end
end

function _check_binary(
    L::Dict{Tuple{UInt64, AbstractWorld}, Bool},
    km::KripkeModel,
    psi::Node
)
    @assert token(psi) in values(operators) "Error - $(token(psi)) is an invalid token"

    psi_hash = hash(formula(psi))
    left_hash = hash(formula(leftchild(psi)))
    right_hash = hash(formula(rightchild(psi)))

    for w in worlds(km)
        current_key = (psi_hash, w)
        if !haskey(L, current_key)
            left_key = (left_hash, w)
            right_key = (right_hash, w)
            # token(psi) works as a function call
            # e.g. ∧(a, b) returns "a && b"
            L[current_key] = token(psi)(L[left_key], L[right_key]) # ? true : false
        end
    end
end

function _process_node(L::Dict{Tuple{UInt64, AbstractWorld}}, km::KripkeModel, psi::Node)
    # When alphabets will be well-defined for each logic, use Traits here
    # "token(psi) in alphabet" -> "is_proposition(token(psi))"
    if token(psi) in alphabet
        _check_alphabet(L, km, psi)
    elseif is_unary_operator(token(psi))
        _check_unary(L, km, psi)
    elseif is_binary_operator(token(psi))
        _check_binary(L, km, psi)
    end
end

function check(km::KripkeModel, formula::Formula)
    L = Dict{Tuple{UInt64, AbstractWorld}, Bool}()

    # For each subformula in ascending order by size
    # evaluate L entry (hash(subformula), world) for each world.
    for psi in subformulas(formula.tree)
        _process_node(L, km, psi)
    end

    return L
end
