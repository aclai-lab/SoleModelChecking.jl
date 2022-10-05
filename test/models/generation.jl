@testset "Fan-in Fan-out based Kripke models generation" begin
    # Given a kripke model, test if it's worlds input and output degrees are lower than a certain threshold
    function graphtest_degrees(
        km::KripkeModel{T},
        n::Integer,
        max_in::Integer,
        max_out::Integer,
    ) where {T<:AbstractWorld}
        @test length(keys(adjacents(km))) - 1 == n    # should be without -1

        # Foreach world its Out Degree is tested foreach world;
        # the numbers of entering edges are regrouped in in_degrees to test In degree later
        in_degrees = Dict{T,Int64}()
        for world in keys(adjacents(km))
            @test length(adjacents(km, world)) <= max_out
            for neighbor in adjacents(km, world)
                if !haskey(in_degrees, neighbor)
                    in_degrees[neighbor] = 0
                end
                in_degrees[neighbor] = in_degrees[neighbor] + 1
            end
        end

        # In Degree is tested
        for in_degree in values(in_degrees)
            @test in_degree <= max_in
        end
    end

    for i = 1:30
        n = 10 * i
        in_degree = rand(1:i)
        out_degree = rand(1:i)
        km = gen_kmodel(
            n,
            SoleLogics.alphabet(MODAL_LOGIC),
            :fanin_fanout,
            in_degree,
            out_degree,
        )
        graphtest_degrees(km, n, in_degree, out_degree)
    end
end
