classdef bdPhasePortrait < bdPanelBase
    %bdPhasePortrait Display panel for plotting phase portraits in bdGUI.
    %
    %AUTHORS
    %Stewart Heitmann (2016a,2017a,2018b,2017c,2019a,2020a,2021a)   
    
    % Copyright (C) 2016-2022 QIMR Berghofer Medical Research Institute
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
        options
    end
    
    properties (Access=public)
        axes                matlab.ui.control.UIAxes
        quiver              matlab.graphics.chart.primitive.Quiver
        contourX            matlab.graphics.chart.primitive.Contour
        contourY            matlab.graphics.chart.primitive.Contour
    end
    
    properties (Access=private)
        sysobj              bdSystem
        selectorX           bdSelector
        selectorY           bdSelector
        tab                 matlab.ui.container.Tab           
        menu                matlab.ui.container.Menu
        menuTransients      matlab.ui.container.Menu
        menuMarkers         matlab.ui.container.Menu
        menuPoints          matlab.ui.container.Menu
        menuModulo          matlab.ui.container.Menu
        menuAutoStep        matlab.ui.container.Menu
        menuVectorField     matlab.ui.container.Menu
        menuNullclines      matlab.ui.container.Menu
        menuHoldAll         matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
        
        lineA               matlab.graphics.primitive.Line
        lineB               matlab.graphics.primitive.Line
        
        markerA             matlab.graphics.primitive.Line
        markerB             matlab.graphics.primitive.Line
        markerC             matlab.graphics.primitive.Line
            
        listener1           event.listener
        listener2           event.listener
        listener3           event.listener
    end
    
    methods
        function this = bdPhasePortrait(tabgrp,sysobj,opt)
            %disp('bdPhasePortrait');
            
            % remember the parents
            this.sysobj = sysobj;
                        
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','Phase Portrait', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');

            % construct the CALIBRATE menu item
            uimenu(this.menu, ...
                'Label', 'Calibrate', ...
                'Tooltip', 'Calibrate the axes to fit the data', ...
                'Callback', @(~,~) this.callbackCalibrate() );
                                    
            % construct the TRANSIENTS menu item
            this.menuTransients = uimenu(this.menu, ...
                'Label', 'Transients', ...
                'Checked', 'on', ...
                'Tag', 'transients', ...
                'Tooltip', 'Show the transient part of the trajectory', ...
                'Callback', @(src,~) this.callbackMenu(src) );
            
            % construct the MARKERS menu item
            this.menuMarkers = uimenu(this.menu, ...
                'Label', 'Markers', ...
                'Checked', 'on', ...
                'Tag', 'markers', ...
                'Tooltip', 'Show the trajectory markers', ...
                'Callback', @(src,~) this.callbackMenu(src) );

            % construct the POINTS menu item
            this.menuPoints = uimenu(this.menu, ...
                'Label', 'Time Points', ...
                'Checked', 'off', ...
                'Tag', 'points', ...
                'Tooltip', 'Show individual time points', ...            
                'Callback', @(src,~) this.callbackMenu(src) );

            % construct the MODULO menu item
            this.menuModulo = uimenu(this.menu, ...
                'Label', 'Modulo', ...
                'Checked', 'off', ...
                'Tag', 'modulo', ...
                'Tooltip', 'Wrap trajectories at the boundaries', ...            
                'Callback', @(src,~) this.callbackMenu(src) );
                                                           
            % construct the AUTOSTEP menu item
            this.menuAutoStep = uimenu(this.menu, ...
                'Label', 'Auto Steps', ...
                'Checked', 'on', ...
                'Tag', 'autostep', ...
                'Tooltip', 'Use the time steps chosen by the solver', ...
                'Callback', @(src,~) this.callbackMenu(src) );                                

            % construct the VECTORFIELD menu item
            this.menuVectorField = uimenu(this.menu, ...
                'Label', 'Vector Field', ...
                'Checked', 'off', ...
                'Tag', 'vectorfield', ...
                'Tooltip', 'Show the vector field', ...
                'Callback', @(src,~) this.callbackMenu(src) );
            
            % VECTORFIELD only applies to ODEs
            switch this.sysobj.solvertype
                case 'odesolver'
                    this.menuVectorField.Enable = 'on';
                otherwise
                    this.menuVectorField.Enable = 'off';
                    this.menuVectorField.Checked = 'off';
            end

            % construct the NULLCLINES menu item
            this.menuNullclines = uimenu(this.menu, ...
                'Label', 'Nullclines', ...
                'Checked', 'off', ...
                'Tag', 'nullclines', ...
                'Tooltip', 'Show the nullclines', ...
                'Callback', @(src,~) this.callbackMenu(src) );
            
            % NULLCLINES only apply to ODEs
            switch this.sysobj.solvertype
                case 'odesolver'
                    this.menuNullclines.Enable = 'on';
                otherwise
                    this.menuNullclines.Enable = 'off';
                    this.menuNullclines.Checked = 'off';
            end
            
            % construct the HOLD menu item
            uimenu(this.menu, ...
                'Label', 'Hold', ...
                'Tooltip', 'Hold the current plot', ...            
                'Callback', @(~,~) this.callbackHold() );          

            % construct the HOLD ALL menu item
            this.menuHoldAll = uimenu(this.menu, ...
                'Label', 'Hold All', ...
                'Tooltip', 'Hold all plots', ...            
                'Callback', @(src,~) this.callbackHoldAll() );
            
            % construct the CLEAR menu item
            uimenu(this.menu, ...
                'Label', 'Clear', ...
                'Tooltip', 'Clear the graphics', ...            
                'Callback', @(~,~) this.callbackClear() );

            % construct the DOCK menu item
            this.menuDock = uimenu(this.menu, ...
                'Label', 'Undock', ...
                'Tooltip', 'Undock the display panel', ...            
                'Callback', @(src,~) this.callbackDock(src,tabgrp) );

            % construct the CLOSE menu item
            uimenu(this.menu, ...
                'Separator','on', ...
                'Label','Close', ...
                'Tooltip', 'Close the display panel', ...            
                'Callback', @(~,~) this.callbackClose(fig) );

            % Create Tab and give it the focus. The tab should have the same
            % Tag as the panel menu so that each can be found by the other.
            this.tab = uitab(tabgrp, 'Title','Phase Portrait', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'1x','1x','1x'};
            GridLayout.RowHeight = {21,'1x'};
            GridLayout.ColumnSpacing = 50;
            GridLayout.RowSpacing = 10;
            GridLayout.Visible = 'off';

            % Create the selector objects
            this.selectorY = bdSelector(sysobj,'vardef');
            this.selectorX = bdSelector(sysobj,'vardef');
                       
            % Create DropDown for selectorY
            combo = this.selectorY.DropDownCombo(GridLayout);
            combo.Layout.Row = 1;
            combo.Layout.Column = 1;
            
            % Create DropDown for selectorX
            combo = this.selectorX.DropDownCombo(GridLayout);
            combo.Layout.Row = 1;
            combo.Layout.Column = 3;
            
            % Create axes
            this.axes = uiaxes(GridLayout);
            this.axes.Layout.Row = 2;
            this.axes.Layout.Column = [1 3];
            this.axes.NextPlot = 'add';
            this.axes.XGrid = 'off';
            this.axes.YGrid = 'off';
            this.axes.Box = 'on';
            this.axes.XLabel.String = 'X';
            this.axes.YLabel.String = 'Y';
            this.axes.FontSize = 11;

            % Customise the axes toolbars
            axtoolbar(this.axes,{'export','datacursor','restoreview'});
            
            % Construct the quiver plot for the vector field
            this.quiver = quiver(this.axes,[],[],[],[]);
            this.quiver.Color = [0.75 0.75 0.75];
            this.quiver.AutoScale='off';
            this.quiver.ShowArrowHead = 'off';
            this.quiver.Marker = 'o';
            this.quiver.MarkerSize = 5;
            this.quiver.HitTest = 'off';
            
            % Construct the contour plot for the X nullcline
            [~,this.contourX] = contour(this.axes,[],[],[]);
            this.contourX.LevelList = [0 0];
            this.contourX.Color = [0 1 0];
            this.contourX.LineStyle = '-';
            this.contourX.LineWidth = 1;
            this.contourX.HitTest = 'off';

            % Construct the contour plot for the Y nullcline
            [~,this.contourY] = contour(this.axes,[],[],[],[0 0]);
            this.contourY.LevelList = [0 0];
            this.contourY.Color = [0 1 0];
            this.contourY.LineStyle = '-';
            this.contourY.LineWidth = 1;
            this.contourY.HitTest = 'off';

            % Construct the line plots (containing NaN)
            this.lineA = line(this.axes,NaN,NaN,'LineStyle','-','color',[0.8 0.8 0.8],'Linewidth',1,'MarkerSize',10);
            this.lineB = line(this.axes,NaN,NaN,'LineStyle','-','color','k','Linewidth',1.5,'MarkerSize',10);

            % Construct the markers
            this.markerA = line(this.axes,NaN,NaN,'Marker','h','color','k','Linewidth',1.00,'MarkerFaceColor','y','MarkerSize',10);
            this.markerB = line(this.axes,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor','w');
            this.markerC = line(this.axes,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor',[0.6 0.6 0.6]);            
            
            % apply the custom options (and render the data)
            this.options = opt;

            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';
            
            % listen for Redraw events
            this.listener1 = listener(sysobj,'redraw',@(src,evnt) this.Redraw(evnt));
            
            % listen for SelectionChanged events
            this.listener2 = listener([this.selectorY, this.selectorX],'SelectionChanged',@(src,evnt) this.SelectorChanged());
            
            % listen for SubscriptChanged events
            this.listener3 = listener([this.selectorY, this.selectorX],'SubscriptChanged',@(src,evnt) this.SubscriptChanged());
        end
        
        function opt = get.options(this)
            opt.title       = this.tab.Title;
            opt.transients  = this.menuTransients.Checked;
            opt.markers     = this.menuMarkers.Checked;
            opt.points      = this.menuPoints.Checked;
            opt.modulo      = this.menuModulo.Checked;
            opt.autostep    = this.menuAutoStep.Checked;
            opt.vectorfield = this.menuVectorField.Checked;
            opt.nullclines  = this.menuNullclines.Checked;
            opt.hold        = this.menuHoldAll.Checked;
            opt.selectorX   = this.selectorX.cellspec();
            opt.selectorY   = this.selectorY.cellspec();
        end
        
        function set.options(this,opt)   
            % check the incoming options and apply defaults to missing values
             opt = this.optcheck(opt);
             
            % update the selectors
            this.selectorX.SelectByCell(opt.selectorX);
            this.selectorY.SelectByCell(opt.selectorY);
             
            % update the tab title
            this.tab.Title = opt.title;
            
            % update the menu title
            this.menu.Text = opt.title;
                        
            % update the TRANSIENTS menu
            this.menuTransients.Checked = opt.transients;

            % update the MARKERS menu
            this.menuMarkers.Checked = opt.markers;

            % update the POINTS menu
            this.menuPoints.Checked = opt.points;
            
            % update the MODULO menu
            this.menuModulo.Checked = opt.modulo;
            
            % update the AUTOSTEP menu
            this.menuAutoStep.Checked = opt.autostep;
            
            % update the VECTORFIELD and NULLCLINES menus
            switch this.sysobj.solvertype
                case 'odesolver'
                    this.menuVectorField.Checked = opt.vectorfield;
                    this.menuNullclines.Checked = opt.nullclines;
                otherwise
                    this.menuVectorField.Checked = 'off';
                    this.menuNullclines.Checked = 'off';
            end
            
            % update the HOLD ALL menu
            this.menuHoldAll.Checked = opt.hold;

            % Redraw everything
            this.RenderBackground();
            this.RenderForeground();
            this.RenderVectorField();
            this.RenderNullclines();
            drawnow;
        end
        
        function delete(this)
           %disp('bdPhasePortrait.delete()');
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods (Access=private)

        % Listener for REDRAW events
        function Redraw(this,evnt)
            %disp('bdPhasePortrait.Redraw()');
            %disp(evnt)
            
            % Get the current selector settings
            [xxxdef,xxxindx] = this.selectorX.Item();
            [yyydef,yyyindx] = this.selectorY.Item();
            
            if evnt.(yyydef)(yyyindx).lim || evnt.(xxxdef)(xxxindx).lim
                this.RenderBackground();
            end
            
            if evnt.sol || evnt.tval || evnt.tstep || evnt.(yyydef)(yyyindx).lim || evnt.(xxxdef)(xxxindx).lim
                this.RenderForeground();
                this.RenderVectorField();
                this.RenderNullclines();            
            end              
            
        end
                
        function RenderBackground(this)
            %disp('bdPhasePortrait.RenderBackground()');
                        
            % update the plot limits for the selected variables
            plimX = this.selectorX.lim();
            plimY = this.selectorY.lim();
            this.axes.XLim = plimX;
            this.axes.YLim = plimY;
            
            % update the axes labels for the selected variables
            [~,~,nameX] = this.selectorX.name();
            [~,~,nameY] = this.selectorY.name();
            this.axes.XLabel.String = nameX;
            this.axes.YLabel.String = nameY;
        end
        
        function RenderForeground(this)
            %disp('bdPhasePortrait.RenderForeground()');
                            
            % hold the graphics (if required)
            switch this.menuHoldAll.Checked
                case 'on'
                    this.callbackHold();
            end

            % evaluate the selected variables
            [~,X,tdomain,tindx0,tindx1,ttindx] = this.selectorX.Trajectory('autostep',this.menuAutoStep.Checked);
            [~,Y] = this.selectorY.Trajectory('autostep',this.menuAutoStep.Checked);

            % extract the transient and non-transient parts of the trajectory
            X0 = X(tindx0);  Y0 = Y(tindx0);
            X1 = X(tindx1);  Y1 = Y(tindx1);
            Xt = X(ttindx);  Yt = Y(ttindx);
            
            % modulo the trajectories (if appropriate)
            switch this.menuModulo.Checked
                case 'on'
                    % limits of the selected variables
                    [~,limX] = this.selectorX.lim();
                    [~,limY] = this.selectorY.lim();

                    % modulo the Y0 values at limY
                    [X0,Y0] = this.modulus(X0,Y0,limY);                   
                    % modulo the X0 values at limX
                    [Y0,X0] = this.modulus(Y0,X0,limX);
                    
                    % modulo the Y1 values at limY
                    [X1,Y1] = this.modulus(X1,Y1,limY);
                    % modulo the X1 values at limX
                    [Y1,X1] = this.modulus(Y1,X1,limX);
                    
                    % modulo the Yt values at limY
                    [Xt,Yt] = this.modulus(Xt,Yt,limY);
                    % modulo the Xt values at limX
                    [Yt,Xt] = this.modulus(Yt,Xt,limX);
            end
            
            % update the transient part of the trajectory
            this.lineA.XData = X0;
            this.lineA.YData = Y0;

            % update the non-transient part of the trajectory
            this.lineB.XData = X1;
            this.lineB.YData = Y1;
                
            % show/hide the individual time points
            switch this.menuPoints.Checked
                case 'on'
                    this.lineA.Marker = '.';
                    this.lineB.Marker = '.';
                case 'off'
                    this.lineA.Marker = 'none';
                    this.lineB.Marker = 'none';
            end
            
            % update the marker plot data
            set(this.markerA, 'XData',X0(1),'YData',Y0(1));
            set(this.markerB, 'XData',Xt,'YData',Yt);
            set(this.markerC, 'XData',X1(end),'YData',Y1(end));
            
            % visibilty of transients 
            this.lineA.Visible   = this.menuTransients.Checked;
            this.markerA.Visible = this.menuTransients.Checked;
            
            % visibility of markers
            switch this.menuMarkers.Checked
                case 'on'
                    this.markerA.Visible = this.menuTransients.Checked;
                    this.markerB.Visible = 'on';
                    this.markerC.Visible = 'on';
                case 'off'
                    this.markerA.Visible = 'off';
                    this.markerB.Visible = 'off';
                    this.markerC.Visible = 'off';
            end
            

        end        
             
        function RenderVectorField(this)
            %disp('RenderVectorField');
                        
            switch this.menuVectorField.Checked
                case 'on'
                    this.quiver.Visible = 'on';
                otherwise
                    this.quiver.Visible = 'off';
                    return
            end

            % get the plot limits of the selected variables
            [~,limX] = this.selectorX.lim();
            [~,limY] = this.selectorY.lim();

            % compute a mesh for the domain
            nx = 11;
            ny = 11;
            xdomain = linspace(limX(1),limX(2), nx);
            ydomain = linspace(limY(1),limY(2), ny);
            [xmesh,ymesh] = meshgrid(xdomain,ydomain);
            dxmesh = zeros(size(xmesh));
            dymesh = zeros(size(ymesh));
            
            % desired length of our tell-tales
            spanX = (limX(2) - limX(1))/20;
            spanY = (limY(2) - limY(1))/20;
            
            % current time slider
            tval = this.sysobj.tval;
            
            % parameter values
            P0  = {this.sysobj.pardef.value};
            
            % initial conditions
            Y0 = this.sysobj.GetVar0();
            
            % indexes of the selected variables in Y0
            [~,subXindx] = this.selectorX.solindx();
            [~,subYindx] = this.selectorY.solindx();

            % evaluate vector field
            for xi = 1:nx
                for yi = 1:ny
                    % initial conditions for current mesh point
                    Y0(subXindx) = xmesh(xi,yi);
                    Y0(subYindx) = ymesh(xi,yi);

                    % evaluate the ODE at Y0
                    dY = this.sysobj.odefun(tval,Y0,P0{:});

                    % extract the dY values for our selected state variables
                    dx = dY(subXindx);
                    dy = dY(subYindx);

                    % we scale our vector field manually using the equation
                    % for an ellipse to accommodate the different spans of
                    % the vertical and horizontal axes.
                    L = sqrt(dx^2/spanX^2 + dy^2/spanY^2);
                    scale = 1/L;
                    if isinf(scale)
                        scale=0;
                    end

                    % save results
                    dxmesh(xi,yi) = dx.*scale;
                    dymesh(xi,yi) = dy.*scale;
                end
            end
            
            % update the quiver plot of the vector field
            this.quiver.XData = xmesh;
            this.quiver.YData = ymesh;
            this.quiver.UData = dxmesh;
            this.quiver.VData = dymesh;
        end
        
        function RenderNullclines(this)
            %disp('RenderNullclines');
                        
            switch this.menuNullclines.Checked
                case 'on'
                    this.contourX.Visible = 'on';
                    this.contourY.Visible = 'on';
                otherwise
                    this.contourX.Visible = 'off';
                    this.contourY.Visible = 'off';
                    return
            end

            % get the plot limits of the selected variables
            [~,limX] = this.selectorX.lim();
            [~,limY] = this.selectorY.lim();
            
            % compute a mesh for the domain
            nx = 41;
            ny = 41;
            xdomain = linspace(limX(1),limX(2), nx);
            ydomain = linspace(limY(1),limY(2), ny);
            [xmesh,ymesh] = meshgrid(xdomain,ydomain);
            dxmesh = zeros(size(xmesh));
            dymesh = zeros(size(ymesh));
            
            % current time slider
            tval = this.sysobj.tval;
            
            % parameter values
            P0  = {this.sysobj.pardef.value};
            
            % initial conditions
            Y0 = this.sysobj.GetVar0();
            
            % indexes of the selected variables in Y0
            [~,subXindx] = this.selectorX.solindx();
            [~,subYindx] = this.selectorY.solindx();

            % evaluate vector field
            for xi = 1:nx
                for yi = 1:ny
                    % initial conditions for current mesh point
                    Y0(subXindx) = xmesh(xi,yi);
                    Y0(subYindx) = ymesh(xi,yi);

                    % evaluate the ODE at Y0
                    dY = this.sysobj.odefun(tval,Y0,P0{:});

                    % save results
                    dxmesh(xi,yi) = dY(subXindx);
                    dymesh(xi,yi) = dY(subYindx);
                end
            end
            
            % update the contour plot of the X nullcline
            this.contourX.XData = xmesh;
            this.contourX.YData = ymesh;
            this.contourX.ZData = dxmesh;
            
            % update the contour plot of the Y nullcline
            this.contourY.XData = xmesh;
            this.contourY.YData = ymesh;
            this.contourY.ZData = dymesh;
        end
        
        
        % Selector Changed callback
        function SelectorChanged(this)
            %disp('bdPhasePortrait.SelectorChanged');
            this.RenderBackground();        % Render the background items
            this.RenderForeground();        % Render the foreground items
            this.RenderVectorField();       % Render the vector field
            this.RenderNullclines();        % Render the nullclines
        end
        
        % Subscript Changed callback
        function SubscriptChanged(this)
            %disp('bdPhasePortrait.SubscriptChanged');
             
            % update the axes labels for the selected variables
            [~,~,nameX] = this.selectorX.name();
            [~,~,nameY] = this.selectorY.name();
            this.axes.XLabel.String = nameX;
            this.axes.YLabel.String = nameY;

            this.RenderForeground();        % Render the foreground items
            this.RenderVectorField();       % Render the vector field
            this.RenderNullclines();        % Render the nullclines
        end
                              
        % Generic callback for menus with Checked states (TRANSIENTS, MARKERS, MODULO, AUTOSTEP)
        function callbackMenu(this,menuitem)
            this.MenuToggle(menuitem);      % Toggle the menu state
            this.RenderBackground();        % Render the background items
            this.RenderForeground();        % Render the foreground items
            this.RenderVectorField();       % Render the vector field
            this.RenderNullclines();        % Render the nullclines
        end
        
        % CALIBRATE menu callback
        function callbackCalibrate(this)
            % time domain
            tspan = this.sysobj.tspan;
            
            % if the TRANSIENTS option is disabled then ...
            switch this.menuTransients.Checked
                case 'off'
                    % do not calibrate the transient data
                    tspan(1) = this.sysobj.tval;
            end
            
            % Calibrate the plot limits via the selectors
            this.selectorX.Calibrate(tspan);
            this.selectorY.Calibrate(tspan);
                
            % redraw all panels (because the new limits apply to all panels)
            this.sysobj.NotifyRedraw([]);
        end

        % CLEAR menu callback
        function callbackClear(this)
            %disp('callbackClear');
            
            % delete all line plots in axes that have Tag='Held'
            objs = findobj(this.axes,'Tag','Held');
            delete(objs);
            
            % delete all data tips
            objs = findobj(this.axes,'Type','datatip');
            delete(objs);

            % render the data
            this.RenderBackground();
            this.RenderForeground();
            this.RenderVectorField();
        end
        
        % HOLD menu callback
        function callbackHold(this)
            % Make new copies of the foreground plot lines
            newlineA = copyobj(this.lineA, this.axes);
            newlineB = copyobj(this.lineB, this.axes);
            
            % Convert the old foreground plot lines to 'Held'
            this.lineA.LineWidth = 1.5;
            this.lineB.LineWidth = 1.5;
            this.lineA.Color = [0.5 0.75 0.5];
            this.lineB.Color = [0.5 0.75 0.5];
            this.lineA.Tag = 'Held';
            this.lineB.Tag = 'Held';
            this.lineA.PickableParts = 'none';
            this.lineB.PickableParts = 'none';          
            
            % Replace the old with the new
            this.lineA = newlineA;
            this.lineB = newlineB;
            
            % The line markers now need to be promoted back to the top level.
            % We do that by constructing fresh copies and deleting the old ones.
            newmarkerA = copyobj(this.markerA, this.axes);
            newmarkerB = copyobj(this.markerB, this.axes);
            newmarkerC = copyobj(this.markerC, this.axes);
            delete(this.markerA);
            delete(this.markerB);
            delete(this.markerC);
            this.markerA = newmarkerA;
            this.markerB = newmarkerB;
            this.markerC = newmarkerC;
        end
        
        % HOLD ALL menu callback
        function callbackHoldAll(this)
            this.MenuToggle(this.menuHoldAll);
        end
        
        % DOCK menu callback
        function callbackDock(this,menuitem,tabgrp)
            %disp('callbackDock');
            switch menuitem.Label
                case 'Undock'
                    newfig = bdPanelBase.Undock(this.tab,this.menu);
                    newfig.DeleteFcn = @(src,~) this.delete();
                    menuitem.Label='Dock';
                    menuitem.Tooltip='Dock the display panel';
                case 'Dock'
                    bdPanelBase.Dock(this.tab,this.menu,tabgrp);
                    menuitem.Label='Undock';
                    menuitem.Tooltip='Undock the display panel';
            end
        end
        
        % CLOSE menu callback
        function callbackClose(this,guifig)
            % find the parents of the panel tab 
            tabgrp = ancestor(this.tab,'uitabgroup');
            fig = ancestor(this.tab,'figure');
                       
            % remember sysobj
            sysobj = this.sysobj;

            % delete the panel
            delete(this);
            
            % reveal the menu of the newly selected panel 
            bdPanelBase.FocusMenu(tabgrp);
            
            % if the parent figure is not the same as the gui figure then ...
            if fig ~= guifig
                % The panel is undocked from the gui. Its figure should be closed too. 
                delete(fig);
            end
        end
        

    end
    
    methods (Static)
        
        function optout = optcheck(opt)
            % check the format of incoming options and apply defaults to missing values
            optout.title       = bdPanelBase.GetOption(opt, 'title', 'Phase Portrait 2D');
            optout.transients  = bdPanelBase.GetOption(opt, 'transients', 'on');            
            optout.markers     = bdPanelBase.GetOption(opt, 'markers', 'on');            
            optout.points      = bdPanelBase.GetOption(opt, 'points', 'off');            
            optout.modulo      = bdPanelBase.GetOption(opt, 'modulo', 'off');
            optout.autostep    = bdPanelBase.GetOption(opt, 'autostep', 'on');
            optout.vectorfield = bdPanelBase.GetOption(opt, 'vectorfield', 'off');
            optout.nullclines  = bdPanelBase.GetOption(opt, 'nullclines', 'off');
            optout.hold        = bdPanelBase.GetOption(opt, 'hold', 'off');
            optout.selectorX   = bdPanelBase.GetOption(opt, 'selectorX', {1,1,1});
            optout.selectorY   = bdPanelBase.GetOption(opt, 'selectorY', {2,1,1});
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning('Ignoring unknown panel option ''bdPhasePortrait.%s''',newfields{idx});
            end
        end
        
        function [xout,yout] = modulus(x,y,ylim)
            % modulo the values in y to force ylo<y<yhi
            span = ylim(2) - ylim(1);
            y = mod(y-ylim(1),span) + ylim(1);
                
            % find the discontinuities in y
            d = 2*abs(diff(y)) > span;
            dcount = sum(d);
            
            % convert the logical indexes into numerical indexes
            di = find([d,1]);

            % Insert NaN at each discontnuity by copying each segment
            % into the output with gaps between them. 
            n = numel(x);
            xout = NaN(1,n+dcount);
            yout = NaN(1,n+dcount);
            i0 = 1;                 % beginning of segment in the output vector
            i1 = 1;                 % beginnning of segment in the input vector
            for i2 = di             % for the end of each segment in the input vector
                indx1 = i1:i2;          % indexes of the segment in the input vector
                indx0 = [i1:i2]-i1+i0;  % indexes of the segment in the output vector
                xout(indx0) = x(indx1); % copy the segment contents
                yout(indx0) = y(indx1); % copy the segment contents                
                i1 = indx1(end)+1;      % beginning of the next segment in the input vector
                i0 = indx0(end)+2;      % beginning of the next segment in the output vector
            end
        end
        
    end
end

