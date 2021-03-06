struct CUDAMalloc
end

function (::CUDAMalloc)(::Type{T}, size::Int) where T
    ptr = memalloc(T, size)
    finalizer(ptr, memfree)
    ptr
end

free(::CUDAMalloc, x::CuPtr) = memfree(x.ptr)

function sss()
    ref = Ref{Ptr{Void}}()
    @apicall :cuMemAlloc (Ptr{Ptr{Void}},Csize_t) ref n*sizeof(T)
    dev = getdevice()
    mb = MemBlock(Ptr{T}(ref[]), n, dev)
    finalizer(mb, memfree)
end

function rrr()
    ref = Ref{Ptr{Void}}()
    status = @unsafe_apicall :cuMemAlloc (Ptr{Ptr{Void}},Csize_t) ref bytesize
    if status != CUDA_SUCCESS
        gc(false)
        status = @unsafe_apicall :cuMemAlloc (Ptr{Ptr{Void}},Csize_t) ref bytesize
        if status != CUDA_SUCCESS
            gc()
            memalloc(bytesize)
        end
    end
    ref[]
end
