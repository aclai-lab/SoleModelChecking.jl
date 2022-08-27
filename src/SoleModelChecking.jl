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
export fgen
export gnp, fanfan
export kripke_model

@reexport using SoleLogics

include("parser.jl")
include("formula_tree.jl")
include("checker.jl")
include("op_behaviour.jl")

include("generator.jl")

end
