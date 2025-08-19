function rotate_point(p::NTuple{3, Float64}, x::NTuple{3, Float64}, ax::NTuple{3, Float64}, angle::Float64)::NTuple{3, Float64}
    # Translate p so that x becomes the origin
    v = (p[1] - x[1], p[2] - x[2], p[3] - x[3])
    
    # Normalize the rotation axis
    norm_ax = sqrt(ax[1]^2 + ax[2]^2 + ax[3]^2)
    u = (ax[1] / norm_ax, ax[2] / norm_ax, ax[3] / norm_ax)
    
    # Precompute cosine and sine of the angle
    c = cos(angle)
    s = sin(angle)
    
    # Compute the cross product u x v
    cross_uv = (u[2]*v[3] - u[3]*v[2],
                u[3]*v[1] - u[1]*v[3],
                u[1]*v[2] - u[2]*v[1])
    
    # Compute the dot product u · v
    dot_uv = u[1]*v[1] + u[2]*v[2] + u[3]*v[3]
    
    # Apply Rodrigues' rotation formula:
    # v_rot = v * cos(angle) + (u x v) * sin(angle) + u*(u · v)*(1 - cos(angle))
    v_rot = (v[1]*c + cross_uv[1]*s + u[1]*dot_uv*(1 - c),
             v[2]*c + cross_uv[2]*s + u[2]*dot_uv*(1 - c),
             v[3]*c + cross_uv[3]*s + u[3]*dot_uv*(1 - c))
    
    # Translate back to the original coordinate system
    return (v_rot[1] + x[1], v_rot[2] + x[2], v_rot[3] + x[3])
end
