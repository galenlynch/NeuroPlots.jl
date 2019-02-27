const XType = Union{AbstractVector, AbstractRange}
const MplAxType = Union{PyObject, Axis{MPL}}

# Assumes regular x
function glbar(
    ax::MplAxType,
    xs::XType,
    ys;
    align_center::Bool = true,
    relative_width::Real = 1,
    plot_kwargs...
)
    length(xs) >= 2 || error("Lazy coding")
    0 <= relative_width <= 1 || throw(ArgumentError("relative_width is wrong"))
    align = ifelse(align_center, "center", "edge")

    dx = stepsize(xs)
    width = dx * relative_width
    ax.bar(xs, ys; width = width, align = align, plot_kwargs...)
end

glbar(xs::XType, args...; kwargs...) = glbar(gca(), xs, args...; kwargs...)

function histplot(
    ax::MplAxType, bin_edges::XType, ys;
    adjust_lims::Bool = true, color = "0.8", edgecolor = "k"
)
    glbar(
        ax, bin_edges[1:end-1], ys;
        align_center = false, color = color, edgecolor = edgecolor
    )
    adjust_lims && ax.set_xlim(bin_edges[1], bin_edges[end])
end

histplot(bin_edges::XType, args...; kwargs...) =
    histplot(gca(), bin_edges, args...; kwargs...)
