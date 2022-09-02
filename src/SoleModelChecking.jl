module SoleModelChecking

using DataStructures
using StatsBase
using Random
using Reexport

using GraphPlot

# Formula tree
export shunting_yard
export tree, subformulas

# Model checker
export Worlds, Adjacents
export KripkeModel, worlds, adjacents, evaluations
export memo, contains, push!
export check, _process_node # NOTE: _process_node should not be exported but is called from experiments.jl
export test_mfmm  # NOTE: this is now in experiments.jl and will be removed from here

# Generation
export gen_formula
export gnp, fanfan  # NOTE: this is for REPL test purpose and will be removed from here
export gen_kmodel

@reexport using SoleLogics

include("parser.jl")
include("formula_tree.jl")
include("checker.jl")
include("op_behaviour.jl")

include("generator.jl")

end
