
import StellaGmsh as SG


mesh = SG.with_gmsh() do
    assembly = (
        SG.Rot((0., 0., 0.), (0., 0., 1.), π/4) * SG.Pos(1., 1., 1.) * SG.Box(0., 0., 0., 1., 1., 1.) +
        SG.Sphere(0., 0., 0., 2.)
    )
    SG.mesh()
end
