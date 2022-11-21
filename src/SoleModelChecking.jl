module SoleModelChecking

using DataStructures
using StatsBase
using Random
using Reexport

# Model checker
export Worlds, Adjacents
export KripkeModel, worlds, worlds!, adjacents, adjacents!, evaluations, evaluations!
export memo, contains, push!
export check

export _process_node

# Generation
export gen_kmodel, dispense_alphabet

@reexport using SoleLogics

include("checker.jl")
include("op_behaviour.jl")

include("generator.jl")

end
