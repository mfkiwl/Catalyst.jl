# Catalyst.jl API
```@meta
CurrentModule = Catalyst
```

## Reaction Network Generation and Representation
Catalyst provides the [`@reaction_network`](@ref) macro for generating a
complete network, stored as a [`ReactionSystem`](@ref), which in turn is
composed of [`Reaction`](@ref)s. `ReactionSystem`s can be converted to other
`ModelingToolkit.AbstractSystem`s, including a `ModelingToolkit.ODESystem`,
`ModelingToolkit.SDESystem`, or `ModelingToolkit.JumpSystem`.

An empty network can be generated using [`@reaction_network`](@ref) with no
arguments (or one argument to name the system), or the
[`make_empty_network`](@ref) function. These can then be extended
programmatically using [`addspecies!`](@ref), [`addparam!`](@ref), and
[`addreaction!`](@ref).

It is important to note for [`@reaction_network`](@ref) that species which are
used *within the macro* as part of a rate expression, but not as a substrate or
product of some reaction, may lead to undefined behavior, i.e., avoid
```julia
rn = @reaction_network begin
    k*X, Y --> W
end k
```
as here `X` is never defined as either a species or parameter.

The [`ReactionSystem`](@ref) generated by the [`@reaction_network`](@ref) macro
is a `ModelingToolkit.AbstractSystem` that symbolically represents a system of
chemical reactions. In some cases it can be convenient to bypass the macro and
directly generate a collection of [`Reaction`](@ref)s and a corresponding
[`ReactionSystem`](@ref) encapsulating them. Below we illustrate with a simple
SIR example how a system can be directly constructed, and demonstrate how to then
generate from the [`ReactionSystem`](@ref) and solve corresponding chemical
reaction ODE models, chemical Langevin equation SDE models, and stochastic
chemical kinetics jump process models. 

```julia
using Catalyst, OrdinaryDiffEq, StochasticDiffEq, DiffEqJump
@parameters β γ t
@variables S(t) I(t) R(t)

rxs = [Reaction(β, [S,I], [I], [1,1], [2])
       Reaction(γ, [I], [R])]
@named rs  = ReactionSystem(rxs, t, [S,I,R], [β,γ])

u₀map    = [S => 999.0, I => 1.0, R => 0.0]
parammap = [β => 1/10000, γ => 0.01]
tspan    = (0.0, 250.0)

# solve as ODEs
odesys = convert(ODESystem, rs)
oprob = ODEProblem(odesys, u₀map, tspan, parammap)
sol = solve(oprob, Tsit5())

# solve as SDEs
sdesys = convert(SDESystem, rs)
sprob = SDEProblem(sdesys, u₀map, tspan, parammap)
sol = solve(sprob, EM(), dt=.01)

# solve as jump process
jumpsys = convert(JumpSystem, rs)
u₀map    = [S => 999, I => 1, R => 0]
dprob = DiscreteProblem(jumpsys, u₀map, tspan, parammap)
jprob = JumpProblem(jumpsys, dprob, Direct())
sol = solve(jprob, SSAStepper())
```


```@docs
@reaction_network
make_empty_network
Reaction
ReactionSystem
```

## Basic properties
```@docs
species
speciesmap
params
paramsmap
reactions
numspecies
numparams
numreactions
```

## Reaction Properties
```@docs
ismassaction
dependents
dependants
substoichmat
prodstoichmat
netstoichmat
reactionrates
```

## Composition and Accessor Functions for `ReactionSystem`s

- `ModelingToolkit.get_eqs(sys)` or `equations(sys)`: The reactions that define the system.
- `ModelingToolkit.get_states(sys)` or `states(sys)`: The set of chemical species in the system.
- `ModelingToolkit.get_ps(sys)` or `parameters(sys)`: The parameters of the system.
- `ModelingToolkit.get_iv(sys)`: The independent variable of the reaction
  system, usually time.

## Functions to extend a Network
```@docs
@add_reactions
addspecies!
addparam!
addreaction!
merge!(network1::ReactionSystem, network2::ReactionSystem)
merge(network1::ReactionSystem, network2::ReactionSystem)
```

## Rate Law Expressions
As the underlying [`ReactionSystem`](@ref) is comprised of `ModelingToolkit`
expressions, one can directly access the generated rate laws, and using
`ModelingToolkit` tooling generate functions or Julia `Expr`s from them.
```@docs
oderatelaw
jumpratelaw
```

## Network Comparison Functions
```@docs
==(rn1::ReactionSystem, rn2::ReactionSystem)
==(rn1::Reaction, rn2::Reaction)
```

## Network Analysis and Representations
```@docs
conservationlaws
conservedquantities
ReactionComplexElement
ReactionComplex
reactioncomplexes
complexstoichmat
complexoutgoingmat
```

## Transformations
```@docs
Base.convert
ModelingToolkit.structural_simplify
```

## Displaying Networks
[Latexify](https://github.com/korsbo/Latexify.jl) can be used to convert
networks to LaTeX mhchem equations by
```julia
using Latexify
latexify(rn)
```

If [Graphviz](https://graphviz.org/) is installed and commandline accessible, it
can be used to create and save network diagrams using [`Graph`](@ref) and
[`savegraph`](@ref).
```@docs
Graph
savegraph
```