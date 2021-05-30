classdef bdBifurcation < bdPanelBase
    %bdBifurcation Display panel for plotting bifurcations
    %   
    %AUTHORS
    %Stewart Heitmann (2018a,2020a,2021a)   
    
    % Copyright (C) 2016-2021 QIMR Berghofer Medical Research Institute
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
        function this = bdBifurcation(tabgrp,sysobj,opt)
            %disp('bdBifurcation');
            
            % remember the parents
            this.sysobj = sysobj;
                        
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','Space Time', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');
                                    
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
                'Callback', @(~,~) this.callbackPoints() );
            
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

            % construct the CLEAR menu item
            uimenu(this.menu, ...
                'Label', 'Clear', ...
                'Tooltip', 'Clear the graphics', ...            
                'Callback', @(src,~) this.callbackClear() );

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
            this.tab = uitab(tabgrp, 'Title','Bifurcation', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'1x','1x','1x'};
            GridLayout.RowHeight = {21,'1x'};
            GridLayout.ColumnSpacing = 50;
            GridLayout.RowSpacing = 10;
            GridLayout.Visible = 'off';

            % Create the selector objects
            this.selectorX = bdSelector(sysobj,'pardef','lagdef');
            this.selectorY = bdSelector(sysobj,'vardef');
            
            % Create DropDown for selectorX
            combo = this.selectorX.DropDownCombo(GridLayout);
            combo.Layout.Row = 1;
            combo.Layout.Column = 3;
            
            % Create DropDown for selectorY
            combo = this.selectorY.DropDownCombo(GridLayout);
            combo.Layout.Row = 1;
            combo.Layout.Column = 1;
                        
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
            axtoolbar(this.axes,{'export','datacursor'});
                        
            % Construct the line plots (containing NaN)
            this.lineA = line(this.axes,NaN,NaN,'LineStyle','-','color',[0.8 0.8 0.8],'Linewidth',1,'MarkerSize',10);
            this.lineB = line(this.axes,NaN,NaN,'LineStyle','-','color','k','Linewidth',1.5,'MarkerSize',10);

            % Construct the markers
            this.markerA = line(this.axes,NaN,NaN,'Marker','h','color','k','Linewidth',1.00,'MarkerFaceColor','y','MarkerSize',10);
            this.markerB = line(this.axes,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor','w');
            this.markerC = line(this.axes,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor',[0.6 0.6 0.6]);            

            % apply the custom options (and render the image)
            this.options = opt;

            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';
            
            % listen for SelectionChanged events
            this.listener1 = listener([this.selectorX, this.selectorY],'SelectionChanged',@(src,evnt) this.SelectorChanged());
            
            % listen for Redraw events
            this.listener2 = listener(sysobj,'redraw',@(src,evnt) this.Redraw(evnt));
        end
        
        function opt = get.options(this)
            opt.title      = this.tab.Title;
            opt.transients = this.menuTransients.Checked;
            opt.markers     = this.menuMarkers.Checked;
            opt.points      = this.menuPoints.Checked;            
            opt.modulo     = this.menuModulo.Checked;
            opt.autostep   = this.menuAutoStep.Checked;
            opt.selectorX  = this.selectorX.cellspec();
            opt.selectorY  = this.selectorY.cellspec();
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
            
            % Redraw everything
            this.RenderBackground();
            this.RenderForeground();
            drawnow;
        end
        
        function delete(this)
           %disp('bdBifurcation.delete()');
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
            %disp('bdBifurcation.Redraw()');
            %disp(evnt)
            
            % Get the current selector settings
            [xxxdef,xxxindx] = this.selectorX.Item();
            [yyydef,yyyindx] = this.selectorY.Item();
            
            if evnt.(yyydef)(yyyindx).lim || evnt.(xxxdef)(xxxindx).lim
                this.RenderBackground();
            end
            
            if evnt.sol || evnt.tval || evnt.tstep || evnt.(yyydef)(yyyindx).lim || evnt.(xxxdef)(xxxindx).lim
                this.RenderForeground();
            end              
        end
        
        
        function RenderBackground(this)
            %disp('bdBifurcation.RenderBackground()');
                        
            % update the plot limits for the selected variables
            this.axes.XLim = this.selectorX.lim();
            this.axes.YLim = this.selectorY.lim();
            
            % update the axes labels for the selected variables
            [~,~,nameX] = this.selectorX.name();
            [~,~,nameY] = this.selectorY.name();
            this.axes.XLabel.String = nameX;
            this.axes.YLabel.String = nameY;
        end

        function RenderForeground(this)
            %disp('bdBifurcation.RenderForeground()');
            
            % Duplicate the non-transient line plot
            newline = copyobj(this.lineB,this.axes);
            this.lineB.Tag = 'remnant';
            this.lineB.Color = [0 0.5 0];
            this.lineB = newline;
            
            % limits of the selected variables
            [plimX,limX] = this.selectorX.lim();
            [plimY,limY] = this.selectorY.lim();

            % evaluate the selected variables
            [~,X,~,tindx0,tindx1,ttindx] = this.selectorX.Trajectory('autostep',this.menuAutoStep.Checked);
            [~,Y] = this.selectorY.Trajectory('autostep',this.menuAutoStep.Checked);

            % extract the transient and non-transient parts of the trajectory
            X0 = X(tindx0);  Y0 = Y(tindx0);
            X1 = X(tindx1);  Y1 = Y(tindx1);
            Xt = X(ttindx);  Yt = Y(ttindx);
            
            % modulo the trajectories (if appropriate)
            switch this.menuModulo.Checked
                case 'on'
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

            % test for fixed point
            X1dev = max(abs(X1(:) - X1(1)));
            Y1dev = max(abs(Y1(:) - Y1(1)));
            fixedpoint = (X1dev < 0.01*(plimX(2)-plimX(1))) && ...
                         (Y1dev < 0.01*(plimY(2)-plimY(1))) ;
                
            % show/hide the individual time points
            switch this.menuPoints.Checked
                case 'on'
                    this.lineA.Marker = '.';
                    this.lineB.Marker = '.';
                case 'off'
                    this.lineA.Marker = 'none';
                    this.lineB.Marker = 'none';
            end
            
            % fixed points need to be highlighted (regardless of menuPoints)
            if fixedpoint
                this.lineB.Marker = '.';
                this.lineB.LineStyle = 'none';
            else
                this.lineB.Marker = 'none';
                this.lineB.LineStyle = '-';
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
                        
        % Selector Changed callback
        function SelectorChanged(this)
            %disp('bdBifurcation.selectorChanged');
            this.RenderBackground();        % Render the background items
            this.RenderForeground();        % Render the foreground items
                        
            % delete remnant plot lines
            objs = findobj(this.axes,'Type','line','Tag','remnant');
            delete(objs);
        end
                              
        % Generic callback for checked menus. Used by TRANSIENTS, MARKERS, etc
        function callbackMenu(this,menuitem)
            this.MenuToggle(menuitem);      % Toggle the menu state
            this.RenderBackground();        % Render the background items
            this.RenderForeground();        % Render the foreground items
        end
              
        % POINTS menu callback
        function callbackPoints(this)
            % Toggle the menu state
            this.MenuToggle(this.menuPoints);
                        
            % Update markers on the remnant plot lines
            objs = findobj(this.axes,'Type','line','Tag','remnant');
            switch this.menuPoints.Checked
                case 'on'
                    for idx=1:numel(objs)
                        switch objs(idx).LineStyle
                            case 'none'
                                % This line object is a fixed point. Leave its marker alone.
                            otherwise
                                % This line object is a trajectory. Change its marker to dot.
                                objs(idx).Marker = '.';
                        end
                    end
                case 'off'
                    for idx=1:numel(objs)
                        switch objs(idx).LineStyle
                            case 'none'
                                % This line object is a fixed point. Leave its marker alone.
                            otherwise
                                % This line object is a trajectory. Remove its marker.
                                objs(idx).Marker = 'none';
                        end
                    end
            end

            % Update markers on the current plot line
            switch this.menuPoints.Checked
                case 'on'
                    this.lineB.Marker = '.';
                case 'off'
                    this.lineB.Marker = 'none';
            end
        end
        
        % CLEAR menu callback
        function callbackClear(this)
            %disp('callbackClear');
            
            % delete all data tips
            objs = findobj(this.axes,'Type','datatip');
            delete(objs);

            % delete remnant plot lines
            objs = findobj(this.axes,'Type','line','Tag','remnant');
            delete(objs);
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
            optout.title      = bdPanelBase.GetOption(opt, 'title', 'Bifurcation');
            optout.transients = bdPanelBase.GetOption(opt, 'transients', 'on');   
            optout.markers    = bdPanelBase.GetOption(opt, 'markers', 'on');            
            optout.points     = bdPanelBase.GetOption(opt, 'points', 'off');                        
            optout.modulo     = bdPanelBase.GetOption(opt, 'modulo', 'off');
            optout.autostep   = bdPanelBase.GetOption(opt, 'autostep', 'on');
            optout.selectorX  = bdPanelBase.GetOption(opt, 'selectorX', {1,1,1});
            optout.selectorY  = bdPanelBase.GetOption(opt, 'selectorY', {1,1,1});
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning('Ignoring unknown panel option ''bdBifurcation.%s''',newfields{idx});
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

            % insert NaN at each discontnuity by copying each segment
            % into the output with gaps between them.
            n = numel(x);
            xout = NaN(1,n+dcount);
            yout = NaN(1,n+dcount);
            i0 = 1;                 % beginning of segment in the output vector
            i1 = 1;                 % beginnning of segment in the input vector
            for i2 = di             % for the end of each segment in the input vector
                indx1 = i1:i2;          % indexes of the segment in the input vector
                indx0 = (i1:i2)-i1+i0;  % indexes of the segment in the output vector
                xout(indx0) = x(indx1); % copy the segment contents
                yout(indx0) = y(indx1); % copy the segment contents                
                i1 = indx1(end)+1;      % beginning of the next segment in the input vector
                i0 = indx0(end)+2;      % beginning of the next segment in the output vector
            end
        end
                
    end
end

