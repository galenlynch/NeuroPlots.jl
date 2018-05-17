struct ArtDirector{R<:ResizeableArtist}
    artists::Vector{R}
    axes::Vector{PyObject}
    limx::Vector{NTuple{2, Float64}}
    limy::Vector{NTuple{2, Float64}}
    function ArtDirector{R}(artists::Vector{R}) where {R<:ResizeableArtist}
        nartist = length(artists)
        allaxes = Vector{PyObject}(nartist)
        allxlim = Vector{NTuple{2, Float64}}(nartist)
        allylim = Vector{NTuple{2, Float64}}(nartist)
        for (i, ra) in enumerate(artists)
            allaxes[i] = ra.baseinfo.ax
            allxlim[i] = ra.baseinfo.datalimx
            allylim[i] = ra.baseinfo.datalimy
        end
        axes = unique(allaxes)
        nax = length(axes)
        limx = Vector{NTuple{2,Float64}}(nax)
        limy = Vector{NTuple{2, Float64}}(nax)
        for (i, ax) in enumerate(axes)
            matchmask = allaxes .== ax
            limx[i] = extrema_red(allxlim[matchmask])
            limy[i] = extrema_red(allylim[matchmask])
        end
        return new(artists, axes, limx, limy)
    end
end
function ArtDirector(a::AbstractVector{R}) where {R<:ResizeableArtist}
    return ArtDirector{R}(convert(Vector{R}, a))
end

function set_ax_home(a::ArtDirector)
    for (i, ax) in enumerate(a.axes)
        ax[:set_xlim]([a.xlim[i]...])
        ax[:set_ylim]([a.ylim[i]...])
    end
end

function axis_lim_changed(
    ra::Union{ResizeableArtist, ArtDirector},
    notifying_ax::PyObject
)
    (xstart, xend) = axis_limits(notifying_ax)
    pixwidth = ax_pix_width(notifying_ax)
    maybe_redraw(ra, xstart, xend, pixwidth)
end

function maybe_redraw(
    ad::ArtDirector,
    xstart,
    xend,
    px_width
)
    artists_to_redraw = similar(ad.artists, 0)
    limwidth = xend - xstart
    limcenter = (xend + xstart) / 2
    for ra in ad.artists
        ra.baseinfo.lastlimwidth = limwidth
        ra.baseinfo.lastlimcenter = limcenter
        if artist_should_redraw(ra, xstart, xend, limwidth, limcenter)
            push!(artists_to_redraw, ra)
        end
    end
    update_plotdata(artists_to_redraw, xstart, xend, px_width)
    if ! isempty(artists_to_redraw)
        for ax in ad.axes
            ax[:figure][:canvas][:draw_idle]()
        end
    end
end
