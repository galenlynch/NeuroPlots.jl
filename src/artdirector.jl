struct ArtDirector{P<:PlotLib, S<:ParallelSpeed}
    artists::Vector{ResizeableArtist{<:AbstractDynamicDownsampler, P}}
    axes::Vector{Axis{P}}
    limx::Vector{NTuple{2, Float64}}
    limy::Vector{NTuple{2, Float64}}
    jobchannel::RemoteChannel{Channel{Tuple{Int, FuncCall}}}
    datachannel::RemoteChannel{Channel{Tuple{Int, Vector{Float64}, Vector{Float64}}}}
    pspeeds::Vector{S}
    function ArtDirector{P,S}(
        artists::Vector{<:ResizeableArtist{<:Any, P}}, pspeeds::Vector{S}
    ) where {P<:PlotLib, S<:ParallelSpeed}
        axes, limx, limy = artist_bounds(artists)
        jobchannel = RemoteChannel(
            ()->Channel{Tuple{Int, FuncCall}}(100)
        )
        datachannel = RemoteChannel(
            ()->Channel{Tuple{Int, Vector{Float64}, Vector{Float64}}}(100)
        )
        for p in workers()
            @async remote_do(do_work, p, jobchannel, datachannel)
        end
        return new(artists, axes, limx, limy, jobchannel, datachannel, pspeeds)
    end
end

function ArtDirector(
    a::AbstractVector{<:ResizeableArtist{<:Any, P}}, s::AbstractVector{S}
) where {P<:PlotLib, S<:ParallelSpeed}
    return ArtDirector{P,S}(a, convert(Vector{S}, s))
end

function ArtDirector(a::AbstractVector{<:ResizeableArtist})
    ArtDirector(a, ParallelSpeed.(a))
end

function artist_bounds(ras::AbstractVector{<:ResizeableArtist})
    combine_axis_info(summarize_artists(ras)...)
end

function summarize_artists(
    artists::AbstractVector{<:ResizeableArtist{<:Any, P}}
) where P
    nartist = length(artists)
    allaxes = Vector{Axis{P}}(nartist)
    allxlim = Vector{NTuple{2, Float64}}(nartist)
    allylim = Vector{NTuple{2, Float64}}(nartist)
    for (i, ra) in enumerate(artists)
        allaxes[i] = ra.baseinfo.ax
        allxlim[i] = ra.baseinfo.datalimx
        allylim[i] = ra.baseinfo.datalimy
    end
    allaxes, allxlim, allylim
end

function combine_axis_info(
    allaxes::AbstractVector{<:Axis},
    allxlim::AbstractVector{<:NTuple{2, <:Number}},
    allylim::AbstractVector{<:NTuple{2, <:Number}}
)
    axes = unique(allaxes)
    nax = length(axes)
    limx = Vector{NTuple{2,Float64}}(nax)
    limy = Vector{NTuple{2, Float64}}(nax)
    matchmask = Vector{Bool}(length(allaxes))
    for (i, ax) in enumerate(axes)
        @. matchmask = allaxes == ax
        limx[i] = extrema_red(allxlim[matchmask])
        limy[i] = extrema_red(allylim[matchmask])
    end
    axes, limx, limy
end

function append_artists!(
    ad::ArtDirector, ras::AbstractVector{<:ResizeableArtist}
)
    new_axes, new_xlims, new_ylims = summarize_artists(ras)

    used_mask = fill(false, size(new_axes))
    match_mask = similar(used_mask)
    for (i, old_ax) in enumerate(ad.axes)
        @. match_mask = new_axes == old_ax
        @. used_mask = used_mask | match_mask
        if any(match_mask)
            new_bounding_xlim = extrema_red(new_xlims[match_mask])
            new_bounding_ylim = extrema_red(new_ylims[match_mask])
            ad.limx[i] = reduce_extrema(ad.limx[i], new_bounding_xlim)
            ad.limy[i] = reduce_extrema(ad.limy[i], new_bounding_ylim)
        end
    end

    # Do it in place for no real reason
    @. used_mask = ! used_mask
    novel_mask = used_mask # confusing, I know

    novel_ax, novel_xlim, novel_ylim = combine_axis_info(
        new_axes[novel_mask], new_xlims[novel_mask], new_ylims[novel_mask]
    )
    append!(ad.artists, ras)
    append!(ad.axes, novel_ax)
    append!(ad.limx, novel_xlim)
    append!(ad.limy, novel_ylim)
    nothing
end

function set_ax_home(a::ArtDirector)
    for (i, ax) in enumerate(a.axes)
        setlims(ax, a.limx[i]..., a.limy[i]...)
    end
end

function do_work(jobs, results)
    while true
        (id, fnc_call) = take!(jobs)
        id < 0 && break
        xs, ys = call(fnc_call)
        put!(results, (id, xs, ys))
    end
end

function axis_lim_changed(
    ra::Union{ResizeableArtist, ArtDirector},
    notifying_ax::Axis
)
    (xstart, xend) = axis_xlim(notifying_ax)
    pixwidth = ax_pix_width(notifying_ax)
    maybe_redraw(ra, xstart, xend, pixwidth)
end

function axis_lim_changed(ra::ResizeableArtist{<:Any,PQTG})
    axis_lim_changed(ra, ra.baseinfo.ax)
end

function axis_lim_changed(ra::ArtDirector{PQTG,<:Any})
    axis_lim_changes(ra, ra.axes[1])
end

function maybe_redraw(
    ad::ArtDirector,
    xstart,
    xend,
    px_width::T
) where T<:Integer
    artists_to_redraw = similar(ad.artists, 0)
    limwidth = xend - xstart
    limcenter = (xend + xstart) / 2
    px = Vector{T}()
    for ra in ad.artists
        if artist_should_redraw(ra, xstart, xend, limwidth, limcenter)
            ra.baseinfo.lastlimwidth = limwidth
            ra.baseinfo.lastlimcenter = limcenter
            push!(px, compress_px(ra, xstart, xend, px_width))
            push!(artists_to_redraw, ra)
        end
    end
    update_plotdata(
        artists_to_redraw,
        xstart,
        xend,
        px,
        ad.jobchannel,
        ad.datachannel,
        ad.pspeeds
    )
    if ! isempty(artists_to_redraw)
        for ax in ad.axes
            update_ax(ax)
        end
    end
end
