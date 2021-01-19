classdef bdHilbert < bdPanelBase
    %bdHilbert Display panel for plotting the Hilbert transform of a time series
    %
    %AUTHORS
    %  Stewart Heitmann (2017b,2018a,2019a,2020a,2021a)

    % Copyright (C) 2016-2020 QIMR Berghofer Medical Research Institute
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
        t                   double          % time steps of the signal
        h                   double          % Hilbert transform of the time series
        p                   double          % Hilbert phases of the time series
        
        % Upper/Lower axes
        axes1               matlab.ui.control.UIAxes
        axes2               matlab.ui.control.UIAxes
        
        % Cylinder/Disc meshes        
        mesh1               matlab.graphics.chart.primitive.Surface
        mesh2               matlab.graphics.chart.primitive.Surface 
    end
    
    properties (Access=private)
        sysobj              bdSystem
        selector            bdSelector
        
        % panel menus
        menu                matlab.ui.container.Menu
        menuTransients      matlab.ui.container.Menu
        menuMarkers         matlab.ui.container.Menu
        menuPoints          matlab.ui.container.Menu
        menuRelPhase        matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
        
        % panel tab
        tab                 matlab.ui.container.Tab           

        % instrumentation
        azimuthSlider       matlab.ui.control.Slider
        elevationKnob       matlab.ui.control.Knob
        opacityKnob         matlab.ui.control.Knob
        label1              matlab.ui.control.Label
        
        % background traces (upper plot)
        trace1a             matlab.graphics.primitive.Line
        trace1b             matlab.graphics.primitive.Line
        
        % foreground lines (upper plot)
        line1a              matlab.graphics.primitive.Line
        line1b              matlab.graphics.primitive.Line
        
        % foreground lines (lower plot)      
        line2a              matlab.graphics.primitive.Line
        line2b              matlab.graphics.primitive.Line
        
        % markers (upper plot)
        marker1a            matlab.graphics.primitive.Line
        marker1b            matlab.graphics.primitive.Line
        marker1c            matlab.graphics.primitive.Line
        
        % markers (lower plot)
        marker2a            matlab.graphics.primitive.Line
        marker2b            matlab.graphics.primitive.Line
        marker2c            matlab.graphics.primitive.Line

        % event listeners
        listener1
        listener2
        listener3
    end
    
    methods
        function this = bdHilbert(tabgrp,sysobj,opt)
            %fprintf('%s()\n',mfilename);
            
            % remember the parents
            this.sysobj = sysobj;
            
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','Hilbert Phase', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');
            
            % construct the TRANSIENTS menu item
            this.menuTransients = uimenu(this.menu, ...
                'Label', 'Transients', ...
                'Checked', 'on', ...
                'Tag', 'transients', ...
                'Tooltip', 'Show the transient part of the trajectory', ...
                'Callback', @(src,~) this.callbackTransients(src) );
            
            % construct the MARKERS menu item
            this.menuMarkers = uimenu(this.menu, ...
                'Label', 'Markers', ...
                'Checked', 'on', ...
                'Tag', 'markers', ...
                'Tooltip', 'Show the trajectory markers', ...               
                'Callback', @(src,~) this.callbackMarkers(src) );
            
            % construct the POINTS menu item
            this.menuPoints = uimenu(this.menu, ...
                'Label', 'Time Points', ...
                'Checked', 'off', ...
                'Tag', 'points', ...
                'Tooltip', 'Show individual time points', ...            
                'Callback', @(src,~) this.callbackPoints(src) );
                        
            % construct the RELATIVE PHASE menu item
            this.menuRelPhase = uimenu(this.menu, ...
                'Label', 'Relative Phases', ...
                'Checked', 'off', ...
                'Tag', 'relphase', ...
                'Tooltip', 'Adjust phases relative to the 1st time series', ...
                'Callback', @(src,~) this.callbackRelPhase(src) );
                                    
            % construct the HOLD menu item
            uimenu(this.menu, ...
                'Label', 'Hold', ...
                'Tooltip', 'Hold the graphics', ...            
                'Callback', @(src,~) this.callbackHold(src) );
            
            % construct the CLEAR menu item
            uimenu(this.menu, ...
                'Label', 'Clear', ...
                'Tooltip', 'Clear the graphics', ...            
                'Callback', @(~,~) this.callbackClear() );
            
            % construct the RESET menu item
            uimenu(this.menu, ...
                'Label', 'Reset View', ...
                'Tooltip', 'Reset the view angle', ...            
                'Callback', @(~,~) this.callbackReset() );
            
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
            this.tab = uitab(tabgrp, 'Title','Hilbert Phase', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'2x','3x','3x'};
            GridLayout.RowHeight = {21,'3x','1x','2x'};
            GridLayout.RowSpacing = 5;
            GridLayout.ColumnSpacing = 0;
            GridLayout.Visible = 'off';

            % construct the selectors
            this.selector = bdSelector(sysobj,'vardef');

            % Create DropDownCombo for selector
            combo1 = this.selector.DropDownCombo(GridLayout);
            combo1.Layout.Row = 1;
            combo1.Layout.Column = 1;

            % Create label1
            this.label1 = uilabel(GridLayout);
            this.label1.Layout.Row = 1;
            this.label1.Layout.Column = [2 3];
            this.label1.Text = 'Not all traces are shown';
            this.label1.VerticalAlignment = 'center';
            this.label1.HorizontalAlignment = 'right';
            this.label1.FontColor = [0.5 0.5 0.5];
            this.label1.Visible = 'off';

            % Create axes1 (upper plot)
            this.axes1 = uiaxes(GridLayout);
            this.axes1.Layout.Row = 2;
            this.axes1.Layout.Column = [1 3];
            this.axes1.NextPlot = 'add';
            this.axes1.XLabel.String = 'time';
            this.axes1.FontSize = 11;
            this.axes1.XGrid = 'off';
            this.axes1.YGrid = 'off';
            this.axes1.Box = 'on';
            this.axes1.XLim = sysobj.tspan;
            this.axes1.YLim = [-1.1 1.1];
            this.axes1.ZLim = [-1.1 1.1];
            this.axes1.View = [0 0];
            this.axes1.YTick = [];
            this.axes1.ZTick = [];
            this.axes1.TickLength=[0.01 0.01];
            
            % Create axes2 (lower plot)
            this.axes2 = uiaxes(GridLayout);
            this.axes2.Layout.Row = [3 4];
            this.axes2.Layout.Column = 3;
            this.axes2.NextPlot = 'add';
            this.axes2.FontSize = 11;
            this.axes2.XGrid = 'off';
            this.axes2.YGrid = 'off';
            this.axes2.Box = 'off';
            this.axes2.XLim = [-1.6 1.6];
            this.axes2.YLim = [-1.6 1.6];
            this.axes2.XTick = [];
            this.axes2.YTick = [];
            this.axes2.DataAspectRatio = [1 1 1];
            this.axes2.Visible = 'off';
                     
            % Customise the axes toolbars
            axtoolbar(this.axes1,{'export'});
            axtoolbar(this.axes2,{'export'});
            
            % Creat Opacity Knob
            this.opacityKnob = uiknob(GridLayout);
            this.opacityKnob.Layout.Row = 4;
            this.opacityKnob.Layout.Column = 1;
            this.opacityKnob.Limits = [0 1];
            this.opacityKnob.Value = 1;
            this.opacityKnob.MajorTicks= [0 1];
            this.opacityKnob.MinorTicks= 0:0.1:1;
            this.opacityKnob.Tooltip = 'Opacity';  
            this.opacityKnob.ValueChangingFcn = @(src,evnt) this.OpacityChanging(src,evnt);
  
            % Create Azimuth slider
            this.azimuthSlider = uislider(GridLayout);
            this.azimuthSlider.Layout.Row = 3;
            this.azimuthSlider.Layout.Column = 1;
            this.azimuthSlider.Limits = [-10 10];
            this.azimuthSlider.Value = 0;
            this.azimuthSlider.MajorTicks = -10:10:10;
            this.azimuthSlider.MinorTicks = -10:2:10;
            this.azimuthSlider.Tooltip = 'Azimuth';
            this.azimuthSlider.ValueChangingFcn = @(src,evnt) this.AzimuthChanging(src,evnt);
            
            % Create Elevation Knob
            this.elevationKnob = uiknob(GridLayout);
            this.elevationKnob.Layout.Row = [3 4];
            this.elevationKnob.Layout.Column = 2;
            this.elevationKnob.Limits = [-180 180];
            this.elevationKnob.Value = 0;
            this.elevationKnob.MajorTicks= -180:45:180;
            this.elevationKnob.MinorTicks= -180:15:180;
            this.elevationKnob.ValueChangingFcn = @(src,evnt) this.ElevationChanging(src,evnt);

            % Construct mesh1 (Cylinder)
            [X,Y,Z] = this.CylinderMesh(0,1,0);
            this.mesh1 = mesh(this.axes1, X, Y, Z, ...
                'EdgeColor',[0.5 0.9 0.5], ...
                'FaceColor',[0.9 1 0.9], ...
                'FaceAlpha',1, ...
                'EdgeAlpha',1, ...
                'PickableParts','none');

            % Construct mesh2 (Disc)
            [X,Y,Z] = this.DiscMesh(0);
            this.mesh2 = mesh(this.axes2, X, Y, Z, ...
                'EdgeColor',[0.8 0.8 0.8], ...
                'FaceColor',[1.0 1.0 1.0], ...
                'PickableParts','none');
            
            % Add text labels to the disc
            text(this.axes2,-1.5,-1.5,'-\pi', ...
                'HorizontalAlignment','left', ...
                'VerticalAlignment','middle', ...
                'FontSize',14);
            text(this.axes2,1.5,-1.5,'+\pi', ...
                'HorizontalAlignment','right', ...
                'VerticalAlignment','middle', ...
                'FontSize',14);
            
            % Construct background traces (containing NaN)
            this.trace1a = line(this.axes1,NaN,NaN, 'LineStyle','-', 'color',[0.8 0.8 0.8], 'Linewidth',1.5, 'PickableParts','none');
            this.trace1b = line(this.axes1,NaN,NaN, 'LineStyle','-', 'color',[0.8 0.8 0.8], 'Linewidth',1.5, 'PickableParts','none');
            
            % Construct the line plots (containing NaN)
            this.line1a = line(this.axes1,NaN,NaN, 'LineStyle','-', 'color',[0.5 0.5 0.5], 'Linewidth',2);
            this.line1b = line(this.axes1,NaN,NaN, 'LineStyle','-', 'color',[0 0 0],'Linewidth',2);
            this.line2a = line(this.axes2,NaN,NaN, 'LineStyle','-', 'color',[0.5 0.5 0.5],'Linewidth',1);
            this.line2b = line(this.axes2,NaN,NaN, 'LineStyle','-', 'color',[0 0 0],'Linewidth',1.5);

            % Construct the markers
            this.marker1a = line(this.axes1,NaN,NaN, 'Marker','h', 'color','k', 'Linewidth',0.75, 'MarkerFaceColor','y', 'MarkerSize',10);
            this.marker1b = line(this.axes1,NaN,NaN, 'Marker','o', 'color','k', 'Linewidth',1,    'MarkerFaceColor','w');
            this.marker1c = line(this.axes1,NaN,NaN, 'Marker','o', 'color','k', 'Linewidth',1,    'MarkerFaceColor',[0.6 0.6 0.6]);
            this.marker2a = line(this.axes2,NaN,NaN, 'Marker','h', 'color','k', 'Linewidth',0.75, 'MarkerFaceColor','y', 'MarkerSize',10);
            this.marker2b = line(this.axes2,NaN,NaN, 'Marker','o', 'color','k', 'Linewidth',1,    'MarkerFaceColor','w');
            this.marker2c = line(this.axes2,NaN,NaN, 'Marker','o', 'color','k', 'Linewidth',1,    'MarkerFaceColor',[0.6 0.6 0.6]);

            % Customise the DataTipTemplate (line1a)
            dt = datatip(this.line1a);
            this.line1a.DataTipTemplate.DataTipRows(1).Label = 'time';
            this.line1a.DataTipTemplate.DataTipRows(2) = [];
            delete(dt);
            
            % Customise the DataTipTemplate (line1b)
            dt = datatip(this.line1b);
            this.line1b.DataTipTemplate.DataTipRows(1).Label = 'time';
            this.line1b.DataTipTemplate.DataTipRows(2) = [];
            delete(dt);
            
            % Customise the DataTipTemplate (marker1a)
            dt = datatip(this.marker1a);
            this.marker1a.DataTipTemplate.DataTipRows(1).Label = 'time';
            this.marker1a.DataTipTemplate.DataTipRows(2) = [];
            delete(dt);
            
            % Customise the DataTipTemplate (marker1b)
            dt = datatip(this.marker1b);
            this.marker1b.DataTipTemplate.DataTipRows(1).Label = 'time';
            this.marker1b.DataTipTemplate.DataTipRows(2) = [];
            delete(dt);
            
            % Customise the DataTipTemplate (marker1c)
            dt = datatip(this.marker1c);
            this.marker1c.DataTipTemplate.DataTipRows(1).Label = 'time';
            this.marker1c.DataTipTemplate.DataTipRows(2) = [];
            delete(dt);
               
            % apply the custom options (and render the data)
            this.options = opt;

            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';

            % listen for SelectionChanged events
            this.listener1 = listener(this.selector,'SelectionChanged',@(src,evnt) this.SelectorChanged());
            
            % listen for SubscriptChanged events
            this.listener2 = listener(this.selector,'SubscriptChanged',@(src,evnt) this.SubscriptChanged());
                       
            % listen for Redraw events
            this.listener3 = listener(sysobj,'redraw',@(src,evnt) this.Redraw(evnt));
        end
        
        function opt = get.options(this)
            opt.title      = this.tab.Title;
            opt.transients = this.menuTransients.Checked;
            opt.markers    = this.menuMarkers.Checked;
            opt.points     = this.menuPoints.Checked;
            opt.relphase   = this.menuRelPhase.Checked;
            opt.azimuth    = this.azimuthSlider.Value;
            opt.elevation  = this.elevationKnob.Value;
            opt.opacity    = this.opacityKnob.Value;  
            opt.selector   = this.selector.cellspec();
        end
        
        function set.options(this,opt)   
            % check the incoming options and apply defaults to missing values
            opt = bdHilbert.optcheck(opt);
             
            % update the selector
            this.selector.SelectByCell(opt.selector);

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
             
            % update the RELATIVE PHASE menu
            this.menuRelPhase.Checked = opt.relphase;

            % update the AZIMUTH slider
            this.azimuthSlider.Value = opt.azimuth;
                
            % update the ELEVATION roller
            this.elevationKnob.Value = opt.elevation;
            
            % update the OPACITY roller
            this.opacityKnob.Value = opt.opacity;
            
            % Redraw everything
            this.RenderBackground();
            this.RenderForeground();
            drawnow;
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        function delete(this)
           %disp('bdHilbert.delete()');
           delete(this.listener1);
           delete(this.listener2);
           delete(this.listener3);
           delete(this.menu);
           delete(this.tab);
       end
    end
    
    methods (Access=private)

        % Listener for REDRAW events
        function Redraw(this,evnt)
            %disp('bdHilbert.Redraw()');

            % Get the current selector settings
            [xxxdef,xxxindx] = this.selector.Item();

            % if the solution (sol) has changed, or
            % if time slider value (tval) has changed, or
            % if the time step size (tstep) has changed, or
            % if the plot limit for our variable has changed
            % then redraw all plot lines.
            if evnt.sol || evnt.tval || evnt.tstep || evnt.tspan || evnt.(xxxdef)(xxxindx).lim
                this.RenderBackground();
                this.RenderForeground();
            end  
            
        end
        
        % Compute the Hilbert transform (of the selected state variable.
        % Returns the results in this.t, this.h and this.p.
        function [tindx0,tindx1] = ComputeHilbertPhases(this)
            % retrieve the relevant time series data via the selector
            [y,~,this.t,tindx0,tindx1] = this.selector.Trajectory();

            % ensure that y is not 3D format
            nt = numel(this.t);
            y = reshape(y,[],nt,1);
            
            % compute the Hilbert transform and its phase angles
            [this.h,this.p] = bdHilbert.hilbert(y);
                        
            % compute relative phases (if appropriate)
            switch this.menuRelPhase.Checked
                case 'on'
                    p0 = this.p(1,1);
                    this.p = this.p - this.p(1,:) + p0;
            end
        end
                
        % Render the background (grey) traces
        function RenderBackground(this)
            %disp('bdHilbert.RenderBackground()');
                        
            % elevation value (in radians)
            roll = this.elevationKnob.Value * pi/180 + pi;

            % update the cylinder mesh
            t0 = this.sysobj.tspan(1);
            t1 = this.sysobj.tspan(2);
            [X,Y,Z] = this.CylinderMesh(t0,t1,roll);
            this.mesh1.XData = X;
            this.mesh1.YData = Y;
            this.mesh1.ZData = Z;

            % update the opacity
            this.mesh1.FaceAlpha = this.opacityKnob.Value;
            this.mesh1.EdgeAlpha = this.opacityKnob.Value;

            % update the azimuth
            this.axes1.View(1) = -this.azimuthSlider.Value;
            
            % update the disc mesh
            [X,Y,Z] = this.DiscMesh(roll);
            this.mesh2.XData = X;
            this.mesh2.YData = Y;
            this.mesh2.ZData = Z;

            % retrieve the plot limits via the selector
            [~,ylim] = this.selector.lim();
            ylo = ylim(1);
            yhi = ylim(2);

            % Compute the Hilbert transform (this.t, this.h, this.p).
            [tindx0,tindx1] = this.ComputeHilbertPhases();

            % number of trajectories in our data
            ntheta = size(this.p,1);

            % number of background traces to plot (100 at most)
            ntraces = min(ntheta,100);

            % Update the warning label
            if ntraces < ntheta
                this.label1.Visible = 'on';
            else
                this.label1.Visible = 'off';
            end

            % Update the background traces (upper plot)
            if ntraces>1
                % indicies of the selected trajectories
                indx = round(linspace(1,ntheta,ntraces));

                % transient part of selected trajectories
                t0 = this.t(tindx0);
                theta0 = this.p(indx,tindx0) - roll;
                
                % non-transient part of selected trajectories
                t1 = this.t(tindx1);
                theta1 = this.p(indx,tindx1) - roll;
                
                % polar coords to X,Y,Z coords (transients)
                X0 = (ones(ntraces,1)*[t0 NaN])';
                Y0 = 0.9 * [cos(theta0), NaN(ntraces,1)]';
                Z0 = 0.9 * [sin(theta0), NaN(ntraces,1)]';
                
                % polar coords to X,Y,Z coords (non-transients)
                X1 = (ones(ntraces,1)*[t1 NaN])';
                Y1 = 0.9 * [cos(theta1), NaN(ntraces,1)]';
                Z1 = 0.9 * [sin(theta1), NaN(ntraces,1)]';

                % update background traces (use reverse Y direction)
                set(this.trace1a, 'XData',X0(:), 'YData',-Y0(:), 'ZData',Z0(:));                
                set(this.trace1b, 'XData',X1(:), 'YData',-Y1(:), 'ZData',Z1(:));                
            else
                set(this.trace1a, 'XData',NaN, 'YData',NaN, 'ZData',NaN);
                set(this.trace1b, 'XData',NaN, 'YData',NaN, 'ZData',NaN);
            end

            % visibility of transients
            this.trace1a.Visible = this.menuTransients.Checked;  
            
            % update the axes labels
            [~,~,name1] = this.selector.name();
            this.axes1.ZLabel.String = name1;
        end
        
        % Render the trajectories
        function RenderForeground(this)
            %disp('bdHilbert.RenderForeground()');
                  
            % elevation value (in radians)
            roll = this.elevationKnob.Value * pi/180 + pi;
            
            % get the selected subscripts and convert to an index
            [rindx,cindx] = this.selector.subscripts();
            [nr,nc] = this.selector.vsize();
            indx = sub2ind([nr,nc],rindx,cindx);
                    
            % get the phase of the selected time series (plus roll angle)
            theta = this.p(indx,:) - roll;
            
            % polar coords to X,Y,Z coords (upper plot)
            X = this.t;
            Y = cos(theta);
            Z = sin(theta);
            
            % polar coords to spiral (lower plot)
            if this.sysobj.backward
                R = linspace(0.5,1.5,numel(X));
            else
                R = linspace(1.5,0.5,numel(X));
            end
            Xr = R.*Y;
            Yr = R.*Z;

            % get the transient and non-transient parts of the time domain
            [tindx0,tindx1,ttindx] = this.sysobj.tindices(this.t);

            % update the time axes limits
            [tlim, ~, tlim1] = this.tlim(this.t,ttindx);
            switch this.menuTransients.Checked
                case 'on'
                    this.axes1.XLim = tlim + [-1e-9 1e-9];
                case 'off'
                    this.axes1.XLim = tlim1 + [-1e-9 1e-9];
            end
            
            % update the line plot data (upper plot)
            set(this.line1a,  'XData',X(tindx0), 'YData',-Y(tindx0), 'ZData',Z(tindx0));
            set(this.line1b,  'XData',X(tindx1), 'YData',-Y(tindx1), 'ZData',Z(tindx1));
                            
            % update the marker plot data (upper plot)
            set(this.marker1a, 'XData',X(1),      'YData',-Y(1),      'ZData',Z(1));
            set(this.marker1b, 'XData',X(ttindx), 'YData',-Y(ttindx), 'ZData',Z(ttindx));
            set(this.marker1c, 'XData',X(end),    'YData',-Y(end),    'ZData',Z(end));

            % update the line plot data (lower plot)
            set(this.line2a,  'XData',Xr(tindx0), 'YData',Yr(tindx0));
            set(this.line2b,  'XData',Xr(tindx1), 'YData',Yr(tindx1));

            % update the marker plot data (lower plot)
            set(this.marker2a, 'XData',Xr(1),      'YData',Yr(1));
            set(this.marker2b, 'XData',Xr(ttindx), 'YData',Yr(ttindx));
            set(this.marker2c, 'XData',Xr(end),    'YData',Yr(end));

            % visibilty of transients (upper plot)
            this.line1a.Visible = this.menuTransients.Checked;
            this.line2a.Visible = this.menuTransients.Checked;

            % visibility of markers (upper and lower plots)
            switch this.menuMarkers.Checked
                case 'on'
                    this.marker1a.Visible = this.menuTransients.Checked;
                    this.marker1b.Visible = 'on';
                    this.marker1c.Visible = 'on';
                    this.marker2a.Visible = this.menuTransients.Checked;
                    this.marker2b.Visible = 'on';
                    this.marker2c.Visible = 'on';
                case 'off'
                    this.marker1a.Visible = 'off';
                    this.marker1b.Visible = 'off';
                    this.marker1c.Visible = 'off';
                    this.marker2a.Visible = 'off';
                    this.marker2b.Visible = 'off';
                    this.marker2c.Visible = 'off';
            end
            
            % visibility of the time points (upper and lower plots)
            switch this.menuPoints.Checked
                case 'on'
                    set(this.line1a, 'Marker','.', 'MarkerSize',12);
                    set(this.line2a, 'Marker','.', 'MarkerSize',10);
                    set(this.line1b, 'Marker','.', 'MarkerSize',12);
                    set(this.line2b, 'Marker','.', 'MarkerSize',10);
                case 'off'
                    set(this.line1a, 'Marker','none');
                    set(this.line2a, 'Marker','none');
                    set(this.line1b, 'Marker','none');
                    set(this.line2b, 'Marker','none');
            end
            
            % update the time label
            this.axes1.XLabel.String = sprintf('time (dt=%g)',this.sysobj.tstep);
        end
          
        % Selector Changed callback
        function SelectorChanged(this)
            %disp('bdHilbert.SelectorChanged');
            this.RenderBackground();
            this.RenderForeground();
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        % Subscript Changed callback
        function SubscriptChanged(this)
            %disp('bdHilbert.SubscriptChanged');
            this.RenderForeground();
                        
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
         
        % Azimuth Changing callback
        function AzimuthChanging(this,src,evnt)
            %fprintf('%s.AzimuthChanging\n',mfilename);
            src.Value = evnt.Value;
            this.axes1.View(1) = -evnt.Value;
        end
        
        % Opacity Changing callback
        function OpacityChanging(this,src,evnt)
            %fprintf('%s.OpacityChanging\n',mfilename);
            src.Value = evnt.Value;
            this.mesh1.FaceAlpha = evnt.Value;
            this.mesh1.EdgeAlpha = evnt.Value;
        end
                
        % Elevation Changing callback
        function ElevationChanging(this,src,evnt)
            %fprintf('%s.ElevationChanging\n',mfilename);
            src.Value = evnt.Value;
            this.RenderBackground();
            this.RenderForeground();
        end
                
        % TRANSIENTS menu callback
        function callbackTransients(this,menuitem)
            % toggle the menu state
            this.MenuToggle(menuitem);
            
            % reset the time axes limits
            [~,~,ttindx,tdomain] = this.sysobj.tindices([]);
            [tlim, ~, tlim1] = this.tlim(tdomain,ttindx);
            switch this.menuTransients.Checked
                case 'on'
                    this.axes1.XLim = tlim + [-1e-9 1e-9];
                case 'off'
                    this.axes1.XLim = tlim1 + [-1e-9 1e-9];
            end
            this.RenderBackground();
            this.RenderForeground();
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
                
        % MARKERS menu callback
        function callbackMarkers(this,menuitem)
            this.MenuToggle(menuitem);
            this.RenderForeground();
                        
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        % POINTS menu callback
        function callbackPoints(this,menuitem)
            this.MenuToggle(menuitem);
            this.RenderForeground();
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
       
        % RELATIVE PHASE menu callback
        function callbackRelPhase(this,menuitem)
            this.MenuToggle(menuitem);
            this.RenderBackground();
            this.RenderForeground();
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
                
        % HOLD menu callback
        function callbackHold(this,menuitem)
            % Make new copies of the foreground plot lines
            l1a = copyobj(this.line1a, this.axes1);
            l1b = copyobj(this.line1b, this.axes1);
            l2a = copyobj(this.line2a, this.axes2);
            l2b = copyobj(this.line2b, this.axes2);
            
            % Convert the old foreground plot lines to 'Held'
            this.line1a.LineWidth = 1.5;
            this.line1b.LineWidth = 1.5;
            this.line1a.Color = [0.5 0.75 0.5];
            this.line1b.Color = [0.5 0.75 0.5];
            this.line1a.Tag = 'Held';
            this.line1b.Tag = 'Held';
            this.line1a.PickableParts = 'none';
            this.line1b.PickableParts = 'none';          
            this.line2a.LineWidth = 1.5;
            this.line2b.LineWidth = 1.5;
            this.line2a.Color = [0.5 0.75 0.5];
            this.line2b.Color = [0.5 0.75 0.5];
            this.line2a.Tag = 'Held';
            this.line2b.Tag = 'Held';
            this.line2a.PickableParts = 'none';
            this.line2b.PickableParts = 'none';
            
            % Replace the old with the new
            this.line1a = l1a;
            this.line1b = l1b;
            this.line2a = l2a;
            this.line2b = l2b;
            
             % The line markers now need to be promoted back to the top level.
             % We do that by constructing fresh copies and deleting the old ones.
             m1a = copyobj(this.marker1a, this.axes1);
             m1b = copyobj(this.marker1b, this.axes1);
             m1c = copyobj(this.marker1c, this.axes1);
             m2a = copyobj(this.marker2a, this.axes2);
             m2b = copyobj(this.marker2b, this.axes2);
             m2c = copyobj(this.marker2c, this.axes2);
             delete(this.marker1a);
             delete(this.marker1b);
             delete(this.marker1c);
             delete(this.marker2a);
             delete(this.marker2b);
             delete(this.marker2c);
             this.marker1a = m1a;
             this.marker1b = m1b;
             this.marker1c = m1c;
             this.marker2a = m2a;
             this.marker2b = m2b;
             this.marker2c = m2c;
        end
        
        % CLEAR menu callback
        function callbackClear(this)
            % delete all line plots in axes1 that have Tag='Held'
            objs = findobj(this.axes1,'Tag','Held');
            delete(objs);

            % delete all line plots in axes2 that have Tag='Held'
            objs = findobj(this.axes2,'Tag','Held');
            delete(objs);
            
            % delete all data tips in axes1
            objs = findobj(this.axes1,'Type','datatip');
            delete(objs);
            
            % delete all data tips in axes2
            objs = findobj(this.axes2,'Type','datatip');
            delete(objs);
        end
        
        % RESET menu callback
        function callbackReset(this)
            % reset the axes limits (upper plot)
            this.axes1.YLim = [-1.1 1.1];
            this.axes1.ZLim = [-1.1 1.1];

            % reset the time axes limits
            [~,~,ttindx,tdomain] = this.sysobj.tindices([]);
            [tlim, ~, tlim1] = this.tlim(tdomain,ttindx);
            switch this.menuTransients.Checked
                case 'on'
                    this.axes1.XLim = tlim + [-1e-9 1e-9];
                case 'off'
                    this.axes1.XLim = tlim1 + [-1e-9 1e-9];
            end
            
            % reset the azimuth (upper plot)
            this.axes1.View = [0 0]; 
            this.azimuthSlider.Value = 0;
            
            % reset the axes limits (lower plot)
            this.axes2.XLim = [-1.6 1.6];
            this.axes2.YLim = [-1.6 1.6];
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
                
        % Cylinder mesh coordinates
        function [X,Y,Z] = CylinderMesh(t0,t1,rot)
            n=32;
            m=32;
            theta = linspace(0,2*pi,n);
            X = ones(m,n).*linspace(t0,t1,m)';
            Y = 0.8*ones(m,1).* cos(theta+rot);
            Z = 0.8*ones(m,1).* sin(theta+rot);
        end
        
        % Disc mesh coordinates
        function [X,Y,Z] = DiscMesh(rot)
            n=32;
            m=8;
            theta = linspace(0,2*pi,n);
            radius = linspace(0.5,1.5,m)';
            X = radius.* cos(theta-rot);
            Y = radius.* sin(theta-rot);
            Z = zeros(m,n);
        end

        function optout = optcheck(opt)
            % check the format of incoming options and apply defaults to missing values
            optout.title         = bdPanelBase.GetOption(opt, 'title', 'Hilbert Phase');
            optout.transients    = bdPanelBase.GetOption(opt, 'transients', 'on');
            optout.markers       = bdPanelBase.GetOption(opt, 'markers', 'on');
            optout.points        = bdPanelBase.GetOption(opt, 'points', 'off');
            optout.relphase      = bdPanelBase.GetOption(opt, 'relphase', 'off');
            optout.selector      = bdPanelBase.GetOption(opt, 'selector', {1,1,1});
            optout.azimuth       = bdPanelBase.GetOption(opt, 'azimuth', 0);
            optout.elevation     = bdPanelBase.GetOption(opt, 'elevation', 0);
            optout.opacity       = bdPanelBase.GetOption(opt, 'opacity', 1);
            
            % safety limits
            optout.azimuth = min(optout.azimuth, 10);
            optout.azimuth = max(optout.azimuth,-10);
            optout.elevation = min(optout.elevation, 180);
            optout.elevation = max(optout.elevation,-180);
            optout.opacity = min(optout.opacity, 1);
            optout.opacity = max(optout.opacity, 0);
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning(sprintf('Ignoring unknown panel option ''bdHilbert.%s''',newfields{idx}));
            end
        end
        
        function [tlim, tlim0, tlim1] = tlim(tdomain,ttindx)
            if tdomain(1) < tdomain(end)
                % tdomain is forward
                tlim = tdomain([1 end]);
                tlim0 = tdomain([1 ttindx]);
                tlim1 = tdomain([ttindx end]);
            else
                % tdomain is reversed
                tlim = tdomain([end 1]);
                tlim0 = tdomain([ttindx 1]);
                tlim1 = tdomain([end ttindx]);
            end
        end
        
        function [H,P] = hilbert(Y)
            % Discrete-time anaytic signal via Hilbert Transform.
            %
            % Usage:
            %   [H,P] = bdHilbert.hilbert(Y)
            % where the real part of H is equivalent to the input signal Y
            % and the imaginary part of H is the Hilbert transform of Y.
            % The phase angles of H are returned in P.
            %
            % The algorithm [1] is similar to that used by the hilbert()
            % function provided with Matlab Signal Processing Toolbox
            % except that here it operates along the rows of Y instead
            % of the columns.
            %
            % [1] Marple S L "Computing the Discrete-Time Analytic Signal
            %     via FFT" IEEE Transactions on Signal Processing. Vol 47
            %     1999, pp 2600-2603.
            %
            % SEE ALSO
            %    hilbert
            
            % Fourier Transform along the rows of Y 
            Yfft = fft(Y,[],2);
            nfft = size(Yfft,2);
            halfn = ceil(nfft/2);

            % construct the multiplier matrix
            M = zeros(size(Yfft));
            if mod(nfft,2)
                % nfft is odd
                M(:,1) = 1;             % DC component
                M(:,2:halfn) = 2;       % positive frequencies
            else
                % nfft is even
                M(:,1) = 1;             % DC component
                M(:,2:halfn) = 2;       % positive frequencies
                M(:,halfn+1) = 1;       % Nyquist component
            end
            
            % Hilbert Transform
            H = ifft(Yfft.*M,[],2);
            
            % Return the phase angles (if requested)
            if nargout==2
                P = angle(H);
            end 
        end
    end
end

