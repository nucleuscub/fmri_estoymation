function [ctr, fig] = prepare_container(parent, name)
%PREPARE_CONTAINER Where a plot function should draw.
%   [ctr, fig] = estfmri.prepare_container(parent, name)
%   With an empty parent, creates a new figure called name and returns it
%   as both ctr and fig. Otherwise clears parent (a figure, uipanel or
%   uitab, e.g. inside estfmri.app) and returns it as ctr, with fig set to
%   its enclosing figure.
if isempty(parent)
    fig = figure('Name', name, 'Color', 'w');
    ctr = fig;
else
    delete(parent.Children);
    ctr = parent;
    fig = ancestor(parent, 'figure');
end
end
