function connect_callbacks(
    ax::Axis{P},
    ra::Union{<:ResizeableArtist{<:Any,P}, <:ArtDirector{<:Any,P,<:Any,<:Any}},
    listen_ax::AbstractVector{<:Axis{P}} = [ax];
    toplevel::Bool = true
) where {P<:MPL}
    ax.ax[:set_autoscale_on](false)
    toplevel && set_ax_home(ra)
    update_fnc = (x) -> axis_lim_changed(ra, Axis{P}(x))
    for lax in listen_ax
        conn_fnc = lax.ax[:callbacks][:connect]::PyCall.PyObject
        conn_fnc("xlim_changed", update_fnc)
        conn_fnc("ylim_changed", update_fnc) # TODO: Is this necessary?
    end
    axis_lim_changed(ra, ax)
    return ra
end

