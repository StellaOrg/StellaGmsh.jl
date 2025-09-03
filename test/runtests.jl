import StellaGmsh as G
using Test


# Simple integration tests - just check they don't error
@testset "Basic" begin
    mesh = G.with_gmsh() do
        G.Box((0.0, 0.0, 0.0), (1.0, 1.0, 1.0))
        G.mesh()
    end
    @test true
end


@testset "Union" begin
    mesh = G.with_gmsh() do
        assembly = (
            G.Box((0.0, 0.0, 0.0), (1.0, 1.0, 1.0)) +
            G.Pos(0.3, 0.3, 0.3) * G.Sphere((0.0, 0.0, 0.0), 0.7)
        )
        G.mesh()
    end
    @test true
end


@testset "Mesh" begin
    mesh = G.with_gmsh() do
        assembly = (
            G.Pos(x=1.0, y=1.0, z=1.0) *
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

        G.write("granudrum.stl")
        mesh
    end
    @test true
end


@testset "Move" begin
    G.with_gmsh() do
        geoms = [G.Sphere((0,0,0), 0.5), G.Box((0,0,0),(1,1,1))]
        trans = G.Pos((1,0,0)) * G.Rot(ax=(0,0,1), angle=π/2)
        new_geoms = trans * geoms
    end
    @test true
end


@testset "Difference" begin
    mesh = G.with_gmsh() do
        plate = G.Box((0,0,0), (2,1,0.05))
        holes = [
            G.Pos(0.5,0.5,0.0) * G.Cylinder((0,0,0), (0,0,1), 0.1),
            G.Pos(1.5,0.5,0.0) * G.Cylinder((0,0,0), (0,0,1), 0.1),
        ]
        geom = plate - holes
        G.mesh(size_min=0.05, size_max=0.1)
    end
    @test true
end


@testset "Write" begin
    G.with_gmsh() do
        outer = G.Cylinder((0,0,0), (0,0,1), 0.5)
        inner = G.Cylinder((0,0,0), (0,0,1), 0.45)
        shell = outer - inner
        G.mesh(size_min=0.05, size_max=0.1)
        G.write("drum.stl")
    end
    @test true
end
