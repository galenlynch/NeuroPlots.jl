using GLPlotting, OpenEphysLoader, OEUtilities, PyPlot, GLUtilities, GLTimeseries
using Base.Test

@testset "GLPlotting"  begin
    @testset "util" begin
        const C = [0, 1]
        const B = fill(C, (2,))
        @test plot_spacing(C) == 0.6
        @test plot_spacing(C, 1.2) == 0.6
        @test plot_spacing(C, 0) == 0
        @test plot_spacing(B) == 1.2

        @test plot_offsets(2, 1) == 0:1
        @test plot_offsets(2, 1, 1) == 1:2
        @test plot_offsets(B) == 0:1.2:1.2
    end

    @testset "indices" begin
        path = "/home/glynch/Documents/Data/Neural/7108/Singing_2017-07-30_14-15-02/113_CH24.continuous"
        ior = open(path, "r")
        const A = SampleArray(ior)
        dts = DynamicTs(A)
        (xs, ys) = downsamp_req(dts, 0, 1, 10)
        downsamp_req(dts, 0.0, 1.0, 10.0)
        GLPlotting.to_patch_plot_coords(xs, ys)
        cb = GLPlotting.make_cb(dts)
        cb = GLPlotting.make_cb(A)
        cb(0, 1, 10)
        (fig, ax) = subplots()
        downsamp_patch(ax, A)
        ax[:set_xlim]([0, n_points_duration(length(A), A.contfile.header.samplerate)])
        ax[:set_ylim]([extrema(A)...])
        plt[:show]()
    end
end
