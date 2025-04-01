mutable struct LinkCutTreeNode
    leftChild::Int
    rightChild::Int
    parent::Int
    pathparent::Int
    index::Int

    LinkCutTreeNode() = new(0,0,0,0,0)
    LinkCutTreeNode(d) = new(0,0,0,0,d)
end

mutable struct LinkCutTree
   nodes::Vector{LinkCutTreeNode}
end

Base.getindex(::Type{LinkCutTree}, ii::Int) = LinkCutTree.nodes[ii]

function LinkCutTree(n::Int)
    nodes = Vector{LinkCutTreeNode}(undef, n)
    for ii = 1:n
        nodes[ii] = LinkCutTreeNode(ii)
    end
    return LinkCutTree(nodes)
end

function left_rotate!(tree::LinkCutTree, node_x::LinkCutTreeNode)
    if node_x.rightChild == 0 
        @show "Problem here", node_x
    end
    node_y = tree.nodes[node_x.rightChild]
    node_x.rightChild = node_y.leftChild
    if node_y.leftChild != 0
        tree.nodes[node_y.leftChild].parent = node_x.index
    end
    node_y.parent = node_x.parent

    if node_x.parent != 0 
        if (node_x == tree.nodes[node_x.parent].leftChild)
            tree.nodes[node_x.parent].leftChild = node_y.index
        else
            tree.nodes[node_x.parent].rightChild = node_y.index
        end
    end
    if node_y != 0
        node_y.leftChild = node_x.index
    end
    node_x.parent = node_y.index
    node_y.pathparent = node_x.pathparent
    node_x.pathparent = 0
end

function right_rotate!(tree::LinkCutTree, node_x::LinkCutTreeNode)
    node_y = tree.nodes[node_x.leftChild]
    node_x.leftChild = node_y.rightChild
    if node_y.rightChild != 0
        tree.nodes[node_y.rightChild].parent = node_x.index
    end
    node_y.parent = node_x.parent
    if node_x.parent != 0
        if (node_x == tree.nodes[node_x.parent].leftChild)
            tree.nodes[node_x.parent].leftChild = node_y.index
        else 
            tree.nodes[node_x.parent].rightChild = node_y.index
        end
    end
    node_y.rightChild = node_x.index
    node_x.parent = node_y.index
    node_y.pathparent = node_x.pathparent;
    node_x.pathparent = 0;
end

# The splaying operation moves node_x to the root of the tree using the series of rotations.
function splay!(tree::LinkCutTree, node_x::LinkCutTreeNode)
    while node_x.parent != 0
        parent = tree.nodes[node_x.parent]
        grand_parent = parent.parent
        if grand_parent == 0
            # single rotation
            if node_x.index == parent.leftChild
                # zig rotation
                right_rotate!(tree, tree.nodes[node_x.parent])
            else
                # zag rotation
                left_rotate!(tree, tree.nodes[node_x.parent])
            end
            # double rotation
        elseif node_x.index == parent.leftChild && parent.index == tree.nodes[grand_parent].leftChild
            # zig-zig rotation
            right_rotate!(tree, tree.nodes[grand_parent])
            right_rotate!(tree, parent)
        elseif node_x.index == parent.rightChild && parent.index == tree.nodes[grand_parent].rightChild
            # zag-zag rotation
            left_rotate!(tree, tree.nodes[grand_parent])
            left_rotate!(tree, parent)
        elseif node_x.index == parent.rightChild && parent.index == tree.nodes[grand_parent].leftChild
            # zig-zag rotation
            left_rotate!(tree, tree.nodes[node_x.parent])
            right_rotate!(tree, tree.nodes[node_x.parent])
        else
            # zag-zig rotation
            right_rotate!(tree, tree.nodes[node_x.parent])
            left_rotate!(tree, tree.nodes[node_x.parent])
        end
    end
end

function access!(tree::LinkCutTree, node_x::LinkCutTreeNode)
    splay!(tree, node_x);
    # disconnect node_x from it's right child
    if node_x.rightChild != 0
        tree.nodes[node_x.rightChild].pathparent = node_x.index;
        tree.nodes[node_x.rightChild].parent = 0;
        node_x.rightChild = 0;
    end

    last = node_x;
    while node_x.pathparent != 0
        node_y = tree.nodes[node_x.pathparent];
        last = node_y;
        splay!(tree, node_y);
        if node_y.rightChild != 0
            tree.nodes[node_y.rightChild].pathparent = node_y.index;
            tree.nodes[node_y.rightChild].parent = 0;
        end
        node_y.rightChild = node_x.index;
        node_x.parent = node_y.index;
        node_x.pathparent = 0;
        splay!(tree, node_x);
    end
    return last;
end

function root!(tree::LinkCutTree, node_x::LinkCutTreeNode)
    access!(tree, node_x)
    while node_x.leftChild != 0
        node_x = tree.nodes[node_x.leftChild]
    end
    #splay!(node_x);?? why splay here?
    return node_x
end
# function cut!(node_x::LinkCutTreeNode)
#     access!(node_x);
#     node_x.leftChild.parent = nothing;
#     node_x.leftChild = nothing;
# end

function link!(tree::LinkCutTree, node_x::LinkCutTreeNode, node_y::LinkCutTreeNode)
    @assert !connected(tree, node_x, node_y)
    make_root!(tree, node_x)
    node_x.pathparent = node_y.index
end

function connected(tree::LinkCutTree, node_x::LinkCutTreeNode, node_y::LinkCutTreeNode)
    r1 = root!(tree::LinkCutTree, node_x::LinkCutTreeNode)
    r2 = root!(tree::LinkCutTree, node_y::LinkCutTreeNode)
    return r1 == r2
end

function make_root!(tree::LinkCutTree, node_x::LinkCutTreeNode)
    access!(tree, node_x);
    if node_x.leftChild != 0
        tree.nodes[node_x.leftChild].parent = 0
        tree.nodes[node_x.leftChild].pathparent = node_x.index
        node_x.leftChild = 0
    end
end


function lca!(node_x::LinkCutTreeNode, node_y::LinkCutTreeNode)
    access!(tree, node_x);
    return access!(tree, node_y);
end