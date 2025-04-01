mutable struct Measure
    weights::Vector{Float64}
    scores::Vector{Function}
    descriptions::Vector{String}
    # TO DO: constraints::Dict{Type{T} where T<:AbstractConstraint, AbstractConstraint}
end

""""""
function Measure()
    scores = Vector{Function}(undef, 0)
    weights = Vector{Float64}(undef, 0)
    descriptions = Vector{String}(undef, 0)
    return Measure(weights, scores, descriptions)
end

""""""
function push_energy!(
    measure::Measure,
    score::Function,
    weight::Real;
    desc::String=""
)
    @assert length(measure.weights) == length(measure.scores)
    weight == 0 && return 
    push!(measure.weights, weight)
    push!(measure.scores, score)
    if desc == ""
        desc = string(score)
    end
    push!(measure.descriptions, desc)
    @assert length(Set(measure.scores)) == length(measure.scores) 
end

""""""
function get_delta_energy(
    partition::LinkCutPartition, 
    measure::Measure,
    update::Update{T}
) where T <: Int
    score = 0
    changed_districts = update.changed_districts
    score += get_log_energy(partition, measure, changed_districts)
    score -= get_log_energy(partition, measure, changed_districts, update)
    return exp(score)
end

""""""
function get_log_energy(
    partition::LinkCutPartition, 
    measure::Measure,
    districts::Union{Tuple{Vararg{T}}, Vector{T}}
        = collect(1:partition.num_dists),
    update::Union{Update{T}, Nothing}=nothing
)::Float64 where T <: Int
    score = 0.0
    for ii = 1:length(measure.weights)
        weight = measure.weights[ii]
        if weight == 0
            continue
        end
        energy = measure.scores[ii]
        score += weight*energy(partition, districts; update=update)
    end
    return score
end

################################## EVERYTHING BELOW SHOULD GO ELSEWHERE

""""""
function get_cut_edge_count(partition::MultiLevelPartition)
    return get_cut_edge_weights(partition, "connections")
end


""""""
function get_cut_edge_perimeter(partition::MultiLevelPartition)
    edge_perimeter_col = partition.graph.graphs_by_level[1].edge_perimeter_col
    return get_cut_edge_weights(partition, edge_perimeter_col)
end


""""""
function get_cut_edge_sum(
    partition::LinkCutPartition;
    column::String="connections"
)
    graph = partition.graph
    total = 0
    for e in edges(graph.simple_graph)
        n1, n2 = src(e), dst(e)
        if partition.node_to_dist[n1] == partition.node_to_dist[n2]
            continue
        end
        total += graph.edge_attributes[Set([n1, n2])][column]
    end
    return total
end

