# mutable struct SplitUnitCountByNodeData
#     identifier::Int64
#     unit::String
#     names::Vector{String}
#     name_to_index::Dict{String, Int64}
#     node_count_totals::Vector{Int64}
#     split_array::Array{Int64,2}
#     split_array_update::Array{Int64,2}
#     split_fractions::Vector{Float64}
#     tmp_split_data::Vector{Int64}
# end

# mutable struct SplitUnitCountsByNodeData <: AbstractEnergyData
#     unitsToSplitData::Dict{String, SplitUnitCountByNodeData}
# end

# function SplitUnitCountByNodeData(
#     partition::LinkCutPartition,
#     unit::String
# )
#     identifier = partition.identifier - 1

#     graph = partition.graph
#     names = collect(Set([z for n in graph.node_attributes for z in n[unit]]))
#     name_to_index = Dict{String, Int64}(n => ii for (ii, n) in enumerate(names))
    
#     node_count_totals = zeros(Int64, length(names))
#     for attr in graph.node_attributes
#         for n in attr[unit]
#             node_count_totals[name_to_index[n]] += 1
#         end
#     end

#     names = collect([n for (ii, n) in enumerate(names) 
#                      if node_count_totals[ii] > 1])
#     name_to_index = Dict{String, Int64}(n => ii for (ii, n) in enumerate(names))
#     node_count_totals = [nct for nct in node_count_totals if nct > 1]
    
#     split_array = zeros(Int64, (partition.num_dists, length(names)))
#     split_array_update = zeros(Int64, (partition.num_dists, length(names)))
#     split_array_update .= -1
#     split_fractions = zeros(Float64, length(names))
#     tmp_split_data = Vector{Int64}(undef, partition.num_dists)
#     return SplitUnitCountByNodeData(identifier, unit, names, name_to_index, 
#                                     node_count_totals, split_array, 
#                                     split_array_update, split_fractions, 
#                                     tmp_split_data)
# end

# function SplitUnitCountsByNodeData(partition::LinkCutPartition, unit::String)
#     units2splt = Dict{String, SplitUnitCountByNodeData}()
#     units2splt[unit] = SplitUnitCountByNodeData(partition, unit)
#     return SplitUnitCountsByNodeData(units2splt)
# end


# """"""
# function set_split_unit_matrix!(
#     suc_data::SplitUnitCountByNodeData,
#     partition::LinkCutPartition,
#     unit::String
# )
#     graph = partition.graph
#     suc_data.split_array .= 0
#     for ni = 1:graph.num_nodes
#         dist = partition.node_to_dist[ni]
#         for el in graph.node_attributes[ni][unit]
#             if haskey(suc_data.name_to_index, el)
#                 el_ind = suc_data.name_to_index[el]
#                 suc_data.split_array[dist, el_ind] += 1
#             end
#         end
#     end
# end


# """"""
# function set_split_unit_update!(
#     suc_data::SplitUnitCountByNodeData,
#     node::Node,
#     partition::LinkCutPartition,
#     unit::String;
#     start=true
# )
#     if start
#         expose!(node)
#     end
#     di = partition.node_to_dist_update[node.vertex]
#     for el in partition.graph.node_attributes[node.vertex][unit]
#         if haskey(suc_data.name_to_index, el)
#             el_ind = suc_data.name_to_index[el]
#             suc_data.split_array_update[di, el_ind] += 1
#         end
#     end

#     for ii = 1:2
#         if node.children[ii] != nothing
#             set_split_unit_update!(suc_data, node.children[ii], partition, unit, 
#                                    start=false)
#         end
#     end
#     for n in node.pathChildren
#         set_split_unit_update!(suc_data, n, partition, unit, start=false)
#     end
# end

# """"""
# function set_split_unit_update!(
#     suc_data::SplitUnitCountByNodeData,
#     partition::LinkCutPartition,
#     unit::String,
#     districts::Union{Tuple{Vararg{T}}, Vector{T}}
# ) where T <: Int
#     graph = partition.graph
#     for di in districts
#         suc_data.split_array_update[di, :] .= 0
#     end
#     for di in districts
#         ri = partition.lct.nodes[partition.district_roots[di]]
#         set_split_unit_update!(suc_data, ri, partition, unit)
#     end
# end

# """"""
# function get_split_unit_fractions_by_node(
#     partition::LinkCutPartition,
#     unit::String,
#     districts::Union{Tuple{Vararg{T}}, Vector{T}}
#         =collect(1:partition.num_dists);
#     update::Union{Update{T}, Nothing}=nothing,
# )::Vector{Float64} where T <: Int
#     if !haskey(partition.energy_data, SplitUnitCountsByNodeData)
#         partition.energy_data[SplitUnitCountsByNodeData] = 
#             SplitUnitCountsByNodeData(partition, unit)
#     end 
#     all_suc_data = partition.energy_data[SplitUnitCountsByNodeData]

#     if !haskey(all_suc_data.unitsToSplitData, unit)
#         all_suc_data.unitsToSplitData[unit] = 
#             SplitUnitCountByNodeData(partition, unit)
#     end
#     suc_data = all_suc_data.unitsToSplitData[unit]

#     split_fractions = suc_data.split_fractions 

#     if update === nothing
#         if partition.identifier != suc_data.identifier
#             suc_data.identifier = partition.identifier
#             set_split_unit_matrix!(suc_data, partition, unit)
#         end
#     else
#         node_to_dist = partition.node_to_dist_update
#         set_split_unit_update!(suc_data, partition, unit, 
#                                update.changed_districts)
#     end 

#     unit_inds = [ii for ii = 1:length(suc_data.names) 
#                  if sum(suc_data.split_array[collect(districts), ii]) > 0]

#     for ii in unit_inds
#         tmp_split_data = suc_data.tmp_split_data
#         tmp_split_data .= suc_data.split_array[:, ii]
#         if update !== nothing
#             for di in update.changed_districts
#                 tmp_split_data[di] = suc_data.split_array_update[di, ii]
#             end
#         end
#         mx_current = maximum(tmp_split_data)
#         mx_possible = suc_data.node_count_totals[ii]
#         split_fractions[ii] = 1.0-mx_current/mx_possible
#     end

#     return split_fractions
# end

# """"""
# function get_split_unit_by_node_count(
#     partition::LinkCutPartition,
#     unit::String,
#     districts::Union{Tuple{Vararg{T}}, Vector{T}}
#         =collect(1:partition.num_dists);
#     update::Union{Update{T}, Nothing}=nothing,
# )::Int64 where T <: Int
#     splits = 0

#     split_fractions = get_split_unit_fractions_by_node(partition, unit, 
#                                                        districts, update=update)

#     return length([v for v in split_fractions if v > 0])
# end


# """"""
# function get_split_unit_by_node_energy(
#     partition::LinkCutPartition,
#     unit::String,
#     districts::Union{Tuple{Vararg{T}}, Vector{T}}
#         =collect(1:partition.num_dists);
#     update::Union{Update{T}, Nothing}=nothing,
#     filter::Function = (x->sqrt(x))
# )::Float64 where T <: Int
#     splits = 0
#     split_fractions = get_split_unit_fractions_by_node(partition, unit, 
#                                                        districts, update=update)

#     return sum([filter(v) for v in split_fractions])
# end


# """"""
# function build_split_unit_by_node_energy(unit; filter::Function = (x->sqrt(x)))
#     f(p::LinkCutPartition, 
#       d::Union{Tuple{Vararg{T}}, Vector{T}}
#         =collect(1:p.num_dists);
#       update::Union{LiftedTreeWalk.Update{T}, Nothing}=nothing
#     ) where T <: Int = 
#       get_split_unit_by_node_energy(p, unit, d, update=update, filter=filter)
#     return f
# end


# """"""
# function build_split_unit_by_node_count(unit)
#     f(p::LinkCutPartition, 
#       d::Union{Tuple{Vararg{T}}, Vector{T}}
#         =collect(1:p.num_dists);
#       update::Union{LiftedTreeWalk.Update{T}, Nothing}=nothing
#     ) where T <: Int = 
#       get_split_unit_by_node_count(p, unit, d; update=update)
# end


# """"""
# function update_energy_data!(
#     eData::SplitUnitCountByNodeData,
#     partition::LinkCutPartition,
#     update::Update{T}
# ) where {T<:Int}
#     for di in update.changed_districts
#         if minimum(eData.split_array_update[di, :]) == -1
#             eData.split_array_update .= -1.0
#             return
#         end
#     end
#     eData.identifier = partition.identifier
#     for di in update.changed_districts
#         eData.split_array[di, :] .= eData.split_array_update[di, :]
#     end
#     eData.split_array_update .= -1.0
# end


# """"""
# function update_energy_data!(
#     eData::SplitUnitCountsByNodeData,
#     partition::LinkCutPartition,
#     update::Update{T}
# ) where {T<:Int}
#     for (unit, energy) in eData.unitsToSplitData
#         update_energy_data!(energy, partition, update)
#     end        
# end
