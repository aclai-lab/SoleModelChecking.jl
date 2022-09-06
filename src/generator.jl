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
# gen_formula(2, P, C) -> tree(["q", "s", AND, DIAMOND]) -> ◊(q ∧ s)

function gen_formula(
    height::Integer;
    P::LetterAlphabet = SoleLogics.alphabet(MODAL_LOGIC),
    C::Operators = SoleLogics.operators(MODAL_LOGIC),
    max_modepth::Integer = height
)
    return tree(_gen_formula(height, P, C, modal_depth=max_modepth))
end

function gen_formula(height::Integer, logic::AbstractLogic; max_modepth::Integer = height)
    return tree(_gen_formula(height, SoleLogics.alphabet(logic), SoleLogics.operators(logic), modal_depth=max_modepth))
end

function _gen_formula(
    height::Integer,
    P::LetterAlphabet,
    C::Operators;
    modal_depth::Integer
)
    # Propositional letters are always leaf
    if height==1
        return [rand(P)]
    end

    # A random valid operator is chosen
    if modal_depth == 0
        #= TODO: this part is broken and the momentary placeholder is ugly
        @assert length(C[!is_modal_operator.(C)]) >= 0
        op = rand(C[!is_modal_operator.(C)])
        =#
        op = rand(filter(x -> !is_modal_operator(x), C))
    else
        op = rand(C)
    end

    # Operator C refers to a number of subformulas equals to its ariety
    f = vcat(map(_ -> _gen_formula(height-1, P, C, modal_depth = modal_depth - is_modal_operator(op)), 1:ariety(op))...)
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
# Create a graph as an adjacency matrix by randomling
# sampling (probability p) the edges between n nodes.
# Convert the same graph to an adjacency list and return it.
function gnp(n::Integer, p::Float64)
    M = _gnp(n, p)

    worlds = Worlds([PointWorld(i) for i in 1:n])
    adjs = Adjacents{PointWorld}()

    # Left triangular matrix is used to generate an adjacency list
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

function _gnp(n::Integer, p::Real)
    M = zeros(Int8, n, n)

    for i in 1:n, j in 1:i
        if rand() < p
            M[i,j] = 1
        end
    end

    return M
end

# Fan-in/Fan-out method
# Create a graph with n nodes as an adjacency list and return it.
# It's possible to set a global maximum to input_degree and output_degree.
# Also it's possible to choose how likely a certain "phase" will happen
# 1) _fanout increases a certain node's output_degree grow by spawning new vertices
# 2) _fanin increases the input_degree of a certain group of nodes
#    by linking a single new vertices to all of them
function fanfan(n::Integer, id::Integer, od::Integer; threshold=0.5)
    adjs = Adjacents{PointWorld}()
    setindex!(adjs, Worlds{PointWorld}([]), PointWorld(0))  # Ecco qua ad esempio metti un GenericWorld

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

function _fanout(
    adjs::Adjacents{PointWorld},
    od_queue::PriorityQueue{PointWorld, Int},
    od::Integer
)
    #=
    Find the vertex v with the biggest difference between its out-degree and od.
    Create a random number of vertices between 1 and (od-m)
    and add edges from v to these new vertices.
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

function _fanin(
    adjs::Adjacents{PointWorld},
    od_queue::PriorityQueue{PointWorld, Int},
    id::Integer,
    od::Integer
)
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

# Associate each world to a subset of proposistional letters
function dispense_alphabet(
    ws::Worlds{T};
    P::LetterAlphabet = SoleLogics.alphabet(MODAL_LOGIC)
) where {T<:AbstractWorld}
    evals = Dict{T, LetterAlphabet}()
    n = length(ws)
    for w in ws
        evals[w] = sample(P, rand(1:length(P)), replace=false)
    end
    return evals
end

# NOTE: read the other gen_kmodel dispatch below as it's signature is more flexible.
# Generate and return a kripke model.
# This utility uses `fanfan` and `dispense_alphabet` default methods
# to define `adjacents` and `evaluations` but one could create its model
# piece by piece and then calling KripkeModel constructor.
function gen_kmodel(
    n::Integer,
    in_degree::Integer,   # needed by fanfan
    out_degree::Integer;  # needed by fanfan
    P::LetterAlphabet = SoleLogics.alphabet(MODAL_LOGIC),
    threshold=0.5         # needed by fanfan
)
    ws = Worlds{PointWorld}(world_gen(n))
    adjs = fanfan(n, in_degree, out_degree, threshold=threshold)
    evs = dispense_alphabet(ws, P=P)
    return KripkeModel{PointWorld}(ws, adjs, evs)
end

# Generate and return a kripke model.
# Example of valid calls:
# gen_kmodel(15, MODAL_LOGIC, :erdos_renyi, 0.42)
# gen_kmodel(10, MODAL_LOGIC, :fanin_fanout, 3, 4)
#
# NOTE:
# This function is a bit tricky as in kwargs (that is, the arguments of the selected method)
# n has to be excluded (in fact it is already the first argument)
# In other words this dispatch is not compatible with graph-generation functions whose
# signature differs from fx(n, other_arguments...)
function gen_kmodel(n::Integer, logic::AbstractLogic, method::Symbol, kwargs...)
    if method == :fanin_fanout
        fx = fanfan
    elseif method == :erdos_renyi
        fx = gnp
    else
        error("Invalid method provided: $method. Refer to the docs <add link here>")
    end

    adjs = fx(n, kwargs...)
    ws = Worlds{PointWorld}(world_gen(length(adjs)))
    evs = dispense_alphabet(ws, P=SoleLogics.alphabet(logic))
    return KripkeModel{PointWorld}(ws, adjs, evs)
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
end

graphplot(A,
          markersize = 0.2,
          node_weights = 1:n,
          markercolor = range(colorant"yellow", stop=colorant"red", length=n),
          names = 1:n,
          fontsize = 10,
          linecolor = :darkgrey
          )
=#
