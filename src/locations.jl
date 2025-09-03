abstract type Location end


struct LocationSequence{L <: Tuple{Vararg{Location}}}
    locations::L
end


struct Pos <: Location
    x::Float64
    y::Float64
    z::Float64
end

function Pos(x::Number, y::Number=0.0, z::Number=0.0)
    Pos(Float64(x), Float64(y), Float64(z))
end

function Pos(p::VecOrTup{<:Number})
    @argcheck length(p) == 3 "Position must be a 3D point"
    Pos(p[1], p[2], p[3])
end

function Pos(; x::Number=0.0, y::Number=0.0, z::Number=0.0)
    Pos(Float64(x), Float64(y), Float64(z))
end


struct Rot{X <: Union{Nothing, NTuple{3, Float64}}} <: Location
    x::X
    ax::NTuple{3, Float64}
    angle::Float64
end

function Rot(x::Union{Nothing, VecOrTup{<:Number}}, ax::VecOrTup{<:Number}, angle::Number)
    @argcheck length(ax) == 3 "Rotation axis must be a 3D vector"
    if isnothing(x)
        return Rot(
            nothing,
            (Float64(ax[1]), Float64(ax[2]), Float64(ax[3])),
            Float64(angle),
        )
    end

    @argcheck length(x) == 3 "Rotation point must be a 3D point"
    Rot(
        (Float64(x[1]), Float64(x[2]), Float64(x[3])),
        (Float64(ax[1]), Float64(ax[2]), Float64(ax[3])),
        Float64(angle),
    )
end

function Rot(ax::VecOrTup{<:Number}, angle::Number)
    @argcheck length(ax) == 3 "Rotation axis must be a 3D vector"
    Rot(
        nothing,
        (Float64(ax[1]), Float64(ax[2]), Float64(ax[3])),
        Float64(angle),
    )
end

function Rot(;
    x::Union{Nothing, VecOrTup{<:Number}}=nothing,
    ax::VecOrTup{<:Number},
    angle::Number,
)
    Rot(x, ax, angle)
end


# Creating sequences of locations
function Base.:*(a::Location, b::Location)
    LocationSequence((a, b))
end


function Base.:*(a::LocationSequence, b::Location)
    LocationSequence((a.locations..., b))
end


function Base.:*(a::Location, b::LocationSequence)
    LocationSequence((a, b.locations...))
end


function Base.:*(a::LocationSequence, b::LocationSequence)
    LocationSequence((a.locations..., b.locations...))
end


# Do movements
function Base.:*(a::Rot{Nothing}, b::AbstractGeometry)
    dim = get_dim(b)
    tag = get_tag(b)
    center = get_center(b)

    gmsh.model.occ.rotate(
        ((dim, tag),),
        center[1], center[2], center[3],
        a.ax[1], a.ax[2], a.ax[3],
        a.angle,
    )
    gmsh.model.occ.synchronize()

    return update_center(b, center...)
end


function Base.:*(a::Rot, b::AbstractGeometry)
    dim = get_dim(b)
    tag = get_tag(b)
    center = get_center(b)

    gmsh.model.occ.rotate(
        ((dim, tag),),
        a.x[1], a.x[2], a.x[3],
        a.ax[1], a.ax[2], a.ax[3],
        a.angle,
    )
    gmsh.model.occ.synchronize()

    # Also rotate center
    new_center = rotate_point(center, a.x, a.ax, a.angle)
    return update_center(b, new_center...)
end


function Base.:*(a::Pos, b::AbstractGeometry)
    dim = get_dim(b)
    tag = get_tag(b)
    center = get_center(b)

    dx = a.x - center[1]
    dy = a.y - center[2]
    dz = a.z - center[3]

    gmsh.model.occ.translate(((dim, tag),), dx, dy, dz)
    gmsh.model.occ.synchronize()

    return update_center(b, a.x, a.y, a.z)
end


function Base.:*(a::Location, b::VecOrTup{<:AbstractGeometry})
    updated = similar(b)
    for i in eachindex(b)
        updated[i] = a * b[i]
    end
    updated
end


function Base.:*(a::LocationSequence, b::VecOrTup{<:AbstractGeometry})
    length(a.locations) > 0 || return b

    op = a.locations[end]
    rest = LocationSequence(Base.front(a.locations))
    new_geom = op * b
    rest * new_geom
end


function Base.:*(a::LocationSequence, b::AbstractGeometry)
    length(a.locations) > 0 || return b

    op = a.locations[end]
    rest = LocationSequence(Base.front(a.locations))
    new_geom = op * b
    rest * new_geom
end
