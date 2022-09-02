using SoleModelChecking
using Test
using Random

Random.seed!(1337)

###############################
#      Multiple formula       #
#      Multiple models        #
#       Model Checking        #
###############################

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
        if haskey(memo(km),h)
            empty!(memo(km,h))
            pop!(memo(km), h)
        end
    end

    return t, s
end

# Return the elapsed time version of check
function _test_check(init_world::AbstractWorld, max_size::Integer)
    return (km, fx) -> _timed_check_experiment(km, fx, init_world=init_world, max_size=max_size)
end

function test_mfmm(
    𝑀::Vector{KripkeModel{T}},
    Φ::Vector{SoleLogics.Formula};
    memo_sizes = collect(range(0,step=2,stop=16)),
    init_world = PointWorld(1)
) where {T<:AbstractWorld}
    algorithms = [_test_check(init_world, i) for i in memo_sizes]

    times = Vector{Float64}()
    outcome = Array{Bool}(undef, length(𝑀), length(Φ))

    for alg in algorithms
        elapsed = zero(Float64)
        #= Previous version,
        where outcome is a Dict{Tuple{KripkeModel, SoleLogics.Formula}, Bool}()
        for km in 𝑀
            for ϕ in Φ
                t, s = alg(km, ϕ)
                elapsed = elapsed + t
                outcome[(km, ϕ)] = s
            end
            empty!(memo(km))
        end
        =#
        for k in eachindex(𝑀)
            for p in eachindex(Φ)
                t, s = alg(𝑀[k], Φ[p])
                elapsed = elapsed + t
                outcome[k,p] = s
            end
            empty!(memo(𝑀[k]))
        end
        push!(times, elapsed/length(algorithms))
    end

    return times, outcome
end

@testset "Multiple Formula Multiple Models Model Checking" begin
    k1 = gen_kmodel(15,3,4)
    k2 = gen_kmodel(25,7,5)
    k3 = gen_kmodel(10,2,2)
    kms = [k1,k2,k3]

    f1 = tree("(p∧q)∧(r∧s)∧(◊t)")
    f2 = tree("(p∧q∧r∧s∧t)")
    f3 = gen_formula(5)
    f4 = gen_formula(10)
    fxs = [f1, f2, f3, f4]

    memo_sizes = collect(range(0, step=2, stop=16))

    # Vector{Float} and Dictionary{Tuple{KripkeModel, Formula}, Bool}
    times, outcome = test_mfmm(kms, fxs, memo_sizes=memo_sizes, init_world=PointWorld(1))

    # Add some test/scan here
    @show times
    @show outcome
end
