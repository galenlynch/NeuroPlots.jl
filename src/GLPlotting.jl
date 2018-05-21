__precompile__()
module GLPlotting

using
    PyPlot,
    PyCall,
    GLTimeseries,
    GLUtilities

export
    # Types
    Axis,
    Artist,
    MPL,
    PQTG,
    ParallelSpeed,
    ParallelSlow,
    ParallelFast,
    FuncCall,

    # Functions
    downsamp_patch,
    plot_spacing,
    plot_offsets,
    plot_vertical_spacing,
    resizeable_spectrogram

include("plotlibs.jl")
include("util.jl")
include("resizeableartists.jl")
include("artdirector.jl")
include("redraw.jl")
include("downsampplot.jl")
include("verticallyspaced.jl")
include("spectrogram.jl")

end # module
