args = ["1", "0.5", "0.0", "0.0"]

import Pkg

mapSamplerPath = joinpath("/Users/g/Projects/Districting/CodeBases/multiscalemapsampler-dev-lct")
push!(LOAD_PATH, mapSamplerPath);

using RandomNumbers
# using Revise
using LiftedTreeWalk


thread_id = parse(Int, args[1])
cycle_walk_frac = parse(Float64, args[2])
gamma = length(args) > 2 ? parse(Float64, args[3]) : 0
iso_weight = length(args) > 3 ? parse(Float64, args[4]) : 0

@assert 0 ≤ cycle_walk_frac ≤ 1

num_dists = 6
rng_seed = 454190 + 151423123*thread_id
pop_dev = 0.02
cycle_walk_steps = 1000 
steps = Int(ceil(cycle_walk_steps/cycle_walk_frac))
outfreq = Int(ceil(250/cycle_walk_frac))

ad_param = Dict{String, Any}(
    "popdev" => pop_dev
)

@show steps, outfreq

pctGraphPath = joinpath("data", "CT_pct20.json")
nodeData = Set(["COUNTY", "NAME", "POP20", "area", "border_length"]);
base_graph = BaseGraph(pctGraphPath, "POP20", inc_node_data=nodeData,
                       area_col="area", node_border_col="border_length", 
                       edge_perimeter_col="length")
graph = MultiLevelGraph(base_graph, ["NAME"])

constraints = initialize_constraints()
add_constraint!(constraints, PopulationConstraint(graph, num_dists, pop_dev))

rng = PCG.PCGStateOneseq(UInt64, rng_seed)
initial_partition = MultiLevelPartition(graph, constraints, num_dists; 
                                        rng=rng);
@show collect(keys(initial_partition.district_to_nodes[1]))[1:min(10,end)]
partition = LinkCutPartition(initial_partition, rng);

cycle_walk = build_lifted_tree_cycle_walk(constraints)
internal_walk = build_internal_forest_walk(constraints)
proposal = [(cycle_walk_frac, cycle_walk), 
            (1.0-cycle_walk_frac, internal_walk)]

measure = Measure()
push_energy!(measure, get_log_spanning_forests, gamma) 
push_energy!(measure, get_isoperimetric_score, iso_weight)

atlasName = "cycleWalk_v0p1"*"_thread"*args[1]*"_walkVSinternal_"*args[2]
if gamma > 0; atlasName *= "_gamma"*args[3] end
if iso_weight > 0; atlasName *= "_iso"*args[4] end
atlasName *= ".jsonl"

output_file_path = joinpath("..", "output", "CT", atlasName)
writer = Writer(measure, constraints, partition, output_file_path; 
                additional_parameters=ad_param)
push_writer!(writer, get_log_spanning_trees)
push_writer!(writer, get_log_spanning_forests)
push_writer!(writer, get_isoperimetric_scores)

run_diagnostics = RunDiagnostics()
push_diagnostic!(run_diagnostics, cycle_walk, AcceptanceRatios(), 
                 desc = "cycle_walk")
push_diagnostic!(run_diagnostics, cycle_walk, CycleLengthDiagnostic())
push_diagnostic!(run_diagnostics, cycle_walk, DeltaNodesDiagnostic())

run_metropolis_hastings!(partition, proposal, measure, 100, rng,
                         writer=writer, output_freq=10, 
                         run_diagnostics=run_diagnostics);

close_writer(writer)