function make_dummy_line(ax::PyObject, plotargs...; plotkwargs...)
    return ax[:plot](0, 0, plotargs...; plotkwargs...)[1]
end
function make_dummy_line(ax::PyObject, l::PyObject, args...; kwargs...)
    lineout = make_dummy_line(ax, args...; kwargs...)
    lineout[:update_from](l)
    return lineout
end
function make_dummy_line(n::Integer, ax::PyObject, args...; kwargs...)
    plots = Vector{PyObject}(n)
    if n > 0
        plots[1] = make_dummy_line(ax, args...; kwargs...)
    end
    if n > 1
        for i in 2:n
            plots[i] = make_dummy_line(ax, plots[1], args..., kwargs...)
        end
    end
    return plots
end

function make_fill(
    ax::PyObject,
    lowline::PyObject,
    highline::PyObject,
    match::Bool = true,
    alpha::AbstractFloat = 0.5,
    args...;
    kwargs...
)
    (lowx, lowy) = lowline[:get_data]()
    (highx, highy) = highline[:get_data]()
    @assert lowx == highx "inputs lines must share the same x points"
    p = ax[:fill_between](lowx, lowy, highy, args...; alpha = alpha, kwargs...)
    if match
        p[:set_facecolors](lowline[:get_color]())
    end
    return p
end

function to_patch_plot_coords(
    xs::AbstractVector,
    ys::A
) where {E<:Real, N, S<:NTuple{N, E}, A<:AbstractVector{S}}
    ny = length(ys)
    outs = ntuple((i) -> (xs, Vector{E}(ny)), N)
    for (y_ndx, y_group) in enumerate(ys)
        for series_no in 1:N
            outs[series_no][2][y_ndx] = y_group[series_no]
        end
    end
    return outs
end

"Used for make a callback to view data that does not require the data"
function make_cb(dts::DynamicTs)
    return (xb, xe, ptmax) -> to_patch_plot_coords(downsamp_req(dts, xb, xe, ptmax)...)
end
function make_cb(a::AbstractVector, fs::Real, offset::Real = 0)
    dts = DynamicTs(a, fs, offset)
    return make_cb(dts)
end

function downsamp_patch(
    ax::PyObject,
    cb::Function,
    plotlines::Vector{PyObject},
    plotpatch::PyObject,
)
    ax[:set_autoscale_on](false)
    rd = prp[:ResizeablePatch](cb, push!(plotlines, plotpatch)) # graph objects must be vector
    ax[:callbacks][:connect]("xlim_changed", rd[:update])
end
function downsamp_patch(ax::PyObject, cb::Function)
    plotlines = make_dummy_line(2, ax)
    plotpatch = make_fill(ax, plotlines...)
    return downsamp_patch(ax, cb, plotlines, plotpatch)
end
downsamp_patch(ax::PyObject, args...) = downsamp_patch(ax, make_cb(args...))
