mutable struct lctNode
    flip::Bool,
    pp::Int,
    p::Int,
    c1::Int,
    c2::Int
    val::Int
    # cval::Int
end

lctNode(v::Int) = lctNode(false, 0, 0, 0, 0, v)
 
struct LinkCutTree
    nodes::Vector{lctNode}
end

# LinkCutTree(sz::Int) = 

Base.getindex(::Type{LinkCutTree}, ii::Int) = LinkCutTree.nodes[ii]

function push!(tree::LinkCutTree, node::lctNode)
	if node.flip
		node.flip = false
		tmp = node.c1
		node.c1 = node.c2
		node.c2 = tmp
		if node.c1 =! 0
			tree[node.c1].flip ⊻= 1
		end
		if node.c2 =! 0
			tree[node.c2].flip ⊻= 1
		end
	end
end

function pull!(tree::LinkCutTree, node::lctNode)
	push!(tree, node)
	if node.c1 =! 0
		push!(tree, tree[node.c1])
	end
	if node.c2 =! 0
		push!(tree, tree[node.c2])
	end
end

function rot!(tree::LinkCutTree, node::lctNode, t::Bool) {
	y = node.p
	z = tree[node.p].p
	w = if t node.c1 else node.c2 end
	if z != 0 
		zn = tree[z]
		if zn.c1 == y
			zn.c2 = node.val;
		else
			zn.c1 = node.val;
		end
	end
	if w != 0 tree[w].p = y end
	if t
		tree[y].c1 = w
	else
		tree[y].c2 = w
	end
	node.p = z;
	if t node.c1 = y else node.c2 = y end
	tree[y].p = node.val; 
	pull!(tree, tree[y]);
end


	void g() { if (p) p->g(), pp = p->pp; push(); }
	void splay() {
		g();
		while (p) {
			Node* y = p; Node *z = y->p;
			bool t1 = (y->c[1] != this);
			bool t2 = z && (z->c[1] != y) == t1;
			if (t2) y->rot(t1);
			rot(t1);
			if (z && !t2) rot(!t1);
		}
		pull();
	}
	Node* access() {
		for (Node *y = 0, *z = this; z; y = z, z = z->pp) {
			z->splay();
			if (z->c[1]) z->c[1]->pp = z, z->c[1]->p = 0;
			if (y) y->p = z;
			z->c[1] = y; z->pull();
		}
		splay();
		flip ^= 1;
		return this;
	}
};
struct LinkCut {
	vector<Node> nodes;
	LinkCut(int N) : nodes(N) {}
	bool cut(int u, int v) { /// start-hash
		Node *y = nodes[v].access();
		Node *x = nodes[u].access();
		if (x->c[0] != y || y->c[1]) return false;
		x->c[0] = y->p = y->pp = 0;
		x->pull();
		return true;
	} /// end-hash
	bool isConnected(int u, int v) {
		Node *x = nodes[u].access();
		Node *y = nodes[v].access();
        return x == y || x -> p;
	}
	bool link(int u, int v) {
		if (isConnected(u, v)) return false;
		nodes[u].access()->pp = &nodes[v];
		return true;
	}
	void update(int u, int c) {
		nodes[u].access()->val += c;
	}
	int query(int u, int v) { // Find max on the path.
		nodes[v].access();
		return nodes[u].access()->cval;
	}
};