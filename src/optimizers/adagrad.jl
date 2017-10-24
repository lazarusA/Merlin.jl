export AdaGrad

"""
    AdaGrad

See: http://jmlr.org/papers/v12/duchi11a.html
"""
mutable struct AdaGrad
    alpha::Float64
    states::ObjectIdDict
end

AdaGrad(alpha::Float64) = AdaGrad(alpha, ObjectIdDict())

(opt::AdaGrad)(x::Var) = opt(x.data, x.grad)
function (opt::AdaGrad)(value::Array{T}, grad::Array{T}) where T
    state = get!(opt.states, value, nothing)
    if state == nothing
        sqgrad = zeros(T, length(value))
        opt.states[value] = sqgrad
    else
        sqgrad = state::Array{T}
    end
    @inbounds @simd for i = 1:length(grad)
        sqgrad[i] += grad[i] * grad[i]
        if abs(sqgrad[i]) > T(1e-8)
            value[i] -= T(opt.alpha) * grad[i] / sqrt(sqgrad[i])
        end
    end
    fill!(grad, T(0.0))
end
