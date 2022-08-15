# Add token type to node

# Temporary file to store operators behaviour.

SoleLogics.NEGATION(a::Bool) = (!a)

SoleLogics.CONJUNCTION(a::Bool, b::Bool) = (a&&b)

SoleLogics.DISJUNCTION(a::Bool, b::Bool) = (a||b)

SoleLogics.IMPLICATION(a::Bool, b::Bool) = ifelse(a == true && b == false, false, true)

# use traits here (is_abstract_modop, is_existential_modop)
function dispatch_modop(
    token::T,
    km::KripkeModel{WT},
    current_world::WT,
    subformula::UInt64, # change to phi
) where {
    T<:AbstractModalOperator,
    WT<:AbstractWorld
}
    # Consider v as some neighbor of our current_world
    # In the existential case, if some km,v ⊨ subformula (possibly one v) then return true
    # In the universal case, if all km,v ⊨ subformula then return true

    # ⟨⟩ (or ◊) Existential modal operator case:
    # s = false
    # foreach neighbor of psi
    #   s = s or L[(subformula, neighbor)]
    #   if s is true, then i can already stop cycling

    # [] (or □) Universal modal operator case:
    # s = true
    # foreach neighbor of psi
    #   s = s and L[(subformula, neighbor)]
    #   if s is false, then i can already stop cycling

    start_cond = is_universal_modal_operator(token)
    op = is_universal_modal_operator(token) ? CONJUNCTION : DISJUNCTION

    s = start_cond
    for neighbor in adjacents(km, current_world)
        memo_key = (subformula, neighbor)
        s = op(s,  memo(km, memo_key))
        if s == !start_cond
            break;
        end
    end

    return s
end
