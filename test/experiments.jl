using SoleModelChecking
using Test
using Random
using Missings
using Plots
using BenchmarkTools

# NOTE: -i flag is needed when executing this script outside REPL, to show plots.

###############################
#      Multiple formula       #
#      Multiple models        #
#       Model Checking        #
###############################

# A random generated formula is applied on multiple kripke models (_mmcheck_experiment).
# This process is repeated `fnumbers` times, thus returning an array of times (Float64),
# for each requested `memo_size`.
# Eg: mmcheck_experiment(some_models, 1000, 10, [0,2,4,6]) returns a 4x1000 matrix of times.
function mmcheck_experiment(
    𝑀::Vector{KripkeModel{T}},
    fnumbers::Integer,
    fdepth::Integer,
    memo_sizes::Vector{Int64};
    rng::Integer = 1337,
    reps::Integer = 1,
    isplotted::Bool = false
) where {T<:AbstractWorld}
    times = Matrix{Float64}(undef, (length(memo_sizes), fnumbers))

    for m in eachindex(memo_sizes)
        # `fnumbers` model checkings are called, keeping memoization among calls
        current_times = Float64[]
        for i in 1:fnumbers
            push!(current_times, _mmcheck_experiment(𝑀, fdepth, memo_sizes[m], rng, reps))
        end

        # current_times are copied in the collection wich will be returned
        times[m,:] = current_times[:]

        # memoization is completely cleaned up; this way next iterations can't cheat
        for km in 𝑀
            empty!(memo(km))
        end
    end

    # for each requested memo_size, a line is plotted
    if isplotted
        plt = plot()
        for m in eachindex(memo_sizes)
            plot!(plt, 1:fnumbers, cumsum(times[m,:]))
        end
        display(plt)
    end

    return times
end

# Utility function to retrieve total time elapsed to compute multiple model checkings.
# See mmcheck_experiment.
function _mmcheck_experiment(
    𝑀::Vector{KripkeModel{T}},
    fdepth::Integer,
    memo_size::Integer,
    rng::Integer,
    reps::Integer
) where {T<:AbstractWorld}
    Random.seed!(rng)
    elapsed = zero(Float64)

    for km in 𝑀
        total_time = zero(Float64)
        for rep in 1:reps
            t, s = _timed_check_experiment(km, gen_formula(fdepth), max_size=memo_size)
            total_time = total_time + t
        end
        elapsed = elapsed + total_time/reps
    end

    return elapsed
end

# Timed model checking. Return a pair containing the elapsed time
# and a boolean (representing if fx is valid on init_world).
# The latter can be used to test check correctness.
function _timed_check_experiment(km::KripkeModel, fx::SoleLogics.Formula; init_world=PointWorld(1), max_size=Inf)
    forget_list = Vector{SoleLogics.Node}()
    t = zero(Float64)

    if !haskey(memo(km), fhash(fx.tree))
        for psi in subformulas(fx.tree)
            if height(psi) > max_size
                push!(forget_list, psi)
            end
            t = t + @elapsed if haskey(memo(km), fhash(psi)) continue end
            t = t + @elapsed (_process_node(km, psi))
        end
    end

    t = t + @elapsed (s = init_world in memo(km, fx))

    for h in forget_list
        k = fhash(h)
        if haskey(memo(km),k)
            empty!(memo(km,k))
            pop!(memo(km), k)
        end
    end

    return t, s
end

kms = [gen_kmodel(10, 2, 2) for _ in 1:5]
# REVIEW:
# For some reason, this happens https://groups.google.com/g/julia-users/c/b8pTffun3PI
# This time has to be ignored as compilation time is considered too...
mmcheck_experiment(kms, 1000, 5, [0,5,10], isplotted=false) #please don't read this atm.

kms = [gen_kmodel(10, 2, 2) for _ in 1:5]
mmcheck_experiment(kms, 2000, 7, [1,2,3,4,5,6,7], reps=10, isplotted=true)
