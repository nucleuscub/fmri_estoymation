function varargout = timing_load_info_1(varargin)
% TIMING_LOAD_INFO_1 MATLAB code for timing_load_info_1.fig
%      TIMING_LOAD_INFO_1, by itself, creates a new TIMING_LOAD_INFO_1 or raises the existing
%      singleton*.
%
%      H = TIMING_LOAD_INFO_1 returns the handle to a new TIMING_LOAD_INFO_1 or the handle to
%      the existing singleton*.
%
%      TIMING_LOAD_INFO_1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TIMING_LOAD_INFO_1.M with the given input arguments.
%
%      TIMING_LOAD_INFO_1('Property','Value',...) creates a new TIMING_LOAD_INFO_1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before timing_load_info_1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to timing_load_info_1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help timing_load_info_1

% Last Modified by GUIDE v2.5 05-Aug-2013 22:38:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @timing_load_info_1_OpeningFcn, ...
                   'gui_OutputFcn',  @timing_load_info_1_OutputFcn, ...
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


% --- Executes just before timing_load_info_1 is made visible.
function timing_load_info_1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to timing_load_info_1 (see VARARGIN)

% Choose default command line output for timing_load_info_1
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes timing_load_info_1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = timing_load_info_1_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global opts_2

opts_2.Nfiles = str2num(get(handles.edit_Nfiles, 'String'));
opts_2.Nruns  = str2num(get(handles.edit_Nruns, 'String'));

 switch get(get(handles.uipanel_fileformat,'SelectedObject'),'Tag')
     case 'radiobutton_t'
         opts_2.tfile_format = 1;
     case 'radiobutton_ta'
         opts_2.tfile_format = 2;
 end

[opts_2.FileName,opts_2.opts.PathName,FilterIndex] = uigetfile('.1D','MultiSelect','on' );

h = timing_load_info_1;
close(h);

function edit_Nfiles_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Nfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Nfiles as text
%        str2double(get(hObject,'String')) returns contents of edit_Nfiles as a double


% --- Executes during object creation, after setting all properties.
function edit_Nfiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Nfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Nruns_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Nruns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Nruns as text
%        str2double(get(hObject,'String')) returns contents of edit_Nruns as a double


% --- Executes during object creation, after setting all properties.
function edit_Nruns_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Nruns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
