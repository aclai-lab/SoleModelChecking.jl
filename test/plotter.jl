using Plots, Plots.Measures
# using PGFPlots
using ArgParse
using CSV
using Tables
using Statistics
using PGFPlotsX

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
    lcolors = deepcopy(theme_palette(:vibrant))
    lstyles = [:solid :dash :dashdotdot :dot :dashdot]
    lmarkers = [:circle, :circle, :circle, :utriangle, :dtriangle]
    memo_label = [split(args["memolabel"])...]
    prf_label = [split(args["prlabel"])...]

    # Simple plot (different pruning factor in one)
    plt1 = plot()
    for i in eachindex(files)
        nrows, ncols = Base.size(files[i])

        for row in 1:nrows
            #NOTE: this will be removed, it's only purpose is to remove memo3 from plots
            if memo_label[row] == "SKIP"
                lcolors[6] = lcolors[5]
                continue
            end

            plot!(
                plt1,
                cumsum(files[i][row,:]),
                linestyle=lstyles[i],
                linecolor=lcolors[row],
                # title=args["title"],
                legend=:topleft,
                label="memo: $(memo_label[row]), pr: $(prf_label[i])",
                margins=5mm,
                titlelocation=:left,
                titlefontsize=11
            )
        end
    end
    xlabel!(plt1, "Number of formulas")
    ylabel!(plt1, "Cumulative time [s]")
    savefig(plt1, joinpath(pwd(), "test", "plots", "simple_$(fname).png"))

    lcolors = deepcopy(theme_palette(:vibrant))
    # Scatter plot (each plot has only one pruning factor)
    for i in eachindex(files)
        nrows, ncols = Base.size(files[i])

        plt2 = plot()
        for row in 1:nrows
            #NOTE: this will be removed, it's only purpose is to remove memo3 from plots
            if memo_label[row] == "SKIP"
                lcolors[6] = lcolors[5]
                continue
            end

            ymax = mean(files[i][1,:]) + 0.0001 # Formula to remove outliners
            scatter!(
                plt2,
                files[i][row,:],
                markersize=3,
                markerstrokewidth=0,
                markershape=lmarkers[i],
                markercolor=lcolors[row],
                # title=args["title"],
                legend=:topright,
                label="memo: $(memo_label[row]), pr: $(prf_label[i])",
                margins=5mm,
                ylim=(0, ymax),
                titlelocation=:left,
                titlefontsize=11
            )
        end
        xlabel!("Number of formulas")
        ylabel!("Instantaneous time [s]")
        savefig(plt2, joinpath(pwd(), "test", "plots", "scatter_$(fname)_$(prf_label[i]).png"))
    end
end

# Similar to plot_mmcheck, but exports to .tex
function plot_mmcheck_latex(args::Dict{String, Any})
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
    lcolors = deepcopy(theme_palette(:vibrant))
    lstyles = [:solid :dash :dashdotdot :dot :dashdot]
    lmarkers = [:circle, :circle, :circle, :utriangle, :dtriangle]
    memo_label = [split(args["memolabel"])...]
    prf_label = [split(args["prlabel"])...]

    # Plots backend
    pgfplotsx()

    # Simple plot (different pruning factor in one)
    plt1 = plot()
    for i in eachindex(files)
        nrows, ncols = Base.size(files[i])

        for row in 1:nrows
            #NOTE: this will be removed, it's only purpose is to remove memo3 from plots
            if memo_label[row] == "SKIP"
                lcolors[6] = lcolors[5]
                continue
            end

            plot!(
                plt1,
                cumsum(files[i][row,:]),
                linestyle=lstyles[i],
                linecolor=lcolors[row],
                # title=args["title"],
                legend=:topleft,
                label="memo: $(memo_label[row]), pr: $(prf_label[i])",
                margins=5mm,
                titlelocation=:left,
                titlefontsize=11
            )
        end
    end
    xlabel!(plt1, "Number of formulas")
    ylabel!(plt1, "Cumulative time [s]")
    # savefig(plt1, joinpath(pwd(), "test", "plots", "simple_$(fname).png"))
    savefig(plt1, joinpath(pwd(), "test", "latex_plots", "simple_$(fname).tex"))

    lcolors = deepcopy(theme_palette(:vibrant))
    # Scatter plot (each plot has only one pruning factor)
    for i in eachindex(files)
        nrows, ncols = Base.size(files[i])

        plt2 = plot()
        for row in 1:nrows
            #NOTE: this will be removed, it's only purpose is to remove memo3 from plots
            if memo_label[row] == "SKIP"
                lcolors[6] = lcolors[5]
                continue
            end

            ymax = mean(files[i][1,:]) + 0.0001 # Formula to remove outliners
            scatter!(
                plt2,
                files[i][row,:],
                markersize=3,
                markerstrokewidth=0,
                markershape=lmarkers[i],
                markercolor=lcolors[row],
                # title=args["title"],
                legend=:topright,
                label="memo: $(memo_label[row]), pr: $(prf_label[i])",
                margins=5mm,
                ylim=(0, ymax),
                titlelocation=:left,
                titlefontsize=11
            )
        end
        xlabel!("Number of formulas")
        ylabel!("Instantaneous time [s]")
        # savefig(plt2, joinpath(pwd(), "test", "plots", "scatter_$(fname)_$(prf_label[i]).png"))
        savefig(plt2, joinpath(pwd(), "test", "latex_plots", "scatter_$(fname)_$(prf_label[i]).tex"))
    end
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

# E.g usage from terminal (uncomment the following)
# julia -i --project=. test/plotter.jl --directory=test/csv/simple_10_4_4 --title="#Models=10, #Letters=4, MaxHeight=4" --memolabel="no 0 1 2 4 8" --prlabel="0.2 0.5 0.8"
# plot_mmcheck(parse_commandline())

n_models = 10
n_worlds = 10
for n_letters in [2 4 8 16]
    for fheight in [1 2 4]
        arguments = Dict{String, Any}(
            "directory" => joinpath("test", "csv", "$(n_models)_$(n_letters)_$(fheight)"),
            "title" => "#Models=$(n_models), #Worlds=$(n_worlds), #Letters=$(n_letters), MaxHeight=$(fheight)",
            "memolabel" => "no 0 1 2 SKIP 4",
            "prlabel" => "0.2 0.5 0.8"
        )
        plot_mmcheck(arguments)
    end
end

for n_letters in [2 4 8 16]
    for fheight in [8]
        arguments = Dict{String, Any}(
            "directory" => joinpath("test", "csv", "$(n_models)_$(n_letters)_$(fheight)"),
            "title" => "#Models=$(n_models), #Worlds=$(n_worlds), #Letters=$(n_letters), MaxHeight=$(fheight)",
            "memolabel" => "no 0 1 2 4 8",
            "prlabel" => "0.2 0.5 0.8"
        )
        plot_mmcheck(arguments)
    end
end

n_models = 50
n_worlds = 20
for n_letters in [2 4 8 16]
    for fheight in [1 2 4]
        arguments = Dict{String, Any}(
            "directory" => joinpath("test", "csv", "$(n_models)_$(n_letters)_$(fheight)"),
            "title" => "#Models=$(n_models), #Worlds=$(n_worlds), #Letters=$(n_letters), MaxHeight=$(fheight)",
            "memolabel" => "no 0 1 2 SKIP 4",
            "prlabel" => "0.4 0.6 0.8"
        )
        plot_mmcheck(arguments)
    end
end

for n_letters in [2 4 8 16]
    for fheight in [8]
        arguments = Dict{String, Any}(
            "directory" => joinpath("test", "csv", "$(n_models)_$(n_letters)_$(fheight)"),
            "title" => "#Models=$(n_models), #Worlds=$(n_worlds), #Letters=$(n_letters), MaxHeight=$(fheight)",
            "memolabel" => "no 0 1 2 4 8",
            "prlabel" => "0.4 0.6 0.8"
        )
        plot_mmcheck(arguments)
    end
end
