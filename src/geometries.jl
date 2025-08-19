abstract type AbstractGeometry{Dim} end
get_dim(::AbstractGeometry{Dim}) where {Dim} = Dim
get_tag(geom::AbstractGeometry) = geom.tag
get_center(geom::AbstractGeometry) = geom.center

function update_center(geom::AbstractGeometry, x::Float64, y::Float64, z::Float64)
    updated = @set geom.center = (x, y, z)
    updated
end


struct Geometry{Dim} <: AbstractGeometry{Dim}
    tag::Int
    center::NTuple{3, Float64}
end


struct Point <: AbstractGeometry{0}
    tag::Int
    center::NTuple{3, Float64}
end

function Point(x::Float64=0.0, y::Float64=0.0, z::Float64=0.0, mesh_size::Float64=0.0, tag::Int=-1)
    _tag = gmsh.model.occ.addPoint(x, y, z, mesh_size, tag)
    gmsh.model.occ.synchronize()
    Point(_tag, (x, y, z))
end


struct Line <: AbstractGeometry{1}
    tag::Int
    center::NTuple{3, Float64}
end

function Line(p1::Point, p2::Point, tag::Int=-1)
    _tag = gmsh.model.occ.addLine(p1.tag, p2.tag, tag)
    gmsh.model.occ.synchronize()
    Line(_tag, 0.5 .* (p1.center .+ p2.center))
end


struct Cylinder <: AbstractGeometry{3}
    tag::Int
    center::NTuple{3, Float64}
end

function Cylinder(
    x::Float64,
    y::Float64,
    z::Float64,
    dx::Float64,
    dy::Float64,
    dz::Float64,
    r::Float64,
    tag::Int=-1,
    angle::Float64=2π,
)
    _tag = gmsh.model.occ.addCylinder(x, y, z, dx, dy, dz, r, tag, angle)
    gmsh.model.occ.synchronize()
    Cylinder(_tag, (x, y, z) .+ 0.5 .* (dx, dy, dz))
end

function Cylinder(
    origin::VecOrTup, axis::VecOrTup,
    r::Number,
    tag::Number=-1,
    angle::Number=2π,
)
    x, y, z = origin
    dx, dy, dz = axis
    Cylinder(
        Float64(x), Float64(y), Float64(z),
        Float64(dx), Float64(dy), Float64(dz),
        Float64(r),
        Int(tag),
        Float64(angle),
    )
end


struct Sphere <: AbstractGeometry{3}
    tag::Int
    center::NTuple{3, Float64}
end

function Sphere(
    x::Float64,
    y::Float64,
    z::Float64,
    r::Float64,
    tag::Int=-1,
    angle1::Float64=-π/2,
    angle2::Float64=π/2,
    angle3::Float64=2π,
)
    _tag = gmsh.model.occ.addSphere(x, y, z, r, tag, angle1, angle2, angle3)
    gmsh.model.occ.synchronize()
    Sphere(_tag, (x, y, z))
end

function Sphere(
    center::VecOrTup,
    r::Number,
    tag::Number=-1,
    angle1::Number=-π/2,
    angle2::Number=π/2,
    angle3::Number=2π,
)
    x, y, z = center
    Sphere(
        Float64(x), Float64(y), Float64(z),
        Float64(r),
        Int(tag),
        Float64(angle1),
        Float64(angle2),
        Float64(angle3),
    )
end


struct Box <: AbstractGeometry{3}
    tag::Int
    center::NTuple{3, Float64}
end

function Box(
    x::Float64,
    y::Float64,
    z::Float64,
    dx::Float64,
    dy::Float64,
    dz::Float64,
    tag::Int=-1,
)
    _tag = gmsh.model.occ.addBox(x, y, z, dx, dy, dz, tag)
    gmsh.model.occ.synchronize()
    Box(_tag, (x, y, z) .+ 0.5 .* (dx, dy, dz))
end

function Box(
    origin::VecOrTup, extents::VecOrTup,
    tag::Number=-1,
)
    x, y, z = origin
    dx, dy, dz = extents
    Box(
        Float64(x), Float64(y), Float64(z),
        Float64(dx), Float64(dy), Float64(dz),
        Int(tag),
    )
end

struct Rectangle <: AbstractGeometry{3}
    tag::Int
    center::NTuple{3, Float64}
end

function Rectangle(
    x::Float64,
    y::Float64,
    z::Float64,
    dx::Float64,
    dy::Float64,
    tag::Int=-1,
    roundedRadius::Float64=0.0,
)
    _tag = gmsh.model.occ.addRectangle(x, y, z, dx, dy, tag, roundedRadius)
    gmsh.model.occ.synchronize()
    Rectangle(_tag, ((x, y) .+ 0.5 .* (dx, dy)..., z))
end

function Rectangle(
    origin::VecOrTup, extents::VecOrTup,
    tag::Number=-1, roundedRadius::Number=0.0,
)
    x, y, z = origin
    dx, dy = extents
    Rectangle(
        Float64(x), Float64(y), Float64(z),
        Float64(dx), Float64(dy),
        Int(tag), Float64(roundedRadius),
    )
end


function Base.copy(geom::AbstractGeometry)
    new_dimtags = gmsh.model.occ.copy(((get_dim(geom), get_tag(geom)),))
    typeof(geom)(new_dimtags[1][2], get_center(geom))
end
