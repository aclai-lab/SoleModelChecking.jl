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

# NOTE: _process_node should not be exported but is called from experiments.jl;
# in the latter file, writing include("../src/checker.jl") doesn't work and throws an error.
export _process_node

# Generation
export gnp, fanfan  # NOTE: this is for REPL test purpose and will be removed from here
export gen_kmodel, dispense_alphabet

@reexport using SoleLogics

include("checker.jl")
include("op_behaviour.jl")

include("generator.jl")

end
