""""""
struct CuttableEdgePairsDiagnostic <: AbstractProposalDiagnostics
    data_vec::Vector{Int64}
end

""""""
function CuttableEdgePairsDiagnostic()
    data_vec = Vector{Int64}(undef, 0)
    return CuttableEdgePairsDiagnostic(data_vec)
end

""""""

##############################

""""""
function push_cuttable_edge_pairs_diagnostic!(
    diag::CuttableEdgePairsDiagnostic, 
    edge_pair_inds::Union{Nothing, Vector}
)
    if edge_pair_inds === nothing 
        push!(diag.data_vec, 1)
    else 
        push!(diag.data_vec, length(edge_pair_inds)+1)
    end
end

""""""
function reset_diagnostic!(diag::CuttableEdgePairsDiagnostic)
    resize!(diag.data_vec, 0)
end