import Pkg
push!(LOAD_PATH, "..");

using RandomNumbers
using MultiScaleMapSampler

pctGraphPath = joinpath(".", "4x4.json")
precinct_name = "precinct"
county_name = "county"
population_col = "TOTPOP"
num_dists = 4
rng_seed = 454190
pop_dev = 0.0
gamma = 0.0 #0 is uniform on forests; 1 is uniform on partitions
steps = 100000
edge_weights= "connections"
output_file_path = "./4x4_atlas_gamma"*string(gamma)*".jsonl"

nodeData = Set([precinct_name, county_name, population_col])

base_graph = BaseGraph(
    pctGraphPath, 
    population_col, 
    inc_node_data=nodeData,
    edge_weights=edge_weights
);
graph = MultiLevelGraph(base_graph, [county_name, precinct_name]);

constraints = initialize_constraints()
add_constraint!(constraints, PopulationConstraint(graph, num_dists, pop_dev))
add_constraint!(constraints, ConstrainDiscontinuousTraversals(graph))

rng = PCG.PCGStateOneseq(UInt64, rng_seed)
partition = MultiLevelPartition(graph, constraints, num_dists; rng=rng);

proposal = build_forest_recom2(constraints)
measure = Measure(gamma)


output_file_path = "./4x4_atlas_output.jsonl"
output_file_io = smartOpen(output_file_path, "w")
writer = Writer(measure, constraints, partition, output_file_io)


run_metropolis_hastings!(
    partition, 
    proposal, 
    measure, 
    steps, 
    rng,
    writer=writer, 
    output_freq=1
);