using SoleModelChecking
using Test
using Random
using Missings
using Plots
using CSV, Tables
using CPUTime

#=
using BenchmarkTools
BenchmarkTools.DEFAULT_PARAMETERS.samples = 1
BenchmarkTools.DEFAULT_PARAMETERS.evals = 1
=#

###############################
#      Multiple formula       #
#      Multiple models        #
#       Model Checking        #
###############################

# The purpose of this function is to force julia to compile all the functions
# involved in the process of testing mmcheck.
# This is must be called once before measuring times, but doesn't guarantee to compile all
# the needed code.
# Also, this is the ugliest thing I have ever written and should be changed
function __force_compilation__()
    # Setting a specific seed here is crucial as the final plot result could be alterate
    # if this experiment doesn't always triggers the same "compilation-spots".
    Random.seed!(5000)
    kms = [gen_kmodel(30, 5, 5) for _ in 1:30]
    for _ in 1:100
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
    P = SoleLogics.alphabet(MODAL_LOGIC),
    reps::Integer = 1,
    experiment_parametrization::Tuple = (fnumbers, fheight, fheight_memo, Threads.nthreads()),
    rng::Union{Integer,AbstractRNG} = 1337,
    export_plot = true
) where {T<:AbstractWorld}
    # __force_compilation__()
    rng = (typeof(rng) <: Integer) ? Random.MersenneTwister(rng) : rng

    # all the different memoization levels are converted to integers
    fheight_memo = [m == Inf ? fheight : convert(Int64, m) for m in fheight_memo]

    # time matrix is initialized
    times = fill(zero(Float64), length(fheight_memo), fnumbers)

    for _ in 1:reps
        fxs = [gen_formula(fheight, P=P, rng=rng) for _ in 1:fnumbers]
        for m in eachindex(fheight_memo)
            # `fnumbers` model checkings are called, keeping memoization among calls
            current_times = Float64[]
            for i in 1:fnumbers
                push!(current_times, _mmcheck_experiment(𝑀, fxs[i], fheight_memo[m]))
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

    # times are exported in a CSV file
    CSV.write("./test/csv/$(join(experiment_parametrization, "_")).csv", Tables.table(times), append=true)

    # if requested, plots are exported too
    if export_plot
        fpath = "./test/plots/"
        mkpath(fpath)
        # number of formulas vs cumulative time
        plt1 = plot()
        for m in eachindex(fheight_memo)
            plot!(plt1, 1:fnumbers, cumsum(times[m,:]), labels="memo: $(fheight_memo[m])", legend=:topleft)
        end
        savefig(plt1, fpath*"simple-$(join(experiment_parametrization, "_")).png")

        # nth formula vs istantaneous time
        plt2 = plot()
        for m in eachindex(fheight_memo)
            scatter!(plt2, 1:fnumbers, times[m,:], labels="memo: $(fheight_memo[m])", legend=:topleft, markersize=2, markerstrokewidth = 0)
        end
        savefig(plt2, fpath*"scatter-$(join(experiment_parametrization, "_")).png")
    end

    return times
end

# Utility function to retrieve total time elapsed to compute multiple model checkings.
# See mmcheck_experiment.
function _mmcheck_experiment(
    𝑀::Vector{KripkeModel{T}},
    fx::SoleLogics.Formula,
    memo_fheight::Integer;
) where {T<:AbstractWorld}
    elapsed = zero(Float64)
    for km in 𝑀
        elapsed = elapsed + _timed_check_experiment(km, fx, max_fheight_memo=memo_fheight)
    end
    return elapsed
end

# Timed model checking. Return a pair containing the elapsed time
# and a boolean (representing if fx is valid on init_world).
# The latter can be used to test check correctness.
function _timed_check_experiment(
    km::KripkeModel,
    fx::SoleLogics.Formula;
    max_fheight_memo=Inf
)
    forget_list = Vector{SoleLogics.Node}()
    t = zero(Float64)

    if !haskey(memo(km), fhash(fx.tree))
        for psi in subformulas(fx.tree)
            if height(psi) > max_fheight_memo
                push!(forget_list, psi)
            end
            t = t + @CPUelapsed if !haskey(memo(km), fhash(psi)) _process_node(km, psi) end

            #= This is the correct way to measure time without the giant
            (98%) interference of compilation time. But it's too slow and
            BenchmarkTools default "samples" and "evals" parameters must be set to 1.
            if haskey(memo(km), fhash(psi)) continue end
            t = t + @belapsed (_process_node($km, $psi))
            =#
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

# This needs
# number of models, worlds in each model, alphabet cardinality, formula height, number of formulas, repetitions
# e.g 10 20 2 3 1000 10
# TODO: add ArgParser.jl
function driver(
    kwargs...;
    rng::Union{Integer,AbstractRNG} = 1337
)
    rng = (typeof(rng) <: Integer) ? Random.MersenneTwister(rng) : rng
    rng2 = deepcopy(rng)

    # Create an alphabet with kwargs[3]-1 letters
    letters = LetterAlphabet(collect(string.(['a':('a'+(kwargs[3]-1))]...)))
    # Create kwargs[1] models. Each world in/out degree ranges from 1 to kwargs[2]
    kms = [gen_kmodel(kwargs[2], rand(rng, 1:rand(rng, 1:kwargs[2])), rand(rng, 1:rand(rng, 1:kwargs[2])), P=letters, rng=rng) for _ in 1:kwargs[1]]

    # Start an experiment with kwargs[5] formulas, each with height kwargs[4], and repeat it kwargs[6] times
    # NOTE: This code is repeated 2 times in order to be sure to get rid of compilation
    # overhead which drastically affect the final experiment plot.
    # Another solution has to be found as execution time is now doubled.
    # times = mmcheck_experiment(kms, kwargs[5], kwargs[4], collect([0:kwargs[4]]...), P=letters, reps=kwargs[6], rng=rng, export_plot=false)
    times = mmcheck_experiment(
        kms,
        kwargs[5],
        kwargs[4],
        collect([0:kwargs[4]]...),
        P=letters,
        reps=kwargs[6],
        experiment_parametrization=Tuple([kwargs..., Threads.nthreads()]),
        rng=rng2,
    )
end

driver(parse.(Int64, ARGS)..., rng=1337)
