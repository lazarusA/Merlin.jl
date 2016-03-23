# Merlin.jl

[![Build Status](https://travis-ci.org/hshindo/Merlin.jl.svg?branch=master)](https://travis-ci.org/hshindo/Merlin.jl)

Merlin.jl is a flexible neural network library written in [Julia](http://julialang.org).

- [Documentation (latest)](http://hshindo.github.io/Merlin.jl/latest/)

## Requirements for CUDA GPU
[cuDNN](https://developer.nvidia.com/cudnn) v4

## Install

- Julia 0.4

```julia
julia> Pkg.clone("https://github.com/hshindo/Merlin.jl.git")
```

## Basic Usage

### Decoding
1. Create `Variable` from Array (CPU) or CudaArray (CUDA GPU).
1. Create `Functor`s.
1. Apply the functors to the variable.

```julia
using Merlin

x = Variable(rand(Float32,50,5))
f = Linear(Float32,50,30)
y = f(x)
```

### Training
1. Create `Optimizer`.
1. Decode your variables.
1. Compute gradient.
1. Update `Functor`s with your `Optimizer`.
```julia
using Merlin

opt = SGD(0.001)
f = [Linear(Float32,50,30), ReLU(), Linear(Float32,30,10)]

for i = 1:10
  x = Variable(rand(Float32,50,20))
  y = f(x)
  gradient!(y)
  update!(opt, f)
end
```
