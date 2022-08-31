# NOTE: token type could be directly added to node
# in order to avoid writing typeof(token(node))

# TODO: Define WorldsSet{T} where T is forced to be <:AbstractWorld
# and then remove the where clauses here

SoleLogics.NEGATION(a::Bool) = (!a)
SoleLogics.NEGATION(universe::Worlds{T}, ws::Worlds{T}) where {T<:AbstractWorld} = begin
    return Worlds{T}(setdiff(universe, ws))
end
SoleLogics.NEGATION(universe::Set{T}, ws::Set{T}) where {T<:AbstractWorld} = begin
    return setdiff(universe, ws)
end

SoleLogics.CONJUNCTION(a::Bool, b::Bool) = (a&&b)
SoleLogics.CONJUNCTION(a::Worlds{T}, b::Worlds{T}) where {T<:AbstractWorld} = Worlds{T}(intersect(a,b))
SoleLogics.CONJUNCTION(a::Set{T}, b::Set{T}) where {T<:AbstractWorld} = intersect(a,b)

SoleLogics.DISJUNCTION(a::Bool, b::Bool) = (a||b)
SoleLogics.DISJUNCTION(a::Worlds{T}, b::Worlds{T}) where {T<:AbstractWorld} = Worlds{T}(union(a,b))
SoleLogics.DISJUNCTION(a::Set{T}, b::Set{T}) where {T<:AbstractWorld} = union(a,b)

SoleLogics.IMPLICATION(a::Bool, b::Bool) = ifelse(a == true && b == false, false, true)
SoleLogics.IMPLICATION(a::Worlds{T}, b::Worlds{T}) where {T<:AbstractWorld} = error("TODO Expand code")
SoleLogics.IMPLICATION(a::Set{T}, b::Set{T}) where {T<:AbstractWorld} = error("TODO expand code")

# use traits here (is_abstract_modop, is_existential_modop)
function dispatch_modop(
    token::T,
    km::KripkeModel{WT},
    w::WT,
    phi::Integer
) where {
    T<:AbstractModalOperator,
    WT<:AbstractWorld
}
    # Consider v as some neighbor of our w
    # In the existential case, if some km,v ⊨ phi (possibly one v) then return true
    # In the universal case, if all km,v ⊨ phi then return true

    # ⟨⟩ (or ◊) Existential modal operator case:
    # s = false
    # foreach neighbor of psi
    #   s = s or contains(km, phi, neighbor)
    #   if s is true, then i can already stop cycling   <- short circuit

    # [] (or □) Universal modal operator case:
    # s = true
    # foreach neighbor of psi
    #   s = s and contains(km, phi, neighbor)
    #   if s is false, then i can already stop cycling  <- short circuit

    start_cond = is_universal_modal_operator(token)
    op = is_universal_modal_operator(token) ? CONJUNCTION : DISJUNCTION

    # TODO: test if a solutions which uses set operations is faster here
    # intuitively this should be good in fact, by iterating neighbors one by one,
    # sometime short-circuit happens
    s = start_cond
    for neighbor in adjacents(km, w)
        s = op(s, contains(km, phi, neighbor))
        if s == !start_cond
            break;
        end
    end

    return s
end
