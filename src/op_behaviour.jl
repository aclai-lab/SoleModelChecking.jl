# Add token type to node

# Temporary file to store operators behaviour.

SoleLogics.NEGATION(a::Bool) = (!a)

SoleLogics.CONJUNCTION(a::Bool, b::Bool) = (a&&b)

SoleLogics.DISJUNCTION(a::Bool, b::Bool) = (a||b)

SoleLogics.IMPLICATION(a::Bool, b::Bool) = ifelse(a == true && b == false, false, true)

# use traits here (is_abstract_modop, is_existential_modop)
function dispatch_modop(
    token::T,
    L::Dict{Tuple{UInt64, AbstractWorld}, Bool},
    neighbors::Vector{AbstractWorld},
    subformula::UInt64, # change to phi
) where {T<:Union{AbstractExistentialModalOperator, AbstractExistentialModalOperator}}
    # ◊ Existential modal operator case:
    # s = false
    # foreach neighbor of psi
    #   s = s or L[(subformula, neighbor)]
    #   if s is true, then i can already stop cycling

    # □ Universal modal operator case:
    # s = true
    # foreach neighbor of psi
    #   s = s and L[(subformula, neighbor)]
    #   if s is false, then i can already stop cycling

    start_cond = (T <: AbstractExistentialModalOperator) ? false : true
    op = (T <: AbstractExistentialModalOperator) ? DISJUNCTION : CONJUNCTION

    s = start_cond
    for neighbor in neighbors
        s = op(s, L[(subformula, neighbor)])
        if s == !start_cond
            break;
        end
    end

    return s
end

#=
This could be the future dispatch_modop structure to implement fuzzy logic
(ICTCS 2020 Time Series Checking with Fuzzy Interval Temporal Logics, pg 10 row 13 to 24)

...
start_cond = (typeof(token(psi)) <: AbstractExistentialModalOperator) ? false : true
op1 = (typeof(token(psi)) <: AbstractExistentialModalOperator) ? DISJUNCTION : CONJUNCTION
op2 = (typeof(token(psi)) <: AbstractExistentialModalOperator) ? CONJUNCTION : IMPLICATION

s = start_cond
for neighbor in neighbors
    s = op1(s, op2(value, L[(subformula, neighbor)]))
    if s == !start_cond
        break;
    end
end
=#
