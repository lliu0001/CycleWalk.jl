struct Update{T <: Int}
    changed_districts::Tuple{Vararg{Int64}}
    links::Vector{Vector{T}}
    cuts::Vector{Vector{T}}
    new_cross_d_edg::Dict{Tuple{T,T}, Set{SimpleWeightedEdge}}
    swap_link11::Bool
    # identifier::T
end 

function Update(
    changed_districts::Tuple{Vararg{T}},
    links::Vector{Vector{T}},
    cuts::Vector{Vector{T}},
    new_cross_d_edg::Dict{Tuple{T,T}, Set{SimpleWeightedEdge}},
    swap_link11::Bool#,
    # identifier::T
)::Update{T} where T <: Int 
    Update{T}(changed_districts, links, cuts, new_cross_d_edg, swap_link11)#, 
              # identifier)
end