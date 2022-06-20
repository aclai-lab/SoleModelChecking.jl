using SoleModelChecking
using Documenter

DocMeta.setdocmeta!(SoleModelChecking, :DocTestSetup, :(using SoleModelChecking); recursive=true)

makedocs(;
    modules=[SoleModelChecking],
    authors="Eduard I. STAN, Giovanni PAGLIARINI",
    repo="https://github.com/aclai-lab/SoleModelChecking.jl/blob/{commit}{path}#{line}",
    sitename="SoleModelChecking.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aclai-lab.github.io/SoleModelChecking.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/aclai-lab/SoleModelChecking.jl",
)
