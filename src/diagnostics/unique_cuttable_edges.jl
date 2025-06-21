""""""
struct UniqueCuttableEdgesDiagnostic <: AbstractProposalDiagnostics
    data_vec::Vector{Int64}
end

""""""
function UniqueCuttableEdgesDiagnostic()
    data_vec = Vector{Int64}(undef, 0)
    return UniqueCuttableEdgesDiagnostic(data_vec)
end

""""""

##############################

""""""
function push_unique_cuttable_edges_diagnostic!(
    diag::UniqueCuttableEdgesDiagnostic, 
    edge_pair_inds::Union{Nothing, Vector},
    len_cycle::Union{Nothing, Int},
    len_uPath::Union{Nothing, Int}
)
    if edge_pair_inds === nothing || len_uPath === nothing || 
        len_cycle === nothing
        push!(diag.data_vec, 2)
        return
    end

    edges = Set{Int64}([1, len_uPath+1])
    for (e1, e2) in edge_pair_inds
        e2 = mod(e2, len_cycle)+1
        push!(edges, e1)
        push!(edges, e2)
    end
    push!(diag.data_vec, length(edges))
end

""""""
function reset_diagnostic!(diag::UniqueCuttableEdgesDiagnostic)
    resize!(diag.data_vec, 0)
end