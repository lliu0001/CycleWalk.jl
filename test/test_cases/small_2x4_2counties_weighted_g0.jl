@testset "small_2x4 test graph, 2 districts, pop=(4,4), gamma=0; weighted" begin
    function edge_weight_func(
        base_graph::BaseGraph, 
        diff_cnty_weight::Float64=1.0,
        cnty_field::String
    )
        cur_weight = base_graph.simple_graph.weights[n1, n2]
        cnty1 = base_graph.node_attributes[n1][cnty_field]
        cnty2 = base_graph.node_attributes[n2][cnty_field]
        if cnty1 != cnty2
            return diff_cnty_weight
        else 
            return 1.0
        end
    end

    constraints = initialize_constraints()
    add_constraint!(constraints, PopulationConstraint(4,4))
    measure = Measure()
    n = 10000

    cycle_walk_frac = 0.1
    cycle_walk = build_lifted_tree_cycle_walk(constraints)
    internal_walk = build_internal_forest_walk(constraints)
    proposal = [(cycle_walk_frac, cycle_walk), 
                (1.0-cycle_walk_frac, internal_walk)]

    ##### Unweighted #####
    rng = PCG.PCGStateOneseq(UInt64, 1241909)
    ml_partition = MultiLevelPartition(small_2x4_graph, constraints, 
                                       small_2x4_dists; rng=rng);
    partition = LinkCutPartition(ml_partition, rng);
            
    middleSplitsCount = 0

    e11 = small_2x4_graph.partition_to_ids[1][("(1,0)",)]
    e12 = small_2x4_graph.partition_to_ids[1][("(2,0)",)]
    e21 = small_2x4_graph.partition_to_ids[1][("(1,1)",)]
    e22 = small_2x4_graph.partition_to_ids[1][("(2,1)",)]

    for ii = 1:n
        run_metropolis_hastings!(partition, proposal, measure, 1, rng)
        

        for d2n in district_to_nodes
            if d2n in keys(observed_districts)
                observed_districts[d2n] += 1
            else 
                observed_districts[d2n] = 1 
            end 
        end
    end
    
    c1, c2, c3 = count_small_square_districts(observed_districts)

    # the three instances should have approximately a 4:2:1 observation ratio. (c1 double counts)
    @test is_close(c1/n/2, 4/7) 
    @test is_close(c2/n, 1/7) 
    @test is_close(c3/n, 2/7) 
end 