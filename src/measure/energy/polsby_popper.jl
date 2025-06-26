mutable struct IsoperimetricData <: AbstractEnergyData
    identifier::Int64
    areas::Vector{Float64}
    perimeters::Vector{Float64}
    areas_update::Vector{Float64}
    perimeters_update::Vector{Float64}
end

function IsoperimetricData(partition::LinkCutPartition)
    identifier = partition.identifier - 1
    areas = Vector{Float64}(undef, partition.num_dists)
    perimeters= Vector{Float64}(undef, partition.num_dists)
    areas_update  = Vector{Float64}(undef, partition.num_dists)
    perimeters_update = Vector{Float64}(undef, partition.num_dists)
    areas_update .= -1.0
    return IsoperimetricData(identifier, areas, perimeters, 
                             areas_update, perimeters_update)
end

function set_areas_and_perimeters!(partition::LinkCutPartition)

    if !haskey(partition.energy_data, IsoperimetricData)
        partition.energy_data[IsoperimetricData] = 
            IsoperimetricData(partition)
    end
    iso_data = partition.energy_data[IsoperimetricData]

    graph = partition.graph
    num_dists = partition.num_dists
    
    node_to_dist = partition.node_to_dist
    areas = iso_data.areas
    perimeters = iso_data.perimeters
    edge_dict = partition.cross_district_edges
    iso_data.identifier = partition.identifier

    border_len_col = graph.node_border_col
    area_col = graph.area_col
    edge_perimeter_col = graph.edge_perimeter_col

    areas .= 0
    perimeters .= 0

    for ni = 1:length(node_to_dist)
        areas[node_to_dist[ni]] += graph.node_attributes[ni][area_col]
        perimeters[node_to_dist[ni]] += 
            graph.node_attributes[ni][border_len_col]
    end
    for ((d1,d2), edges) in edge_dict
        for edge in edges
            e = Set([src(edge), dst(edge)])
            perimeters[d1] += graph.edge_attributes[e][edge_perimeter_col]
            perimeters[d2] += graph.edge_attributes[e][edge_perimeter_col]
        end
    end
end

function set_areas_and_perimeters!(
    partition::LinkCutPartition,
    di::T,
    update::Update{T}
) where T <: Int
    if !haskey(partition.energy_data, IsoperimetricData)
        partition.energy_data[IsoperimetricData] = 
            IsoperimetricData(partition)
    end
    iso_data = partition.energy_data[IsoperimetricData]
    
    graph = partition.graph
    num_dists = partition.num_dists
    
    node_to_dist = partition.node_to_dist_update
    areas = iso_data.areas_update
    perimeters = iso_data.perimeters_update
    edge_dict = update.new_cross_d_edg
    delta_dists = update.changed_districts

    border_len_col = graph.node_border_col
    area_col = graph.area_col
    edge_perimeter_col = graph.edge_perimeter_col

    if !(di in update.changed_districts)
        @assert partition.identifier == iso_data.identifier
        areas[di] = iso_data.areas[di]
        perimeters[di] = iso_data.perimeters[di]
    else
        nodes = [ii for ii = 1:partition.graph.num_nodes 
                 if node_to_dist[ii]==di]
        for ni in nodes
            areas[di] += graph.node_attributes[ni][area_col]
            perimeters[di] += graph.node_attributes[ni][border_len_col]
        end
        for ((d1,d2), edges) in edge_dict
            if di != d1 && di != d2
                continue
            end
            for edge in edges
                e = Set([src(edge), dst(edge)])
                perimeters[di] += graph.edge_attributes[e][edge_perimeter_col]
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

    if !haskey(partition.energy_data, IsoperimetricData)
        partition.energy_data[IsoperimetricData] = 
            IsoperimetricData(partition)
    end
    iso_data = partition.energy_data[IsoperimetricData]

    if update === nothing
        if partition.identifier != iso_data.identifier
            set_areas_and_perimeters!(partition)
        end
        areas = iso_data.areas
        perimeters = iso_data.perimeters
    else
        areas = iso_data.areas_update
        perimeters = iso_data.perimeters_update
        # if partition.update_identifier != update.identifier
            areas .= 0
            perimeters .= 0
            for di in districts
                set_areas_and_perimeters!(partition, di, update)
            end
        # end
        # update.identifier = partition.update_identifier
    end

    for (ii, di) in enumerate(districts)
        isos[ii] = (perimeters[di]^2)/areas[di]
        # @show di, areas[di], iso_data.areas_update[di], iso_data.areas[di]
        # @show di, perimeters[di], iso_data.perimeters_update[di], iso_data.perimeters[di]
    end    

    return isos
end

""""""
function get_isoperimetric_score(
    partition::LinkCutPartition,
    districts::Union{Tuple{Vararg{T}}, Vector{T}}
        =collect(1:partition.num_dists);
    update::Union{Update{T}, Nothing}=nothing,
    omit_least_compact::Int=0,
    pow_on_sum::Union{Nothing,Float64}=nothing,
    exponent::F=1.0
)::Float64 where {T <: Int, F <: Real}
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

function update_energy_data!(
    eData::IsoperimetricData,
    partition::LinkCutPartition,
    update::Update{T}
) where {T<:Int}
    for di in update.changed_districts
        if eData.areas_update[di] == -1
            eData.areas_update .= -1.0
            return
        end
    end
    eData.identifier = partition.identifier
    for di in update.changed_districts
        eData.areas[di] = eData.areas_update[di]
        eData.perimeters[di] = eData.perimeters_update[di]
        eData.areas_update[di] = -1.0
    end
end
