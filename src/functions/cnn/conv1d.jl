export Conv1d

doc"""
    Conv1d(T, ksize, inchannel, outchannel, [padding=0, stride=1, dilation=1])

1-dimensional convolution function.

```julia
T = Float32
x = Var(rand(T,10,5))
f = Conv1d(T, 5, 10, 3, padding=2)
y = f(x)
```
"""
mutable struct Conv1d <: Functor
    W::Var
    b::Var
    ksize::Int
    padding::Int
    stride::Int
    dilation::Int
end

getparams(f::Conv1d) = (f.W, f.b)

function Conv1d(::Type{T}, ksize::Int, inchannel::Int, outchannel::Int;
    padding=0, stride=1, dilation=1, init_W=Xavier(), init_b=Fill(0)) where T

    W = init_W(T, ksize*inchannel, outchannel)
    b = init_b(T, outchannel)
    Conv1d(param(W), param(b), ksize, padding, stride, dilation)
end

function (f::Conv1d)(xs::Vector{Var})
    idxs = map(xs) do x
        @assert size(x) == 2
        conv1d_index(f, size(x,2))
    end
    idx = cat(2, idxs...)
    x = concat(2, xs...)
    h = lookup(x, Var(idx))

    @assert ndims(x) == 2 && sum(length) == size(x,2)
    idx = conv1d_index(f.ksize, f.padding, f.stride, f.dilation, length)
    h = lookup(x, Var(idx))
    y = linear(h, f.W, f.b)
    y
end
(f::Conv1d)(x::Node) = Node(f, x)

function conv1d_index(f::Conv1d, inlength::Int)
    ksize, padding, stride, dilation = f.ksize, f.padding, f.stride, f.dilation
    k = (ksize - 1) * dilation + 1
    outlength = (inlength + 2padding - k) ÷ stride + 1

    y = Array{Int}(ksize, outlength)
    yi = 1
    i = -padding + 1
    for d = 1:outlength
        j = i + (ksize-1)*dilation
        for k = i:dilation:j
            y[yi] = 0 < k <= inlength ? k : 0
            yi += 1
        end
        i += stride
    end
    y
end

function conv1d_index(ksize::Int, padding::Int, stride::Int, dilation::Int, batchsize::Vector{Int})
    outdims = map(batchsize) do d
        k = (ksize - 1) * dilation + 1
        (d + 2padding - k) ÷ stride + 1
    end
    cumdim = 0
    y = Array{Int}(ksize, sum(outdims))
    yi = 1
    for n = 1:length(batchsize)
        ndims = batchsize[n]
        i = cumdim - padding + 1
        for d = 1:outdims[n]
            for j = i:dilation:i+(ksize-1)*dilation
                xi = cumdim < j <= cumdim+ndims ? j : 0
                y[yi] = xi
                yi += 1
            end
            i += stride
        end
        cumdim += ndims
    end
    y
end
