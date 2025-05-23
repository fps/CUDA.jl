# constructors
voidptr_a = CuPtr{Cvoid}(Int(0xDEADBEEF))
@test reinterpret(Ptr{Cvoid}, voidptr_a) == Ptr{Cvoid}(Int(0xDEADBEEF))

# getters
@test eltype(voidptr_a) == Cvoid

# comparisons
voidptr_b = CuPtr{Cvoid}(Int(0xCAFEBABE))
@test voidptr_a != voidptr_b


@testset "conversions" begin

# between regular and CUDA pointers
@test_throws ArgumentError convert(Ptr{Cvoid}, voidptr_a)

# between CUDA pointers
intptr_a = CuPtr{Int}(Int(0xDEADBEEF))
@test convert(typeof(intptr_a), voidptr_a) == intptr_a

# convert back and forth from UInt
intptr_b = CuPtr{Int}(Int(0xDEADBEEF))
@test convert(UInt, intptr_b) == 0xDEADBEEF
@test convert(CuPtr{Int}, Int(0xDEADBEEF)) == intptr_b
@test Int(intptr_b) == Int(0xDEADBEEF)

# pointer arithmetic
intptr_c = CuPtr{Int}(Int(0xDEADBEEF))
intptr_d = 2 + intptr_c
@test isless(intptr_c, intptr_d)
@test intptr_d - intptr_c == 2
@test intptr_d - 2 == intptr_c
end


@testset "GPU or CPU integration" begin

a = [1]
ccall(:clock, Nothing, (Ptr{Int},), a)
@test_throws Exception ccall(:clock, Nothing, (CuPtr{Int},), a)
ccall(:clock, Nothing, (PtrOrCuPtr{Int},), a)

data = GPUArrays.DataRef(Returns(nothing), CUDA.Managed(CUDA.DeviceMemory()))
b = CuArray{eltype(a), ndims(a)}(data, size(a))
ccall(:clock, Nothing, (CuPtr{Int},), b)
@test_throws Exception ccall(:clock, Nothing, (Ptr{Int},), b)
ccall(:clock, Nothing, (PtrOrCuPtr{Int},), b)

end


@testset "reference values" begin
    # Ref

    @test typeof(Base.cconvert(Ref{Int}, 1)) == typeof(Ref(1))
    @test Base.unsafe_convert(Ref{Int}, Base.cconvert(Ref{Int}, 1)) isa Ptr{Int}

    ptr = reinterpret(Ptr{Int}, C_NULL)
    @test Base.cconvert(Ref{Int}, ptr) == ptr
    @test Base.unsafe_convert(Ref{Int}, Base.cconvert(Ref{Int}, ptr)) == ptr

    arr = [1]
    @test Base.cconvert(Ref{Int}, arr) isa Base.RefArray{Int, typeof(arr)}
    @test Base.unsafe_convert(Ref{Int}, Base.cconvert(Ref{Int}, arr)) == pointer(arr)


    # CuRef

    @test typeof(Base.cconvert(CuRef{Int}, 1)) == typeof(CuRef(1))
    @test Base.unsafe_convert(CuRef{Int}, Base.cconvert(CuRef{Int}, 1)) isa CuRef{Int}

    cuptr = reinterpret(CuPtr{Int}, C_NULL)
    @test Base.cconvert(CuRef{Int}, cuptr) == cuptr
    @test Base.unsafe_convert(CuRef{Int}, Base.cconvert(CuRef{Int}, cuptr)) == Base.bitcast(CuRef{Int}, cuptr)

    cuarr = CUDA.CuArray([1])
    @test Base.cconvert(CuRef{Int}, cuarr) isa CUDA.CuRefArray{Int, typeof(cuarr)}
    @test Base.unsafe_convert(CuRef{Int}, Base.cconvert(CuRef{Int}, cuarr)) == Base.bitcast(CuRef{Int}, pointer(cuarr))

    ref = CuRef{Int64}(1)
    @test eltype(ref) == Int64
    @test convert(CuRef{Int64}, ref) === ref
    @test sprint(show, ref) == "CuRefValue{Int64}(1)"
    @test ref[] == 1
    @test Base.unsafe_convert(CuPtr{Cvoid}, ref) isa CuPtr{Cvoid}
    
    arr_ref = convert(CuRef{Int64}, CUDA.ones(Int64, 1))
    @test eltype(arr_ref) == Int64
    @test convert(CuRef{Int64}, arr_ref) === arr_ref
    @test sprint(show, arr_ref) == "CuRefArray{Int64}(1)"
    @test arr_ref[] == 1
    arr_ref[] = zero(Int64)
    @test arr_ref[] == 0
    @test Base.unsafe_convert(CuPtr{Cvoid}, arr_ref) isa CuPtr{Cvoid}
end
