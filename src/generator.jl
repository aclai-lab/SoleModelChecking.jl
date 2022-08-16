using Random
rand(MersenneTwister(314592))

# This is just an ugly test/stream of consciousness.
# Please don't even read

P = SoleLogics.alphabet(MODAL_LOGIC)
C = SoleLogics.operators(MODAL_LOGIC)

_str(op::AbstractOperator) = String(Symbol(op))

# GES, top down formula generator
# (see Function 1 https://arxiv.org/pdf/2110.09228.pdf)
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

    return _str(op) * "(" * join(f, "") * ")"
end

# GES(5, P, C)
