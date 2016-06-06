workspace()
ENV["USE_CUDA"] = false
using Merlin
using Merlin.Caffe
using CUDA
using JLD
using Base.LinAlg.BLAS
using Base.Test

gru = GRU(Float32,100)
x = param(rand(Float32,100,1))
h = param(rand(Float32,100,1))
y = gru(:x=>x, :h=>h)

y = gru(:x => , :h => Var(rand(Float32,100)))
y.value

f = @graph begin
  T = Float32
  x = Var(:x)
  x = Linear(T, 10, 5)(x)
  x = relu(x)
  x = Linear(T, 5, 3)(x)
  x
end

y = f(:x => Var(rand(Float32,10,5)))

y = f((:x,Var(rand(Float32,10,5))))

[1,2,3]
w = Var(rand(Float32,10,100))
x = Var([[1 3 5]])
y = lookup(w, x)

x = Var(rand(Float32,10,5))
f = Linear(Float32,10,7)
f(x)

x = [param(rand(Float32,100,100)) for i=1:10]

function a1(arg1::Int, arg2::Int, arg3::Int, arg4::Int)
  x = rand(Int,100)
  a = 0
  for aa in args
    a += aa
  end
  for xx in x
    a += xx
  end
end

function a2(args::Vector{Int})
  x = rand(Int,100)
  a = 0
  for aa in args
    a += aa
  end
  for xx in x
    a += xx
  end
end

function bench()
  r1 = [1,2,3]
  #r1 = rand(100,100)
  #r2 = rand(100,100)
  for i = 1:10000
    #a1(r1...)
    a2(r1)
  end
end

@time bench()

np = Caffe.load("C:/Users/hshindo/Desktop/VGG_ILSVRC_19_layers.caffemodel")
p = np["conv5_3"].convolution_param

x1 = Var(rand(10,5))
y = relu(x1)
y.value

x2 = rand(5,7)
y = zeros(10,7)
gemm!('N', 'N', 1., x1, x2, 0., y)

Var(rand(Float32,5,4))

x = Var(rand(Float32,5,4,3,2))
w = Var(rand(Float32,2,2,3,4)) # 2-d convolution
f = Conv(w, Var(), (1,1), (0,0))
y = f(x)

xx = CuArray(x.value)
ww = CuArray(w.value)
yy = conv(f, xx, ww)
z = Array(yy)
z - y

x = CuArray(rand(Float32,5,4,3,2))
xx = Array(x)
f = Convolution(Float32, (3,4), (2,2), (1,1), (0,0))
w = CuArray(f.w.val)
ww = Array(w)

y_cpu = Merlin.convolution(f, xx)
y_cpu = reshape(y_cpu, 12, 24)
y_cpu = reshape(ww, 4, 12) * y_cpu
y_cpu = reshape(y_cpu, 4, 3, 4, 2)
vec(y_cpu)

y_gpu = Merlin.convolution(f, x, w)
y_gpu = Array(y_gpu)
vec(y_gpu)

dir = joinpath(dirname(@__FILE__), "..", "lib")
libname = "softmax_float_10_5.dll"
libpath = joinpath(dir, libname)
h = Merlin.Native.softmax_float_10_5
Libdl.dlclose(Merlin.Native.)

x = rand(Float32,10,10)
softmax(x)

dir = joinpath(dirname(@__FILE__), "..", "deps")
const HANDLE = Libdl.dlsym(Merlin.Native.library, :softmax_fw_f32)

function bench()
  x1 = rand(500,100,3)
  x2 = rand(100,100)
  for i = 1:1000
    for j = 1:3
      #a = pointer_to_array(pointer(x1, (j-1)*50000), (500, 100))
      gemm('N', 'N', slice(x1,:,:,j), x2)
    end
  end
end
@time bench()
y

x1 = Variable(rand(10,5))
x2 = Variable(rand(10))
x = [x1,x2]
a = map(xx -> xx.val, x)
typeof(a)

x1 = Variable(rand(Float32,7,5),zeros(Float32,7,5))
x2 = Variable(rand(Float32,10,5),zeros(Float32,7,5))
f = Concat(1)
y = (x1,x2) |> f
y.backward!(ones(Float32,17,5))
x2.grad

a = Dict(Float32 => 1)
a[Float32]
typeof(Type{Float32})

x = rand(Float32,10,5)
Merlin.Native.softmax(x, x)
eltype(x)
# w1-w3 are the hidden layer weight matrices, x1 the input vector
function ann(w1, w2, w3, x1)
    x2 = w1 * x1
    x2 = log(1. + exp(x2))   # soft RELU unit
    x3 = w2 * x2
    x3 = log(1. + exp(x3))   # soft RELU unit
    x4 = w3 * x3
    1. / (1. + exp(-x4[1]))  # sigmoid output
end

w1, w2, w3 = randn(10,10), randn(10,10), randn(1,10)
x1 = randn(10)
dann = rdiff(ann, (w1, w2, w3, x1))
dann(w1, w2, w3, x1) # network output + gradient on w1, w2, w3 and x1

softmax_native()
a = CudaArray(Float32,10,5)

function bench()
  for i = 1:10000
    a = CudaArray(Float32,10,5)
    #axpy!(-1.0f0, C, A*B)
    #D = A * B
    #broadcast!(+, B, B, C)
    #D = B + C
    #for ii = 1:10
    #  v = Variable()
    #end
  end
end

@time bench()

path = "C:/temp/"
A = reshape(1:120, 15, 8)
A = AAA(A)
save("$(path)/A.jld", "A", A)
v = load("$(path)/A.jld", "A")
