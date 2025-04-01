mutable struct COISplitData <: AbstractEnergyData
    identifier::Int64
    coi_names::Vector{String}
    coi_pops::Vector{Real}
    coi_ids::Dict{String, Int}
    splits::Array{Real,2}
    ideal_dist_pop::Real
end

function build_coi_score(
    partition::LinkCutPartition,
    coi_col::String;
    ideal_pop::Union{Nothing,Real}=nothing
)
    cois = COISplitData(partition, coi_col, ideal_pop=ideal_pop)
    get_coi_score!(cois, coi_col, partition)
    f(p, d=collect(1:p.num_dists); update=nothing) = get_coi_score!(cois, coi_col, p, d)
    return f
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

function get_coi_score!(
    cois::COISplitData,
    coi_col::String,
    partition::LinkCutPartition,
    districts::Vector{Int} = collect(1:partition.num_dists);
    update::Union{Update{T}, Nothing}=nothing
)
    ousted_population = 0
    coi_ids = Set{Int}()
    # @show districts
    for di in districts
        # @show keys(partition.district_to_nodes[di])
        cois.splits[di,:] .= 0 
        union!(coi_ids, get_coi_splits!(cois, coi_col, partition, di))
        # @show "after union", coi_ids
    end
    ideal_pop = cois.ideal_dist_pop
    # @show ideal_pop
    sorted_perm = zeros(Int, partition.num_dists)
    for coi_id in coi_ids
        coi_pop = cois.coi_pops[coi_id]
        num_dists = coi_pop/ideal_pop
        whole_dists = Int(floor(num_dists))
        # if coi_id == 4 
        #     @show coi_pop, num_dists
        # end
        sortperm!(sorted_perm, cois.splits[:, coi_id], rev=true)
        if num_dists > 1
            for ii = 1:whole_dists
                di = sorted_perm[ii]
                ousted_population += partition.dist_populations[di]
                ousted_population -= cois.splits[di, coi_id]
                # if coi_id == 4 
                #     dpop = partition.dist_populations[di]
                #     split = cois.splits[di, coi_id]
                #     ousted = partition.dist_populations[di]-cois.splits[di, coi_id] 
                #     @show ii, coi_pop, num_dists, dpop, split, ousted
                # end
            end 
            df = sorted_perm[whole_dists+1] 
            fraction = num_dists - floor(num_dists)
            ousted_frac = ideal_pop*fraction - cois.splits[df, coi_id]
            if ousted_frac > 0
                ousted_population += ousted_frac
            end
            # if coi_id == 4 
            #     ideal_rem = ideal_pop*fraction
            #     @show ousted_frac, ideal_rem
            # end
        else 
            rep_dist = sorted_perm[1]
            ousted_population += coi_pop - cois.splits[rep_dist, coi_id]
        end
    end
    # @show cois.splits[:,4], ousted_population
    # @show ousted_population
    # @show cois
    return ousted_population
end

function get_coi_splits!(
    cois::COISplitData,
    coi_col::String,
    partition::LinkCutPartition,
    di::Int
)::Set{Int}
    # node_set::Dict{Tuple{Vararg{String}}, Any}=partition.district_to_nodes[di]
    coi_ids = Set{Int}()
    graph = partition.graph
    node_attributes = graph.node_attributes
    for node in keys(node_set)
        for (coi, pop) in node_attributes[node_id][coi_col]
            coi_id = cois.coi_ids[coi]
            cois.splits[di, coi_id] += pop
            push!(coi_ids, coi_id)
        end
    end
    return coi_ids
end

function COISplitData(
    partition::LinkCutPartition,
    coi_col::String; 
    ideal_pop::Union{Real, Nothing}=nothing
)::COISplitData
    identifier = partition.identifier - 1
    coi_names = Vector{String}(undef, 0)
    coi_pops = Vector{Float64}(undef, 0)
    coi_ids = Dict{String, Int}()
    graph = partition.graph
    node_attributes = graph.node_attributes
    
    coi_id_count = 1
    for node_id = 1:graph.num_nodes
        cois = node_attributes[node_id][coi_col]
        for (coi, pop) in cois
            if haskey(coi_ids, coi)
                coi_pops[coi_ids[coi]] += pop
            else
                push!(coi_pops, pop)
                push!(coi_names, coi)
                coi_ids[coi] = coi_id_count
                coi_id_count += 1
            end
        end
    end
    splits = zeros(partition.num_dists, length(coi_pops))
    if ideal_pop == nothing
        ideal_pop = graph.total_pop/partition.num_dists
    end
    return COISplitData(identifier, coi_names, coi_pops, coi_ids, splits, 
                        ideal_pop)
end