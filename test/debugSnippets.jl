prev_cut = 1
    steps = 0
    first_valid_cut = initial_cut_index
    while true
        first_valid_cut -= 1
        pop1 = sum(cycle_weights[1:first_valid_cut])
        pop2 = totpop_uv - pop1
        if !(min_pop <= pop1 <= max_pop && min_pop <= pop2 <= max_pop)
            break
        end
    end
    @show first_valid_cut
    for cut1 = 1:path_length
        found_cut = false
        for cut2 = max(cut1, first_valid_cut):path_length
            pop1 = sum(cycle_weights[cut1:cut2])
            pop2 = totpop_uv - pop1
            steps += 1
            @show "step", steps, cut1, cut2, first_valid_cut
            if min_pop <= pop1 <= max_pop && min_pop <= pop2 <= max_pop
                push!(possible_pairs, (cut1, cut2))
                if !found_cut
                    found_cut = true
                    first_valid_cut = cut2
                end
                @show "adding", cut1, cut2, pop1, pop2
            elseif found_cut
                break
            end
        end
    end
    return possible_pairs


###########
    @show [u.vertex for u in uPath]
    @show [v.vertex for v in vPath]
    # u1 = partition.lct.nodes[src(edge_pair[1])]
    # v1 = partition.lct.nodes[dst(edge_pair[1])]
    # u2 = partition.lct.nodes[src(edge_pair[2])]
    # v2 = partition.lct.nodes[dst(edge_pair[2])]
    # r2 = find_root!(u2)
    # if u1 != r2 
    #     # u1 and u2 are in different districts, redefine v2 as u2 so they are
    #     u2, v2 = v2, u2
    # end
    # @show u1.vertex, u2.vertex, find_root!(u1).vertex, find_root!(u2).vertex
    # @show v1.vertex, v2.vertex, find_root!(v1).vertex, find_root!(v2).vertex
    @show cycle_weights
###########


lct = MultiScaleMapSampler.LinkCutTree{Int}(4)
lct.nodes[1].children[1] = lct.nodes[2]
lct.nodes[2].parent = lct.nodes[1]
lct.nodes[1].reversed = true

lct.nodes[2].children[1] = lct.nodes[3]
lct.nodes[3].parent = lct.nodes[2]

lct.nodes[3].children[1] = lct.nodes[4]
lct.nodes[4].parent = lct.nodes[3];

# MultiScaleMapSampler.evert!(lct.nodes[1])
# print_lct(lct)
# println()
# MultiScaleMapSampler.evert!(lct.nodes[2])
# print_lct(lct)
# println()
# MultiScaleMapSampler.evert!(lct.nodes[1])
# print_lct(lct)
# println()
# MultiScaleMapSampler.evert!(lct.nodes[1])
# pushReversed!()
print_lct(lct)
@show MultiScaleMapSampler.parents(lct)

MultiScaleMapSampler.pushReversed!(lct.nodes[4])
# MultiScaleMapSampler.expose!(lct.nodes[1])

# @show MultiScaleMapSampler.find_root!(lct.nodes[1]).vertex
# MultiScaleMapSampler.pushReversed!(lct.nodes[2])
# MultiScaleMapSampler.pushReversed!(lct.nodes[2])
print_lct(lct)


=========================================================

function print_lct(lct)
    for k = 1:length(lct.nodes)
        v = lct.nodes[k].vertex
        cs = [if c==nothing; (-1); else c.vertex end for c in lct.nodes[k].children]
        p = if lct.nodes[k].parent===nothing; -1; else lct.nodes[k].parent.vertex end
        pp = if lct.nodes[k].pathParent===nothing; -1; else lct.nodes[k].pathParent.vertex end
        pc = [c.vertex for c in lct.nodes[k].pathChildren]
        rev = lct.nodes[k].reversed
        @show v,p,cs,pp,pc,rev
    end
end

=========================================================

# partition.lct.nodes[364].children
# partition.lct.nodes[364].parent.vertex

# cc = MultiScaleMapSampler.cc(nodes[364])
MultiScaleMapSampler.evert!(partition.lct.nodes[364])
# MultiScaleMapSampler.evert!(partition.lct.nodes[349])
# MultiScaleMapSampler.evert!(partition.lct.nodes[364])
# MultiScaleMapSampler.evert!(nodes[364])

for k in cc
    v = partition.lct.nodes[k].vertex
    cs = [if c==nothing; (-1); else c.vertex end for c in partition.lct.nodes[k].children]
    p = if partition.lct.nodes[k].parent===nothing; -1; else partition.lct.nodes[k].parent.vertex end
    pp = if partition.lct.nodes[k].pathParent===nothing; -1; else partition.lct.nodes[k].pathParent.vertex end
    pc = [c.vertex for c in partition.lct.nodes[k].pathChildren]
    rev = partition.lct.nodes[k].reversed
    @show v,p,cs,pp,pc, rev
end

=========================================================

cc = MultiScaleMapSampler.cc(nodes[364]);

=========================================================

function print_lct_cc(node, lct)
    ccs = MultiScaleMapSampler.cc(node)
    for k in ccs
        v = lct.nodes[k].vertex
        cs = [if c==nothing; (-1); else c.vertex end for c in lct.nodes[k].children]
        p = if lct.nodes[k].parent===nothing; -1; else lct.nodes[k].parent.vertex end
        pp = if lct.nodes[k].pathParent===nothing; -1; else lct.nodes[k].pathParent.vertex end
        pc = [c.vertex for c in lct.nodes[k].pathChildren]
        rev = lct.nodes[k].reversed
        @show v,p,cs,pp,pc,rev
    end
end

=========================================================
=========================================================
=========================================================
=========================================================

@show "looping"
    for ii = 1:(length(uPath) + length(vPath))
        e = get_node_indices_from_paths(ii, uPath, vPath)
        @show ii, e[1].vertex, e[2].vertex
    end