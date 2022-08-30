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
export KripkeModel, check

# Generation
export gen_formula
export gnp, fanfan  #NOTE: this is for test purpose and will be removed later
export gen_kmodel

@reexport using SoleLogics

include("parser.jl")
include("formula_tree.jl")
include("checker.jl")
include("op_behaviour.jl")

include("generator.jl")

end
