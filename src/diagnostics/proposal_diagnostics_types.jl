abstract type AbstractProposalDiagnostics end

ProposalDiagnostics = Dict{Type{T} where T<:AbstractProposalDiagnostics, 
                           AbstractProposalDiagnostics}
RunDiagnostics = Dict{Function, Tuple{String, ProposalDiagnostics}}

""""""
struct AcceptanceRatios <: AbstractProposalDiagnostics
    data_vec::Vector{Float64}
end


""""""
function AcceptanceRatios()
    data_vec = Vector{Float64}(undef, 0)
    return AcceptanceRatios(data_vec)
end


""""""
struct CycleLengthDiagnostic <: AbstractProposalDiagnostics
    data_vec::Vector{Int64}
end


""""""
function CycleLengthDiagnostic()
    data_vec = Vector{Int64}(undef, 0)
    return CycleLengthDiagnostic(data_vec)
end


