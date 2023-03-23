using NestedUnitRanges
using Test

import BlockArrays

# @testset "NestedUnitRange.jl" begin
    nur = nestedrange([[2,3],4])

    @test length(nur) == 9
    @test BlockArrays.blocksize(nur) == (2,)

    data = rand(9)
    pbv = BlockArrays.PseudoBlockVector(data, (nur,))
    @test axes(pbv) == (nur,)

    v1 = view(pbv, BlockArrays.Block(1))
    @test v1 isa SubArray
    @test axes(v1,1) == nestedrange([2,3])

    v12 = view(v1, BlockArrays.Block(2))
    @test v12 isa SubArray
    @test axes(v12,1) == nestedrange([3])

    v12[end] = 123
    @test pbv[5] == 123

    a1 = getindex(pbv, BlockArrays.Block(1))
    @test a1 isa BlockArrays.PseudoBlockVector
    @test axes(a1,1) == nestedrange([2,3])
    
    a2 = getindex(pbv, BlockArrays.Block(2))
    @test a2 isa BlockArrays.PseudoBlockVector
    @test axes(a2,1) == nestedrange([4])

    a12 = getindex(a1, BlockArrays.Block(1))
    @test a12 isa BlockArrays.PseudoBlockVector
    @test axes(a12,1) == nestedrange([2])

    a22 = getindex(a1, BlockArrays.Block(2))
    @test a22 isa BlockArrays.PseudoBlockVector
    @test axes(a22,1) == nestedrange([3])

    a12[end] = 321
    @test pbv[5] == 123

    w12 = view(a1, BlockArrays.Block(2))
    @test w12 isa SubArray
    @test axes(w12,1) == nestedrange([3])

    b12 = getindex(w12, BlockArrays.Block(1))
    @test b12 isa BlockArrays.PseudoBlockVector
    @test axes(b12,1) == nestedrange([3])
# end
