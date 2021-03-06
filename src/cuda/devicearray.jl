export CuDeviceArray

struct CuDeviceArray{T,N}
    ptr::Ptr{T}
    dims::NTuple{N,Cint}
    strides::NTuple{N,Cint}
    contigious::Cuchar
end

function CuDeviceArray(x::AbstractCuArray)
    c = iscontigious(x) ? Cuchar(1) : Cuchar(0)
    CuDeviceArray(rawpointer(x), map(Cint,size(x)), map(Cint,strides(x)), c)
end

Base.length(x::CuDeviceArray) = Int(prod(x.dims))

@generated function Base.copy!(dest::CuDeviceArray{T,N}, src::CuDeviceArray{T,N}) where {T,N}
    Ct = cstring(T)
    k = Kernel("""
    __global__ void copy(Array<$Ct,$N> dest, Array<$Ct,$N> src) {
        int idx = blockIdx.x * blockDim.x + threadIdx.x;
        if (idx >= src.length()) return;

        int sub[$N];
        dest.ind2sub(sub, idx);
        dest(sub) = src(sub);
    }""")
    quote
        gdims, bdims = cudims(length(src))
        $k(gdims, bdims, dest, src)
        dest
    end
end

@generated function add!(dest::CuDeviceArray{T,N}, src::CuDeviceArray{T,N}) where {T,N}
    Ct = cstring(T)
    k = Kernel("""
    __global__ void add(Array<$Ct,$N> dest, Array<$Ct,$N> src) {
        int idx = blockIdx.x * blockDim.x + threadIdx.x;
        if (idx >= src.length()) return;

        int sub[$N];
        dest.ind2sub(sub, idx);
        dest(sub) += src(sub);
    }
    """)
    quote
        gdims, bdims = cudims(length(src))
        $k(gdims, bdims, dest, src)
        dest
    end
end
