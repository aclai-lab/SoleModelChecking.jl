using Plots, Plots.Measures
# using PGFPlots
using ArgParse
using CSV
using Tables

#=
Plot attributes
https://docs.juliaplots.org/latest/generated/attributes_series/
=#

function check_extension(filename::String)
    filename[findlast(isequal('.'), filename):end]
end

# Utility script to reproduce specific plots from the csv files
# contained in a directory.
function plot_mmcheck(args::Dict{String, Any})
    files = []
    for file in readdir(args["directory"])
        if check_extension(file) != ".csv"
            continue
        end

        filepath = joinpath(pwd(), args["directory"], file)
        push!(files, CSV.read(filepath, Tables.matrix, header=0))
    end

    # Exported plot name
    fname = split(args["directory"], Base.Filesystem.path_separator)[end]

    # Collections to make plot meaningfull
    theme(:vibrant)
    lcolors = theme_palette(:vibrant)
    lstyles = [:solid :dash :dot :dashdot :dashdotdot]
    memo_label = [split(args["memolabel"])...]
    prf_label = [split(args["prlabel"])...]

    plt1 = plot()
    for i in eachindex(files)
        theme(:vibrant)
        nrows, ncols = Base.size(files[i])

        for row in 1:nrows

            #NOTE: this will be removed, it's only purpose is to remove memo3 from plots
            if nrows >= 6 && row == 5 continue end

            plot!(
                plt1,
                cumsum(files[i][row,:]),
                linestyle=lstyles[i],
                linecolor=lcolors[row],
                title=args["title"],
                legend=:topleft,
                label="memo: $(memo_label[row]), pr: $(prf_label[i])",
                margins=5mm
            )
        end
    end
    display(plt1)
    savefig(plt1, joinpath(pwd(), "test", "plots", "$(fname).png"))

    #=
    linestyle=lstyles[i],
    labels="$row",
    legend=:topleft,
    margins=15mm
    =#

#=
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
    =#
end

function ArgParse.parse_item(::Type{Vector{String}}, x::AbstractString)
    return [split(x)]
end

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--directory"
            help = "Directory containing all the CSVs to plot"
        "--title"
            help = "Plot title"
        "--memolabel"
            help = "Labels regarding memoization"
        "--prlabel"
            help = "Labels regarding pruning factor labels"
    end

    return parse_args(s)
end

plot_mmcheck(parse_commandline())
