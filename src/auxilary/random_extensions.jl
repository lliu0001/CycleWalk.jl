import Base: isslotfilled

function rand_set_element(r::AbstractRNG, s::Set)
    isempty(s) && throw(ArgumentError("set must be non-empty"))
    n = length(s.dict.slots)
    while true
        i = rand(r, 1:n)
        isslotfilled(s.dict, i) && return s.dict.keys[i]
    end
end

function rand_set_element_and_ind(r::AbstractRNG, s::Set)
    isempty(s) && throw(ArgumentError("set must be non-empty"))
    n = length(s.dict.slots)
    while true
        i = rand(r, 1:n)
        isslotfilled(s.dict, i) && return s.dict.keys[i], i
    end
end

function rand_set_element_pair(r::AbstractRNG, s::Set)
    length(s) < 2 && throw(ArgumentError("set must have two or more elements"))
    n = length(s.dict.slots)
    el, first = rand_set_element_and_ind(r, s)
    while true
        i = rand(r, 1:n)
        isslotfilled(s.dict, i) && i!=first && return (s.dict.keys[i], el)
    end
end

function rand_dict_key(r::AbstractRNG, d::Dict)
    isempty(d) && throw(ArgumentError("Dictionary must be non-empty"))
    n = length(d.slots)
    while true
        i = rand(r, 1:n)
        isslotfilled(d, i) && return d.keys[i]
    end
end

# rand(rng, s, 2, with_replacement=true)
