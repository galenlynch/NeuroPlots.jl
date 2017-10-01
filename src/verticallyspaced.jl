function plot_vertical_spacing(
    ax::PyObject,
    As::A,
    fss::AbstractVector,
    offsets::AbstractVector = [],
    listen_ax::Vector{PyObject} = [ax]
) where {E<:AbstractVector, A<:AbstractVector{E}}
    na = length(As)
    if isempty(offsets)
        offsets = zeros(na)
    end
    xbounds = duration.(As, fss, offsets)
    ybounds = extrema.(As)
    extents = map((x) -> x[2] - x[1], ybounds)
    if na > 1
        y_spacing = plot_spacing(extents)
    else
        y_spacing = 0
    end
    y_offsets = plot_offsets(na, y_spacing)
    transforms = Vector{Function}(na)
    for (i, offset) in enumerate(y_offsets)
        transforms[i] = (x) -> x + y_offsets[i]
    end
    mappedybounds = map((x, y) -> map((z) -> z + y, x), ybounds, y_offsets)
    Ys = mappedarray.(transforms, As)
    dts = CachingDynamicTs.(Ys, fss, offsets)
    patchartists = plot_multi_patch(ax, cbs, xbounds, mappedybounds, listen_ax)
    min_x = mapreduce((x) -> x[1], min, Inf, xbounds)
    max_x = mapreduce((x) -> x[2], max, -Inf, xbounds)
    min_y = mappedybounds[1][1] - y_spacing * 0.1
    max_y = mappedybounds[end][2] + y_spacing * 0.1
    multi_xlim = [min_x, max_x]
    multi_ylim = [min_y, max_y]
    return (patchartists, multi_xlim, multi_ylim)
end
# Version for downsampler input
function plot_vertical_spacing(
    ax::PyObject,
    ts::A,
    listen_ax::Vector{PyObject} = [ax]
) where {E<:DynamicDownsampler, A<:AbstractVector{E}}
    nts = length(ts)
    y_transforms = Vector{Function}(nts)
    mappedybounds = Vector{NTuple{2, Float64}}(nts)
    extents = Vector{Float64}(nts)
    xbounds = Vector{NTuple{2, Float64}}(nts)
    for i in 1:nts
        xbounds[i] = duration(ts[i])
        (xs, ys) = downsamp_req(ts[i], xbounds[i][1], xbounds[i][2], 1)
        mappedybounds[i] = ys[1]
        extents[i] = mappedybounds[i][2] - mappedybounds[i][1]
    end
    if nts > 1
        y_spacing = plot_spacing(extents)
    else
        y_spacing = 0
    end
    y_offsets = plot_offsets(nts, y_spacing)
    for (i, offset) in enumerate(y_offsets)
        thisoffset = y_offsets[i]
        y_transforms[i] = make_shifter(thisoffset)
        mappedybounds[i] = (mappedybounds[i][1] + thisoffset, mappedybounds[i][2] + thisoffset)
    end
    mts = MappedDynamicDownsampler.(ts, y_transforms)
    patchartists = plot_multi_patch(ax, mts, xbounds, mappedybounds, listen_ax)
    min_y = mappedybounds[1][1] - y_spacing * 0.1
    max_y = mappedybounds[end][2] + y_spacing * 0.1
    global_y = [min_y, max_y]
    global_x = reduce(reduce_extrema, (Inf, -Inf), xbounds)
    global_x = [global_x...]
    return (patchartists, global_x, global_y)
end

function plot_multi_patch(
    ax::PyObject,
    cbs::Vector{Function},
    xbs::Vector{NTuple{2, I}},
    ybs::Vector{NTuple{2, J}},
    listen_ax::Vector{PyObject} = [ax]
) where {I<:Real, J<:Real}
    na = length(cbs)
    indicies = mod.(0:(na - 1), 10) # for Python consumption, base zero
    colorargs = ["C$n" for n in indicies]
    patchartists = Vector{PyObject}(na)
    for i in 1:na
        patchartists[i] = downsamp_patch(ax, cbs[i], xbs[i], ybs[i], listen_ax, colorargs[i])
    end
    return patchartists
end
function plot_multi_patch(
    ax::PyObject,
    dts::A,
    args...
) where {D <: DynamicDownsampler, A<:AbstractVector{D}}
    cbs = Array{Function}(length(dts))
    for (i, dt) in enumerate(dts)
        cbs[i] = make_cb(dt)
        cbs[i](0, 0, 10)
    end
    plot_multi_patch(ax, cbs, args...)
end
