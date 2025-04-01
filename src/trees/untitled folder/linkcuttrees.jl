"""
    link_cut_tree(g)

 Returns a link_cut_tree data structure from a graph that is a rooted, directed tree or forest of trees https://dl.acm.org/doi/10.1145/3828.3835

 Directed trees are sometimes called [polytrees](https://en.wikipedia.org/wiki/Polytree)). 

"""
function link_cut_tree(g::AG, tree_edges::Vector) where {U,AG<:AbstractGraph{U}}
    tree = LinkCutTree

    for e in tree_edges
        evert!(tree.nodes[src(e)])
        link!(tree.nodes[src(e)],tree.nodes[dst(e)])
    end

    return tree
end

#Link Cut Functions:


"Returns a vector of integers, each entry i indicating the index of the parent of the node at index i."
# function parents(f::LinkCutTree)
#     nodes = copy(f.nodes)
#     p = Vector{T}(undef,length(f.nodes))
#     while length(nodes) > 0
#         r = findSplayRoot(nodes[1])
#         s = traverseSubtree(r)
#         if r.pathParent isa LinkCutNode
#             p[s[1].vertex] = r.pathParent.vertex
#         else
#             p[s[1].vertex] = s[1].vertex
#         end    
#         for i in 2:lastindex(s)
#             p[s[i].vertex] = s[i-1].vertex
#         end
#         setdiff!(nodes,s)        
#     end
#     return p
# end

"Returns a vector of the current subtree that n is in, in order of depth on the represented tree."
function findPath(n::LinkCutNode)
    return traverseSubtree(findSplayRoot(n))
end

"returns a vector of the integer labels for the current subtree that the node indexed by i is in,
 in the tree t, in order of depth on the represented tree."
function findPath(i::Integer, t::LinkCutTree)
    A = traverseSubtree(findSplayRoot(t.nodes[i]))
    B = Vector{Integer}(undef,length(A))
    for i in eachindex(A)
        B[i] = A[i].vertex
    end
    return B
end

"Replaces the right subtree of n with r, or with nothing if r is unspecified.
the old right subtree of n is moved to a separate auxillary tree and tracked with a path-parent pointer."
function replaceRightSubtree!(t::LinkCutTree, n::LinkCutNode, r::Union{LinkCutNode, Nothing}=nothing)
    c = n.right_child
    if c isa LinkCutNode
        c.pathParent = n
        c.parent = nothing
    end

    n.right_child = r
    if r isa LinkCutNode
        r.pathParent = nothing
    end

end


"Moves n to the tree at the root of the link-cut tree using splay tree operations.
Preserves the represented tree, and n will be the deepest node on the preferred path."
function expose!(t::LinkCutTree, n::LinkCutNode)

    splay!(t, n)
    replaceRightSubtree!(n)

    while n.pathParent isa LinkCutNode
        p = n.pathParent
        splay!(p)
        replaceRightSubtree!(p,n)
        splay!(n)
    end
end

"Links two represented trees, where u is the root of one represented tree and becomes a child of v."
function link!(u::LinkCutNode, v::LinkCutNode)

    expose!(u)
    if u.left_child isa LinkCutNode
        throw(ArgumentError("u must be the root of its represented tree to link."))
    end

    expose!(v)
    if u.parent isa LinkCutNode || u.pathParent isa LinkCutNode
        throw(ArgumentError("Can't link two nodes in the same represented tree"))
    end
    u.pathParent = v
end

"Cuts the node u away from its parent in the represented tree.
u cannot be the root of the represented tree."
function cut!(u::LinkCutNode)
    expose!(u)

    if !(u.left_child isa LinkCutNode)
        throw(ArgumentError("can't cut the root of the represented tree."))
    end

    v = u.left_child

    v.parent = nothing
    u.left_child = nothing

end

"Changes the root of the represented tree to u."
function evert!(u::LinkCutNode)
    expose!(u)
    u.reversed = true
end

# function undirected_tree(parents::AbstractVector{T}) where {T<:Integer}
#     n = T(length(parents))
#     t = Graph{T}(n)
#     for (v, u) in enumerate(parents)
#         if u > zero(T) && u != v
#             add_edge!(t, u, v)
#         end
#     end
#     return t
# end
