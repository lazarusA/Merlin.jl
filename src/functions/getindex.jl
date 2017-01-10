import Base.getindex

"""
    getindex(x::Var, inds...)

```julia
x = Var(rand(Float32,10,5))
y = x[1:3]
y = x[2:2]
```
Note that `y = x[i]` throws an error since `y` is not a vector but a scholar.
Instead, use `y = x[i:i]`.
"""
function getindex(x::Var, inds::Tuple)
    isa(x.data, Void) && return Var(nothing, getindex, (x,inds))
    y = x.data[inds...]
    function df(gy)
        isa(x.grad, Void) && return
        gx = view(x.grad, inds...)
        broadcast!(+, gx, gx, gy)
    end
    Var(y, df, (x,))
end
getindex(x::Var, inds...) = getindex(x, inds)
