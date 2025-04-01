mutable struct LogForestEnergyData <: AbstractEnergyData
    identifier::Int64
    log_trees::Vector{Float64}
    log_trees_update::Vector{Float64}
end

function LogForestEnergyData(partition::LinkCutPartition)
    identifier = partition.identifier - 1
    log_trees = Vector{Float64}(undef, partition.num_dists)
    log_trees_update = Vector{Float64}(undef, partition.num_dists)
    log_trees_update .= -1.0
    return LogForestEnergyData(identifier, log_trees, log_trees_update)
end

function get_log_spanning_trees(
    node_to_dist::Vector{Int64},
    simple_graph::SimpleWeightedGraph,
    di::T
)::Float64 where T <: Int64
    nodes = [ii for ii = 1:length(node_to_dist) if node_to_dist[ii]==di]
    sg, vm = induced_subgraph(simple_graph, nodes)
    return log_nspanning(sg)
end

""""""
function get_log_spanning_trees(
    partition::LinkCutPartition,
    districts::Union{Tuple{Vararg{T}}, Vector{T}}
        =collect(1:partition.num_dists);
    update::Union{Update{T}, Nothing}=nothing
)::Vector{Float64} where T <: Int
    log_spanning_trees = Vector{Float64}(undef, length(districts))

    if haskey(partition.energy_data, LogForestEnergyData)
        log_tree_data = partition.energy_data[LogForestEnergyData]
    else
        log_tree_data = LogForestEnergyData(partition)
        partition.energy_data[LogForestEnergyData] = log_tree_data
    end

    simple_graph = partition.graph.simple_graph

    if update === nothing
        node_to_dist = partition.node_to_dist
        log_trees = log_tree_data.log_trees
        if partition.identifier != log_tree_data.identifier
            log_tree_data.identifier = partition.identifier
            for ii = 1:partition.num_dists
                log_trees[ii] = get_log_spanning_trees(node_to_dist, 
                                                       simple_graph, ii)
            end
        end
    else
        node_to_dist = partition.node_to_dist_update
        log_trees = log_tree_data.log_trees_update
        for di in districts
            log_trees[di] = get_log_spanning_trees(node_to_dist, simple_graph,
                                                   di)
        end
    end

    for (ii, di) in enumerate(districts)
        log_spanning_trees[ii] = log_trees[di]
    end
    return log_spanning_trees
end

""""""
function get_log_spanning_forests(
    partition::LinkCutPartition,
    districts::Union{Tuple{Vararg{T}}, Vector{T}}
        = collect(1:partition.num_dists);
    update::Union{Update{T}, Nothing}=nothing
)::Float64 where T <: Int
    return sum(get_log_spanning_trees(partition, districts, update=update))
end

function update_energy_data!(
    eData::LogForestEnergyData,
    partition::LinkCutPartition,
    update::Update{T}
) where {T<:Int}
    # @show "in tree based updater"
    for di in update.changed_districts
        if eData.log_trees_update[di] == -1
            eData.log_trees_update .= -1.0
            return
        end
    end
    eData.identifier = partition.identifier
    for di in update.changed_districts
        eData.log_trees[di] = eData.log_trees_update[di]
        eData.log_trees_update[di] = -1.0
    end
end