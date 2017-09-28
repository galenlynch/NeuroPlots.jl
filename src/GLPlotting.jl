__precompile__()
module GLPlotting

using
    PyPlot,
    PyCall,
    GLTimeseries

const prp = PyNULL()

function __init__()
    copy!(prp, pyimport("py_resizeable_plots.resizeable_artists"))
end

export
    # Functions
    downsamp_patch,
    plot_spacing,
    plot_offsets

include("util.jl")
include("downsampplot.jl")

end # module
