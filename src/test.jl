using Test

export @test_function, @test_grad, @test_cuda

macro test_grad(f, params...)
    quote
        test_grad(() -> $(esc(f)), $(map(esc,params)...))
    end
end

function test_grad(f, params::Var...; atol=1e-3)
    setcpu()
    y = f()

    foreach(zerograd!, params)
    gradient!(y)
    gxs1 = map(x -> x.grad, params)

    gxs2 = map(params) do p
        x = p.data
        gx2 = similar(x)
        for k = 1:length(x)
            xk = x[k]
            x[k] = xk + 1e-3

            y1 = copy(f().data) # In case y == x
            x[k] = xk - 1e-3

            y2 = copy(f().data)
            x[k] = xk

            gx2[k] = sum(y1-y2) / 2e-3
        end
        gx2
    end

    for (gx1,gx2) in zip(gxs1,gxs2)
        @test maximum(map(abs,gx1-gx2)) < atol
    end
end

macro test_cuda(f, params...)
    quote
        test_cuda(() -> $(esc(f)), $(map(esc,params)...))
    end
end

function test_cuda(f, params::Var...; atol=2e-3)
    CUDA.AVAILABLE || return
    setcpu()

    y = f()
    foreach(zerograd!, params)
    gradient!(y)
    gxs = map(x -> copy(x.grad), params)

    setcuda()
    d_y = f()
    foreach(zerograd!, params)
    gradient!(d_y)
    d_gxs = map(x -> x.grad, params)

    @test y.data ≈ Array(d_y.data) atol=atol
    for (gx,d_gx) in zip(gxs,d_gxs)
        @test gx ≈ Array(d_gx) atol=atol
    end

    setcpu()
end