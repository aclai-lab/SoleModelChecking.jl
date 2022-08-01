# Temporary file to store operators behaviour.

SoleLogics.NEGATION(a::Bool) = (!a)

SoleLogics.CONJUNCTION(a::Bool, b::Bool) = (a&&b)

SoleLogics.DISJUNCTION(a::Bool, b::Bool) = (a||b)

SoleLogics.IMPLICATION(a::Bool, b::Bool) = ifelse(a == true && b == false, false, true)

SoleLogics.DIAMOND(
    L::Dict{Tuple{UInt64, AbstractWorld}, Bool},
    neighbors::Vector{AbstractWorld},
    previous_formula::UInt64
) =
begin
    s = false
    for neighbor in neighbors
        s = (s || L[(previous_formula, neighbor)])
        if s == true
            break;
        end
    end
    return s
end

SoleLogics.BOX(
    L::Dict{Tuple{UInt64, AbstractWorld}, Bool},
    neighbors::Vector{AbstractWorld},
    previous_formula::UInt64
) =
begin
    s = true
    for neighbor in neighbors
        s = (s && L[(previous_formula, neighbor)])
        if s == false
            break;
        end
    end
    return s
end
