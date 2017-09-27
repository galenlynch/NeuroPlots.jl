function downsamp_oe(ax::PyObject, a::OEContArray, plotargs...; plotkwargs...)
    ax[:set_autoscale_on](false)
    plotlines = make_dummy_plots(ax, 2, plotargs...; plotkwargs...)
    dts = DynamicTs(a)
    cb = make_cb(dts)
    rd = prd[:ResizableDisplay](cb, plotlines)
    ax[:callbacks][:connect]("xlim_changed", rd[:update])
    ax[:set_xlim]([0, n_points_duration(length(a), a.contfile.header.samplerate)])
    ax[:set_ylim]([extrema(a)...])
    plt[:show]()
end

function make_cb(dts::DynamicTs)
    return (xb, xe, ptmax) -> to_plot_coords(downsamp_req(dts, xb, xe, ptmax)...)
end

function to_plot_coords(
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

function make_dummy_plots(ax::PyObject, n::Integer, plotargs...; plotkwargs...)
    plotlines = Vector{PyObject}(n)
    for i in eachindex(plotlines)
        plotlines[i] = ax[:plot](0, 0, plotargs...; plotkwargs...)[1]
    end
    return plotlines
end
