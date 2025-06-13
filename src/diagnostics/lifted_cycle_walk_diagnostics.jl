""""""
function gather_lifted_cycle_walk_diagnostics!(
    diagnostics::Union{ProposalDiagnostics, Nothing};
    accept_ratio::T=0,
    cycle_weights::Union{Nothing, Vector{Float64}}=nothing,
    dist_pair::Union{Nothing, Tuple}=nothing,
    edge_pair::Union{Nothing, Tuple}=nothing,
    edge_inds::Union{Nothing, Tuple}=nothing,
    partition::Union{Nothing, LinkCutPartition}=nothing,
    swap_data=Union{Nothing, Tuple{Int, Bool}}
) where T <: Real
    diagnostics === nothing && return

    if haskey(diagnostics, AcceptanceRatios)
        diagnostic = diagnostics[AcceptanceRatios]
        push_acceptance_probability!(diagnostic, accept_ratio)
    end

    if haskey(diagnostics, CycleLengthDiagnostic)
        diagnostic = diagnostics[CycleLengthDiagnostic]
        push_cycle_length_diagnostic!(diagnostic, cycle_weights)
    end

    if haskey(diagnostics, DeltaNodesDiagnostic)
        diagnostic = diagnostics[DeltaNodesDiagnostic]
        push_delta_node_diagnostic!(diagnostic, dist_pair, edge_pair,
                                    edge_inds, partition)
    end

end