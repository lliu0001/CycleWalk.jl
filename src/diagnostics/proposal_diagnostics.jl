""""""
function get_proposal_diagnostics(
    run_diagnostics::RunDiagnostics,
    proposal::Function
)::Union{Nothing, ProposalDiagnostics}
    if !haskey(run_diagnostics, proposal)
        return nothing
    end
    return run_diagnostics[proposal][end]
end

""""""
function push_diagnostic!(
    run_diagnostics::RunDiagnostics, 
    proposal::Function,
    proposal_diagnostic::PD;
    desc::String = string(proposal)
) where PD <: AbstractProposalDiagnostics
    if !haskey(run_diagnostics, proposal)
        run_diagnostics[proposal] = (desc, ProposalDiagnostics())
    end
    proposal_diagnostics = run_diagnostics[proposal][2]
    proposal_diagnostics[typeof(proposal_diagnostic)] = proposal_diagnostic
end

""""""
function push_acceptance_probability!(
    acceptance_ratios::AcceptanceRatios, 
    p_accept::Real
)
    push!(acceptance_ratios.data_vec, p_accept)
end

""""""
function update_acceptance_ratio_diagnostic!(
    proposal_diagnostics::Union{ProposalDiagnostics, Nothing}, 
    acceptance_ratio::Float64
)
    proposal_diagnostics === nothing && return
    !haskey(proposal_diagnostics, AcceptanceRatios) && return
    
    acceptance_ratios = proposal_diagnostics[AcceptanceRatios]
    acceptance_ratios.data_vec[end] = acceptance_ratio
end

""""""
function reset_diagnostic!(acceptance_ratios::AcceptanceRatios)
    resize!(acceptance_ratios.data_vec, 0)
end

##############################

""""""
function push_cycle_length_diagnostic!(
    cycle_len_diag::CycleLengthDiagnostic, 
    cycle_weights::Union{Nothing, Vector{Float64}}
)
    len = 0
    if cycle_weights !== nothing
        len = length(cycle_weights)
    end
    push!(cycle_len_diag.data_vec, len)
end

""""""
function reset_diagnostic!(cycle_len_diag::CycleLengthDiagnostic)
    resize!(cycle_len_diag.data_vec, 0)
end

##############################

""""""
function push_delta_node_diagnostic!(
    del_node_diag::DeltaNodesDiagnostic,
    dist_pair::Union{Nothing, Tuple}=nothing,
    edge_pair::Union{Nothing, Tuple}=nothing,
    edge_inds::Union{Nothing, Tuple}=nothing,
    partition::Union{Nothing, LinkCutPartition}=nothing
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

    init_c = length(uPath)
    initial_cut = (1, length(uPath))
    proposed_cut = edge_inds

    to1 = min(init_c, proposed_cut[2])+1
    from1 = max(init_c, proposed_cut[2])
    to2 = min(init_c, proposed_cut[1])+1
    from2 = max(init_c, proposed_cut[1])
    delta_nodes1 = sum(branch_nodes[1:proposed_cut[1]-1]) + 
                   sum(branch_nodes[to1:from1])
    delta_nodes2 = sum(branch_nodes[to2:from2]) + 
                   sum(branch_nodes[proposed_cut[2]+1:end])
    delta_nodes = min(delta_nodes1, delta_nodes2)
    push!(del_node_diag.data_vec, delta_nodes)
end

""""""
function reset_diagnostic!(del_node_diag::DeltaNodesDiagnostic)
    resize!(del_node_diag.data_vec, 0)
end

##############################


""""""
function reset_diagnostics!(
    diagnostics::ProposalDiagnostics
)
    for diagnostic in values(diagnostics)
        reset_diagnostic!(diagnostic)
    end
end

""""""
function reset_diagnostics!(
    diagnostics::RunDiagnostics
)
    for proposal in keys(diagnostics)
        desc, proposal_diagnostics = diagnostics[proposal]
        reset_diagnostics!(proposal_diagnostics)
    end
end 

""""""
function gather_diagnostics!(
    diagnostics::RunDiagnostics,
    proposal::Function,
    p_accept::Real
)
    !haskey(diagnostics, proposal) && return
    desc, proposal_diagnostics = diagnostics[proposal]

    if haskey(proposal_diagnostics, AcceptanceRatios)
        diagnostic = proposal_diagnostics[AcceptanceRatios]
        push_acceptance_probability!(diagnostic, p_accept)
    end
end
