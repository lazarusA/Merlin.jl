export Var
export batchsize, isvoid, isfixed, isparam, gradient!, setdevice!

"""
    Var

Variable struct.
"""
mutable struct Var
    data
    batchdims
    f
    args
    grad
end

function Var(data, batchdims=nothing, f=nothing, args=(); fixed=true)
    batchdims == nothing && (batchdims = [size(data,ndims(data))])
    grad = fixed ? nothing : zeros(data)
    Var(data, batchdims, f, args, grad)
end

Base.size(x::Var) = size(x.data)
Base.size(x::Var, i::Int) = size(x.data, i)
Base.length(x::Var) = length(x.data)
Base.ndims(x::Var) = ndims(x.data)
Base.eltype(x::Var) = eltype(x.data)
isvoid(x) = x == nothing

"""
    batchsize(x::Var)
    batchsize(x::Var, i::Int)
"""
batchsize(x::Var) = x.batchdims
batchsize(x::Var, i::Int) = x.batchdims[i]

"""
    isfixed(x::Var)::Bool
"""
isfixed(x::Var) = x.grad == nothing

"""
    isparam(x::Var)::Bool
Returns whether `x` is a parameter or not
"""
isparam(x::Var) = !isfixed(x) && isempty(x.args)

function setdevice!(x::Var, dev::String)
    if dev == "cpu"
        isa(x.data,CuArray) && (x.data = Array(x.data))
    elseif startswith(dev, "gpu")
    end
    nothing
end
setdevice!(xs::Vector{Var}, dev) = foreach(x -> setdevice!(x,dev), xs)

function topsort{T}(tops::T...)
    sorted = T[]
    dict = ObjectIdDict()
    function visit(v::T)
        haskey(dict,v) && return
        dict[v] = v
        for arg in v.args
            if isa(arg, T)
                visit(arg)
            elseif isa(arg, Vector{T})
                foreach(visit, arg)
            end
        end
        push!(sorted, v)
    end
    foreach(visit, tops)
    sorted
end

"""
    gradient!(top::Var)
"""
function gradient!(top::Var)
    sorted = topsort(top)
    isvoid(top.grad) && (top.grad = ones(top.data))
    for v in sorted
        if !isempty(v.args) && isvoid(v.grad)
            v.grad = zeros(v.data)
        end
    end
    for i = length(sorted):-1:1
        v = sorted[i]
        isvoid(v.f) || addgrad!(v, v.f, v.args...)
    end
    filter(isparam, sorted)
end
