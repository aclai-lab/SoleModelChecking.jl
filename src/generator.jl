using Random
rand(MersenneTwister(314592))

ariety(::AbstractUnaryOperator) = return 1
ariety(::AbstractBinaryOperator) = return 2

# Simple toy generator for a formula-tree
# given expected depth, a set of propositional letters and a set of operators.
#
# Currently, I modified the first algorithm in https://arxiv.org/pdf/2110.09228.pdf
# to match postfix notation.
#
# P = SoleLogics.alphabet(MODAL_LOGIC)
# C = SoleLogics.operators(MODAL_LOGIC)
# generate(2, P, C) -> tree(["q", "s", AND, DIAMOND]) -> ◊(q ∧ s)

# TODO change depth to Int8
function generate(
    depth::Int64,
    P::Vector{String} = SoleLogics.alphabet(MODAL_LOGIC),
    C::Operators = SoleLogics.operators(MODAL_LOGIC);
    modal_depth = depth
)
    return tree(_generate(depth, P, C, modal_depth=modal_depth))
end

function _generate(
    depth::Int64,
    P::Vector{String},
    C::Operators;
    modal_depth::Int64
)
    # Propositional letters are always leaf
    if depth==0
        return rand(P)
    end

    # Random operator is chosen
    # If it is modal but modal_depth has already been reached,
    # then randomly chose another operator until it is valid
    op = rand(C)
    while is_modal_operator(op) && modal_depth==0
        op = rand(C)
    end

    # Operator C refers to a number of subformulas equals to its ariety
    f = vcat(map(_ -> _generate(depth-1, P, C, modal_depth = modal_depth - is_modal_operator(op)), 1:ariety(op))...)
    f = convert(Vector{Union{String, AbstractOperator}}, f)
    push!(f, op)

    return f
end
