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
function __force_compilation__()
    kms = [gen_kmodel(30, 5, 5) for _ in 1:10]
    for _ in 1:500
        _mmcheck_experiment(kms, 10, 9999, 1337, 10)
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
    rng::Integer = 1337,
    reps::Integer = 1
) where {T<:AbstractWorld}
    __force_compilation__()

    # all the different memoization levels are converted to integers
    fheight_memo = [m == Inf ? fheight : convert(Int64, m) for m in fheight_memo]

    times = Matrix{Float64}(undef, (length(fheight_memo), fnumbers))

    for m in eachindex(fheight_memo)
        # `fnumbers` model checkings are called, keeping memoization among calls
        current_times = Float64[]
        for i in 1:fnumbers
            push!(current_times, _mmcheck_experiment(𝑀, fheight, fheight_memo[m], rng, reps))
        end

        # current_times are copied in the collection wich will be returned
        times[m,:] = current_times[:]

        # memoization is completely cleaned up; this way next iterations can't cheat
        for km in 𝑀
            empty!(memo(km))
        end
    end

    # for each requested memo_fheight, a line is plotted
    labels=["a", "b", "c","d","e","f","g"]

    # number of formulas vs time
    plt1 = plot()
    for m in eachindex(fheight_memo)
        plot!(plt1, 1:fnumbers, cumsum(times[m,:]), labels=labels[m], legend=:topleft)
    end
    display(plt1)

    # level of memoization
    plt2 = plot()
    plot!(plt2, fheight_memo[:], [cumsum(times[row,:])[fnumbers] for row in 1:length(fheight_memo)])
    display(plt2)

    return times
end

# Utility function to retrieve total time elapsed to compute multiple model checkings.
# See mmcheck_experiment.
function _mmcheck_experiment(
    𝑀::Vector{KripkeModel{T}},
    fheight::Integer,
    memo_fheight::Integer,
    rng::Integer,
    reps::Integer
) where {T<:AbstractWorld}
    Random.seed!(rng)
    elapsed = zero(Float64)

    for km in 𝑀
        total_time = zero(Float64)
        for _ in 1:reps
            t = _timed_check_experiment(km, gen_formula(fheight), max_size=memo_fheight)
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
            t = t + @CPUelapsed if haskey(memo(km), fhash(psi)) continue end
            t = t + @CPUelapsed (_process_node(km, psi))
        end
    end

    t = t + @CPUelapsed (s = init_world in memo(km, fx))

    for h in forget_list
        k = fhash(h)
        if haskey(memo(km),k)
            empty!(memo(km,k))
            pop!(memo(km), k)
        end
    end

    return t
end

kms = [gen_kmodel(20, rand(1:rand(1:20)), rand(1:rand(1:20))) for _ in 1:50]
times = mmcheck_experiment(kms, 100, 5, [0,1,2,3,4,Inf], reps=10)

#=
times = Matrix{Float64}(undef, (2, 5))
times[1,:] = [1,2,3,4,5]
times[2,:] = [6,7,8,9,10]
=#

#=
open("results.txt", "w") do file
    for row in 1:6
        write(file, "$row: ")
        for columns in 1:1000
            write(file, "$(times[row,columns]) ")
        end
        write(file, "\n")
    end
end
=#
