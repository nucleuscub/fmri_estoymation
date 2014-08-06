function varargout = plot_signals_gui(varargin)
% PLOT_SIGNALS_GUI MATLAB code for plot_signals_gui.fig
%      PLOT_SIGNALS_GUI, by itself, creates a new PLOT_SIGNALS_GUI or raises the existing
%      singleton*.
%
%      H = PLOT_SIGNALS_GUI returns the handle to a new PLOT_SIGNALS_GUI or the handle to
%      the existing singleton*.
%
%      PLOT_SIGNALS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOT_SIGNALS_GUI.M with the given input arguments.
%
%      PLOT_SIGNALS_GUI('Property','Value',...) creates a new PLOT_SIGNALS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plot_signals_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plot_signals_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plot_signals_gui

% Last Modified by GUIDE v2.5 07-Feb-2014 00:28:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plot_signals_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @plot_signals_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before plot_signals_gui is made visible.
function plot_signals_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plot_signals_gui (see VARARGIN)

% Choose default command line output for plot_signals_gui
handles.output = hObject;



% UIWAIT makes plot_signals_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%**************************************************************************
%**************************************************************************
[handles.simresult,handles.opts] = set_guidata(handles);
%**************************************************************************
%**************************************************************************

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = plot_signals_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in listbox_signals.
function listbox_signals_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_signals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_signals contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_signals

%**************************************************************************
%**************************************************************************
 if ~strcmp(get(gcf,'SelectionType'),'open')
    
     
    %Plot on click
    if get(handles.radiobutton_hold_sg,'value') 
        hold on;
    end
        
    sgn_i = get(handles.listbox_signals,'Value');
    set(handles.listbox_signals_est,'Value',sgn_i);
    htemp = plot(handles.simresult.signal_wn(:,sgn_i),'Color',[0.7,0.7,0.7]);
  
    plot_off = 0.0001;
    legend(htemp,['Signals']);
    legend('boxoff');
    xlabel('TR');
    set(gca,'XLim',[1,handles.opts.npts*handles.opts.num_runs]);             % Setting the X limits
    set(gca,'YLim',[min(handles.simresult.signal_wn(:))+ plot_off*min(handles.simresult.signal_wn(:)) max(handles.simresult.signal_wn(:)) + plot_off*max(handles.simresult.signal_wn(:))]); % Setting the Y limits
    grid on;
    
    
    if get(handles.radiobutton_hold_sg,'value') 
        hold off;
    end
 end
%**************************************************************************
%**************************************************************************

% --- Executes during object creation, after setting all properties.
function listbox_signals_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_signals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_clearsgn.
function pushbutton_clearsgn_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clearsgn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cla;
handles.c_cmap = 1;
guidata(hObject,handles);

% --- Executes on selection change in listbox_reg.
function listbox_reg_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_reg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_reg contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_reg


% --- Executes during object creation, after setting all properties.
function listbox_reg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_reg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_plot.
function pushbutton_plot_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%**************************************************************************
%**************************************************************************
% try  
push_button_plot_signals_2(handles);
% catch err
%     msgbox('Check your entries','Error');
%     return;
% end
%**************************************************************************
%**************************************************************************

% --- Executes on selection change in popupmenu_selectplot.
function popupmenu_selectplot_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_selectplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_selectplot contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_selectplot


% --- Executes during object creation, after setting all properties.
function popupmenu_selectplot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_selectplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_clearreg.
function pushbutton_clearreg_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clearreg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton_clearreg.
function set_data(hObject, eventdata, handles)
% hObject    handle to pushbutton_clearreg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plot(rand(10));


% --- Executes on selection change in listbox3.
function listbox3_Callback(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox3


% --- Executes during object creation, after setting all properties.
function listbox3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_plot_ref.
function pushbutton_plot_ref_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_plot_ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%**************************************************************************
%**************************************************************************
% try
if get(handles.radiobutton_hold_sg,'value')
    hold on;
end

push_button_plot_signals_1(hObject,handles);

if get(handles.radiobutton_hold_sg,'value')
    hold off;
end

% catch err
%     msgbox('Check your entries','Error');
%     return;
% end
%**************************************************************************
%**************************************************************************


% --- Executes on selection change in popupmenu_selectplot_ref.
function popupmenu_selectplot_ref_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_selectplot_ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_selectplot_ref contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_selectplot_ref


% --- Executes during object creation, after setting all properties.
function popupmenu_selectplot_ref_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_selectplot_ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_ref.
function listbox_ref_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_ref contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_ref


% --- Executes during object creation, after setting all properties.
function listbox_ref_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox5.
function listbox5_Callback(hObject, eventdata, handles)
% hObject    handle to listbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox5


% --- Executes during object creation, after setting all properties.
function listbox5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_signals_est.
function listbox_signals_est_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_signals_est (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_signals_est contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_signals_est

%**************************************************************************
%**************************************************************************
 if ~strcmp(get(gcf,'SelectionType'),'open')
    
     
    %Plot on click
    if get(handles.radiobutton_hold_sg,'value') 
        hold on;
    end
        
    sgn_est_i = get(handles.listbox_signals_est,'Value');
    set(handles.listbox_signals,'Value',sgn_est_i);
    
    signal_est = sum(handles.simresult.X_est(:,:,sgn_est_i).*repmat(handles.simresult.betas_est(:,sgn_est_i)',size(handles.simresult.X_est(:,:,sgn_est_i),1),1),2); hold on;
    htemp = plot(signal_est,'Color',[0.8,0,0],'LineWidth',2);
  
    plot_off = 0.0001;
    legend(htemp,['Signals']);
    legend('boxoff');
    xlabel('TR');
    set(gca,'XLim',[1,handles.opts.npts*handles.opts.num_runs]);             % Setting the X limits
     
    set(gca,'YLim',[min(handles.simresult.signal_wn(:))+ plot_off*min(handles.simresult.signal_wn(:)) max(handles.simresult.signal_wn(:)) + plot_off*max(handles.simresult.signal_wn(:))]); % Setting the Y limits
    grid on;
    
    
    if get(handles.radiobutton_hold_sg,'value') 
        hold off;
    end
 end
%**************************************************************************
%**************************************************************************

% --- Executes during object creation, after setting all properties.
function listbox_signals_est_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_signals_est (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
