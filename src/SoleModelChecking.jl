module SoleModelChecking

using DataStructures
using Reexport

# Formula tree
export shunting_yard
export tree, subformulas

# Model checker
export Worlds, Adjacents
export KripkeModel, check

# Generation
export GES

@reexport using SoleLogics

include("parser.jl")
include("formula_tree.jl")
include("checker.jl")
include("op_behaviour.jl")

# include("generator.jl")

end
