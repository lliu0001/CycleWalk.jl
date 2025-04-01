"""
    AbstractlctNode

An abstract type with two subtypes: lctNode and DummylctNode. DummylctNode will be a singleton type,
and represents a node that isn't in the represented tree (like the children of a leaf node).
lctNode will represent a node of a splay tree. 
as the LCT will be used to represent a graph, each node must remember what vertex it represents.
as such, T is whatever type is used to keep track of the vertices.
"""
# abstract type AbstractlctNode{T} end

mutable struct LinkCutNode
    vertex::Int
    parent::Int
    pathParent::Int
    left_child::Int
    right_child::Int
    reversed::Bool
end

LinkCutNode(vertex::Int) = LinkCutNode(vertex, 0, 0, 0, 0, false) 

struct LinkCutTree
    #nodes should be ordered- the first node is vertex 1, etc.
    nodes::Vector{LinkCutNode}
end

function LinkCutTree(s::Int)
    nodes = Vector{LinkCutNode}(undef,s)
    for n in 1:length(nodes)
        nodes[n] = LinkCutNode(n)
    end
    return LinkCutTree(nodes)
end

Base.getindex(::Type{LinkCutTree}, ii::Int) = LinkCutTree.nodes[ii]

#Getters and Setters:
@inline function setParent!(t::LinkCutTree, n::Int , p::Int)
    if n == 0
        return 0
    end
    t[n].parent = p
end

@inline function setChild!(t::LinkCutTree, n::Int, i::Int, c::Int)
    if i == 1
        t[n].left_child = c
    else
        t[n].right_child = c
    end
    setParent!(t, c, n)
end

function setLeft!(t::LinkCutTree, n::Int, l::Int)
    setChild!(t,n,1,l)
end

function setRight!(t::LinkCutTree, n::lctNode, r::Int)
    setChild!(t,n,2,r)
end


#Finding information / utility functions:
@inline function samelctNode(t::LinkCutTree, n1::Int, n2::Int)
    return n1 == n2        
end

"Returns the index n has in its parent's vector of children. Requires a real parent."
@inline function childIndex(t::LinkCutTree, n::lctNode)
    if samelctNode(n.parent.left_child, n)
        return 1
    else 
        return 2
    end
end

function findSplayRoot(n::lctNode)
    r = n
    while r.parent isa lctNode
        r = r.parent
    end
    return r
end

@inline function getChild(n::lctNode,i::Int)
    if i==1
        return n.left_child
    else
        return n.right_child
    end
end

"Finds the left- or right-most node in the splay tree of n."
function findExtreme(n::lctNode, largest::Bool)
    r = findSplayRoot(n)
    childIndex = 1
    # largest && (childIndex+=1)==2

    while r.right_child isa lctNode
        r = r.right_child

    end

    return r
end


#don't export this, the other one is the wrapper that should be called.
function traverseSubtree!(A::Array, n::lctNode, order::Int, reverse::Bool)

    if order == 1
        append!(A,[n])
    end

    for i in 0:1
        if i == 1 && order == 2
            append!(A, [n])
        end

        c = getChild(n, (i⊻n.reversed⊻reverse)+1)
        if c isa lctNode
            traverseSubtree!(A,c,order,n.reversed⊻reverse)
        end

    end

    if order == 3
        append!(A,[n])
    end

end

"returns an array with the desired traversal of the subtree of n."
function traverseSubtree(n::lctNode, order::String="in-order")
    A = []

    pre_order, in_order, post_order = false,false,false

    (pre_order=(order=="pre-order"))||(in_order=(order=="in-order"))||(post_order=(order=="post-order"))

    order = pre_order + in_order*2 + post_order*3

    traverseSubtree!(A,n,order,false)

    return A
end




#splay tree modification:
"Rotates n upwards in the splay tree while maintaining BST rules. Requires a real parent."
function rotateUp(n::lctNode)
    i = childIndex(n)
    p = n.parent
    g = p.parent

    setParent!(n,g)
    if g isa lctNode
        j = childIndex(p)
        setChild!(g,j,n)
    else
        n.pathParent = p.pathParent
        t = typeof(n.vertex)
        p.pathParent = nothing
    end

    #move n's correct child into the place where n used to be, beneath p.
    setChild!(p, i, getChild(n, 3-i))
    #set p to be n's correct child.
    setChild!(n,3-i,p)

end

"Alters the tree until n is the root. Does not disrupt the ordering."
function splay!(n::lctNode)
    pushReversed!(n)
    while n.parent isa lctNode
        p = n.parent
        
        #just zig; n is a child of the root.
        if p.parent == nothing
            rotateUp(n)

        # zig-zig: n<p<p.parent, or n>p>p.parent
        elseif childIndex(n) == childIndex(p)
            rotateUp(p)
            rotateUp(n)
        
        #zig-zag: p<n<p.parent, or p.parent<n<p
        else 
            rotateUp(n)
            rotateUp(n)
        end
    end
end

function pushReversed!(n::lctNode)
    if typeof(n.parent) <: lctNode
        pushReversed!(n.parent)
    end

    if n.reversed 
        tmp = n.left_child
        n.left_child = n.right_child
        n.right_child = tmp
        c = n.left_child
        if c isa lctNode
            c.reversed = !c.reversed
        end
        c = n.right_child
        if c isa lctNode
            c.reversed = !c.reversed
        end
        n.reversed = false
    end
end

