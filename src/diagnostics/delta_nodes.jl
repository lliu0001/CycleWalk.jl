""""""
struct DeltaNodesDiagnostic <: AbstractProposalDiagnostics
    data_vec::Vector{Int64}
end


""""""
function DeltaNodesDiagnostic()
    data_vec = Vector{Int64}(undef, 0)
    return DeltaNodesDiagnostic(data_vec)
end

""""""
function push_delta_node_diagnostic!(
    del_node_diag::DeltaNodesDiagnostic,
    dist_pair::Union{Nothing, Tuple}=nothing,
    edge_pair::Union{Nothing, Tuple}=nothing,
    edge_inds::Union{Nothing, Tuple}=nothing,
    partition::Union{Nothing, LinkCutPartition}=nothing,
    swap_data::Union{Nothing, Tuple{Int, Bool}}=nothing
)
    if (dist_pair === nothing || edge_pair === nothing || 
        edge_inds === nothing || partition === nothing)
        push!(del_node_diag.data_vec, 0)
        return
    end

    uPath, vPath = get_paths!(partition, edge_pair)
    branch_nodes = get_collapsed_cycle_weights(uPath, vPath, partition; 
                                               field=nothing)
    evert!(partition.lct.nodes[partition.district_roots[dist_pair[1]]])
    evert!(partition.lct.nodes[partition.district_roots[dist_pair[2]]])


    proposed_cut = edge_inds
    overlap1 = 0
    tot_nodes = sum(branch_nodes)
    if proposed_cut[1] <= length(uPath)
        overlap1 += sum(branch_nodes[proposed_cut[1]:min(length(uPath),
                                                         proposed_cut[2])])
    elseif proposed_cut[1] > length(uPath)+1
        overlap1 += sum(branch_nodes[length(uPath)+1:proposed_cut[1]-1])
    end
    if proposed_cut[2] < length(branch_nodes)
        overlap1 += sum(branch_nodes[max(length(uPath)+1, 
                                         proposed_cut[2]+1):end])
    end

    path_ind_l11, swap_link11 = swap_data
    l11_cur = path_ind_l11 <= length(uPath)
    l11_proposed = (proposed_cut[1] <= path_ind_l11 <= proposed_cut[2])
    delta_nodes = overlap1
    if swap_data === nothing
        delta_nodes = min(overlap1, tot_nodes-overlap1)
    elseif (l11_cur ⊻ l11_proposed) ⊻ !swap_link11
        delta_nodes = tot_nodes-overlap1
    end
    push!(del_node_diag.data_vec, delta_nodes)
end

""""""
function reset_diagnostic!(del_node_diag::DeltaNodesDiagnostic)
    resize!(del_node_diag.data_vec, 0)
end