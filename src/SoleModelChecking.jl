module SoleModelChecking

using Reexport

include("parser.jl")
include("formula_tree.jl")

@reexport using SoleLogics

end
