import Base.LinAlg.BLAS: gemv, gemm
export gemm_batch

"""
    gemv(tA::Char, alpha, A::Var, x::Var)

* tA: 'T' (transpose) or 'N' (not transpose)

```math
y = \alpha \times \textrm{tA}(A) \times x
```
"""
function gemv(tA::Char, alpha::Number, A::Var, x::Var)
    T = eltype(A.data)
    data = BLAS.gemv(tA, T(alpha), A.data, x.data)
    y = Var(data, gemv, (tA,alpha,A,x))
    y.df! = () -> begin
        if !isvoid(A.grad)
            tA == 'N' ?
            BLAS.gemm!('N', 'T', T(alpha), redim(y.grad,2), redim(x.data,2), T(1), A.grad) :
            BLAS.gemm!('N', 'T', T(alpha), redim(x.data,2), redim(y.grad,2), T(1), A.grad)
        end
        isvoid(x.grad) || BLAS.gemv!(tA=='N'?'T':'N', T(alpha), A.data, y.grad, T(1), x.grad)
    end
    y
end

"""
    gemm(tA::Char, tB::Char, alpha, A::Var, B::Var)
    gemm(A::Var, B::Var, [tA='N'], [tB='N'], [alpha=1])

* tA: 'T' (transpose) or 'N' (not transpose)
* tB: same as tA

```math
C = \alpha \times \textrm{tA}(A) \times \textrm{tB}(B)
```
"""
function gemm(tA::Char, tB::Char, alpha::Number, A::Var, B::Var)
    T = eltype(A.data)
    data = BLAS.gemm(tA, tB, T(alpha), A.data, B.data)
    C = Var(data, gemm, (tA,tB,alpha,A,B))
    C.df! = () -> begin
        if !isconst(A)
            tA == 'N' ?
            BLAS.gemm!('N', tB=='N'?'T':'N', T(alpha), C.grad, B.data, T(1), A.grad) :
            BLAS.gemm!(tB, 'T', T(alpha), B.data, C.grad, T(1), A.grad)
        end
        if !isconst(B)
            tB == 'N' ?
            BLAS.gemm!(tA=='N'?'T':'N', 'N', T(alpha), A.data, C.grad, T(1), B.grad) :
            BLAS.gemm!('T', tA, T(alpha), C.grad, A.data, T(1), B.grad)
        end
    end
    C
end

"""
    gemm_batch(tA::Char, tB::Char, alpha, As::Vector{Var}, B::Vector{Var})
    gemm_batch(As::Vector{Var}, B::Vector{Var}, [tA='N'], [tB='N'], [alpha=1])
"""
gemm_batch(tA, tB, alpha, As::Vector{Var}, Bs::Vector{Var}) = forward(tA, tB, alpha, As, Bs)
gemm_batch(As, Bs; tA='N', tB='N', alpha=1) = gemm_batch(tA, tB, alpha, As, Bs)

function forward(::typeof(gemm_batch), tA::Char, tB::Char, alpha, As::Vector{Matrix}, Bs::Vector{Matrix})
    length(As) == length(Bs) || throw(DimensionMismatch("Length of As and Bs must be the same."))

    rowC = tA == 'N' ? size(As[1],1) : size(As[1],2)
    colC = tB == 'N' ? size(Bs[1],2) : size(Bs[1],1)
    T = eltype(As[1])
    C = Array{T}(rowC, colC, length(As))
    for i = 1:length(As)
        BLAS.gemm!(tA, tB, alpha, As[i], Bs[i], T(0), view(C,:,:,i))
    end
    df(gC) = ∇gemm_batch!(gC, tA, tB, alpha, As, Bs)
    Var(C, df, (As,Bs))
end

function ∇gemm_batch!(tA, tB, alpha, As::Vector, gAs::Vector, Bs::Vector, gBs::Vector, gC::Array)
    @assert length(As) == length(Bs)
    for i = 1:length(As)
        g = view(gC, :, :, i)
        ∇gemm_A!(tB, alpha, gAs[i], Bs[i], g)
        ∇gemm_B!(tA, alpha, As[i], gBs[i], g)
    end
end
∇gemm_batch!(As, gAs, Bs, gBs, gC; tA='N', tB='N', alpha=1.0) = ∇gemm_batch!(tA, tB, alpha, As, gAs, Bs, gBs, gC)
