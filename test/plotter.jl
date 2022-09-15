using Plots
using ArgParse
using CSV

# Given a csv about a Multiple Models Multiple Formulas Model Checking
# (see experiments.jl), plot it in a clean fashion way.
function plot_mmcheck(args)
    @show typeof(args)
    csv_reader = CSV.File(args["file"])
end

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--file"
            help = "Number of kripke models"
    end

    return parse_args(s)
end

plot_mmcheck(parse_commandline())
