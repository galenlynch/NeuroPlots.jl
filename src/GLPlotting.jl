__precompile__()
module GLPlotting

using
    PyPlot,
    PyCall,
    GLTimeSeries

const prp = PyNULL()

function __init__()
    copy!(prp, pyimport("py_resizeable_plots.resizeable_artists"))
end

export
    # Functions
    downsamp_patch

include("downsampplot.jl")

end # module
