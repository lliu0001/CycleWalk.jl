## Run:
# julia runCycleWalk_ct.jl

## Activate the CycleWalk environment and load necessary packages
import Pkg
Pkg.activate("./runCycleWalkEnv")
Pkg.instantiate()

using RandomNumbers
using CycleWalk

## Establish parameters
twocycle_frac = 0.1 #Fraction of steps using two-tree cycle walk 
gamma = 1.0 # 0 is spanning forest measure, 1 is partition
iso_weight = 0.3 # Weight on the sum of isoperimetric ratios; i.e. Polsby-Popper

@assert 0 ≤ twocycle_frac ≤ 1

num_dists = 9 #Number of districts 
rng = PCG.PCGStateOneseq(UInt64, 4541901234)
pop_dev = 0.02 #Population deviation allowed (fraction from ideal)
cycle_walk_steps = 10^2
steps = Int(cycle_walk_steps/twocycle_frac)
outfreq = Int(1000/twocycle_frac)

## Build graph of Connecticut (see CT_pct20.json file for individual nodes)
# pctGraphPath = joinpath("data","ct","CT_pct20.json") #Joins as data/ct/CT_pct20.json
pctGraphPath = "/Users/lliu001/Desktop/CycleWalk.jl/examples/data/tx/graph_DFW.json"
nodeData = Set(["county", "id", "total", "area", "boundary_perim"]); #Encode data of each node (corresponding to a precinct/county, etc.)
graph = build_graph(pctGraphPath, "total", "id", nodeData; #Specifies parameters for node weight, label, & metadata (nodeData)
              area_col="area", node_border_col="boundary_perim", #Specify which column to use for each parameter (includes perimeter of each node/precinct)
              edge_perimeter_col="shared_perim") #Each edge connects two adjacent precincts

## Build partition of districts
constraints = initialize_constraints()
add_constraint!(constraints, PopulationConstraint(graph, num_dists, pop_dev)) #Districts can't deviate from ideal population by a certain amount
partition = LinkCutPartition(graph, constraints, num_dists; rng=rng, 
                             verbose=true);

## Build proposal
cycle_walk = build_two_tree_cycle_walk(constraints)
internal_walk = build_one_tree_cycle_walk(constraints)
proposal = [(twocycle_frac, cycle_walk), 
            (1.0-twocycle_frac, internal_walk)]

## Build measure
measure = Measure()
push_energy!(measure, get_log_spanning_forests, gamma) # add spanning forests energy
push_energy!(measure, get_isoperimetric_score, iso_weight) # add isoperimetric score energy

## Establish output name and path
atlasName = "cycleWalk_2cyclefrac_"*string(twocycle_frac)
atlasName *= "_gamma"*string(gamma)
atlasName *= "_iso"*string(iso_weight)
atlasName *= ".jsonl.gz" # or just ".jsonl" for an uncompressed output
output_file_path = joinpath("/Users/lliu001/Desktop/CycleWalk.jl/output","tx", atlasName) # add output directory to path

## Establish writer to which the output will be written
ad_param = Dict{String, Any}("popdev" => pop_dev) # specific info to write
writer = Writer(measure, constraints, partition, output_file_path; 
                additional_parameters=ad_param)
push_writer!(writer, get_log_spanning_trees) # add spanning trees count to writer
push_writer!(writer, get_log_spanning_forests) # add spanning forests count to writer
push_writer!(writer, get_isoperimetric_scores) # add isoperimetric scores to writer

## optional run diagnostics
# run_diagnostics = RunDiagnostics()
# push_diagnostic!(run_diagnostics, cycle_walk, AcceptanceRatios(), 
#                  desc = "cycle_walk")
# push_diagnostic!(run_diagnostics, cycle_walk, CycleLengthDiagnostic())
# push_diagnostic!(run_diagnostics, cycle_walk, DeltaNodesDiagnostic())

## run MCMC sampler
println("running mcmc; outputting here: "* output_file_path)
run_metropolis_hastings!(partition, proposal, measure, steps, rng,
                         writer=writer, output_freq=outfreq
                        #, run_diagnostics = run_diagnostics  ## Uncoment this line to run diagnostics
)
close_writer(writer) # close atlas