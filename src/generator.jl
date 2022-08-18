using Random
rand(MersenneTwister(314592))

# Simple toy generator for a formula-tree
# given expected depth, a set of propositional letters and a set of operators.
#
# Currently, I modified the algorithm described here https://arxiv.org/pdf/2110.09228.pdf
# to match postfix notation.
#
# E.g. of a call to generate(2,P,C):
# (where P and C are taken from MODAL_LOGIC, see SoleLogics at logics.jl)
#
# generate -> ["q", "s", AND, DIAMOND] -> ◊(q ∧ s)
#

# TODO change depth to Int8
function generate(
    depth::Int64,
    P::Vector{String} = SoleLogics.alphabet(MODAL_LOGIC),
    C::Operators = SoleLogics.operators(MODAL_LOGIC)
)
    return tree(_generate(depth, P, C))
end

function _generate(
    depth::Int64,
    P::Vector{String},
    C::Operators
)
    if depth==0
        return rand(P)
    end

    op = rand(C)

    # More elegant using a loop
    if is_unary_operator(op)
        return vcat(_generate(depth-1, P, C), [op])
    elseif is_binary_operator(op)
        return vcat(_generate(depth-1, P, C), _generate(depth-1, P, C), [op])
    else
        error("Expand code")
    end
end

# GES, top down formula generator
# (see Function 1 https://arxiv.org/pdf/2110.09228.pdf)
#=
function GES(depth::Int64, P::Vector{String}, C::Operators)
    if depth == 0
        return rand(P)
    end

    op = rand(C)
    ariety = is_binary_operator(op) ? 2 : 1
    i = rand(1:ariety)

    f = resize!(String[], ariety)
    f[i] = GES(depth-1, P, C)
    for x in (union(1:(i-1),(i+1):ariety))
        f[x] = GES(rand(1:depth), P, C)
    end

    return _str(op) * "(" * join(f, ",") * ")"
end
=#
