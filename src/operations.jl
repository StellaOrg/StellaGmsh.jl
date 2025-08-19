# Fusing
Base.:+(a::AbstractGeometry, b::AbstractGeometry) = [a] + [b]
Base.:+(a::Vector{<:AbstractGeometry}, b::AbstractGeometry) = a + [b]
Base.:+(a::AbstractGeometry, b::Vector{<:AbstractGeometry}) = [a] + b

function Base.:+(a::Vector{<:AbstractGeometry}, b::Vector{<:AbstractGeometry})
    a_dimtags = Vector{Tuple{Int, Int}}(undef, length(a))
    for i in eachindex(a)
        a_dimtags[i] = (get_dim(a[i]), get_tag(a[i]))
    end

    b_dimtags = Vector{Tuple{Int, Int}}(undef, length(b))
    for i in eachindex(b)
        b_dimtags[i] = (get_dim(b[i]), get_tag(b[i]))
    end

    out_dimtags, _ = gmsh.model.occ.fuse(a_dimtags, b_dimtags)
    gmsh.model.occ.synchronize()

    # Re-wrap the dimtags in Geometry objects
    out = [
        Geometry{dim}(tag, gmsh.model.occ.getCenterOfMass(dim, tag))
        for (dim, tag) in out_dimtags
    ]
    return out
end


# Intersecting
Base.:&(a::AbstractGeometry, b::AbstractGeometry) = [a] & [b]
Base.:&(a::Vector{<:AbstractGeometry}, b::AbstractGeometry) = a & [b]
Base.:&(a::AbstractGeometry, b::Vector{<:AbstractGeometry}) = [a] & b

function Base.:&(a::Vector{<:AbstractGeometry}, b::Vector{<:AbstractGeometry})
    a_dimtags = Vector{Tuple{Int, Int}}(undef, length(a))
    for i in eachindex(a)
        a_dimtags[i] = (get_dim(a[i]), get_tag(a[i]))
    end

    b_dimtags = Vector{Tuple{Int, Int}}(undef, length(b))
    for i in eachindex(b)
        b_dimtags[i] = (get_dim(b[i]), get_tag(b[i]))
    end

    out_dimtags, _ = gmsh.model.occ.intersect(a_dimtags, b_dimtags)
    gmsh.model.occ.synchronize()

    # Re-wrap the dimtags in Geometry objects
    out = [
        Geometry{dim}(tag, gmsh.model.occ.getCenterOfMass(dim, tag))
        for (dim, tag) in out_dimtags
    ]
    return out
end


# Cutting
Base.:-(a::AbstractGeometry, b::AbstractGeometry) = [a] - [b]
Base.:-(a::Vector{<:AbstractGeometry}, b::AbstractGeometry) = a - [b]
Base.:-(a::AbstractGeometry, b::Vector{<:AbstractGeometry}) = [a] - b

function Base.:-(a::Vector{<:AbstractGeometry}, b::Vector{<:AbstractGeometry})
    a_dimtags = Vector{Tuple{Int, Int}}(undef, length(a))
    for i in eachindex(a)
        a_dimtags[i] = (get_dim(a[i]), get_tag(a[i]))
    end

    b_dimtags = Vector{Tuple{Int, Int}}(undef, length(b))
    for i in eachindex(b)
        b_dimtags[i] = (get_dim(b[i]), get_tag(b[i]))
    end

    out_dimtags, _ = gmsh.model.occ.cut(a_dimtags, b_dimtags)
    gmsh.model.occ.synchronize()

    # Re-wrap the dimtags in Geometry objects
    out = [
        Geometry{dim}(tag, gmsh.model.occ.getCenterOfMass(dim, tag))
        for (dim, tag) in out_dimtags
    ]
    return out
end
