function connect_callbacks(
    ax::PyObject,
    ra::Union{ResizeableArtist, ArtDirector},
    listen_ax::Vector{PyObject} = [ax];
    toplevel::Bool = true
)
    ax[:set_autoscale_on](false)
    toplevel && set_ax_home(ra)
    update_fnc = (x) -> axis_lim_changed(ra, x)
    for lax in listen_ax
        conn_fnc = lax[:callbacks][:connect]::PyCall.PyObject
        conn_fnc("xlim_changed", update_fnc)
        conn_fnc("ylim_changed", update_fnc) # TODO: Is this necessary?
    end
    update_fnc(ax)
    return ra
end

