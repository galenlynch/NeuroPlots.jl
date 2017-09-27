__precompile__()
module GLPlotting

using
    PyPlot,
    PyCall,
    Munging,
    OpenEphysLoader,
    GLUtilities

const prd = PyNULL()

function __init__()
    copy!(prd, pyimport("py_resizabledisplay"))
end

export
    # Functions
    downsamp_oe

include("downsampplot.jl")

end # module
