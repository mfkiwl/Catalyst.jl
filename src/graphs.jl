# adapted from Petri.jl
# https://github.com/mehalter/Petri.jl

graph_attrs = Attributes(:rankdir=>"LR")
node_attrs  = Attributes(:shape=>"plain", :style=>"filled", :color=>"white")
edge_attrs  = Attributes(:splines=>"splines")

function edgify(δ, i, reverse::Bool)
    attr = Attributes()
    return map(δ) do p
        val = String(p[1].op.name)
      weight = "$(p[2])"
      attr = Attributes(:label=>weight, :labelfontsize=>"6")
      return Edge(reverse ? ["rx_$i", "$val"] :
                            ["$val", "rx_$i"], attr)
    end
end

"""
    Graph(rn::ReactionSystem)

Converts a [`ReactionSystem`](@ref) into a
[Catlab.jl](https://github.com/AlgebraicJulia/Catlab.jl/) Graphviz graph.
Reactions correspond to small green circles, and species to blue circles. Arrows
from species to reactions indicate reactants, and are labelled with their input
stoichiometry. Arrows from reactions to species indicate products, and are
labelled with their output stoichiometry. 

*Note*, arrows only indicate species with defined input or output stoichiometry
within a given `Reaction` in the `ReactionSystem`. The do not account for
species that appear only in a rate. i.e., for `k*A*C, A --> B` the arrow from
`A` to the reaction would have stoichiometry one, and there would be no arrow
from `C` to the reaction. 
"""
function Graph(rn::ReactionSystem)
    rxs = reactions(rn)
    statenodes = [Node(string(s.name), Attributes(:shape=>"circle", :color=>"#6C9AC3")) for s in species(rn)]
    transnodes = [Node(string("rx_$i"), Attributes(:shape=>"point", :color=>"#E28F41", :width=>".1")) for (i,r) in enumerate(rxs)]

    stmts = vcat(statenodes, transnodes)
    edges = map(enumerate(rxs)) do (i,r)
      vcat(edgify(zip(r.substrates,r.substoich), i, false),
           edgify(zip(r.products,r.prodstoich), i, true))
    end |> flatten |> collect
    stmts = vcat(stmts, edges)
    g = Graphviz.Graph("G", true, stmts, graph_attrs, node_attrs,edge_attrs)
    return g
end


"""
    savegraph(g::Graph, fname, fmt="png")

Given a [Catlab.jl](https://github.com/AlgebraicJulia/Catlab.jl/) `Graph`
generated by [`Graph`](@ref), save the graph to the file with name `fname` and
extension `fmt`. 

Notes:
- `fmt="png"` is the default output format.
"""
function savegraph(g::Graph, fname, fmt="png")
    open(fname, "w") do io
        run_graphviz(io, g, format=fmt)
    end 
    nothing
end