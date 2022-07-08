module SoleModelChecking

using SoleLogics

include("parser.jl")
include("formula_tree.jl")
include("checker.jl")

export shunting_yard, tree, inorder, subformulas

end
