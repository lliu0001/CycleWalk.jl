mutable struct VotingData <: AbstractEnergyData
    identifier::Int64
    dem_votes::Vector{Float64}
    rep_votes::Vector{Float64}
    dem_margins::Vector{Float64}
    dem_votes_update::Vector{Float64}
    rep_votes_update::Vector{Float64}
    dem_margins_update::Vector{Float64}
end

function VotingData(partition::LinkCutPartition)
    identifier = partition.identifier - 1
    dem_votes = Vector{Float64}(undef, partition.num_dists)
    rep_votes = Vector{Float64}(undef, partition.num_dists)
    dem_margins = Vector{Float64}(undef, partition.num_dists)
    dem_votes_update = Vector{Float64}(undef, partition.num_dists)
    rep_votes_update = Vector{Float64}(undef, partition.num_dists)
    dem_margins_update = Vector{Float64}(undef, partition.num_dists)
    dem_margins_update .= -1.0
    return VotingData(identifier, dem_votes, rep_votes, dem_margins,
                      dem_votes_update, rep_votes_update, dem_margins_update)
end

function set_vote_data!(
    partition::LinkCutPartition, 
    votes1::String, 
    votes2::String, 
    vote_data::VotingData,
    update::Union{Update{T}, Nothing}=nothing
) where T<:Int
    node_attributes = partition.graph.node_attributes
    num_dists = partition.num_dists
    num_nodes = partition.graph.num_nodes

    node_to_dist = partition.node_to_dist
    dem_votes = vote_data.dem_votes
    rep_votes = vote_data.rep_votes
    dem_margins = vote_data.dem_margins
    nodes = 1:num_nodes
    districts = 1:num_dists

    if update !== nothing
        node_to_dist = partition.node_to_dist_update
        dem_votes = vote_data.dem_votes_update
        rep_votes = vote_data.rep_votes_update
        dem_margins = vote_data.dem_margins_update
        nodes = [ii for ii = 1:num_nodes 
                 if node_to_dist[ii]∈update.changed_districts]
        districts = update.changed_districts
    end

    for di in districts
        dem_votes[di] = 0
        rep_votes[di] = 0
    end

    for ii in nodes
        dem_votes[node_to_dist[ii]] += node_attributes[ii][votes1]
        rep_votes[node_to_dist[ii]] += node_attributes[ii][votes2]
    end
    for di in districts
        dem_margins[di] = 100.0*dem_votes[di]/(dem_votes[di]+rep_votes[di])
    end

    if update === nothing
        vote_data.identifier = partition.identifier
    end
end

""""""
function get_partisan_margins(
    partition::LinkCutPartition,
    votes1::String, 
    votes2::String,
    districts::Vector{Int} = collect(1:partition.num_dists);
    update::Union{Update{T}, Nothing}=nothing
)::Vector{Float64} where T <: Int
    margins = Vector{Float64}(undef, length(districts))

    if !haskey(partition.energy_data, (VotingData, (votes1, votes2)))
        partition.energy_data[(VotingData, (votes1, votes2))] = 
            VotingData(partition)
    end
    vote_data = partition.energy_data[(VotingData, (votes1, votes2))]

    if update === nothing
        if partition.identifier != vote_data.identifier
            set_vote_data!(partition, votes1, votes2, vote_data)
        end
        margins .= vote_data.dem_margins
    else
        margins .= vote_data.dem_margins
        set_vote_data!(partition, votes1, votes2, vote_data, update)
        for di in update.changed_districts
            margins[di] = vote_data.dem_margins_update[di]
        end
    end

    return margins
end

""""""
function get_partisan_seats(
    partition::LinkCutPartition,
    votes1::String, 
    votes2::String,
    districts::Vector{Int} = collect(1:partition.num_dists);
    update::Union{Update{T}, Nothing}=nothing
)::Float64 where T <: Int
    leans = get_partisan_margins(partition, votes1, votes2, districts; 
                                 update=update)
    return length([1 for l in leans if l > 50.0])
end

""""""
function build_get_partisan_margins(
    votes1::String, votes2::String
)
    f(p, d=collect(1:p.num_dists); update=nothing) = 
                       get_partisan_margins(p, votes1, votes2, d; update=update)
    return f
end

""""""
function build_get_partisan_seats(
    votes1::String, votes2::String
)
    f(p, d=collect(1:p.num_dists); update=nothing) = 
                         get_partisan_seats(p, votes1, votes2, d; update=update)
    return f
end


function update_energy_data!(
    eData::VotingData,
    partition::LinkCutPartition,
    update::Update{T}
) where {T<:Int}
    for di in update.changed_districts
        if eData.dem_margins_update[di] == -1
            eData.dem_margins_update .= -1.0
            return
        end
    end
    eData.identifier = partition.identifier
    for di in update.changed_districts
        eData.dem_votes[di] = eData.dem_votes_update[di]
        eData.rep_votes[di] = eData.rep_votes_update[di]
        eData.dem_margins[di] = eData.dem_margins_update[di]
        eData.dem_margins_update[di] = -1.0
    end
end

