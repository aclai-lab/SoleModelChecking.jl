#################################
#          Kripke Model         #
#           components          #
#################################

# Adjacents is the simplest type of relation-collection
struct Adjacents{T<:AbstractWorld} <: AbstractDict{T, Worlds}
    adjacents::Dict{T, Worlds{T}}

    function Adjacents{T}() where {T<:AbstractWorld}
        return new{T}(Dict{T, Worlds{T}}());
    end

    function Adjacents{T}(adjacents::Dict{T, Worlds{T}}) where {T<:AbstractWorld}
        return new{T}(adjacents);
    end
end
Base.iterate(adj::Adjacents, state=1) = state < length(adj.adjacents) ? Base.iterate(adj, state+1) : nothing
Base.keys(adj::Adjacents) = keys(adj.adjacents)
Base.values(adj::Adjacents) = values(adj.adjacents)
Base.length(adj::Adjacents) = length(adj.adjacents)

Base.isassigned(adj::Adjacents, w::AbstractWorld) = (w in adj.adjacents)
Base.getindex(adj::Adjacents, key::AbstractWorld) = adj.adjacents[key]
Base.setindex!(adj::Adjacents, value::Worlds, key::AbstractWorld) = adj.adjacents[key] = value
Base.setindex!(adj::Adjacents, value::AbstractWorld, key::AbstractWorld) = adj.adjacents[key] = Worlds([value])

Base.push!(adj::Adjacents, key::AbstractWorld, value::AbstractWorld) = push!(adj.adjacents[key].worlds, value)
Base.push!(adj::Adjacents, key::AbstractWorld, value::Worlds) = push!(adj.adjacents[key].worlds, value...)

Base.print(io::IO, adj::Adjacents) = print(adj.adjacents)
Base.show(io::IO, adj::Adjacents) = show(adj.adjacents)

# TODO: may be useful to define a common interface for different/"similar" Memo types
#
# e.g at the moment memoization value-type can be switched between Set and Vector as
# `contains`, `push!` and all the operators custom dispatching does support those types.
# This flexibility could be further extended
const WorldsSet{T<:AbstractWorld} = Set{T}  # Write this in SoleWorlds, near Worlds wrapper
const MemoValueType{T} = WorldsSet{T}
const Memo{T} = Dict{SoleLogics.Node, MemoValueType{T}}
# const MemoValue{T} = Worlds{T}            <- a possible working alternative
# const Memo{T} = Dict{Integer, Worlds{T}}   <-

struct KripkeModel{T<:AbstractWorld}
    worlds::Worlds{T}                    # worlds in the model
    adjacents::Adjacents{T}              # neighbors of a given world
    evaluations::Dict{T, LetterAlphabet} # list of prop. letters satisfied by a world

    L::Memo{T}                           # memoization collection associated with this model

    function KripkeModel{T}() where {T<:AbstractWorld}
        worlds = Worlds{T}([])
        adjacents = Dict{T, Worlds{T}}([])
        evaluations = Dict{T, Vector{String}}()
        L = Memo{T}()

        return new{T}(worlds, adjacents, evaluations, L)
    end

    function KripkeModel{T}(
        worlds::Worlds{T},
        adjacents::Adjacents{T},
        evaluations::Dict{T, Vector{String}}
    ) where {T<:AbstractWorld}
        L = Memo{T}()
        return new{T}(worlds, adjacents, evaluations, L)
    end
end
worlds(km::KripkeModel) = km.worlds

adjacents(km::KripkeModel) = km.adjacents
adjacents(km::KripkeModel, w::AbstractWorld) = km.adjacents[w]

evaluations(km::KripkeModel) = km.evaluations
evaluations(km::KripkeModel, w::AbstractWorld) = km.evaluations[w]

Base.eltype(::Type{KripkeModel{T}}) where {T} = T

########################
#     Memo structure   #
#       utilities      #
########################
memo(km::KripkeModel) = km.L
_memo_kexist(km::KripkeModel, key) = haskey(memo(km), key)

memo(km::KripkeModel, key) = begin
    if _memo_kexist(km, key)
        memo(km)[key]
    else
        MemoValueType{eltype(km)}([])
    end
end
memo(km::KripkeModel, key::Formula) = memo(km, key.tree)

# This setter is dangerous as it doesn't check if key exists in the memo structure
# memo!(km::KripkeModel, key::Integer, val::MemoValueType) = km.L[key] = val # memo(km, key) = val

contains(km::KripkeModel, key, value::AbstractWorld) = begin
    (!_memo_kexist(km, key) || !(value in memo(km, key))) ? false : true
end

# If I try to insert in a non-allocated memory place,
# i first reserve space to this new key.
Base.push!(km::KripkeModel, key, val::AbstractWorld) = begin
    if !_memo_kexist(km, key)
        setindex!(memo(km), MemoValueType{eltype(km)}([]), key)
    end
    push!(memo(km, key), val)
end

#################################
#         Model Checking        #
#################################
function _check_alphabet(
    km::KripkeModel,
    psi::Node
)
    # If current world is not associated to the subformula-hash, but it should, then do it.
    for w in worlds(km)
        if !(w in values(memo(km, psi))) && token(psi) in evaluations(km,w)
            push!(km, psi, w)
        end
    end
end

function _check_unary(
    km::KripkeModel,
    psi::Node,
)
    @assert token(psi) in values(operators) "Error - $(token(psi)) is an invalid token"

    # Result is already computed
    if _memo_kexist(km, psi)
        return
    end

    right_key = rightchild(psi)

    # Ad-hoc negation case
    if typeof(token(psi)) == SoleLogics.UnaryOperator{:¬}
        # NOTE: why is casting to MemoValueType needed here?
        setindex!(memo(km), MemoValueType{eltype(km)}(setdiff(worlds(km), memo(km, right_key))), psi)
    elseif is_modal_operator(token(psi))
        for w in worlds(km)
            # Consider w's neighbors
            if dispatch_modop(token(psi), km, w, right_key)
                push!(km, psi, w)
            end
        end
    else
        error("TODO expand code")
    end
end

function _check_binary(
    km::KripkeModel,
    psi::Node
)
    # TODO: `operators` collection has to be removed from parser.jl
    @assert token(psi) in values(operators) "Error - $(token(psi)) is an invalid token"

    # Result is already computed
    if _memo_kexist(km, psi)
        return
    end

    left_key = leftchild(psi)
    right_key = rightchild(psi)

    # Implication case is ad-hoc as it needs to know the
    # universe were the two operands are placed
    if typeof(token(psi)) == SoleLogics.BinaryOperator{:→}
        setindex!(memo(km), IMPLICATION(worlds(km), memo(km, left_key), memo(km, right_key)), psi)
    else
        setindex!(memo(km), token(psi)(memo(km, left_key), memo(km, right_key)), psi)
    end
end

function _process_node(km::KripkeModel, psi::Node)
    # TODO:
    # When alphabets will be well-defined for each logic, use Traits here
    # "token(psi) in alphabet" -> "is_proposition(token(psi))"
    if token(psi) in alphabet
        _check_alphabet(km, psi)
    elseif is_unary_operator(token(psi))
        _check_unary(km, psi)
    elseif is_binary_operator(token(psi))
        _check_binary(km, psi)
    end
end

function check(km::KripkeModel, fx::SoleLogics.Formula; max_size=Inf)
    forget_list = Vector{SoleLogics.Node}()

    for psi in subformulas(fx.tree)
        if SoleLogics.size(psi) > max_size
            push!(forget_list, psi)
        end

        _process_node(km, psi)
    end

    # Those are the worlds where a given formula is valid.
    # After return them, memoization-regulation is applied
    # to forget some formula and free space
    fcollection = memo(km, fx)
    for h in forget_list
        pop!(memo(km), h)   # NOTE: is memory safely deallocated?
    end

    return fcollection
end


# Timed model checking. Return a pair containing the elapsed time
# and a boolean (representing if fx is valid on init_world)
function _timed_check_experiment(km::KripkeModel, fx::SoleLogics.Formula; init_world=PointWorld(1), max_size=Inf)
    forget_list = Vector{Integer}()
    t = zero(Float64)

    for psi in subformulas(fx.tree)
        if SoleLogics.size(psi) > max_size
            push!(forget_list, hash(formula(psi)))
        end
        t = t + @elapsed (_process_node(km, psi))
    end

    t = t + @elapsed (s = init_world in memo(km, fx))

    for h in forget_list
        if haskey(memo(km), h)
            pop!(memo(km), h)   # NOTE: is memory safely deallocated?
        end
    end

    return t, s
end

# Return the elapsed time version of check
function _test_check(init_world::AbstractWorld, max_size::Integer)
    return (km, fx) -> _timed_check_experiment(km, fx, init_world=init_world, max_size=max_size)
end

# TODO: experiments.jl
function experiments(𝑀::Vector{KripkeModel{T}}, Φ::Vector{SoleLogics.Formula}) where {T<:AbstractWorld}
    memo_sizes = [1,2,4,6,8,10,12,14,16]
    init_world = PointWorld(1)
    algorithms = [_test_check(init_world, i) for i in memo_sizes]

    times = Vector{Float64}()
    correctness = Dict{Tuple{KripkeModel, SoleLogics.Formula}, Bool}()

    for alg in algorithms
        elapsed = zero(Float64)
        for km in 𝑀
            for ϕ in Φ
                t, s = alg(km, ϕ)
                elapsed = elapsed + t
                correctness[(km, ϕ)] = s
            end
            empty!(memo(km))
        end

        push!(times, elapsed/length(algorithms))
    end

    return times, correctness
end

#=
    k1 = gen_kmodel(15,3,4)
    k2 = gen_kmodel(25,7,5)
    k3 = gen_kmodel(10,2,2)
    kms = [k1,k2,k3]

    f1 = tree("(p∧q)∧(r∧s)∧(◊t)")
    f2 = tree("(p∧q∧r∧s∧t)")
    f3 = gen_formula(5)
    f4 = gen_formula(10)
    fxs = [f1, f2, f3, f4]

    experiments(kms, fxs)
=#
