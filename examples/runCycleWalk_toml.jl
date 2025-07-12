# # Example script to run CycleWalk with parameters from a TOML file
#
#  julia runCycleWalk_toml.jl toml/param_ct.toml
#  julia runCycleWalk_toml.jl  toml/param_grid10x10.toml
#  julia runCycleWalk_toml.jl  toml/param_hex10x10.toml
#  julia runCycleWalk_toml.jl toml/param_grid4x4.toml  --thread_id 200 --two_cycle_walk_frac .1 --cycle_walk_steps 1e4



import Pkg
Pkg.activate("cycleWalk_env", shared=true)

using RandomNumbers
using CycleWalk

using UnPack, TOML, ArgMacros


## loads command line parameters
##  These override the values in the TOML config file
args = @dictarguments begin
    @argumentoptional Int thread_id "--thread_id"
    @argumentoptional Number two_cycle_walk_frac "--two_cycle_walk_frac" "-f"
    @argumentoptional Number cycle_walk_steps "--cycle_walk_steps" "-s"
    @argumentoptional Number gamma "--gamma" 
    @argumentoptional Number iso_weight "--iso_weight" 
    @argumentoptional Int num_dists "--num_dists" "-n"
    @argumentoptional Number pop_dev "--pop_dev" "-p"
    @argumentoptional Bool run_diagnostics "--run_diagnostics" "-d"
    @positionalrequired String toml_config_file

end

toml_config_file=args[:toml_config_file]        # set name of TOML config file from arguments
params=TOML.parsefile(toml_config_file)         # parse TOML config file



# override TOML config values with command line config values
params["run"]["thread_id"]= args[:thread_id]!=nothing ? args[:thread_id] : params["run"]["thread_id"]
params["mcmc"]["two_cycle_walk_frac"]= args[:two_cycle_walk_frac]!=nothing ?  args[:two_cycle_walk_frac] : params["mcmc"]["two_cycle_walk_frac"]
params["mcmc"]["cycle_walk_steps"]= args[:cycle_walk_steps]!=nothing ?  args[:cycle_walk_steps] : params["mcmc"]["cycle_walk_steps"]
params["measure"]["gamma"]= args[:gamma]!=nothing ? args[:gamma] : params["measure"]["gamma"]
params["measure"]["iso_weight"]= args[:iso_weight]!=nothing ? args[:iso_weight] : params["measure"]["iso_weight"]
params["plans"]["pop_dev"]= args[:pop_dev]!=nothing ? args[:pop_dev] : params["plans"]["pop_dev"]
params["plans"]["num_dists"]= args[:num_dists]!=nothing ? args[:num_dists] : params["plans"]["num_dists"]
params["run"]["run_diagnostics"]= args[:run_diagnostics]!=nothing ? args[:run_diagnostics] : params["run"]["run_diagnostics"]


#load parameters from updated TOML dictionary 
@unpack gamma,iso_weight = params["measure"]
@unpack cycle_walk_steps, two_cycle_walk_frac = params["mcmc"]
@unpack outputDirectory,atlasNameBase = params["run"]
@unpack thread_id = params["run"]
@unpack cycle_walk_out_freq = params["run"]
@unpack map_directory,map_file = params["plans"]
@unpack num_dists,pop_dev=params["plans"]
@unpack node_data,pop_col,geo_units=params["plans"]


# load optional parameters from updated TOML dictionary 
measure_scores =   "measure_scores" in  keys(params["measure"]) ? params["measure"]["measure_scores"] : []  
writer_stats =  "writer_stats" in  keys(params["plans"]) ? params["plans"]["writer_stats"] : []
area_col= "area_col" in keys(params["plans"]) ? params["plans"]["area_col"] : nothing 
node_border_col= "node_border_col" in keys(params["plans"]) ? params["plans"]["node_border_col"] : nothing 
edge_perimeter_col= "edge_perimeter_col" in keys(params["plans"]) ? params["plans"]["edge_perimeter_col"] : nothing 
compress= "compress" in keys(params["run"]) ? "."*params["run"]["compress"] : "" 

node_data=Set(node_data) # change from vector to Set
@assert 0 ≤ two_cycle_walk_frac ≤ 1


rng_seed = 454190 + 15123*thread_id
steps = Int(ceil(cycle_walk_steps/two_cycle_walk_frac))  #set number of total steps needed to have correct expected number of cycle_wak_steps
outfreq = Int(floor(cycle_walk_out_freq/two_cycle_walk_frac))


#data to be added to atlas header
ad_param = Dict{String, Any}(
    "popdev" => pop_dev
)

atlasName = atlasNameBase*"_thread"*string(thread_id)*"_cyclewalkVS_2treeCycleWalk_"*string(two_cycle_walk_frac)
if gamma > 0; atlasName *="_gamma"*string(gamma) end
if iso_weight > 0; atlasName *="_iso"*string(iso_weight) end
atlasName *= ".jsonl"*compress
output_file_path = joinpath(outputDirectory... , atlasName)

@show thread_id
@show steps, outfreq
@show two_cycle_walk_frac,cycle_walk_steps
@show num_dists,pop_dev
@show atlasName
@show node_data

pctGraphPath = joinpath(map_directory... , map_file)
@show pctGraphPath

#node_data = Set(["COUNTY", "NAME", "POP20", "area", "border_length"]);
base_graph = BaseGraph(pctGraphPath, pop_col, inc_node_data=node_data,
                    area_col=area_col, node_border_col=node_border_col, 
                    edge_perimeter_col=edge_perimeter_col)
graph = MultiLevelGraph(base_graph, geo_units)

constraints = initialize_constraints()
add_constraint!(constraints, PopulationConstraint(graph, num_dists, pop_dev))

rng = PCG.PCGStateOneseq(UInt64, rng_seed)
initial_partition = MultiLevelPartition(graph, constraints, num_dists; 
                                        rng=rng);

partition = LinkCutPartition(initial_partition, rng);

cycle_walk = build_lifted_tree_cycle_walk(constraints)
internal_walk = build_internal_forest_walk(constraints)
proposal = [(two_cycle_walk_frac, cycle_walk), 
            (1.0-two_cycle_walk_frac, internal_walk)]

measure = Measure()
for fnct_str in measure_scores
    if fnct_str=="get_log_spanning_forests"
        push_energy!(measure, get_log_spanning_forests, gamma) 
    elseif fnct_str=="get_isoperimetric_score"
        push_energy!(measure, get_isoperimetric_score, iso_weight)
    else
        fnct = getfield(LiftedTreeWalk, Symbol(statistic))
        push_energy!(measure, fnct)
    end
end

@show output_file_path
writer = Writer(measure, constraints, partition, output_file_path; 
                additional_parameters=ad_param)
for stat in writer_stats
    fnct = getfield(LiftedTreeWalk, Symbol(stat))
    push_writer!(writer, fnct)
end
# push_writer!(writer, get_log_spanning_forests)
# push_writer!(writer, get_isoperimetric_scores)

run_diagnostics = RunDiagnostics()

if params["run"]["run_diagnostics"]==true
    push_diagnostic!(run_diagnostics, cycle_walk, AcceptanceRatios(), 
                    desc = "cycle_walk")
    push_diagnostic!(run_diagnostics, cycle_walk, CycleLengthDiagnostic())
    push_diagnostic!(run_diagnostics, cycle_walk, DeltaNodesDiagnostic())
end
println("\n\nRunning CycleWalk with $steps steps, output every $outfreq steps")
println("Using $two_cycle_walk_frac fraction of two_cycle_walk proposals")
println("Using $gamma gamma and $iso_weight iso_weight")
println("Using $num_dists number of distances and $pop_dev population deviation")

run_metropolis_hastings!(partition, proposal, measure, steps, rng,
                         writer=writer, output_freq=outfreq,run_diagnostics=run_diagnostics);
                        
close_writer(writer)
println("CycleWalk completed. Output written to $output_file_path")

