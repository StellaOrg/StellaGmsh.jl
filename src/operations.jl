function _collect_dimtags(a::AbstractVector{<:AbstractGeometry})
    dimtags = Vector{Tuple{Int, Int}}(undef, length(a))
    for i in eachindex(a)
        dimtags[i] = (get_dim(a[i]), get_tag(a[i]))
    end
    return dimtags
end

function _collect_dimtags(a::Tuple{Vararg{AbstractGeometry}})
    dimtags = Vector{Tuple{Int, Int}}(undef, length(a))
    i = Ref(1)
    unrolled_foreach(a) do geom
        dimtags[i[]] = (get_dim(geom), get_tag(geom))
        i[] += 1
    end
    return dimtags
end

function _rewrap_geometries(dimtags::VecOrTup{Tuple{I, I}}) where {I <: Integer}
    out = Vector{AbstractGeometry}(undef, length(dimtags))
    for i in eachindex(dimtags)
        (dim, tag) = dimtags[i]
        out[i] = Geometry{dim}(tag, gmsh.model.occ.getCenterOfMass(dim, tag))
    end
    return out
end


# Fusing
Base.:+(a::AbstractGeometry, b::AbstractGeometry) = (a,) + (b,)
Base.:+(a::VecOrTup{<:AbstractGeometry}, b::AbstractGeometry) = a + (b,)
Base.:+(a::AbstractGeometry, b::VecOrTup{<:AbstractGeometry}) = (a,) + b

function Base.:+(a::VecOrTup{<:AbstractGeometry}, b::VecOrTup{<:AbstractGeometry})
    a_dimtags = _collect_dimtags(a)
    b_dimtags = _collect_dimtags(b)

    out_dimtags, _ = gmsh.model.occ.fuse(a_dimtags, b_dimtags)
    gmsh.model.occ.synchronize()

    return _rewrap_geometries(out_dimtags)
end


# Intersecting
Base.:&(a::AbstractGeometry, b::AbstractGeometry) = (a,) & (b,)
Base.:&(a::VecOrTup{<:AbstractGeometry}, b::AbstractGeometry) = a & (b,)
Base.:&(a::AbstractGeometry, b::VecOrTup{<:AbstractGeometry}) = (a,) & b

function Base.:&(a::VecOrTup{<:AbstractGeometry}, b::VecOrTup{<:AbstractGeometry})
    a_dimtags = _collect_dimtags(a)
    b_dimtags = _collect_dimtags(b)

    out_dimtags, _ = gmsh.model.occ.intersect(a_dimtags, b_dimtags)
    gmsh.model.occ.synchronize()

    return _rewrap_geometries(out_dimtags)
end


# Cutting
Base.:-(a::AbstractGeometry, b::AbstractGeometry) = (a,) - (b,)
Base.:-(a::VecOrTup{<:AbstractGeometry}, b::AbstractGeometry) = a - (b,)
Base.:-(a::AbstractGeometry, b::VecOrTup{<:AbstractGeometry}) = (a,) - b

function Base.:-(a::VecOrTup{<:AbstractGeometry}, b::VecOrTup{<:AbstractGeometry})
    a_dimtags = _collect_dimtags(a)
    b_dimtags = _collect_dimtags(b)

    out_dimtags, _ = gmsh.model.occ.cut(a_dimtags, b_dimtags)
    gmsh.model.occ.synchronize()

    return _rewrap_geometries(out_dimtags)
end
