module NestedUnitRanges

import BlockArrays
import ArrayLayouts
import AbstractTrees

export nestedrange

struct NestedUnitRange <: AbstractUnitRange{Int}
    length::Int
    first::Int
    children::Vector{NestedUnitRange}
end

"""
    rebase_axis(nested_range)

Return a deep copy of `nested_range` that is rebased such that the first entry equals `1`.
"""
function rebase_axis(nested_range, offset=1)
    len = nested_range.length
    rebased_children = NestedUnitRange[]
    child_offset = 1
    for child in nested_range.children
        rebased_child = rebase_axis(child, child_offset)
        push!(rebased_children, rebased_child)
        child_offset += child.length
    end
    NestedUnitRange(len, offset, rebased_children)
end

Base.axes(r::NestedUnitRange) = (rebase_axis(r),)
Base.first(r::NestedUnitRange) = r.first
Base.last(r::NestedUnitRange) = r.first + r.length - 1

# Make sure that views remember the nested block structure of the parent. This
# seems to be the default on 1.8 but no on 1.6
Base.axes(s::SubArray{T,1,A,Tuple{NestedUnitRange}}) where {T,A} = axes(s.indices[1])

function nestedrange(tree, first=1, treesize=nestedsum)
    children = Vector{NestedUnitRange}()
    child_first = first
    # tree_size = 0
    for len in AbstractTrees.children(tree)
        child = nestedrange(len, child_first, treesize)
        child_first += child.length
        push!(children, child)
    end
    return NestedUnitRange(treesize(tree), first, children)
end


function nestedsum(lengths)
    total = 0
    for len in lengths
        total += nestedsum(len)
    end
    return total
end
nestedsum(lengths::Int) = lengths


# Implement the blockaxes interface
function BlockArrays.blockaxes(ax::NestedUnitRange)
    if isempty(ax.children)
        return (Base.OneTo(1),)
    end
    BlockArrays.blockaxes(BlockArrays.blockedrange([ch.length for ch in ax.children]))
end


function BlockArrays.getindex(ax::NestedUnitRange, K::BlockArrays.Block{1})
    if isempty(ax.children)
        @assert K == BlockArrays.Block(1)
        return ax
    end
    return ax.children[K.n[1]]
end


function BlockArrays.getindex(ax::NestedUnitRange, bs::BlockArrays.BlockSlice)
    getindex(ax, bs.block)
end


function BlockArrays.blockfirsts(ax::NestedUnitRange)
    isempty(ax.children) && return Int[1]
    Int[ch.first for ch in ax.children]
end


function BlockArrays.blocklasts(ax::NestedUnitRange)
    isempty(ax.children) && return Int[ax.first + ax.length - 1]

    lasts = Int[]
    last = ax.first-1
    for child in ax.children
        last += child.length
        push!(lasts, last)
    end
    return lasts
end


function BlockArrays.findblock(ax::NestedUnitRange, k)
    ax1 = blockedrange([ch.length for ch in ax.children])
    findblock(ax1, k)
end

ArrayLayouts.sub_materialize(::Any, V, axs::Tuple{<:NestedUnitRange}) = BlockArrays.PseudoBlockArray(Array(V), axs)
end
