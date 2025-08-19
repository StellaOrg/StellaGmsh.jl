module StellaGmsh


# Public exports
export with_gmsh
export Pos, Rot


# Internal imports
using Accessors
using ArgCheck: @argcheck
import GeometryBasics
import Gmsh: gmsh


# Internal definitions
const VecOrTup{T} = Union{Vector{T}, Tuple{Vararg{T}}}



"""
Run GMSH commands to create a geometry and mesh it.

# Examples
Simple box mesh:
```julia
import StellaGmsh as G

mesh = G.with_gmsh() do
    G.Box((0.0, 0.0, 0.0), (1.0, 1.0, 1.0))
    G.mesh()
end
```

Fuse a box and a moved sphere:
```julia
import StellaGmsh as G

mesh = G.with_gmsh() do
    assembly = (
        G.Box((0.0, 0.0, 0.0), (1.0, 1.0, 1.0)) +
        G.Pos(1.0, 1.0, 1.0) * G.Sphere((0.0, 0.0, 0.0), 0.5)
    )
    G.mesh()
end
```

Geometry positioning and rotation can be done with `Pos` and `Rot`; like in
function composition, `C * B * A * obj` applies A, then B, then C:
```julia
import StellaGmsh as G

mesh = G.with_gmsh() do
    # Associativity is as for matrices, rightmost is applied first; first
    # rotate cylinder then move it to make a GranuDrum
    assembly = (
        G.Pos(1.0, 1.0, 1.0) *
        G.Rot((0.0, 0.0, 0.0), (0.0, 1.0, 0.0), π/2) *
        G.Cylinder((0.0, 0.0, 0.0), (0.0, 0.0, 1.0), 0.5)
    )

    # Mesh settings
    mesh = G.mesh(
        size_min=0.1,       # Minimum mesh element size
        size_max=0.1,       # Maximum mesh element size
        size_factor=1.0,    # Global mesh scaling factor
        curvature=0.0,      # Number of points in 360 degrees
        smooth=1,           # Number of vertex smoothing iterations
    )

    # Open GMSH GUI
    G.plot()

    # Write mesh
    G.write("granudrum.stl")

    # Return mesh from `do` block
    mesh
end
```

Geometry-geometry operations include `+` for fusing geometries, `-` for subtracting (cutting),
`&` for intersecting.
"""
function with_gmsh(
    f;
    argv=Vector{String}(),
    read_config_files=true,
    run=false,
    model_name="StellaGmshModel",
)

    gmsh.initialize(argv, read_config_files, run)
    gmsh.model.add(model_name)

    try
        ret = f()
        return ret
    finally
        gmsh.finalize()
    end
end


function plot()
    gmsh.fltk.run()
end


function mesh(;
    file::Union{Nothing, String}=nothing,
    dim=2,
    size_min=0.0,
    size_max=1e22,
    size_factor=1.0,
    curvature=0.0,
    smooth=1,
)
    gmsh.option.setNumber("Mesh.MeshSizeMin", size_min)
    gmsh.option.setNumber("Mesh.MeshSizeMax", size_max)
    gmsh.option.setNumber("Mesh.MeshSizeFactor", size_factor)
    gmsh.option.setNumber("Mesh.MeshSizeFromCurvature", curvature)
    gmsh.option.setNumber("Mesh.Smoothing", smooth)

    gmsh.model.mesh.generate(dim)

    if !isnothing(file)
        gmsh.write(file)
    end

    # Get all points in mesh
    indices, points, _ = gmsh.model.mesh.getNodes()

    # Sort points by indices
    isorted = sortperm(indices)
    @argcheck indices[isorted] == 1:length(indices)

    points = Matrix{Float64}(reshape(points, 3, length(indices)))
    points = points[:, isorted]

    # Get mesh elements (faces)
    element_types, element_tags, node_tags = gmsh.model.mesh.getElements(dim)
    @argcheck length(element_types) == 1 "Only one element type (triangular) is supported at the moment; post an issue"
    @argcheck element_types[1] == 2 "Only triangular elements are supported at the moment; post an issue"

    # Turn into connectivity matrix
    connectivity = Matrix{Int}(reshape(node_tags[1], 3, length(element_tags[1])))

    # Turn into standard GeometryBasics.Mesh
    vertices = [GeometryBasics.Point(x, y, z) for (x, y, z) in eachcol(points)]
    faces = [GeometryBasics.TriangleFace(i, j, k) for (i, j, k) in eachcol(connectivity)]

    return GeometryBasics.Mesh(vertices, faces)
end


function write(file::String)
    gmsh.write(file)
end




# Internal sub-includes
include("utilities.jl")
include("geometries.jl")
include("locations.jl")
include("operations.jl")


end # module StellaGmsh
