# StellaGmsh.jl

**An ergonomic Julia interface to [Gmsh.jl](https://github.com/JuliaFEM/Gmsh.jl)**

StellaGmsh.jl wraps Gmsh.jl with a small set of composable geometry builders, boolean operations, and a tidy `do`-block workflow that handles Gmsh initialisation and shutdown for you.

## Highlights

* **Clean lifecycle** with `with_gmsh do ... end` that initialises, names, and finalises the Gmsh model automatically.
* **Composable transforms** with `Pos` and `Rot`, using `*` to chain operations right-to-left (matrix style).
* **Boolean CSG ops** using Julia operators: `+` fuse, `-` cut.
* **GeometryBasics integration**: `mesh(...)` returns a `GeometryBasics.Mesh` for easy downstream use.
* **Quick inspect**: `plot()` opens the Gmsh FLTK GUI.
* **Export**: `write("file.stl")` or pass `file=` to `mesh(...)` to save immediately.

> Note: At present the mesh conversion targets **2D triangular elements**. See Limitations.

---

## Installation

```julia
pkg> add StellaGmsh
```

StellaGmsh depends on Gmsh.jl, which will download a suitable Gmsh binary on first use. If you prefer a system Gmsh, follow the Gmsh.jl docs.

---

## Quick start

Create and mesh a simple box:

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
        G.Pos(0.3, 0.3, 0.3) * G.Sphere((0.0, 0.0, 0.0), 0.7)
    )
    G.mesh()
    G.plot()
end
```

Build a rotated-and-shifted cylinder and export:

```julia
import StellaGmsh as G

mesh = G.with_gmsh() do
    assembly = (
        G.Pos(1.0, 1.0, 1.0) *
        G.Rot((0.0, 0.0, 0.0), (0.0, 1.0, 0.0), π/2) *
        G.Cylinder((0.0, 0.0, 0.0), (0.0, 0.0, 1.0), 0.5)
    )

    mesh = G.mesh(
        size_min=0.1,      # minimum element size
        size_max=0.1,      # maximum element size
        size_factor=1.0,   # global scaling factor
        curvature=0.0,     # points per 360° (see Limitations)
        smooth=1,          # vertex smoothing iterations
    )

    G.plot()              # open Gmsh GUI
    G.write("granudrum.stl")
    mesh
end
```

### Meshing and IO

```julia
mesh(; file::Union{Nothing,String}=nothing,
       dim::Integer=2,
       size_min=0.0,
       size_max=1e22,
       size_factor=1.0,
       curvature=0.0,
       smooth=1)
```

Sets common Gmsh mesh options, generates a mesh for the given `dim`, optionally writes `file`, then returns a `GeometryBasics.Mesh` built from the 2D triangular surface elements. See Limitations.

```julia
plot()
```

Opens the Gmsh FLTK GUI so you can inspect the geometry and mesh interactively.

```julia
write(file::AbstractString)
```

Writes the current model to a file via `gmsh.write`.

### Primitives

All primitives are lightweight wrappers that create OCC entities and keep track of a centre for ergonomic transforms.

```julia
Point(x=0.0, y=0.0, z=0.0; mesh_size=0.0, tag=-1)
Line(p1::Point, p2::Point)
Box(origin::Tuple, extents::Tuple; tag=-1)
Sphere(center::Tuple, r; tag=-1, angle1=-π/2, angle2=π/2, angle3=2π)
Cylinder(origin::Tuple, axis::Tuple, r; tag=-1, angle=2π)
Rectangle(origin::Tuple, extents::Tuple; tag=-1, roundedRadius=0.0)
```

### Transforms

```julia
Pos(x=0.0, y=0.0, z=0.0)
Rot(ax::NTuple{3,Float64}, angle::Float64)                      # rotate about geometry centre
Rot(x::NTuple{3,Float64}, ax::NTuple{3,Float64}, angle::Float64) # rotate about point x
```

Chain with `*`. Rightmost is applied first, like matrix multiplication:

```julia
assembly = G.Pos(1,2,3) * G.Rot((0,0,0),(0,0,1),π/4) * G.Box((0,0,0),(1,1,1))
```

Sequences apply to vectors of geometries as well:

```julia
geoms = [G.Sphere((0,0,0), 0.5), G.Box((0,0,0),(1,1,1))]
trans = G.Pos(1,0,0) * G.Rot((0,0,1), π/2)
new_geoms = trans * geoms
```

### Boolean operations

Use standard Julia operators. Operations accept single geometries or vectors and return new wrapper objects centred at their OCC centre of mass.

```julia
fused        = a + b
cut          = a - b

copied = copy(a)
```

---

## Worked examples

### 1. Plate with holes

```julia
import StellaGmsh as G

G.with_gmsh() do
    plate = G.Box((0,0,0), (2,1,0.05))
    holes = [
        G.Pos(0.5,0.5,0.0) * G.Cylinder((0,0,0), (0,0,1), 0.1),
        G.Pos(1.5,0.5,0.0) * G.Cylinder((0,0,0), (0,0,1), 0.1),
    ]
    geom = plate - holes
    G.mesh( size_min=0.05, size_max=0.1)
    G.plot()
end
```

### 2. Simple drum shell

```julia
import StellaGmsh as G

G.with_gmsh() do
    outer = G.Cylinder((0,0,0), (0,0,1), 0.5)
    inner = G.Cylinder((0,0,0), (0,0,1), 0.45)
    shell = outer - inner
    G.mesh(size_min=0.05, size_max=0.1)
    G.write("drum.stl")
end
```


## Acknowledgements

Built on the excellent **Gmsh** and **Gmsh.jl**. This package is not affiliated with the Gmsh team.

---

## Licence

MIT Licence. See `LICENSE` in the repository.
