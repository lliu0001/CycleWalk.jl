mutable struct logLinkingEdgeData <: AbstractEnergyData
    identifier::Int64
    # data may become useful when using weighted edges, but shouldn't be at the moment
    # log_edge_sum::Dict{Int, Int}Vector{Float64}
    # log_edge_sum_update::Dict
end

""""""
function get_log_linking_edges(
    partition::LinkCutPartition,
    districts::Union{Tuple{Vararg{T}}, Vector{T}, Nothing}
        = nothing
)::Float64 where T <: Int
    if districts == nothing
        keys = keys(partition.cross_district_edges)
    else
        keys = [k for k in keys(partition.cross_district_edges) 
                if k[1] in districts || k[2] in districts]
    end

    log_linking_edge_product = 0
    for key in keys
        pair_sum = 0
        for e in partition.cross_district_edges[key]
            pair_sum += weight(e)
        end
        log_linking_edge_product += log(pair_sum)
    end
    return log_linking_edge_product
end

""""""
function get_log_linking_edges(
    partition::LinkCutPartition,
    new_cross_d_edg::Dict{Tuple{T,T}, Set{SimpleWeightedEdge}}
)::Float64 where T <: Int
    log_linking_edge_product = 0
    for key in keys(new_cross_d_edg)
        pair_sum = 0
        for e in new_cross_d_edg[key]
            pair_sum += weight(e)
        end
        log_linking_edge_product += log(pair_sum)
    end
    return log_linking_edge_product
end
# in above, could past a dictionary and set of keys
# update would be new_cross_d_edg and keys(new_cross_d_edg)
#!update would be partition.cross_district_edges and key subset or whole

function edges(
    partition::LinkCutPartition,
    update::Update{T};
    update_huh::Bool=false
) where T <: Int
    if !update
        return get_log_spanning_forests(partition, update.changed_districts)
    else
        return get_log_spanning_forests(partition, update.new_cross_d_edg) 
    end
end