classdef bdTimePortrait < bdPanelBase
    %bdTimePortrait Display panel for plotting time series data in bdGUI.
    %  The panel includes an upper and lower axes which independently plot
    %  the time traces of selected variables.
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a,2017b,2017c,2019a,2020a)

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
        axes1               matlab.ui.control.UIAxes
        axes2               matlab.ui.control.UIAxes
    end
    
    properties (Access=private)
        sysobj              bdSystem
        selector1           bdSelector
        selector2           bdSelector
        
        tab                 matlab.ui.container.Tab           
        menu                matlab.ui.container.Menu
        menuTransients      matlab.ui.container.Menu
        menuMarkers         matlab.ui.container.Menu
        menuPoints          matlab.ui.container.Menu
        menuModulo          matlab.ui.container.Menu
        menuAutoStep        matlab.ui.container.Menu
        menuHoldAll         matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
        
        label1              matlab.ui.control.Label
        
        trace1a             matlab.graphics.primitive.Line
        trace1b             matlab.graphics.primitive.Line
        trace2a             matlab.graphics.primitive.Line
        trace2b             matlab.graphics.primitive.Line
        
        line1a              matlab.graphics.primitive.Line
        line1b              matlab.graphics.primitive.Line
        line2a              matlab.graphics.primitive.Line
        line2b              matlab.graphics.primitive.Line
        
        marker1a            matlab.graphics.primitive.Line
        marker1b            matlab.graphics.primitive.Line
        marker1c            matlab.graphics.primitive.Line
        marker2a            matlab.graphics.primitive.Line
        marker2b            matlab.graphics.primitive.Line
        marker2c            matlab.graphics.primitive.Line

        listener1
        listener2
        listener3
        listener4
        listener5
    end
    
    methods
        function this = bdTimePortrait(tabgrp,sysobj,opt)
            %disp('bdTimePortrait');
            
            % remember the parents
            this.sysobj = sysobj;
                        
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','Time Portrait', ...
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
                'Callback', @(~,~) this.callbackTransients() );
            
            % construct the MARKERS menu item
            this.menuMarkers = uimenu(this.menu, ...
                'Label', 'Markers', ...
                'Checked', 'on', ...
                'Tag', 'markers', ...
                'Tooltip', 'Show the trajectory markers', ...               
                'Callback', @(~,~) this.callbackMarkers() );
            
            % construct the POINTS menu item
            this.menuPoints = uimenu(this.menu, ...
                'Label', 'Time Points', ...
                'Checked', 'off', ...
                'Tag', 'points', ...
                'Tooltip', 'Show individual time points', ...            
                'Callback', @(~,~) this.callbackPoints() );
            
            % construct the MODULO menu item
            this.menuModulo = uimenu(this.menu, ...
                'Label', 'Modulo', ...
                'Checked', 'off', ...
                'Tag', 'modulo', ...
                'Tooltip', 'Modulo (wrap) lines at the boundary', ...            
                'Callback', @(~,~) this.callbackModulo() );

            % construct the AUTOSTEP menu item
            this.menuAutoStep = uimenu(this.menu, ...
                'Label', 'Auto Steps', ...
                'Checked', 'on', ...
                'Tag', 'autostep', ...
                'Tooltip', 'Use the time steps chosen by the solver', ...
                'Callback', @(~,~) this.callbackAutostep() );
                                    
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
            this.tab = uitab(tabgrp, 'Title','Time Portrait', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'1x','2x','1x'};
            GridLayout.RowHeight = {21,'1x','1x'};
            GridLayout.RowSpacing = 10;
            GridLayout.Visible = 'off';

            % construct the selectors
            this.selector1 = bdSelector(sysobj,'vardef');
            this.selector2 = bdSelector(sysobj,'vardef');

            % Create DropDownCombo for selector1
            combo1 = this.selector1.DropDownCombo(GridLayout);
            combo1.Layout.Row = 1;
            combo1.Layout.Column = 1;

            % Create DropDownCombo for selector2
            combo2 = this.selector2.DropDownCombo(GridLayout);
            combo2.Layout.Row = 1;
            combo2.Layout.Column = 3;

            % Create label1
            this.label1 = uilabel(GridLayout);
            this.label1.Layout.Row = 1;
            this.label1.Layout.Column = 2;
            this.label1.Text = 'Not all traces are shown';
            this.label1.VerticalAlignment = 'center';
            this.label1.HorizontalAlignment = 'center';
            this.label1.FontColor = [0.5 0.5 0.5];
            this.label1.Visible = 'off';

            % Create axes1
            this.axes1 = uiaxes(GridLayout);
            this.axes1.Layout.Row = 2;
            this.axes1.Layout.Column = [1 3];
            this.axes1.NextPlot = 'add';
            this.axes1.XLabel.String = 'time';
            %this.axes1.Title.String = 'Time Portrait';
            this.axes1.FontSize = 11;            
            this.axes1.XGrid = 'off';
            this.axes1.YGrid = 'off';
            this.axes1.Box = 'on';
            this.axes1.XLim = sysobj.tspan;
            this.axes1.YLim = this.selector1.lim();
            
            % Create axes2
            this.axes2 = uiaxes(GridLayout);
            this.axes2.Layout.Row = 3;
            this.axes2.Layout.Column = [1 3];
            this.axes2.NextPlot = 'add';
            this.axes2.XLabel.String = 'time';
            this.axes2.FontSize = 11;
            this.axes2.XGrid = 'off';
            this.axes2.YGrid = 'off';
            this.axes2.Box = 'on';
            this.axes2.XLim = sysobj.tspan;
            this.axes2.YLim = this.selector2.lim();              

            % Customise the axes toolbars
            axtoolbar(this.axes1,{'export','restoreview'});
            axtoolbar(this.axes2,{'export','restoreview'});
            
            % Construct background traces (containing NaN)
            this.trace1a = line(this.axes1,NaN,NaN, 'LineStyle','-', 'color',[0.8 0.8 0.8], 'Linewidth',0.5, 'PickableParts','none');
            this.trace1b = line(this.axes1,NaN,NaN, 'LineStyle','-', 'color',[0.8 0.8 0.8], 'Linewidth',0.5, 'PickableParts','none');
            this.trace2a = line(this.axes2,NaN,NaN, 'LineStyle','-', 'color',[0.8 0.8 0.8], 'Linewidth',0.5, 'PickableParts','none');
            this.trace2b = line(this.axes2,NaN,NaN, 'LineStyle','-', 'color',[0.8 0.8 0.8], 'Linewidth',0.5, 'PickableParts','none');
            
            % Construct the line plots (containing NaN)
            this.line1a = line(this.axes1,NaN,NaN,'LineStyle','-','color',[0.8 0.8 0.8],'Linewidth',1);
            this.line1b = line(this.axes1,NaN,NaN,'LineStyle','-','color','k','Linewidth',1.5);
            this.line2a = line(this.axes2,NaN,NaN,'LineStyle','-','color',[0.8 0.8 0.8],'Linewidth',1);
            this.line2b = line(this.axes2,NaN,NaN,'LineStyle','-','color','k','Linewidth',1.5);

            % Construct the markers
            this.marker1a = line(this.axes1,NaN,NaN,'Marker','h','color','k','Linewidth',1.00,'MarkerFaceColor','y','MarkerSize',10);
            this.marker1b = line(this.axes1,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor','w');
            this.marker1c = line(this.axes1,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor',[0.6 0.6 0.6]);
            this.marker2a = line(this.axes2,NaN,NaN,'Marker','h','color','k','Linewidth',1.00,'MarkerFaceColor','y','MarkerSize',10);
            this.marker2b = line(this.axes2,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor','w');
            this.marker2c = line(this.axes2,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor',[0.6 0.6 0.6]);
                     
            % apply the custom options (and reder the data)
            this.options = opt;

            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';
                       
            % listen for Redraw events
            this.listener1 = listener(sysobj,'redraw',@(src,evnt) this.Redraw(evnt));

            % listen for SelectionChanged events
            this.listener2 = listener(this.selector1,'SelectionChanged',@(src,evnt) this.SelectorChanged());
            this.listener3 = listener(this.selector2,'SelectionChanged',@(src,evnt) this.SelectorChanged());
            
            % listen for SubscriptChanged events
            this.listener4 = listener(this.selector1,'SubscriptChanged',@(src,evnt) this.SubscriptChanged());
            this.listener5 = listener(this.selector2,'SubscriptChanged',@(src,evnt) this.SubscriptChanged());
        end
        
        function opt = get.options(this)
            opt.title      = this.tab.Title;
            opt.transients = this.menuTransients.Checked;
            opt.markers    = this.menuMarkers.Checked;
            opt.points     = this.menuPoints.Checked;
            opt.modulo     = this.menuModulo.Checked;
            opt.autostep   = this.menuAutoStep.Checked;
            opt.hold       = this.menuHoldAll.Checked;
            opt.selector1  = this.selector1.cellspec();
            opt.selector2  = this.selector2.cellspec();
        end
        
        function set.options(this,opt)   
            % check the incoming options and apply defaults to missing values
            opt = bdTimePortrait.optcheck(opt);
         
            % update the selectors
            this.selector1.SelectByCell(opt.selector1);
            this.selector2.SelectByCell(opt.selector2);
             
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
            
            % update the HOLD ALL menu
            this.menuHoldAll.Checked = opt.hold;
            
            % Redraw everything
            this.RenderBackground();
            this.RenderForeground();
            drawnow;
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        function delete(this)
           %disp('bdTimePortrait.delete()');
           delete(this.listener1);
           delete(this.listener2);
           delete(this.listener3);
           delete(this.listener4);
           delete(this.listener5);
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods (Access=private)

        % Listener for REDRAW events
        function Redraw(this,evnt)
            %disp('bdTimePortrait.Redraw()');

            % Get the current selector settings
            [~,xxxindx1] = this.selector1.Item();
            [~,xxxindx2] = this.selector2.Item();

            % if the solution (sol) has changed, or
            % if time slider value (tval) has changed, or
            % if the time step size (tstep) has changed
            % then redraw all plot lines.
            if evnt.sol || evnt.tval || evnt.tstep || evnt.vardef(xxxindx1).lim || evnt.vardef(xxxindx2).lim
                this.RenderBackground();
                this.RenderForeground();
            end  
            
            % if the plot limit of the selected variable has changed
            % then adjust the YLim of the axes.
            if evnt.vardef(xxxindx1).lim
                this.axes1.YLim = this.selector1.lim();     % upper axes
            end
            if evnt.vardef(xxxindx2).lim
                this.axes2.YLim = this.selector2.lim();     % lower axes
            end            
            
            % if the time span has changed then adjust the XLim of the axes
            if evnt.tspan
                % calculate the plot limits of the time domain
                tlim = this.sysobj.tspan;
                if tlim(1) > tlim(2)
                    tlim = tlim([2 1]);
                end
                
                % apply the new plot limits
                this.axes1.XLim = tlim + [-1e-9 1e-9];
                this.axes2.XLim = tlim + [-1e-9 1e-9];
            end
        end
        
        % Render the background traces
        function RenderBackground(this)
            %disp('bdTimePortrait.RenderBackground()');
            if isvalid(this.tab)         
                % retrieve the relevant time series data via the selectors
                [y1,~,tdomain,tindx0,tindx1] = this.selector1.Trajectory('autostep',this.menuAutoStep.Checked);
                [y2] = this.selector2.Trajectory('autostep',this.menuAutoStep.Checked);
            
                % ensure that y1 and y2 are not 3D format
                nt = numel(tdomain);
                y1 = reshape(y1,[],nt,1);
                y2 = reshape(y2,[],nt,1);

                % size of our data
                ny1 = size(y1,1);      % number of trajectories in y1
                ny2 = size(y2,1);      % number of trajectories in y2
                
                % Determine the number of background traces (100 at most)
                ntrace1 = min(ny1,100);
                ntrace2 = min(ny2,100);
                
                % Update the warning label
                if (ntrace1 < ny1) || (ntrace2 < ny2)
                    this.label1.Visible = 'on';
                else
                    this.label1.Visible = 'off';
                end
                
                % Update the background traces (upper plot)
                if ntrace1>1
                    % indicies of the selected trajectories
                    yindx1 = round(linspace(1,ny1,ntrace1));
                                       
                    % plot limits via the selector
                    [~,lim1] = this.selector1.lim();

                    % collate the transients into a single trace separated by NaN
                    xtrace1a = (ones(ntrace1,1)*[tdomain(tindx0) NaN])';
                    ytrace1a = [y1(yindx1,tindx0), NaN(ntrace1,1)]';
                    xtrace1a = reshape(xtrace1a,1,[]);
                    ytrace1a = reshape(ytrace1a,1,[]);
                    
                    % collate the non-transients into a single trace separated by NaN
                    xtrace1b = (ones(ntrace1,1)*[tdomain(tindx1) NaN])';
                    ytrace1b = [y1(yindx1,tindx1), NaN(ntrace1,1)]';
                    xtrace1b = reshape(xtrace1b,1,[]);
                    ytrace1b = reshape(ytrace1b,1,[]);

                    % modulo the traces (if approppriate)
                    switch this.menuModulo.Checked
                        case 'on'
                            % modulo the transients
                            [xtrace1a,ytrace1a] = this.modulus(xtrace1a,ytrace1a,lim1);

                            % modulo the non-transients
                            [xtrace1b,ytrace1b] = this.modulus(xtrace1b,ytrace1b,lim1);
                    end
                    
                    % update the line data (upper plot)
                    this.trace1a.XData = xtrace1a;
                    this.trace1a.YData = ytrace1a;
                    
                    % update the line data (lower plot)
                    this.trace1b.XData = xtrace1b;
                    this.trace1b.YData = ytrace1b;
                else
                    this.trace1a.XData = NaN;
                    this.trace1a.YData = NaN;
                    this.trace1b.XData = NaN;
                    this.trace1b.YData = NaN;
                end

                % Update the background traces (lower plot)
                if ntrace2>1
                    % indicies of the selected trajectories
                    yindx2 = round(linspace(1,ny2,ntrace2));
                                    
                    % plot limits via the selector
                    [~,lim2] = this.selector2.lim();

                    % collate the transients into a single trace separated by NaN
                    xtrace2a = (ones(ntrace2,1)*[tdomain(tindx0) NaN])';
                    ytrace2a = [y2(yindx2,tindx0), NaN(ntrace2,1)]';
                    xtrace2a = reshape(xtrace2a,1,[]);
                    ytrace2a = reshape(ytrace2a,1,[]);
                    
                    % collate the non-transients into a single trace separated by NaN
                    xtrace2b = (ones(ntrace2,1)*[tdomain(tindx1) NaN])';
                    ytrace2b = [y2(yindx2,tindx1), NaN(ntrace2,1)]';
                    xtrace2b = reshape(xtrace2b,1,[]);
                    ytrace2b = reshape(ytrace2b,1,[]);

                    % modulo the traces (if appropriate)
                    switch this.menuModulo.Checked
                        case 'on'
                            % modulo the transients
                            [xtrace2a,ytrace2a] = this.modulus(xtrace2a,ytrace2a,lim2);
                            
                            % modulo the non-transients
                            [xtrace2b,ytrace2b] = this.modulus(xtrace2b,ytrace2b,lim2);
                    end
                    
                    % update the line data
                    set(this.trace2a, 'XData',xtrace2a, 'YData',ytrace2a);                
                    set(this.trace2b, 'XData',xtrace2b, 'YData',ytrace2b);                    
                else
                    set(this.trace2a, 'XData',NaN, 'YData',NaN);
                    set(this.trace2b, 'XData',NaN, 'YData',NaN);
                end
                
                % visibilty of transients
                this.trace1a.Visible = this.menuTransients.Checked;
                this.trace2a.Visible = this.menuTransients.Checked;
            end
        end
        
        % Render the trajectories
        function RenderForeground(this)
            %disp('bdTimePortrait.RenderForeground()');
            if isvalid(this.tab)
                
                % hold the graphics (if required)
                switch this.menuHoldAll.Checked
                    case 'on'
                        this.callbackHold();
                end
                
                % retrieve the time series data via the selectors
                [~,ysub1,tdomain,tindx0,tindx1,ttindx] = this.selector1.Trajectory('autostep',this.menuAutoStep.Checked);
                [~,ysub2] = this.selector2.Trajectory('autostep',this.menuAutoStep.Checked);
                
                % retrieve plot limits via the selectors
                [plim1,lim1] = this.selector1.lim();
                [plim2,lim2] = this.selector2.lim();
                
                % construct the plot line data (Xline1a, Yline1a, etc)
                switch this.menuModulo.Checked
                    case 'on'
                        % modulo the trajectories (upper plot)
                        [Xline1a,Yline1a] = this.modulus(tdomain(tindx0),ysub1(tindx0),lim1);
                        [Xline1b,Yline1b] = this.modulus(tdomain(tindx1),ysub1(tindx1),lim1);

                        % modulo the trajectories (lower plot)
                        [Xline2a,Yline2a] = this.modulus(tdomain(tindx0),ysub2(tindx0),lim2);
                        [Xline2b,Yline2b] = this.modulus(tdomain(tindx1),ysub2(tindx1),lim2);

                        % modulo the markers (upper plot)
                        [Xmarker1a,Ymarker1a] = this.modulus(tdomain(1),ysub1(1),lim1);
                        [Xmarker1b,Ymarker1b] = this.modulus(tdomain(ttindx),ysub1(ttindx),lim1);
                        [Xmarker1c,Ymarker1c] = this.modulus(tdomain(end),ysub1(end),lim1);

                        % modulo the markers (lower plot)
                        [Xmarker2a,Ymarker2a] = this.modulus(tdomain(1),ysub2(1),lim2);
                        [Xmarker2b,Ymarker2b] = this.modulus(tdomain(ttindx),ysub2(ttindx),lim2);
                        [Xmarker2c,Ymarker2c] = this.modulus(tdomain(end),ysub2(end),lim2);
                        
                    otherwise
                        % continuous trajectories (upper plot)
                        Xline1a = tdomain(tindx0);      % transient part
                        Yline1a = ysub1(tindx0);
                        Xline1b = tdomain(tindx1);      % non-transient part
                        Yline1b = ysub1(tindx1);

                        % continuous trajectories (lower plot)
                        Xline2a = tdomain(tindx0);      % transient part
                        Yline2a = ysub2(tindx0);
                        Xline2b = tdomain(tindx1);      % non-transient part
                        Yline2b = ysub2(tindx1);

                        % markers (upper plot)
                        Xmarker1a = tdomain(1);         % hexagon marker
                        Ymarker1a = ysub1(1);
                        Xmarker1b = tdomain(ttindx);    % open circle marker
                        Ymarker1b = ysub1(ttindx);
                        Xmarker1c = tdomain(end);       % closed circle marker
                        Ymarker1c = ysub1(end);

                        % markers (lower plot)
                        Xmarker2a = tdomain(1);         % hexagon marker
                        Ymarker2a = ysub2(1);
                        Xmarker2b = tdomain(ttindx);    % open circle marker
                        Ymarker2b = ysub2(ttindx);
                        Xmarker2c = tdomain(end);       % closed circle marker
                        Ymarker2c = ysub2(end);
                end
                
                % update the line plot data
                set(this.line1a,  'XData',Xline1a, 'YData',Yline1a);
                set(this.line1b,  'XData',Xline1b, 'YData',Yline1b);
                set(this.line2a,  'XData',Xline2a, 'YData',Yline2a);
                set(this.line2b,  'XData',Xline2b, 'YData',Yline2b);

                % update the marker plot data
                set(this.marker1a, 'XData',Xmarker1a,  'YData',Ymarker1a);
                set(this.marker1b, 'XData',Xmarker1b,  'YData',Ymarker1b);
                set(this.marker1c, 'XData',Xmarker1c,  'YData',Ymarker1c);
                set(this.marker2a, 'XData',Xmarker2a,  'YData',Ymarker2a);
                set(this.marker2b, 'XData',Xmarker2b,  'YData',Ymarker2b);
                set(this.marker2c, 'XData',Xmarker2c,  'YData',Ymarker2c);

                % visibilty of transients
                this.line1a.Visible = this.menuTransients.Checked;
                this.line2a.Visible = this.menuTransients.Checked;
 
                % adjust the vertical plot limits
                this.axes1.YLim = plim1;
                this.axes2.YLim = plim2;                                            

                % visibility of markers
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
                               
                % Adjust the plot time limit when the transients are hidden 
                switch this.menuTransients.Checked
                    case 'on'
                        % do nothing
                    case 'off'
                        % calculate the plot limits of the time domain
                        [~, ~, tlim1] = this.tlim(tdomain,ttindx);

                        % apply the new plot limits
                        this.axes1.XLim = tlim1 + [-1e-9 1e-9];
                        this.axes2.XLim = tlim1 + [-1e-9 1e-9];
                end
                
                switch this.menuPoints.Checked
                    case 'on'
                        set(this.line1a, 'Marker','.', 'MarkerSize',10);
                        set(this.line2a, 'Marker','.', 'MarkerSize',10);
                        set(this.line1b, 'Marker','.', 'MarkerSize',10);
                        set(this.line2b, 'Marker','.', 'MarkerSize',10);
                    case 'off'
                        set(this.line1a, 'Marker','none');
                        set(this.line2a, 'Marker','none');
                        set(this.line1b, 'Marker','none');
                        set(this.line2b, 'Marker','none');
                end

                % update the vertical axes labels
                [~,~,name1] = this.selector1.name();
                [~,~,name2] = this.selector2.name();
                this.axes1.YLabel.String = name1;
                this.axes2.YLabel.String = name2;
                                           
                % update the time labels
                switch this.menuAutoStep.Checked
                    case 'on'
                        this.axes1.XLabel.String = 'time (dt=auto)';
                        this.axes2.XLabel.String = 'time (dt=auto)';
                    case 'off'
                        this.axes1.XLabel.String = sprintf('time (dt=%g)',this.sysobj.tstep);
                        this.axes2.XLabel.String = sprintf('time (dt=%g)',this.sysobj.tstep);
                end

            end
        end
                
        % Selector Changed callback
        function SelectorChanged(this)
            %disp('bdTimePortrait.Selector1Changed');
            this.RenderBackground();
            this.RenderForeground();
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        % SubscriptChangedCallback
        function SubscriptChanged(this)
            %disp('bdTimePortrait.SubscriptChanged');
            this.RenderForeground();
                        
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
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
            
            % Calibrate the vardef limits via the selectors
            this.selector1.Calibrate(tspan);
            this.selector2.Calibrate(tspan);
                
            % redraw all panels (because the new limits apply to all panels)
            this.sysobj.NotifyRedraw([]);
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
            
            % reset the vertical axes limits
            this.axes1.YLim = this.selector1.lim();
            this.axes2.YLim = this.selector2.lim();

            % reset the time axes limits
            [~,~,ttindx,tdomain] = this.sysobj.tindices([]);
            [tlim, ~, tlim1] = this.tlim(tdomain,ttindx);
            switch this.menuTransients.Checked
                case 'on'
                    this.axes1.XLim = tlim + [-1e-9 1e-9];
                    this.axes2.XLim = tlim + [-1e-9 1e-9];
                case 'off'
                    this.axes1.XLim = tlim1 + [-1e-9 1e-9];
                    this.axes2.XLim = tlim1 + [-1e-9 1e-9];
            end
        end
        
        % TRANSIENTS menu callback
        function callbackTransients(this)
            % toggle the menu state
            this.MenuToggle(this.menuTransients);
            
            % reset the time axes limits
            [~,~,ttindx,tdomain] = this.sysobj.tindices([]);
            [tlim, ~, tlim1] = this.tlim(tdomain,ttindx);
            switch this.menuTransients.Checked
                case 'on'
                    this.axes1.XLim = tlim + [-1e-9 1e-9];
                    this.axes2.XLim = tlim + [-1e-9 1e-9];
                case 'off'
                    this.axes1.XLim = tlim1 + [-1e-9 1e-9];
                    this.axes2.XLim = tlim1 + [-1e-9 1e-9];
            end
            this.RenderBackground();
            this.RenderForeground();
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
                
        % MARKERS menu callback
        function callbackMarkers(this)
            this.MenuToggle(this.menuMarkers);
            this.RenderForeground();
                        
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        % POINTS menu callback
        function callbackPoints(this)
            this.MenuToggle(this.menuPoints);
            this.RenderForeground();
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
       
        % MODULO menu callback
        function callbackModulo(this)
            this.MenuToggle(this.menuModulo);
            this.RenderBackground();
            this.RenderForeground();
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        % AUTOSTEP menu callback
        function callbackAutostep(this)
            this.MenuToggle(this.menuAutoStep);
            this.RenderBackground();
            this.RenderForeground();
                        
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        % HOLD menu callback
        function callbackHold(this)
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
        
        % HOLD ALL menu callback
        function callbackHoldAll(this)
            this.MenuToggle(this.menuHoldAll);
                         
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
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
            
            % Push the new settings onto the UNDO stack
            notify(sysobj,'push');            
        end
        
    end
    
    methods (Static)
        
        function optout = optcheck(opt)
            % check the format of incoming options and apply defaults to missing values
            optout.title         = bdPanelBase.GetOption(opt, 'title', 'Time Portrait');
            optout.transients    = bdPanelBase.GetOption(opt, 'transients', 'on');
            optout.markers       = bdPanelBase.GetOption(opt, 'markers', 'on');
            optout.points        = bdPanelBase.GetOption(opt, 'points', 'off');
            optout.modulo        = bdPanelBase.GetOption(opt, 'modulo', 'off');
            optout.autostep      = bdPanelBase.GetOption(opt, 'autostep', 'on');
            optout.hold          = bdPanelBase.GetOption(opt, 'hold', 'off');
            optout.selector1     = bdPanelBase.GetOption(opt, 'selector1', {1,1,1});
            optout.selector2     = bdPanelBase.GetOption(opt, 'selector2', {2,1,1});
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning(sprintf('Ignoring unknown panel option ''bdTimePortrait.%s''',newfields{idx}));
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

        function [tout,yout] = modulus(t,y,ylim)
            % modulo the values in y to force ylo<y<yhi
            span = ylim(2) - ylim(1);
            y = mod(y-ylim(1),span) + ylim(1);
                
            % find the discontinuities in y
            d = 2*abs(diff(y)) > span;
            dcount = sum(d);
            
            % convert the logical indexes into numerical indexes
            di = find([d,1]);

            % insert NaN at each discontnuity by copying each segment
            % into the output with gaps between them.
            n = numel(t);
            tout = NaN(1,n+dcount);
            yout = NaN(1,n+dcount);
            i0 = 1;                 % beginning of segment in the output vector
            i1 = 1;                 % beginnning of segment in the input vector
            for i2 = di             % for the end of each segment in the input vector
                indx1 = i1:i2;          % indexes of the segment in the input vector
                indx0 = (i1:i2)-i1+i0;  % indexes of the segment in the output vector
                tout(indx0) = t(indx1); % copy the segment contents
                yout(indx0) = y(indx1); % copy the segment contents                
                i1 = indx1(end)+1;      % beginning of the next segment in the input vector
                i0 = indx0(end)+2;      % beginning of the next segment in the output vector
            end
        end
    end
end

