using Plots, Plots.Measures
using ArgParse
using CSV
# using DelimitedFiles
using Tables

#=
Attributes
https://docs.juliaplots.org/latest/generated/attributes_series/
=#

# Utility script to reproduce specific plots from csv file.

function plot_mmcheck(args::Dict{String, Any})
    times = CSV.read(args["file"], Tables.matrix, header=0)
    times2 = times .* 2

    nrows, ncols = Base.size(times)

    # Simple plot
    # NOTE: different pruning factor could be plotted using different
    # linestyles (e.g. linestyle=:dash or :dashdot)
    plt1 = plot()
    for row in 1:nrows
        plot!(
            plt1,
            1:ncols,
            cumsum(times[row,:]),
            labels="$row",
            linestyle=:solid,
            margins=15mm
        )
    end
    display(plt1)

    # Scatter plot
    plt2 = plot()
    for row in 1:nrows
        scatter!(
            plt2,
            1:ncols,
            times[row,:],
            labels="$row",
            linestyle=:solid,
            margins=15mm,
            markersize=2,
            markerstrokewidth=0
        )
    end
    display(plt2)
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
