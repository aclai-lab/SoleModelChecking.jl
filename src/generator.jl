######################
#      Formulas      #
#     generation     #
######################

# Simple toy generator for a formula-tree
# given expected depth, a set of propositional letters and a set of operators.
#
# Currently, I modified the first algorithm in https://arxiv.org/pdf/2110.09228.pdf
# to match postfix notation.
#
# P = SoleLogics.alphabet(MODAL_LOGIC)
# C = SoleLogics.operators(MODAL_LOGIC)
# generate(2, P, C) -> tree(["q", "s", AND, DIAMOND]) -> ◊(q ∧ s)

function generate(
    depth::Int64,
    P::Vector{String} = SoleLogics.alphabet(MODAL_LOGIC),
    C::Operators = SoleLogics.operators(MODAL_LOGIC);
    modal_maxdepth = depth
)
    return tree(_generate(depth, P, C, modal_depth=modal_maxdepth))
end

function _generate(
    depth::Int64,
    P::Vector{String},
    C::Operators;
    modal_depth::Int64
)
    # Propositional letters are always leaf
    if depth==1
        return [rand(P)]
    end

    # Random operator is chosen
    # If it is modal but modal_depth has already been reached,
    # then randomly chose another operator until it is validz
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

######################
#       Models       #
#     generation     #
######################

# https://hal.archives-ouvertes.fr/hal-00471255v2/document

# Erdos-Rényi method
function gnp(n::Int64, p::Float64)
    M = _gnp(n, p)

    worlds = Worlds([PointWorld(i) for i in 1:n])
    adjs = Adjacents{PointWorld}()

    # Left triangular matrix is checked to
    for i in 1:n
        neighbors = Worlds{PointWorld}([])
        for j in 1:i
            if M[i,j] == 1
                push!(neighbors.worlds, worlds[j])
            end
        end
        setindex!(adjs, neighbors, worlds[i])
    end

    return adjs
end

function _gnp(n::Int64, p::Float64)
    M = zeros(Int8, n, n)

    for i in 1:n, j in 1:i
        if rand() < p
            M[i,j] = 1
        end
    end

    return M
end

# Fan-in/Fan-out method
function fanfan(n::Int64, id::Int64, od::Int64; threshold=0.5)
    adjs = Adjacents{PointWorld}()
    setindex!(adjs, Worlds{PointWorld}([]), PointWorld(0))

    od_queue = PriorityQueue{PointWorld, Int64}(PointWorld(0) => 0)

    while length(adjs.adjacents) <= n
        if rand() <= threshold
            _fanout(adjs, od_queue, od)
        else
            _fanin(adjs, od_queue, id, od)
        end
    end

    return adjs
end

function _fanout(adjs::Adjacents{PointWorld}, od_queue::PriorityQueue{PointWorld, Int}, od::Int64)
    #=
    Find the vertex v with the biggest difference between
    its out-degree and od. Let (od-m) be this difference.
    Add a random number of vertices between 1 and mo
    to V and add edges from v to these new vertices.
    =#
    v,m = peek(od_queue)

    for i in rand(1:(od-m))
        new_node = PointWorld(length(adjs))
        setindex!(adjs, Worlds{PointWorld}([]), new_node)
        push!(adjs, v, new_node)

        od_queue[new_node] = 0
        od_queue[v] = od_queue[v] + 1
    end
end

function _fanin(adjs::Adjacents{PointWorld}, od_queue::PriorityQueue{PointWorld, Int}, id::Int64, od::Int64)
    #=
    Find the set S of all vertices that have out-degree < od.
    Compute a subset T of S of size at most id.
    Add a new vertex v and add new edges (v, t) for all t ∈ T
    =#
    S = filter(x -> x[2]<od, od_queue)
    T = Set(sample(collect(S), rand(1:min(id, length(S))), replace=false))

    v = PointWorld(length(adjs))
    for t in T
        setindex!(adjs, Worlds{PointWorld}([]), v)
        push!(adjs, t[1], v)

        od_queue[t[1]] = od_queue[t[1]] + 1
        od_queue[v] = 0
    end
end

######################
#        Plot        #
#      Utilities     #
######################

#= Graph plotting
using GraphRecipes
using Plots

const n = 15
const A = Float64[ rand() < 0.5 ? 0 : 1 for i=1:n, j=1:n]
for i=1:n
    A[i, 1:i-1] = A[1:i-1, i]
    A[i, i] = 0
enda

graphplot(A,
          markersize = 0.2,
          node_weights = 1:n,
          markercolor = range(colorant"yellow", stop=colorant"red", length=n),
          names = 1:n,
          fontsize = 10,
          linecolor = :darkgrey
          )
=#
