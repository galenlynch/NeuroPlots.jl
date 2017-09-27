using GLPlotting, OpenEphysLoader, PyPlot, Munging
using Base.Test

@testset "GLUtilities"  begin
    @testset "indices" begin
        path = "/home/glynch/Documents/Data/Neural/7108/Singing_2017-07-30_14-15-02/113_CH24.continuous"
        ior = open(path, "r")
        A = SampleArray(ior)
        dts = DynamicTs(A)
        (xs, ys) = downsamp_req(dts, 0, 1, 10)
        downsamp_req(dts, 0.0, 1.0, 10.0)
        GLPlotting.to_plot_coords(xs, ys)
        cb = GLPlotting.make_cb(dts)
        cb(0, 1, 10)
        (fig, ax) = subplots()
        downsamp_oe(ax, A)
    end
end
