export SGD

"""
    SGD

Stochastic Gradient Descent.

## Arguments
* rate: learning rate
* [momentum::Float64]: momentum coefficient
* [nesterov::Bool]: use nesterov acceleration or not
"""
mutable struct SGD
    rate::Float64
    momentum::Float64
    nesterov::Bool
    states::ObjectIdDict
end

function SGD(rate=0.0; momentum=0.0, nesterov=false)
    SGD(rate, momentum, nesterov, ObjectIdDict())
end

(opt::SGD)(x::Var) = opt(x.data, x.grad)
function (opt::SGD){T,N}(x::Array{T,N}, gx::Array{T,N})
    if opt.momentum > 0.0
        if haskey(opt.states, x)
            v = opt.states[x]
        else
            v = zeros(x)
            opt.states[x] = v
        end
        m = T(opt.momentum)
        rate = T(opt.rate)
        v .= m .* v - rate * gx
        if opt.nesterov
            v = copy(v)
            BLAS.scal!(length(v), m, v, 1)
            BLAS.axpy!(-rate, gx, v)
        end
        BLAS.axpy!(T(1), v, x)
    else
        # BLAS.axpy!(T(0.0005), x, gx)
        BLAS.axpy!(T(-opt.rate), gx, x)
    end
    fill!(gx, T(0))
end
