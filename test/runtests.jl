using Base.Test
using Merlin
using CUJulia

tests = ["functions"]

for t in tests
    path = joinpath(dirname(@__FILE__), "$t.jl")
    println("$path ...")
    include(path)
end
