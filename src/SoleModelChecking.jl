module SoleModelChecking

using DataStructures
using Reexport

export shunting_yard
export tree, subformulas
export KripkeFrame, KripkeModel, check
export isnumber, isproposition

@reexport using SoleLogics

include("parser.jl")
include("formula_tree.jl")
include("op_behaviour.jl")
include("checker.jl")

end
