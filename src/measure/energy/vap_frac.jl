mutable struct VAPData <: AbstractEnergyData
    identifier::Int64
    mino_vaps::Vector{Float64}
    total_vaps::Vector{Float64}
    mino_vaps_update::Vector{Float64}
    total_vaps_update::Vector{Float64}
    mino_vap_col::String
    total_vap_col::String
end

function VAPData(
    partition::LinkCutPartition,
    mino_vap_col::String, 
    total_vap_col::String,
)
    identifier = partition.identifier - 1
    mino_vaps = Vector{Float64}(undef, partition.num_dists)
    total_vaps= Vector{Float64}(undef, partition.num_dists)
    mino_vaps_update  = Vector{Float64}(undef, partition.num_dists)
    total_vaps_update = Vector{Float64}(undef, partition.num_dists)
    mino_vaps_update .= -1.0
    return VAPData(identifier, mino_vaps, total_vaps, mino_vaps_update, 
                   total_vaps_update, mino_vap_col, total_vap_col)
end

function set_vaps!(partition::LinkCutPartition, vap_data::VAPData)
    graph = partition.graph
    num_dists = partition.num_dists
    
    node_to_dist = partition.node_to_dist
    mino_vaps = vap_data.mino_vaps
    total_vaps = vap_data.total_vaps
    vap_data.identifier = partition.identifier

    border_len_col = graph.node_border_col
    area_col = graph.area_col
    edge_perimeter_col = graph.edge_perimeter_col

    mino_vaps .= 0
    total_vaps .= 0

    for ni = 1:length(node_to_dist)
        mino_vaps[node_to_dist[ni]] += graph.node_attributes[ni][area_col]
        total_vaps[node_to_dist[ni]] += 
            graph.node_attributes[ni][border_len_col]
    end
    for ((d1,d2), edges) in edge_dict
        for edge in edges
            e = Set([src(edge), dst(edge)])
            total_vaps[d1] += graph.edge_attributes[e][edge_perimeter_col]
            total_vaps[d2] += graph.edge_attributes[e][edge_perimeter_col]
        end
    end
end

function set_vaps!(
    partition::LinkCutPartition,
    di::T,
    update::Update{T},
    vap_data::VAPData
) where T <: Int
    graph = partition.graph
    num_dists = partition.num_dists
    
    node_to_dist = partition.node_to_dist_update
    mino_vaps = vap_data.mino_vaps_update
    total_vaps = vap_data.total_vaps_update
    edge_dict = update.new_cross_d_edg
    delta_dists = update.changed_districts

    border_len_col = graph.node_border_col
    area_col = graph.area_col
    edge_perimeter_col = graph.edge_perimeter_col

    if !(di in update.changed_districts)
        @assert partition.identifier == vap_data.identifier
        mino_vaps[di] = vap_data.mino_vaps[di]
        total_vaps[di] = vap_data.total_vaps[di]
    else
        nodes = [ii for ii = 1:partition.graph.num_nodes 
                 if node_to_dist[ii]==di]
        for ni in nodes
            mino_vaps[di] += graph.node_attributes[ni][area_col]
            total_vaps[di] += graph.node_attributes[ni][border_len_col]
        end
        for ((d1,d2), edges) in edge_dict
            if di != d1 && di != d2
                continue
            end
            for edge in edges
                e = Set([src(edge), dst(edge)])
                total_vaps[di] += graph.edge_attributes[e][edge_perimeter_col]
            end
        end
    end
end

""""""
function get_isoperimetric_scores(
    partition::LinkCutPartition,
    districts::Union{Tuple{Vararg{T}}, Vector{T}}
        =collect(1:partition.num_dists);
    update::Union{Update{T}, Nothing}=nothing
)::Vector{Float64} where T <: Int
    isos = Vector{Float64}(undef, length(districts))

    vap_data = get!(partition.energy_data, VAPData, 
                    VAPData(partition))

    if update === nothing
        if partition.identifier != vap_data.identifier
            set_vaps!(partition, vap_data)
        end
        mino_vaps = vap_data.mino_vaps
        total_vaps = vap_data.total_vaps
    else
        mino_vaps = vap_data.mino_vaps_update
        total_vaps = vap_data.total_vaps_update
        mino_vaps .= 0
        total_vaps .= 0
        for di in districts
            set_vaps!(partition, di, update, vap_data)
        end
    end

    for (ii, di) in enumerate(districts)
        isos[ii] = (total_vaps[di]^2)/mino_vaps[di]
        # @show di, mino_vaps[di], vap_data.mino_vaps_update[di], vap_data.mino_vaps[di]
        # @show di, total_vaps[di], vap_data.total_vaps_update[di], vap_data.total_vaps[di]
    end    

    return isos
end

""""""
function get_mino_vaps(
    partition::LinkCutPartition,
    mino_vap_col::String,
    total_vap_col::String,
    districts::Union{Tuple{Vararg{T}}, Vector{T}}
        =collect(1:partition.num_dists);
    update::Union{Update{T}, Nothing}=nothing 
)
    # if omit_least_compact > 0 || pow_on_sum != nothing
        isos = get_isoperimetric_scores(partition, districts, update=update)
    # else
    #    isos = get_isoperimetric_scores(partition, update=update)
    # end

    if exponent != 1
        isos .^= exponent
    end

    return sum(isos)
end

""""""
function get_mino_vap_score(
    partition::LinkCutPartition,
    mino_vap_col::String,
    total_vap_col::String,
    districts::Union{Tuple{Vararg{T}}, Vector{T}}
        =collect(1:partition.num_dists);
    update::Union{Update{T}, Nothing}=nothing 
)
    if haskey()
    # if omit_least_compact > 0 || pow_on_sum != nothing
        # isos = get_isoperimetric_scores(partition, districts, update=update)
    # else
    #    isos = get_isoperimetric_scores(partition, update=update)
    # end

    if exponent != 1
        isos .^= exponent
    end

    return sum(isos)
end

function update_energy_data!(
    eData::VAPData,
    partition::LinkCutPartition,
    update::Update{T}
) where {T<:Int}
    for di in update.changed_districts
        if eData.mino_vaps_update[di] == -1
            eData.mino_vaps_update .= -1.0
            return
        end
    end
    eData.identifier = partition.identifier
    for di in update.changed_districts
        eData.mino_vaps[di] = eData.mino_vaps_update[di]
        eData.total_vaps[di] = eData.total_vaps_update[di]
        eData.mino_vaps_update[di] = -1.0
    end
end
