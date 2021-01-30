classdef bdGUI < matlab.apps.AppBase
    %bdGUI - The Brain Dynamics Toolbox Graphical User Interface (GUI).
    %
    %The bdGUI application is the graphical user interface for the Brain
    %Dynamics Toolbox. It loads and runs the model defined by the given
    %system structure (sys). That structure contains a handle to the
    %model's ODE function (sys.odefun). It also defines the names and
    %initial values of the system parameters and state variables.
    %
    %   gui = bdGUI(sys);
    %
    %The system structure may be passed to bdGUI as an input parameter or
    %loaded from a mat file. If bdGUI is invoked with no parameters then it
    %prompts the user to load a mat file which is assumed to contain a sys.
    %
    %   gui = bdGUI();
    %
    %A previously computed solution (sol) can be loaded in tandem with the
    %model's system structure. If no solution is provided then bdGUI
    %automatically computes one at start-up.
    %
    %   gui = bdGUI(sys,'sol',sol);
    %
    %The GUI can be run in headless mode by specifying Visible='off'
    %
    %   gui = bdGUI(sys,'Visible','off');
    %
    %In all cases, bdGUI returns a handle (gui) to the bdGUI class. That
    %handle can be used to control the graphical user interface from the
    %matlab workspace.
    %
    %EXAMPLE
    %   >> cd bdtoolbox
    %   >> addpath models
    %   >> sys = LinearODE();
    %   >> gui = bdGUI(sys);
    %
    % gui = 
    %   bdGUI with properties:
    %     version: '2020a'
    %         par: [1�1 struct]
    %         lag: [1�1 struct]
    %        var0: [1�1 struct]
    %        vars: [1�1 struct]
    %       tspan: [0 20]
    %       tstep: 1
    %        tval: 0
    %           t: [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
    %         sys: [1�1 struct]
    %         sol: [1�1 struct]
    %      panels: [1�1 struct]
    %        halt: 0
    %      evolve: 0
    %     perturb: 0
    %      sysobj: [1�1 bdSystem]
    %         fig: [1�1 Figure]
    %     
    % Where
    %   gui.version is the version string of the toolbox (read-only)
    %   gui.par is a struct containing the model parameters (read/write)
    %   gui.lag is a struct containing the DDE lag parameters (read/write)
    %   gui.var0 is a struct containing the initial conditions (read/write)
    %   gui.vars is a struct containing the computed time-series (read-only)
    %   gui.tspan is the time span of the simulation (read/write)
    %   gui.tstep is the time step (dt) of the interpolated solution (read/write)
    %   gui.tval is the current value of the time slider (read/write)
    %   gui.t contains the time steps for the computed solution (read-only)
    %   gui.sys is a copy of the model's system structure (read-only)
    %   gui.sol is the output of the solver (read-only)
    %   gui.panels contains the outputs of the display panels (read-only)
    %   gui.halt is the state of the HALT button (read/write)
    %   gui.evolve is the state of the EVOLVE button (read/write)
    %   gui.perturb is the state of the PERTURB button (read/write)
    %   gui.sysobj is a handle to the internal bdSystem object (read/write)
    %   gui.fig is a handle to the application figure (read/write)
    %
    %SOFTWARE MANUAL
    %   Handbook for the Brain Dynamics Toolbox: Version 2020a.
    %
    %ONLINE COURSES (bdtoolbox.org)
    %   Toolbox Basics - Getting started with the Brain Dynamics Toolbox
    %   Modeller's Workshop - Building custom models with the Brain Dynamics Toolbox
    %
    %AUTHORS
    %   Stewart Heitmann (2016a,2017a,2017b,2017c,2018a,2018b,2019a,2020a)

    % Copyright (C) 2016-2020 QIMR Berghofer Medical Reserach Institute
    % All rights reserved.
    %
    % Redistribution and use in source and binary forms, with or without
    % modification, are permitted provided that the following conditions
    % are met:
    %
    % 1. Redistributions of source code must retain the above copyright
    %    notice, this list of conditions and the following disclaimer.
    % 
    % 2. Redistributions in binary form must reproduce the above copyright
    %    notice, this list of conditions and the following disclaimer in
    %    the documentation and/or other materials provided with the
    %    distribution.
    %
    % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    % "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    % LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    % FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    % COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    % INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    % BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    % LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    % CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    % LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    % ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    % POSSIBILITY OF SUCH DAMAGE.
    
    properties (Dependent)
        version         % toolbox version string (read only)
        par             % system parameters (read/write)
        lag             % time lag parameters (read/write)
        var0            % initial conditions (read/write)
        vars            % solution variables (read only)
        tspan           % time span (read/write)
        tstep           % time step (read/write)
        tval            % time slider value (read/write) 
        t               % solution time domain (read only)
        sys             % system definition structure (read only)
        sol             % current solver output (read only)
        panels          % display panel handles (read/write)
        halt            % state of the HALT button (read/write)
        evolve          % state of the EVOLVE button (read/write)
        perturb         % state of the PERTURB button (read/write)
    end
    
    properties
        sysobj              bdSystem
        fig                 matlab.ui.Figure
    end
       
    properties (Access=private)
        SystemMenu          matlab.ui.container.Menu
        AboutMenu           matlab.ui.container.Menu
        LoadMenu            matlab.ui.container.Menu
        SaveMenu            matlab.ui.container.Menu
        ExportMenu          matlab.ui.container.Menu
        CloneMenu           matlab.ui.container.Menu
        QuitMenu            matlab.ui.container.Menu
        EditMenu            matlab.ui.container.Menu
        UndoMenu            matlab.ui.container.Menu
        RedoMenu            matlab.ui.container.Menu
        NewPanelMenu        matlab.ui.container.Menu
        GridLayout          matlab.ui.container.GridLayout
        TabGroup            matlab.ui.container.TabGroup
        ControlPanel        matlab.ui.container.Panel
        SolverPanel         matlab.ui.container.Panel
        ControlSolver       bdControlSolver
        TimePanel           matlab.ui.container.Panel
        PanelMgr            bdPanelMgr
        UndoStack           bdUndoStack
        rlistener           event.listener
        plistener           event.listener
    end
    
    methods
        function app = bdGUI(varargin)
            % Constructor
            %
            % gui = bdGUI();
            % gui = bdGUI(sys);
            % gui = bdGUI(sys,'sol',sol);
            % gui = bdGUI(sys,'Visible','off');

            % bdGUI require matlab R2019b or newer
            if verLessThan('matlab','9.7.0')
                throw(MException('bdGUI:Version','bdGUI requires MATLAB R2019b or newer'));
            end
            
            % add the bdtoolkit/solvers directory to the path
            addpath(fullfile(fileparts(mfilename('fullpath')),'solvers'));

            % add the bdtoolkit/panels directory to the path
            addpath(fullfile(fileparts(mfilename('fullpath')),'panels'));

            % define a syntax for the input parser
            syntax = inputParser;
            syntax.CaseSensitive = false;
            syntax.FunctionName = 'bdGUI(sys,''sol'',sol,''Visible'',''off'')';
            syntax.KeepUnmatched = false;
            syntax.PartialMatching = false;
            syntax.StructExpand = false;
            addOptional(syntax,'sys',[], @(sys) ~isempty(bdGUI.syscheck(sys)));
            addParameter(syntax,'sol',[]);
            addParameter(syntax,'Visible','on');

            % call the input parser
            parse(syntax,varargin{:});
            if isempty(syntax.Results.sys)
                % Calling syntax: bdGUI()
                % Load the sys (and sol) struct from mat file 
                [sys,sol] = bdGUI.loadsys();
                if isempty(sys)
                    % user cancelled the load operation
                    app = bdGUI.empty();
                    return
                end
            else
                % Calling syntax: bdGUI(sys) or bdGUI(sys,'sol,sol)
                % Take the sys struct from the input parameter
                sys = syntax.Results.sys;                
                if isempty(syntax.Results.sol)
                    % Calling syntax: bdGUI(sys)
                    sol = [];
                else
                    sol = syntax.Results.sol;
                end
            end
            
            if isempty(sol)
                % Construct sysobj from sys
                app.sysobj = bdSystem(sys);

                % Run the solver for the first time (FIX ME)
                app.sysobj.recompute = true;
            else
                % Construct sysobj from sys and import the given sol.
                app.sysobj = bdSystem(sys,'sol',sol);
                app.sysobj.recompute = false;
            end
            
            % initiate the undo stack
            app.UndoStack = bdUndoStack();
            app.UndoStack.Push(sys);
                        
            % Construct a new figure
            app.fig = uifigure('Position',[randi(200),randi(200),900,500], 'Visible','off');
            app.fig.Name = 'Brain Dynamics Toolbox';
            app.fig.CloseRequestFcn = @(src,evnt) app.QuitMenuCallback();

            % Add a unique Tag to the figure. Child figure/dialogs get assigned
            % this same tag to help track them. See the CloseFigure function.
            app.fig.Tag = sprintf('bdGUI-%d',randi(1e10));
                        
            % Create Grid Layout
            app.GridLayout = uigridlayout(app.fig);
            app.GridLayout.ColumnWidth = {'2x','1x'};
            app.GridLayout.RowHeight = {'1x',25,55};
            app.GridLayout.ColumnSpacing = 10;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [10 10 5 10];                       

            % Create System Menu
            app.SystemMenu = uimenu(app.fig);
            app.SystemMenu.Text = 'System ';
            
            % Create AboutMenu
            app.AboutMenu = uimenu(app.SystemMenu);
            app.AboutMenu.Text = 'About';
            app.AboutMenu.Tooltip = ['Brain Dynamics Toolbox, Version ' app.sysobj.version];
            app.AboutMenu.MenuSelectedFcn = @(~,~) AboutMenuCallback(app);

            % Create LoadMenu
            app.LoadMenu = uimenu(app.SystemMenu);
            app.LoadMenu.Text = 'Load';
            app.LoadMenu.Tooltip = 'Load a new system from a mat file';
            app.LoadMenu.MenuSelectedFcn = @(~,~) LoadMenuCallback(app);
            
            % Create SaveMenu
            app.SaveMenu = uimenu(app.SystemMenu);
            app.SaveMenu.Text = 'Save';
            app.SaveMenu.Tooltip = 'Save the system to a mat file';
            app.SaveMenu.MenuSelectedFcn = @(~,~) SaveMenuCallback(app);
            
            % Create ExportMenu
            app.ExportMenu = uimenu(app.SystemMenu);
            app.ExportMenu.Text = 'Export';
            app.ExportMenu.Tooltip = 'Export data to the workspace';
            app.ExportMenu.MenuSelectedFcn = @(~,~) SystemExportCallback(app);
            
            % Create CloneMenu
            app.CloneMenu = uimenu(app.SystemMenu);
            app.CloneMenu.Text = 'Clone';
            app.CloneMenu.Tooltip = 'Clone the GUI';
            app.CloneMenu.MenuSelectedFcn = @(~,~) CloneMenuCallback(app);

            % Create QuitMenu
            app.QuitMenu = uimenu(app.SystemMenu);
            app.QuitMenu.Text = 'Quit';
            app.QuitMenu.Tooltip = 'Quit the GUI';
            app.QuitMenu.MenuSelectedFcn = @(~,~) QuitMenuCallback(app);

            % Create EditMenu
            app.EditMenu = uimenu(app.fig);
            app.EditMenu.Text = 'Edit ';
            
            % Create UndoMenu
            app.UndoMenu = uimenu(app.EditMenu);
            app.UndoMenu.Text = 'Undo';
            app.UndoMenu.Tooltip = 'Undo the last change';
            app.UndoMenu.Enable = app.UndoStack.UndoStatus();
            app.UndoMenu.MenuSelectedFcn = @(~,~) UndoMenuCallback(app);

            % Create RedoMenu
            app.RedoMenu = uimenu(app.EditMenu);
            app.RedoMenu.Text = 'Redo';
            app.RedoMenu.Tooltip = 'Reverse the last Undo';
            app.RedoMenu.Enable = app.UndoStack.RedoStatus();
            app.RedoMenu.MenuSelectedFcn = @(~,~) RedoMenuCallback(app);

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = [1 2];
            app.TabGroup.Layout.Column = 1;
            app.TabGroup.SelectionChangedFcn = @(tabgrp,~) bdPanelBase.FocusMenu(tabgrp);
                                 
            % Solver Panel container
            app.SolverPanel = uipanel(app.GridLayout);
            app.SolverPanel.Title = [];
            app.SolverPanel.Layout.Row = 3;
            app.SolverPanel.Layout.Column = 1;
            app.SolverPanel.BorderType = 'none';
            app.ControlSolver = bdControlSolver(app.sysobj,app.SolverPanel);
            
            % Time Panel container
            app.TimePanel = uipanel(app.GridLayout);
            app.TimePanel.Title = [];
            app.TimePanel.Layout.Row = [2 3];
            app.TimePanel.Layout.Column = 2;
            app.TimePanel.BorderType = 'none';
            bdControlTime(app.sysobj,app.TimePanel);
                        
            % Control Panel container
            app.ControlPanel = uipanel(app.GridLayout);
            app.ControlPanel.Title = [];
            app.ControlPanel.Layout.Row = 1;
            app.ControlPanel.Layout.Column = 2;
            app.ControlPanel.BorderType = 'none';
            bdControlPanel(app.sysobj,app.ControlPanel);
            
            % Create the panel manager         
            app.PanelMgr = bdPanelMgr(app.TabGroup,app.sysobj);

            % Create New-Panel Menu
            app.NewPanelMenu = uimenu(app.fig);
            app.NewPanelMenu.Text = 'New Panel ';  
                        
            % clean the incoming panels structure
            sys.panels = bdPanelMgr.panelscheck(sys.panels);

            % Populate the New-Panel menu items
            app.PanelMgr.PanelMenus(app.NewPanelMenu,sys.panels);

            % make the figure visible (before loading the display panels)
            drawnow;
            app.fig.Visible = syntax.Results.Visible;
            
            % Load the display panels 
            app.PanelMgr.ImportPanels(sys.panels);
            
            %ensure the first Tab is selected
%             if numel(app.TabGroup.Children) > 1
%                 app.TabGroup.SelectedTab = app.TabGroup.Children(1);
%                 bdPanelBase.FocusMenu(app.TabGroup);
%             end
            
            % call the timer function manually to force the first compute
            app.sysobj.TimerFcn();

            % listen to sysobj for PUSH events
            app.plistener = listener(app.sysobj,'push',@(~,~) app.Pusher());

            % listen to sysobj for REDRAW events
            app.rlistener = listener(app.sysobj,'redraw',@(~,evnt) app.Redraw(evnt));

            % start the timer proper
            app.sysobj.TimerStart();            
        end
        
        % Get version property
        function version = get.version(app)
            version = app.sysobj.version;
        end
        
        % Get par property
        function par = get.par(app)
            par = struct();
            for parindx = 1:numel(app.sysobj.pardef)
                name = app.sysobj.pardef(parindx).name;
                par.(name) = app.sysobj.pardef(parindx).value;
            end
        end 
        
        % Set par property
        function set.par(app,value)
            % Assert the incoming value is a struct
            if ~isstruct(value)
                warning('bdGUI: Illegal par value. Input must be a struct');
                return
            end
            
            % Get the names of the incoming fields
            vfields = fieldnames(value);

            % Verify all of the incoming fields are valid before we do anything else.
            % For each field name in the incoming value struct ... 
            for vindx = 1:numel(vfields)
                % Get the name, value and size of the field in the incoming struct
                vfield = vfields{vindx};
                vvalue = value.(vfield);
                vsize = size(vvalue);
                
                % Get the index and size of the matching entry in sysobj.pardef
                [parindx,parsize] = app.sysobj.GetParIndex(vfield);
                if isempty(parindx)
                    warning(['bdGUI: Unknown parameter [',vfield,'].']);
                    return
                end
                
                % Assert the incoming value is the correct shape and size.
                if ~isequal(parsize,vsize)
                    warning(['bdGUI: Size mismatch [',vfield,'].']);
                    return
                end
            end
            
            % For each field name in the incoming value struct ... 
            for vindx = 1:numel(vfields)
                % Get the name and value of the field
                vfield = vfields{vindx};
                vvalue = value.(vfield);

                % copy the value to sysobj.pardef
                parindx = app.sysobj.GetParIndex(vfield);
                app.sysobj.pardef(parindx).value = vvalue;
            end
            
            % notify everything to redraw
            app.sysobj.NotifyRedraw([]);

            % Execute the sysobj TimerFcn manually (and wait for it to complete)
            app.sysobj.TimerFcn();
        end

        % Get lag property
        function lag = get.lag(app)
            lag = struct();
            
            % only DDEs have time lags
            switch app.sysobj.solvertype
                case 'ddesolver'
                    for lagindx = 1:numel(app.sysobj.lagdef)
                        name = app.sysobj.lagdef(lagindx).name;
                        lag.(name) = app.sysobj.lagdef(lagindx).value;
                    end
            end
        end 
        
        % Set lag property
        function set.lag(app,value)
            % Assert the incoming value is a struct
            if ~isstruct(value)
                warning('bdGUI: Illegal lag value. Input must be a struct.');
                return
            end
            
            % only DDEs have time lags
            switch app.sysobj.solvertype
                case 'ddesolver'
                    % OK to proceed
                otherwise
                    warning('bdGUI: Illegal assignment. Time lags only apply to DDEs.');
                    return               
            end
            
            % Get the names of the incoming fields
            vfields = fieldnames(value);

            % Verify all of the incoming fields are valid before we do anything else.
            % For each field name in the incoming value struct ... 
            for vindx = 1:numel(vfields)
                % Get the name, value and size of the field in the incoming struct
                vfield = vfields{vindx};
                vvalue = value.(vfield);
                vsize = size(vvalue);
                
                % Get the index and size of the matching entry in sysobj.lagdef
                [lagindx,lagsize] = app.sysobj.GetLagIndex(vfield);
                if isempty(lagindx)
                    warning(['bdGUI: Unknown lag parameter [',vfield,'].']);
                    return
                end
                
                % Assert the incoming value is the correct shape and size.
                if ~isequal(lagsize,vsize)
                    warning(['bdGUI: Size mismatch [',vfield,'].']);
                    return
                end
            end
            
            % For each field name in the incoming value struct ... 
            for vindx = 1:numel(vfields)
                % Get the name and value of the field
                vfield = vfields{vindx};
                vvalue = value.(vfield);

                % copy the value to sysobj.lagdef
                lagindx = app.sysobj.GetLagIndex(vfield);
                app.sysobj.lagdef(lagindx).value = vvalue;
            end
            
            % notify everything to redraw
            app.sysobj.NotifyRedraw([]);

            % Execute the sysobj TimerFcn manually (and wait for it to complete)
            app.sysobj.TimerFcn();
        end
        
        % Get var0 (initial conditions) property
        function var0 = get.var0(app)
            var0 = struct();
            for varindx = 1:numel(app.sysobj.vardef)
                name = app.sysobj.vardef(varindx).name;
                var0.(name) = app.sysobj.vardef(varindx).value;
            end
        end 

         % Set var0 (initial conditions) property
        function set.var0(app,value)
            % Assert the incoming value is a struct
            if ~isstruct(value)
                warning('bdGUI: Illegal var0 value. Input must be a struct');
                return
            end
            
            % Get the names of the incoming fields
            vfields = fieldnames(value);
            
            % Verify all of the incoming fields are valid before we do anything else.
            % For each field name in the incoming value struct ... 
            for vindx = 1:numel(vfields)
                % Get the name, value and size of the field in the incoming struct
                vfield = vfields{vindx};
                vvalue = value.(vfield);
                vsize = size(vvalue);
                
                % Get the index and size of the matching entry in sysobj.vardef
                [varindx,varsize] = app.sysobj.GetVarIndex(vfield);
                if isempty(varindx)
                    warning(['bdGUI: Unknown variable [',vfield,'].']);
                    return
                end
                
                % Assert the incoming value is the correct shape and size.
                if ~isequal(varsize,vsize)
                    warning(['bdGUI: Variable size mismatch [',vfield,'].']);
                    return
                end
            end
            
            % For each field name in the incoming value struct ... 
            for vindx = 1:numel(vfields)
                % Get the name and value of the field
                vfield = vfields{vindx};
                vvalue = value.(vfield);

                % copy the value to sysobj.vardef
                varindx = app.sysobj.GetVarIndex(vfield);
                app.sysobj.vardef(varindx).value = vvalue;
            end
            
            % notify everything to redraw
            app.sysobj.NotifyRedraw([]);
                        
            % Execute the sysobj TimerFcn manually (and wait for it to complete)
            app.sysobj.TimerFcn();
        end
               
        % Get vars (solution variables) property
        function vars = get.vars(app)
            vars = app.sysobj.vars;
        end
        
        % Get tspan property
        function tspan = get.tspan(app)
            tspan = app.sysobj.tspan;
        end

        % Get tstep property
        function tstep = get.tstep(app)
            tstep = app.sysobj.tstep;
        end
        
        % Get tval (time slider value) property
        function tval = get.tval(app)
            tval = app.sysobj.tval;
        end
        
%         % Set tval (time slider value) property FIX ME
%         function set.tval(gui,tval)
%             % error handling
%             if ~isnumeric(tval) || numel(tval)~=1
%                 throwAsCaller(MException('bdGUI:tval','gui.tval must be numeric'));
%             end
%             
%             % update the system structure
%             gui.sysobj.tval = tval;
%                   
%             % notify everything to redraw
%             gui.sysobj.NotifyRedraw([]);
%             return
%   
%             
%             % adjust tspan if necessary
%             Tspan = gui.control.sys.tspan;
%             if tval<Tspan(1) || tval>Tspan(2)
%                 Tspan(1) = min(Tspan(1),tval);
%                 Tspan(2) = max(Tspan(2),tval);
%                 gui.control.sys.tspan = Tspan;
%             
%                 % Notify the control panel to refresh its widgets
%                 notify(gui.control,'refresh');
%             
%                 % recompute and wait until complete
%                 gui.control.RecomputeWait();
%             else
%                 % Notify the control panel to refresh its widgets
%                 notify(gui.control,'refresh');
% 
%                 % update the indicies of the non-tranient time steps in sol.x
%                 gui.control.tindx = (gui.control.sol.x >= gui.control.sys.tval);
% 
%                 % Notify all panels to redraw
%                 notify(gui.control,'redraw');                
%                 drawnow;
%             end
%         end

        % Get t (solution time domain) property
        function t = get.t(app)
            t = app.sysobj.tdomain;
        end
        
        % Get sys property
        function sys = get.sys(app)
            sys = app.sysobj.ExportSystem();
            sys.panels = app.PanelMgr.ExportPanels();
        end
        
        % Get sol property
        function sol = get.sol(app)
            sol = app.sysobj.sol;
                        
            % remove unwanted function handles from sol.exdata.options
            if isfield(sol,'extdata')
                if isfield(sol.extdata,'options')
                    % remove the sol.extdata.options.OutputFcn handle
                    if isfield(sol.extdata.options,'OutputFcn')
                        sol.extdata.options = rmfield(sol.extdata.options,'OutputFcn');
                    end
                end
            end

        end
        
        % Get panels property
        function out = get.panels(app)
            app.PanelMgr.CleanPanelHands();
            out = app.PanelMgr.panelhands;
        end
        
        % Get halt property
        function halt = get.halt(app)
            halt = app.sysobj.halt;
        end
        
        % Set halt property
        function set.halt(app,value)
            if value
                app.sysobj.halt = true;
            else
                app.sysobj.halt = false;
                app.sysobj.recompute = true;
            end
            % notify everything to redraw
            app.sysobj.NotifyRedraw([]);
        end
        
        % Get evolve property
        function evolve = get.evolve(app)
            evolve = app.sysobj.evolve;
        end
        
        % Set evolve property
        function set.evolve(app,value)
            if value
                app.sysobj.evolve = true;
                app.sysobj.recompute = true;
            else
                app.sysobj.evolve = false;
            end
            % notify everything to redraw
            app.sysobj.NotifyRedraw([]);
        end
        
        % Get perturb property
        function perturb = get.perturb(app)
            perturb = app.sysobj.perturb;
        end
        
        % Set perturb property
        function set.perturb(app,value)
            if value
                app.sysobj.perturb = true;
                app.sysobj.recompute = true;
            else
                app.sysobj.perturb = false;
            end
            % notify everything to redraw
            app.sysobj.NotifyRedraw([]);
        end
        
        % Destructor
        function delete(app)
            %disp('bdGUI.delete');   
            app.sysobj.TimerStop();
            delete(app.plistener);
            delete(app.rlistener);
            delete(app.fig);
            delete(app);
        end
       
    end
    
    % Callbacks that handle component events
    methods (Access = private)

        % Listener for REDRAW events
        function Redraw(app,sysevent)
            %disp('bdGUI.Redraw');
            % if sysobj.halt has changed then start/stop the solver timer
            if sysevent.halt
                if app.sysobj.halt
                    % stop the solver timer
                    app.sysobj.TimerStop();
                else
                    % start the solver timer
                    app.sysobj.TimerStart();
                end
            end
                                    
            % If any of the following events occured then push a new entry onto the undostack
            if any([sysevent.pardef.value]) || ...
               any([sysevent.pardef.lim]) || ...
               any([sysevent.lagdef.value]) || ...
               any([sysevent.lagdef.lim]) || ...
               any([sysevent.vardef.value]) || ...
               any([sysevent.vardef.lim]) || ...
               sysevent.tspan || ...
               sysevent.tstep || ...
               sysevent.tval || ...
               sysevent.noisehold || ...
               sysevent.evolve || ...
               sysevent.perturb || ...
               sysevent.backward || ...
               sysevent.solveritem || ...
               sysevent.odeoption || ...
               sysevent.ddeoption || ...
               sysevent.sdeoption 
                % Push the changes onto the undo stack
                notify(app.sysobj,'push');
            end
        end
        
        % Callback for System-About menu
        function AboutMenuCallback(app)          
            % Create the 'About' figure with the same Tag as the GUI figure
            dlg = uifigure('Position',[300 300 600 320], 'Name','About', 'Resize','off','Color','w','Tag',app.fig.Tag);
            
            % Create GridLayout
            gridlayout = uigridlayout(dlg);
            gridlayout.ColumnWidth = {'1x','1x'};
            gridlayout.RowHeight = {70,100,'1x',50};
            gridlayout.RowSpacing = 0;

            % Brain Dynamics Toolbox: Version XXX
            label = uilabel(gridlayout);
            label.Text = {'Brain Dynamics Toolbox',['Version ' app.sysobj.version]};
            label.FontName = 'Times';
            label.FontSize = 24;
            label.FontWeight = 'bold';
            label.HorizontalAlignment = 'center';
            label.Layout.Row = 1;
            label.Layout.Column = [1 2];
            
            % Stewart Heitmann
            label = uilabel(gridlayout);
            label.Text = {'Stewart Heitmann','Victor Chang Cardiac Research Institute','Darlinghurst NSW 2131, Australia','heitmann@bdtoolbox.org'};
            label.FontName = 'Times';
            label.FontSize = 16;
            label.HorizontalAlignment = 'center';
            label.Layout.Row = 2;
            label.Layout.Column = 1;
            
            % Michael Breakspear
            label = uilabel(gridlayout);
            label.Text = {'Michael Breakspear','The University of Newcastle','Callaghan NSW 2308, Australia','michael.breakspear@newcastle.edu.au'};
            label.FontName = 'Times';
            label.FontSize = 16;
            label.HorizontalAlignment = 'center';
            label.Layout.Row = 2;
            label.Layout.Column = 2;
            
            % Blurb
            label = uilabel(gridlayout);
            label.Text = {'The Brain Dynamics Toolbox is open software for simulating dynamical systems in',' neuroscience and related fields. It solves initial-value problems in custom systems', 'of Ordinary Differential Equations (ODEs), Delay Differential Equations (DDEs),', 'Stochastic Differential Equations (SDEs) and Partial Differential Equations (PDEs).'};
            label.FontName = 'Times';
            label.FontSize = 16;
            label.HorizontalAlignment = 'center';
            label.Layout.Row = 3;
            label.Layout.Column = [1 2];
            
            % website
            label = uilabel(gridlayout);
            label.Text = {'Visit bdtoolbox.org for links to the official handbook and online training courses.'};
            label.FontName = 'Times';
            label.FontSize = 16;
            label.HorizontalAlignment = 'center';
            label.Layout.Row = 4;
            label.Layout.Column = [1 2];
        end
        
         
        % Callback for System-Load menu
        function LoadMenuCallback(app)
            %disp('bdGUI.LoadMenuCallback'); 
            % Load the sys (and sol) struct from mat file 
            [sys,sol] = bdGUI.loadsys();
            if isempty(sys)
                % user cancelled the load operation
                return
            end
            bdGUI(sys,'sol',sol);
        end
        
        % Callback for System-Save menu
        function SaveMenuCallback(app)
            % widget geometry
            panelw = 180;
            panelh = 390;
            yoffset = 30;
            boxh = 20;
            rowh = 22;            

            % construct dialog box
            dlg = figure('Units','pixels', ...
                'Position',[randi(300,1,1) randi(300,1,1), panelw, panelh], ...
                'MenuBar','none', ...
                'Name','Save to File', ...
                'NumberTitle','off', ...
                'ToolBar', 'none', ...
                'Resize','off');

            % SYSTEM title
            uicontrol('Style','text', ...
                'String','System', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', dlg, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % sys check box
            uicontrol('Style','checkbox', ...
                'String','sys', ...
                'Value', 1, ...
                'Tag', 'bdSaveSys', ...
                'TooltipString', 'sys is the system structure', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % sol check box
            uicontrol('Style','checkbox', ...
                'String','sol', ...
                'Tag', 'bdSaveSol', ...
                'TooltipString', 'sol is the solution structure', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + 1.5*rowh;

            % PARAMETERS title
            uicontrol('Style','text', ...
                'String','Parameters', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', dlg, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % par check box
            uicontrol('Style','checkbox', ...
                'String','par', ...
                'Tag', 'bdSavePar', ...
                'TooltipString', 'par contains the system parameters', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);      
            
            % next row
            yoffset = yoffset + rowh;

            % If our system has lag parameters then enable that checkbox
            if isempty(app.sysobj.lagdef)
                lagEnable = 'off';
            else
                lagEnable = 'on';
            end

            % lag check box
            uicontrol('Style','checkbox', ...
                'String','lag', ...
                'Tag', 'bdSaveLag', ...
                'TooltipString', 'lag contains the time-lag parameters', ...
                'Enable', lagEnable, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);
            
            % next row
            yoffset = yoffset + 1.5*rowh;           

            % STATE VARIABLES title
            uicontrol('Style','text', ...
                'String','State Variables', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', dlg, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % var0 check box
            uicontrol('Style','checkbox', ...
                'String','var0', ...
                'Tag', 'bdSaveVar0', ...
                'TooltipString', 'var0 contains the initial conditions', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);
            
            % next row
            yoffset = yoffset + rowh;  
            
            % var1 check box
            uicontrol('Style','checkbox', ...
                'String','vars', ...
                'Tag', 'bdSaveVars', ...
                'TooltipString', 'vars contains the computed trajectories', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);
           
            % next row
            yoffset = yoffset + 1.5*rowh;

            % TIME DOMAIN title
            uicontrol('Style','text', ...
                'String','Time Domain', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', dlg, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;                                    

            % time check box
            uicontrol('Style','checkbox', ...
                'String','tdomain', ...
                'Tag', 'bdSaveTime', ...
                'TooltipString', num2str(numel(app.sysobj.tdomain),'t is 1x%d'), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);
            
            % next row
            yoffset = yoffset + 2.75*rowh;
            
            % button group for the FORMAT radio buttons
            bgrp = uibuttongroup('Visible','on', ...
                'Parent', dlg, ...
                'Title', 'File Format', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Units', 'pixels', ...
                'Position',[10, panelh-yoffset, panelw-20, 2*rowh] );
            
            % v6 radio button
            uicontrol('Style','radiobutton', ...
                'String','v6', ...
                'Value', 1, ...
                'Tag', 'bdSaveV6', ...
                'TooltipString', 'v6 files will load in MATLAB 5.0 (R8) or later', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', bgrp, ...
                'Units','pixels', ...
                'Position',[5 5 50 rowh]);

            % v7 radio button
            uicontrol('Style','radiobutton', ...
                'String','v7', ...
                'Value', 0, ...
                'Tag', 'bdSaveV7', ...
                'TooltipString', 'v7 files will load in MATLAB 7.0 (R14) or later', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', bgrp, ...
                'Units','pixels', ...
                'Position',[55 5 50 rowh]);

            % v7.3 radio button
            uicontrol('Style','radiobutton', ...
                'String','v7.3', ...
                'Value', 0, ...
                'Tag', 'bdSaveV73', ...
                'TooltipString', 'v7.3 files will load in MATLAB 7.3 (R2006b) or later', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', bgrp, ...
                'Units','pixels', ...
                'Position',[105 5 50 rowh]);
            
            % construct the 'Cancel' button
            uicontrol('Style','pushbutton', ...
                'String','Cancel', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Callback', @(~,~) delete(dlg), ...
                'Position',[10 15 60 20]);

            % construct the 'Save' button
            uicontrol('Style','pushbutton', ...
                'String','Save', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Callback', @(~,~) app.SaveButtonCallback(dlg), ... 
                'Position',[panelw-70 15 60 20]);
        end

        % Callback for Save dialog button
        function SaveButtonCallback(app,dlg)
            % initialise the outgoing data
            data = [];
            
            % The matlab save function wont save an empty struct
            % so we ensure that our struct always has something in it.
            data.bdtoolbox = app.sysobj.version;    % toolkit version string
            data.date = date();                     % today's date
                
            % find the sys checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveSys');
            if objs.Value>0
                % include the sys struct in the outgoing data
                data.sys = app.sysobj.ExportSystem();
                % include sys.panels in the outgoing data too
                data.sys.panels = app.PanelMgr.ExportPanels();
            end

            % find the sol checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveSol');
            if objs.Value>0
                % include the sol struct in the outgoing data
                data.sol = app.sysobj.sol;
                % remove the OutputFcn option from the sol.extdata.options struct 
                if isfield(data.sol,'extdata') && isfield(data.sol.extdata,'options') && isfield(data.sol.extdata.options,'OutputFcn')
                    data.sol.extdata.options = rmfield(data.sol.extdata.options,'OutputFcn');
                end
            end

            % find the par checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSavePar');
            if objs.Value>0
                % include the par struct in the outgoing data
                data.par = app.par;
            end
            
            % find the lag checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveLag');
            if objs.Value>0
                % include the lag parameter values in the outgoing data
                data.lag = app.lag;
            end
            
            % find the var0 checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveVar0');
            if objs.Value>0
                % include the initial values in the outgoing data
                data.var0 = app.var0;
            end

            % find the var1 checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveVars');
            if objs.Value>0
                % include the initial values in the outgoing data
                data.vars = app.vars;
            end
            
            % find the time checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveTime');
            if objs.Value>0
                % include the time steps in the outgoing data
                data.tdomain = app.sysobj.tdomain;
            end
            
            % find the File Format radio buttons in the dialog box
            vflag = [];            
            objs = findobj(dlg,'Tag','bdSaveV6');   % -v6 option
            if objs.Value
                vflag = '-v6';
            end
            objs = findobj(dlg,'Tag','bdSaveV7');   % -v7 option
            if objs.Value
                vflag = '-v7';
            end
            objs = findobj(dlg,'Tag','bdSaveV73');   % -v4 option
            if objs.Value
                vflag = '-v7.3';
            end
            
            % Close the dialog box
            delete(dlg);

            % Save data to mat file
            [fname,pname] = uiputfile('*.mat','Save mat file');
            if fname~=0
                save(fullfile(pname,fname),'-struct','data',vflag);
            end
            
        end
        
        % Callback for the System-Export menu
        function SystemExportCallback(app)
            labs = {'gui','fig','par','var0','vars','t','lag','sys','sol'};
            vars = {'gui','fig','par','var0','vars','t','lag','sys','sol'};
            vals = {app, app.fig, app.par,app.var0,app.vars,app.t,app.lag,app.sys,app.sol};
            export2wsdlg(labs,vars,vals,'Export to Workspace',false(numel(labs),1));
        end
 
        % Callback for System-Clone menu
        function CloneMenuCallback(app)
            %disp('bdGUI.CloneMenuCallback');
            
            % Get the sys structure for this model
            sys = app.sysobj.ExportSystem();
            
            % Inlude the panels in the sys structure
            sys.panels = app.PanelMgr.ExportPanels();
            
            % Get the sol structure for this model 
            sol = app.sysobj.sol;

            % remove the OutputFcn option from the sol.extdata.options struct 
            if isfield(sol,'extdata') && isfield(sol.extdata,'options') && isfield(sol.extdata.options,'OutputFcn')
                sol.extdata.options = rmfield(sol.extdata.options,'OutputFcn');
            end
    
            % Construct a new GUI
            bdGUI(sys,'sol',sol);
        end
        
        % Callback for System-Quit menu
        function QuitMenuCallback(app)
            %disp('bdGUI.QuitMenuCallback'); 
            
            % stop the timer loop
            app.sysobj.TimerStop();
            
            % delete all figures with the same tag as the main GUI figure.
            tag = app.fig.Tag;
            figs = findall(0,'Type','figure','Tag',tag);
            delete(figs);
            
            % delete the bdGUI object
            delete(app);
        end
   
        % Listener for PUSH events
        function Pusher(app)
            %disp('gui.Pusher');
            
            % Obtain a copy of the current sys structure
            % including the current panel settings.
            sys = app.sysobj.ExportSystem();
            sys.panels = app.PanelMgr.ExportPanels();

            % Push the sys structure onto the Undo stack
            app.UndoStack.Push(sys);

            % Enable/Disable the Undo menu as appropriate
            if isvalid(app.UndoMenu)
                app.UndoMenu.Enable = app.UndoStack.UndoStatus();
            end

            % Enable/Disable the Re-do menu as appropriate
            if isvalid(app.RedoMenu)
                app.RedoMenu.Enable = app.UndoStack.RedoStatus();
            end 
        end
               
        % Callback for Edit-Undo menu
        function UndoMenuCallback(app)
            %disp('bdGUI.UndoMenuCallback');
            sys = app.UndoStack.Pop();          % Retrieve the previous system settings
            if ~isempty(sys)
                halt = app.sysobj.halt;         % Remember the HALT button state
                app.sysobj.ImportSystem(sys);   % Restore the previous system settings
                app.sysobj.halt = halt;         % UNDO does not alter the HALT button

                % Restore the previous panels (without invoking Pusher)
                app.plistener.Enabled = 0;              % Disable the PUSH listener
                app.PanelMgr.ImportPanels(sys.panels);  % Restore the previous panel settings
                app.sysobj.NotifyRedraw(app.rlistener); % Notify everything (except self) to REDRAW                
                app.plistener.Enabled = 1;              % Enable the PUSH listener
            end
            
            % Enable/Disable the Undo menu as appropriate
            if isvalid(app.UndoMenu)
                app.UndoMenu.Enable = app.UndoStack.UndoStatus();
            end
            
            % Enable/Disable the Redo menu as appropriate
            if isvalid(app.RedoMenu)
                app.RedoMenu.Enable = app.UndoStack.RedoStatus();
            end
            %disp('bdGUI.UndoMenuCallback END');
        end
        
        % Callback for Edit-Redo menu
        function RedoMenuCallback(app)
            %disp('bdGUI.RedoMenuCallback');
            sys = app.UndoStack.UnPop();        % Retrieve the earlier system settings
            if ~isempty(sys)
                halt = app.sysobj.halt;         % Remember the HALT button state
                app.sysobj.ImportSystem(sys);   % Apply the retrieved system settings
                app.sysobj.halt = halt;         % REDO does not alter the HALT button
                
                % Restore the previous panels (without invoking Pusher)
                app.plistener.Enabled = 0;              % Disable the PUSH listener
                app.PanelMgr.ImportPanels(sys.panels);  % Restore the previous panel settings
                app.sysobj.NotifyRedraw(app.rlistener); % Notify everything (except self) to REDRAW                
                app.plistener.Enabled = 1;              % Enable the PUSH listener
            end
            
            % Enable/Disable the Undo menu as appropriate
            if isvalid(app.UndoMenu)
                app.UndoMenu.Enable = app.UndoStack.UndoStatus();
            end
            
            % Enable/Disable the Redo menu as appropriate
            if isvalid(app.RedoMenu)
                app.RedoMenu.Enable = app.UndoStack.RedoStatus();
            end
            %disp('bdGUI.RedoMenuCallback END');
        end
        
    end
    
    methods (Static)

        % Prompt the user to load a sys struct (and optionally a sol struct) from a matlab file. 
        function [sys,sol] = loadsys()
            % init the return values
            sys = [];
            sol = [];

            % prompt the user to select a mat file
            [fname, pname] = uigetfile({'*.mat','MATLAB data file'},'Load system file');
            if fname==0
                return      % user cancelled the operation
            end

            % load the mat file that the user selected
            warning('off','MATLAB:load:variableNotFound');
            fdata = load(fullfile(pname,fname),'sys','sol');
            warning('on','MATLAB:load:variableNotFound');

            % extract the sys structure 
            if isfield(fdata,'sys')
                sys = fdata.sys;
            else
                msg = {'The load operation has failed because the selected mat file does not contain a ''sys'' structure.'
                       ''
                       'Explanation: Every model is defined by a special data structure that is named ''sys'' by convention. The System-Load menu has failed to find a data structure of that name in the selected mat file.'
                       ''
                       'To succeed, select a mat file that you know contains a ''sys'' structure. Example models are provided in the ''bdtoolkit'' installation directory. See Chapter 1 of the Handbook for the Brain Dynamics Toolbox for a list.'
                       ''
                       };
                uiwait( warndlg(msg,'Load failed') );
                throw(MException('bdGUI:badsys','Missing sys structure'));
            end

            % check the sys struct and display a dialog box if errors are found
            try
                % check the validity of the sys structure
                sys = bdGUI.syscheck(sys);
            catch ME
                throw(MException('bdGUI:badsys','Invalid sys structure'));
            end

            % extract the sol structure (if it exists) 
            if isfield(fdata,'sol')
                sol = fdata.sol;
%                 try
%                     % check that the sol struct matches the sys struct.
%                     solsyscheck(sol,sys);
%                 catch ME
%                     msg = {ME.message
%                            ''
%                            'Explanation: The solution (sol) found in the mat file is not compatible with this model (sys). The solution data is ignored.'
%                            ''
%                            };
%                     uiwait( warndlg(msg,'Solution not loaded') );
%                     sol = [];
%                 end
            end
        end    
    
        % Check the sys struct and display a dialog box if errors are detected 
        function sys = syscheck(sys)
            try
                % check the validity of the sys structure
                sys = bdSystem.syscheck(sys);
            catch ME
                switch ME.identifier
                    case {'bdtoolkit:syscheck:odefun'
                          'bdtoolkit:syscheck:ddefun'
                          'bdtoolkit:syscheck:sdeF'
                          'bdtoolkit:syscheck:sdeG'}
                        msg = {ME.message
                               ''
                               'Explanation: The model could not be loaded because its ''sys'' structure contains a handle to a function that is not in the matlab search path.'
                               ''
                               'To succeed, ensure that all functions belonging to the model are accessible to matlab via the search path. See ''Getting Started'' in the Handbook for the Brain Dynamics Toolbox.'
                               ''
                               };
                        uiwait( warndlg(msg,'Missing Function') );

                    otherwise
                        msg = {ME.message
                               ''
                               'Explanation: The model could not be loaded because its ''sys'' structure is invalid. Use the ''bdSysCheck'' command-line tool to diagnose the exact problem. Refer to the Handbook for the Brain Dynamics Toolbox for a comprehensive description of the format of the ''sys'' structure.'
                               ''
                               };
                        uiwait( warndlg(msg,'Invalid sys structure') );
                end
                throw(MException('bdGUI:badsys','Invalid sys structure'));
            end
        end

    end
end



