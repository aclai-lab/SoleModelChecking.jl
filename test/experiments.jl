using SoleModelChecking
using Test
using Random
using Missings
using Plots
using CPUTime

# NOTE: -i flag is needed when executing this script outside REPL, to show plots.

###############################
#      Multiple formula       #
#      Multiple models        #
#       Model Checking        #
###############################

# The purpose of this function is to force julia to compile all the functions
# involved in the process of testing mmcheck.
# This is must be called once before measuring times.
# Also, this is the ugliest thing I have ever written and should be changed
function __force_compilation__()
    kms = [gen_kmodel(30, 5, 5) for _ in 1:10]
    for _ in 1:10
        _mmcheck_experiment(kms, 10, 9999)
    end
end

# A random generated formula is applied on multiple kripke models (_mmcheck_experiment).
# This process is repeated `fnumbers` times, thus returning an array of times (Float64),
# for each requested `memo_fheight`.
# Eg: mmcheck_experiment(some_models, 1000, 10, [0,2,4,6]) returns a 4x1000 matrix of times.
function mmcheck_experiment(
    𝑀::Vector{KripkeModel{T}},
    fnumbers::Integer,
    fheight::Integer,
    fheight_memo::Vector{<:Number};
    reps::Integer = 1,
    rng::Integer = 1337
) where {T<:AbstractWorld}
    __force_compilation__()

    # all the different memoization levels are converted to integers
    fheight_memo = [m == Inf ? fheight : convert(Int64, m) for m in fheight_memo]

    times = fill(zero(Float64), length(fheight_memo), fnumbers)

    for _ in 1:reps
        for m in eachindex(fheight_memo)
            # seed is set, then it's increased to guarantee more variability in the future
            Random.seed!(rng)
            rng = rng + 1

            # `fnumbers` model checkings are called, keeping memoization among calls
            current_times = Float64[]
            for i in 1:fnumbers
                push!(current_times, _mmcheck_experiment(𝑀, fheight, fheight_memo[m]))
            end

            # current_times are additioned in the collection wich will be returned
            times[m,:] = times[m,:] + current_times[:]

            # memoization is completely cleaned up; this way next iterations will not cheat
            for km in 𝑀
                empty!(memo(km))
            end
        end
    end
    # mean times
    times = times ./ reps

    # for each requested memo_fheight, a line is plotted
    # number of formulas vs time
    plt1 = plot()
    for m in eachindex(fheight_memo)
        plot!(plt1, 1:fnumbers, cumsum(times[m,:]), labels="memo: $(fheight_memo[m])", legend=:topleft)
    end
    display(plt1)

    # level of memoization vs time
    #=
    plt2 = plot()
    plot!(plt2, fheight_memo[:], [cumsum(times[row,:])[fnumbers] for row in 1:length(fheight_memo)])
    display(plt2)
    =#

    return times
end

# Utility function to retrieve total time elapsed to compute multiple model checkings.
# See mmcheck_experiment.
function _mmcheck_experiment(
    𝑀::Vector{KripkeModel{T}},
    fheight::Integer,
    memo_fheight::Integer
) where {T<:AbstractWorld}
    elapsed = zero(Float64)

    for km in 𝑀
        t = _timed_check_experiment(km, gen_formula(fheight), max_height=memo_fheight)
        elapsed = elapsed + t
    end

    return elapsed
end

# Timed model checking. Return a pair containing the elapsed time
# and a boolean (representing if fx is valid on init_world).
# The latter can be used to test check correctness.
function _timed_check_experiment(
    km::KripkeModel,
    fx::SoleLogics.Formula;
    init_world=PointWorld(1),
    max_height=Inf
)
    forget_list = Vector{SoleLogics.Node}()
    t = zero(Float64)

    if !haskey(memo(km), fhash(fx.tree))    # TODO: this check should be timed too
        for psi in subformulas(fx.tree)
            if height(psi) > max_height
                push!(forget_list, psi)
            end
            t = t + @CPUelapsed if haskey(memo(km), fhash(psi)) continue end
            t = t + @CPUelapsed (_process_node(km, psi))
        end
    end

    for h in forget_list
        k = fhash(h)
        if haskey(memo(km),k)
            empty!(memo(km,k))
            pop!(memo(km), k)
        end
    end

    return t
end

rng = 1337
Random.seed!(rng)
kms = [gen_kmodel(10, rand(1:rand(1:5)), rand(1:rand(1:5)), P=letters) for _ in 1:10]
letters = LetterAlphabet(["p1", "p2", "p3"])
times = mmcheck_experiment(kms, 1000, 3, [0,1,2,3], reps=10, rng=rng)

# kms = [gen_kmodel(50, ["p1", "p2", "p3", "p4", "p5", "p6", "p7"], :fanin_fanout, rand(1:rand(1:50)), rand(1:rand(1:50))) for _ in 1:10]
# kms = [gen_kmodel(10, rand(1:rand(1:5)), rand(1:rand(1:5))) for _ in 1:10]
