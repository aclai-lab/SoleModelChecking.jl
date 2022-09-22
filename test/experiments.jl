using SoleModelChecking
using Test
using ArgParse
using Random
using Missings
using Plots, Plots.Measures
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

# A random generated formula is applied on multiple kripke models (_mmcheck_experiment).
# This process is repeated `fnumbers` times, thus returning an array of times (Float64),
# for each requested `memo_fheight`.
# Eg: mmcheck_experiment(some_models, 1000, 10, [0,2,4,6]) returns a 4x1000 matrix of times.
function mmcheck_experiment(
    𝑀::Vector{KripkeModel{T}},
    fnumbers::Integer,
    fheight::Integer,
    fheight_memo::Vector{<:Number};
    P::LetterAlphabet = SoleLogics.alphabet(MODAL_LOGIC),
    pruning_factor::Float64 = 0.0,
    reps::Integer = 1,
    experiment_parametrization::Tuple = (fnumbers, fheight, fheight_memo, Threads.nthreads()),
    rng::Union{Integer,AbstractRNG} = 1337,
    export_plot = true
) where {T<:AbstractWorld}
    rng = (typeof(rng) <: Integer) ? Random.MersenneTwister(rng) : rng

    # all the different memoization levels are converted to integers
    fheight_memo = [m == Inf ? fheight : convert(Int64, m) for m in fheight_memo]

    # time matrix is initialized
    times = fill(zero(Float64), length(fheight_memo), fnumbers)

    # Dummy execution
    for _ in 1:(reps*0.1)
        _mmcheck_experiment(𝑀, fnumbers, fheight, fheight_memo, pruning_factor=pruning_factor, rng=rng)
    end
    # Main computational cycle
    for _ in 1:reps
        times = times + _mmcheck_experiment(𝑀, fnumbers, fheight, fheight_memo, P=P, pruning_factor=pruning_factor, rng=rng)
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
            plot!(plt1, 1:fnumbers, cumsum(times[m,:]), labels="memo: $(fheight_memo[m])", margins=10mm, legend=:topleft)
        end
        savefig(plt1, fpath*"simple-$(join(experiment_parametrization, "_")).png")

        # nth formula vs istantaneous time
        plt2 = plot()
        for m in eachindex(fheight_memo)
            scatter!(plt2, 1:fnumbers, times[m,:], labels="memo: $(fheight_memo[m])", margins=10mm, legend=:topleft, markersize=2, markerstrokewidth = 0)
        end
        savefig(plt2, fpath*"scatter-$(join(experiment_parametrization, "_")).png")
    end

    return times
end

function _mmcheck_experiment(
    𝑀::Vector{KripkeModel{T}},
    fnumbers::Integer,
    fheight::Integer,
    fheight_memo::Vector{<:Number};
    P::LetterAlphabet = SoleLogics.alphabet(MODAL_LOGIC),
    pruning_factor::Float64 = 0.0,
    rng::AbstractRNG = Random.GLOBAL_RNG
) where {T <: AbstractWorld}
    # time matrix is initialized
    times = fill(zero(Float64), length(fheight_memo), fnumbers)

    # an array of formulas is generated
    fxs = [
        fnormalize!(gen_formula(fheight, P=P, pruning_factor=pruning_factor, rng=rng))
        for _ in 1:fnumbers
    ]

    for m in eachindex(fheight_memo)
        # `fnumbers` model checkings are called, keeping memoization among calls
        current_times = Float64[]

        # fnumbers times are pushed into current_times
        for i in 1:fnumbers
            elapsed = zero(Float64)
            for km in 𝑀
                elapsed = elapsed + _timed_check_experiment(km, fxs[i], max_fheight_memo=fheight_memo[m])
            end
            push!(current_times, elapsed)
        end

        # a complete level of memoization is now tested
        times[m,:] = current_times[:]
        # memoization is completely cleaned up; this way next iterations will not cheat
        for km in 𝑀
            empty!(memo(km))
        end
    end

    return times
end

# Timed model checking.
function _timed_check_experiment(
    km::KripkeModel,
    fx::SoleLogics.Formula;
    max_fheight_memo=Inf
)
    forget_list = Vector{SoleLogics.Node}()
    t = zero(Float64)

    if !haskey(memo(km), fhash(fx.tree))
        for psi in subformulas(fx.tree)
            if SoleLogics.height(psi) > max_fheight_memo
                push!(forget_list, psi)
            end
            t = t + @CPUelapsed if !haskey(memo(km), fhash(psi)) _process_node(km, psi) end
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

# Experiments driver function
function driver(
    args;
    rng::Union{Integer,AbstractRNG} = 1337
)
    rng = (typeof(rng) <: Integer) ? Random.MersenneTwister(rng) : rng

    letters = LetterAlphabet(collect(string.(['a':('a'+(args["nletters"]-1))]...)))

    # A "primer" Kripke Model is fixed, then models with different Valuations set are generated
    primer = gen_kmodel(args["nworlds"], rand(rng, 1:rand(rng, 1:args["nworlds"])), rand(rng, 1:rand(rng, 1:args["nworlds"])), P=letters, rng=rng)
    kms = [deepcopy(primer) for _ in 1:args["nmodels"]]
    for km in kms
        evaluations!(km, dispense_alphabet(worlds(km), P=letters, rng=rng))
    end

    if args["fmaxheight"] < 7
        fheight_memo = [-1, collect([0:args["fmaxheight"]]...)...]
    else
        fheight_memo = [-1,0,1,2,4,8]
    end

    mmcheck_experiment(
        kms,
        args["nformulas"],
        args["fmaxheight"],
        fheight_memo,
        P=letters,
        pruning_factor=args["prfactor"],
        reps=args["nreps"],
        experiment_parametrization=Tuple([args["nmodels"], args["nworlds"], args["nletters"], args["fmaxheight"], args["nformulas"], args["prfactor"], args["nreps"], Threads.nthreads()]),
        rng=rng,
    )
end

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--nmodels"
            help = "Number of kripke models"
            arg_type = Int
        "--nworlds"
            help = "Number of worlds in each kripke model"
            arg_type = Int
        "--nletters"
            help = "Alphabet cardinality"
            arg_type = Int
        "--fmaxheight"
            help = "Formula max height"
            arg_type = Int
        "--nformulas"
            help = "Number of formulas"
            arg_type = Int
        "--prfactor"
            help = "Pruning factor to shorten generated formulas"
            arg_type = Float64
        "--nreps"
            help = "Number of repetitions"
            arg_type = Int
    end

    return parse_args(s)
end

# e.g julia --project=. test/experiments.jl --nmodels 10 --nworlds 20 --nletters 2 --fmaxheight 3 --nformulas 1000 --prfactor 0.5 --nreps 10
driver(parse_commandline(), rng=1337)
