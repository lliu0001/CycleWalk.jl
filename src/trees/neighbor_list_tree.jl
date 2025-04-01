#using DataStructures

function neighbor_list_bfs(graph, start)
    visited = Set()
    queue = Deque{Tuple{Int,Int}}()
    push!(queue, (start, 0))
    farthest_node = start
    max_distance = 0

    while !isempty(queue)
        current_node, distance = popfirst!(queue)
        if distance > max_distance
            farthest_node = current_node
            max_distance = distance
        end

        for neighbor in graph[current_node]
            if !(neighbor in visited)
                push!(visited, neighbor)
                push!(queue, (neighbor, distance + 1))
            end
        end
    end

    return farthest_node, max_distance
end

"
gets the distence from the specified vertex to all of the vertices in a tree 
held in a neighbor list
"
function get_distances_BFS(neighbors, start_vertex)

    distances = Dict{Int64,Int64}()
    for vert in keys(neighbors)
        distances[vert]=-1
    end
    queue = [start_vertex]  # Queue for BFS, starting with the start_vertex

    distances[start_vertex] = 0

    while !isempty(queue)
        current_vertex = popfirst!(queue)

        for neighbor in neighbors[current_vertex]
            if distances[neighbor] == -1
                distances[neighbor] = distances[current_vertex] + 1
                push!(queue, neighbor)
            end
        end
    end

    return distances
end


function neighbor_list_find_tree_diameter(tree)
    farthest_node, _ = bfs(tree, first(keys(tree)))
    _, diameter = bfs(tree, farthest_node)
    return diameter
end


