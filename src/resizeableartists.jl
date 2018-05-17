"""
Base type for resizeable artists, must implement a setdata method and have a
baseinfo field"
"""
abstract type ResizeableArtist end

mutable struct RABaseInfo
    ax::PyObject
    artists::Vector{PyObject}
    datalimx::NTuple{2, Float64}
    datalimy::NTuple{2, Float64}
    threshdiff::Float64
    lastlimwidth::Float64
    lastlimcenter::Float64

    function RABaseInfo(
    ax::PyObject,
    artists::Vector{PyObject},
    datalimx::NTuple{2, Float64},
    datalimy::NTuple{2, Float64},
    threshdiff::Float64 = 0.0,
    lastlimwidth::Float64 = 0.0,
    lastlimcenter::Float64 = 0.0
)
        return new(
            ax,
            artists,
            datalimx,
            datalimy,
            threshdiff,
            lastlimwidth,
            lastlimcenter
        )
    end
end

function RABaseInfo(
    ax::PyObject,
    a::AbstractVector{PyObject},
    limx::NTuple{2, Real},
    limy::NTuple{2, Real}
)
    return RABaseInfo(
        ax,
        a,
        convert(NTuple{2, Float64}, limx),
        convert(NTuple{2, Float64}, limy)
    )
end

function RABaseInfo(ax::PyObject, artist::PyObject, args...)
    return RABaseInfo(ax, [artist], args...)
end

xbounds(a::RABaseInfo) = a.datalimx
ybounds(a::RABaseInfo) = a.datalimy

xbounds(a::ResizeableArtist) = xbounds(a.baseinfo)
ybounds(a::ResizeableArtist) = ybounds(a.baseinfo)

function set_ax_home(a::ResizeableArtist)
    a.baseinfo.ax[:set_ylim]([a.baseinfo.datalimy...])
    a.baseinfo.ax[:set_xlim]([a.baseinfo.datalimx...])
end

ratiodiff(a, b) = abs(a - b) / (b + eps(b))

function artist_is_visible(ra::ResizeableArtist, xstart, xend, ystart, yend)
    xoverlap = check_overlap(
        xstart, xend, ra.baseinfo.datalimx[1], ra.baseinfo.datalimx[2]
    )
    yoverlap = check_overlap(
        ystart, yend, ra.baseinfo.datalimy[1], ra.baseinfo.datalimy[2]
    )
    return xoverlap && yoverlap
end

function artist_should_redraw(
    ra::ResizeableArtist,
    xstart,
    xend,
    limwidth = xend - xstart,
    limcenter = (xend + xstart) / 2
)
    (ystart, yend) = axis_limits(ra.baseinfo.ax, :intervaly)
    if artist_is_visible(ra, xstart, xend, ystart, yend)
        width_rd = ratiodiff(limwidth, ra.baseinfo.lastlimwidth)
        center_rd = ratiodiff(limcenter, ra.baseinfo.lastlimcenter)
        redraw = max(width_rd, center_rd) > ra.baseinfo.threshdiff
    else
        redraw = false
    end
    return redraw
end

function maybe_redraw(ra::ResizeableArtist, xstart, xend, px_width)
    limwidth = xend - xstart
    limcenter = (xend + xstart) / 2
    if artist_should_redraw(ra, xstart, xend, limwidth, limcenter)
        ra.baseinfo.lastlimwidth = limwidth
        ra.baseinfo.lastlimcenter = limcenter
        update_plotdata(ra, xstart, xend, px_width)
        ra.baseinfo.ax[:figure][:canvas][:draw_idle]()
    end
end

function update_plotdata(ra::ResizeableArtist, xstart, xend, pixwidth)
    datafcn = plotdata_fnc(ra, xstart, xend, pixwidth)
    data = datafcn()
    update_artists(ra, data...)
end

function update_plotdata(ras::Vector{<:ResizeableArtist}, xstart, xend, pixwidth)
    datafncs = plotdata_fnc.(ras, xstart, xend, pixwidth)
    all_data = pmap((f) -> f(), datafncs)
    for (i, data) in enumerate(all_data)
        udpate_artists(ras[i], data...)
    end
end
