# CycleWalk.jl

This repository contains Julia code the run the Metropolized Cycle Walk algorithm which is used to sample a used specified distribution on the space of political redistricting plans. This MCMC algorithm is used to create ensemble of redistricting plans that can be used to analyze the impact of different redistricting plans on electoral outcomes. 

Metropolized Cycle Walk supports number of different score/energy functions which are used to define the distribution. The distribution encodes the legal and policy preferences. 

Metropolized Cycle Walk outputs the samples into an [Atlas file](https://github.com/jonmjonm/AtlasIO.jl/blob/main/atlas_format.md). AtlasIO files can be loaded using Julia or Python using the [AtlasIO.jl](https://github.com/jonmjonm/AtlasIO.jl) library.

## Metropolized Cycle Walk Algorithm

The basic Cycle Walk produced $d$-tree spanning forests where each of the $d$ spanning trees is approximately balanced in the sense that the total population of each tree is approximately balanced.  

One step of the Cycle Walk proceeds by either proposing a 1-Tree Cycle Walk or a 2-Tree Cycle Walk. The 1-Tree Cycle Walk adds an edge the tree and then removes and edge from cycle this addition creates so that one again has a tree. The 2-Tree Cycle Walk adds two edges between two adjacent trees and then removes two edges from the cycle these additions creates so that one again has two trees. 

The Metropolized Cycle Walk algorithm uses these walks as proposals to a Metropolis-Hastings algorithm to sample from a specified target distribution. 

More details on the algorithm can be found in the [Cycle Walk paper].

## Basic Usage

```julia
NEED TO BE ADDED
```

## Example Scripts

The `examples` directory contains example scripts that demonstrate how to use the Metropolized Cycle Walk algorithm. These scripts can be run to generate redistricting plans and analyze their properties.