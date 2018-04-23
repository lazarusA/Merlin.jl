export dropout

doc"""
    dropout(x::Var, droprate::Float64)

Drops elements randomly with probability ``droprate`` and scales the other elements by factor ``1 / (1 - droprate)``.
"""
function dropout(x::Var, droprate::Float64)
    configure!(x)
    droprate == 0.0 && return x
    istrain() || return x
    y, work = dropout(x.data, droprate)
    Var(y, (dropout,x,droprate,work))
end

dropout(x::Node, droprate) = Node(dropout, x, droprate)

function dropout(x::Array{T}, droprate::Float64) where T
    work = rand(T, length(x))
    scale = T(1 / (1-droprate))
    y = similar(x)
    @inbounds for i = 1:length(x)
        y[i] = work[i] <= droprate ? T(0) : scale*x[i]
    end
    y, work
end

dropout(x::CuArray, droprate) = CUDNN.dropout(x, droprate)

function addgrad!(y::Var, ::typeof(dropout), x::Var, droprate::Float64, work)
    isvoid(x.grad) && return
    ∇dropout!(y.grad, x.grad, droprate, work)
end

function ∇dropout!(gy::Array{T}, gx::Array{T}, droprate::Float64, work::Vector{T}) where T
    scale = T(1 / (1-droprate))
    @inbounds for i = 1:length(gx)
        gx[i] += work[i] <= droprate ? T(0) : scale*gy[i]
    end
end

∇dropout!(gy::CuArray, gx, droprate, dropdesc) = CUDNN.∇dropout!(gy, gx, droprate, dropdesc)
