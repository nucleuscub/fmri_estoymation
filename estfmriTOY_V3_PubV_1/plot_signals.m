function [ output_args ] = plot_signals_main( handles, opts)

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
handles_gui = plot_signals_gui;
scrsz = get(0,'ScreenSize'); 
set(handles_gui.figure1, 'units', 'normalized', 'position', scrsz)


set(handles_gui, 'position', scrsz);

end

