#push!(LOAD_PATH,joinpath(@__DIR__, ".."))
#push!(LOAD_PATH,"../src/")
using Documenter, Jchemo

DocMeta.setdocmeta!(Jchemo, :DocTestSetup, :(using Jchemo); recursive = true)

makedocs(;
    modules = [Jchemo],
    authors = "Matthieu Lesnoff",
    sitename = "Jchemo.jl",
    repo = "https://github.com/mlesnoff/Jchemo.jl/blob/{commit}{path}#L{line}",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://mlesnoff.github.io/Jchemo.jl",
        assets = String[]
        ),
    #format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    pages = ["Domains" => "functions.md",
        "Index" => "api.md",
        "News" => "news.md"]
    )

deploydocs(;
    repo = "github.com/mlesnoff/Jchemo.jl.git"
    )
