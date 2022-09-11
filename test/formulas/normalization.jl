@testset "Normalization correctness" begin

    # A new kripke model km is generated.
    # A new formula is generated and model checking is computed.
    # Then, the memoization structure in km is resetted, the formula is normalized
    # and the model checking is computed again: is this result equal to the previous?
    for _ in 1:100
        N = 20
        km = gen_kmodel(N, rand(1:rand(1:N)), rand(1:rand(1:N)))
        for h in 2:15
            fx = gen_formula(h)
            ans1 = check(km, fx, max_fheight_memo=0)
            fnormalize!(fx)
            ans2 = check(km, fx, max_fheight_memo=0)
            @test ans1 == ans2
        end
    end

end
