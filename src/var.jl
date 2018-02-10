export Var
export zerograd, zerograd!, isvoid, isparam, gradient!

doc"""
    Var

Variable struct.

`Var` contains the following members:
* data
* args
* grad
* work

# Example
```julia
T = Float32
x = Var(rand(T,10,5)) # x.grad is set to `nothing`
x = zerograd(rand(T,10,5)) # x.grad is initialized as zero.
```
"""
mutable struct Var
    data
    args
    grad
    work
end

Var(data=nothing, args=(); grad=nothing, work=()) = Var(data, args, grad, work)

zerograd(data) = Var(data, grad=zeros(data))
function zerograd!(x::Var)
    isvoid(x.grad) && return
    x.grad = zeros(x.data)
    x
end

Base.size(x::Var) = size(x.data)
Base.size(x::Var, i::Int) = size(x.data, i)
Base.length(x::Var) = length(x.data)
Base.ndims(x::Var) = ndims(x.data)
Base.eltype(x::Var) = eltype(x.data)
Base.strides(x::Var) = strides(x.data)
Base.stride(x::Var, i::Int) = stride(x.data, i)
Base.getindex(x::Var, i::Int) = x.args[i]
isvoid(x) = x == nothing

doc"""
    isparam(x::Var)

Returns whether `x` is a parameter or not
"""
isparam(x::Var) = !isvoid(x.grad) && isempty(x.args)

doc"""
    topsort(tops::T...)

Topological sort.
"""
function topsort(tops::T...) where T
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

doc"""
    gradient!(top::Var)

Compute gradients.
"""
function gradient!(tops::Var...)
    sorted = topsort(tops...)
    for top in tops
        isvoid(top.grad) && (top.grad = ones(top.data))
    end
    for v in sorted
        if !isempty(v.args) && isvoid(v.grad)
            v.grad = zeros(v.data)
        end
    end
    for i = length(sorted):-1:1
        y = sorted[i]
        isvoid(y.grad) && continue
        isempty(y.args) && continue
        addgrad!(y, y.args...)
    end
    filter(isparam, sorted)
end

function unify!(x::Var, y::Var)
    if isa(x.data, Array)
        y.data = Array(y.data)
        isvoid(y.grad) || (y.grad = Array(y.grad))
    elseif isa(x.data, CuArray)
        y.data = CuArray(y.data)
        isvoid(y.grad) || (y.grad = CuArray(y.grad))
    else
        throw("Invalid data type: $(typeof(x.data))")
    end
end
