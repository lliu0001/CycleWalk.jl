import Pkg
Pkg.activate("CycleWalkRunner", shared=true)
using RandomNumbers
push!(LOAD_PATH, ".."); #if not installed via package manager, point to install path
using CycleWalk

twocycle_frac = 0.01
gamma = 1.0 # 0 is spanning forest measure, 1 is partition
iso_weight = 0.3 # weight on the sum of isoperimetric ratios; i.e. Polsby-Popper

@assert 0 ≤ twocycle_frac ≤ 1

num_dists = 5
rng = PCG.PCGStateOneseq(UInt64, 4541901234)
pop_dev = 0.02 # population deviation (fraction from ideal)
cycle_walk_steps = 10^2
steps = Int(cycle_walk_steps/twocycle_frac)
outfreq = Int(1000/twocycle_frac)

# build graph
pctGraphPath = joinpath("example_data", "CT_pct20.json")
nodeData = Set(["COUNTY", "NAME", "POP20", "area", "border_length"]);
graph = build_graph(pctGraphPath, "POP20", "NAME", nodeData;
              area_col="area", node_border_col="border_length", 
              edge_perimeter_col="length")

# build partition
constraints = initialize_constraints()
add_constraint!(constraints, PopulationConstraint(graph, num_dists, pop_dev))
partition = LinkCutPartition(graph, constraints, num_dists; rng=rng, 
                             verbose=true);

# build proposal
cycle_walk = build_lifted_tree_cycle_walk(constraints)
internal_walk = build_internal_forest_walk(constraints)
proposal = [(twocycle_frac, cycle_walk), 
            (1.0-twocycle_frac, internal_walk)]

# build measure
measure = Measure()
push_energy!(measure, get_log_spanning_forests, gamma) 
push_energy!(measure, get_isoperimetric_score, iso_weight)

# establish output name and path
atlasName = "cycleWalk_2cyclefrac_"*string(twocycle_frac)
atlasName *= "_gamma"*string(gamma)
atlasName *= "_iso"*string(iso_weight)
atlasName *= ".jsonl.gz" # or just ".jsonl" for an uncompressed output
output_file_path = joinpath("..", "output", "CT", atlasName)

# establish writer
ad_param = Dict{String, Any}("popdev" => pop_dev) # specific info to write
writer = Writer(measure, constraints, partition, output_file_path; 
                additional_parameters=ad_param)
push_writer!(writer, get_log_spanning_trees)
push_writer!(writer, get_log_spanning_forests)
push_writer!(writer, get_isoperimetric_scores)

# optional run diagnostics
# run_diagnostics = RunDiagnostics()
# push_diagnostic!(run_diagnostics, cycle_walk, AcceptanceRatios(), 
#                  desc = "cycle_walk")
# push_diagnostic!(run_diagnostics, cycle_walk, CycleLengthDiagnostic())
# push_diagnostic!(run_diagnostics, cycle_walk, DeltaNodesDiagnostic())

# run MCMC sampler
println("running mcmc; outputting here: "* output_file_path)
run_metropolis_hastings!(partition, proposal, measure, steps, rng,
                         writer=writer, output_freq=outfreq)
                         # run_diatnostics = run_diatnostics)
                         
close_writer(writer)