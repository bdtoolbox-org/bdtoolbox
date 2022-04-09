classdef bdSpaceTime < bdPanelBase
    %bdSpaceTime Brain Dynamics GUI panel for space-time plots.
    %  The Space-Time panel plots the time trace of vector-valued dynamic 
    %  variables side-by-side as if they were arranged spatially.
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a-c,2018a,2019a,2020a,2021a)

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
        t                   double 
        y                   double
        surf0               matlab.graphics.primitive.Surface
        surf1               matlab.graphics.primitive.Surface
    end
    
    properties (Access=private)
        sysobj              bdSystem
        selector            bdSelector
        tab                 matlab.ui.container.Tab           
        dropdown            matlab.ui.control.DropDown
        menu                matlab.ui.container.Menu
        menuTransients      matlab.ui.container.Menu
        menuBlend           matlab.ui.container.Menu
        menuClip            matlab.ui.container.Menu        
        menuModulo          matlab.ui.container.Menu
        menuYDir            matlab.ui.container.Menu
        menuAutoStep        matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
        listener1           event.listener
        listener2           event.listener
    end
    
    methods
        function this = bdSpaceTime(tabgrp,sysobj,opt)
            %disp('bdSpaceTime');
            
            % remember the parents
            this.sysobj = sysobj;
                        
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','Space Time', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');
            
            % construct the CALIBRATE menu item
            uimenu(this.menu, ...
                'Label', 'Calibrate', ...
                'Tooltip', 'Calibrate the colour limits to fit the data', ...
                'Callback', @(~,~) this.callbackCalibrate() );
                        
            % construct the TRANSIENTS menu item
            this.menuTransients = uimenu(this.menu, ...
                'Label', 'Transients', ...
                'Checked', 'on', ...
                'Tag', 'transients', ...
                'Tooltip', 'Show the transient part of the trajectory', ...
                'Callback', @(src,~) this.callbackMenu(src) );

            % construct the BLEND menu item
            this.menuBlend = uimenu(this.menu, ...
                'Label', 'Blend', ...
                'Checked', 'off', ...
                'Tag', 'modulo', ...
                'Tooltip', 'Interpolated colour facets', ...            
                'Callback', @(src,~) this.callbackMenu(src) );
            
            % construct the CLIP menu item
            this.menuClip = uimenu(this.menu, ...
                'Label', 'Clipping', ...
                'Checked', 'off', ...
                'Tag', 'modulo', ...
                'Tooltip', 'Exclude data that is beyond the colour scale', ...            
                'Callback', @(src,~) this.callbackMenu(src) );
            
            % construct the MODULO menu item
            this.menuModulo = uimenu(this.menu, ...
                'Label', 'Modulo', ...
                'Checked', 'off', ...
                'Tag', 'modulo', ...
                'Tooltip', 'Wrap the colour scale at its limits', ...            
                'Callback', @(src,~) this.callbackMenu(src) );
                                               
            % construct the YDIR menu item
            this.menuYDir = uimenu(this.menu, ...
                'Label', 'YDir Reverse', ...
                'Checked', 'on', ...
                'Tag', 'YDir', ...
                'Tooltip', 'Reverse the direction of the y-axis', ...            
                'Callback', @(src,~) this.callbackMenu(src) );
            
            % construct the AUTOSTEP menu item
            this.menuAutoStep = uimenu(this.menu, ...
                'Label', 'Auto Steps', ...
                'Checked', 'on', ...
                'Tag', 'autostep', ...
                'Tooltip', 'Use the time steps chosen by the solver', ...
                'Callback', @(src,~) this.callbackMenu(src) );                                

            % construct the RESET menu item
            uimenu(this.menu, ...
                'Label', 'Reset', ...
                'Tooltip', 'Reset the view', ...            
                'Callback', @(src,~) this.callbackReset(src) );

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
            this.tab = uitab(tabgrp, 'Title','Space Time', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'1x','2x','1x'};
            GridLayout.RowHeight = {21,'1x'};
            GridLayout.RowSpacing = 10;
            GridLayout.Visible = 'off';

            % Create the selector object
            this.selector = bdSelector(sysobj,'vardef');
            
            % Create DropDown for the selector
            combo = this.selector.DropDown(GridLayout);
            combo.Layout.Row = 1;
            combo.Layout.Column = 1;

            % Create DropDown for the colormap
            this.dropdown = uidropdown(GridLayout);
            this.dropdown.Layout.Row = 1;
            this.dropdown.Layout.Column = 3;
            this.dropdown.Items = {'parula','jet','hsv','hot','cool','spring','summer','autumn','winter','gray','bone','copper','pink','lines','prism','flag','circular'};
            this.dropdown.ValueChangedFcn = @(~,~) this.ColorMapChanged();
            this.dropdown.Tooltip = 'Colour Map';
            
            % Create axes
            this.axes = uiaxes(GridLayout);
            this.axes.Layout.Row = 2;
            this.axes.Layout.Column = [1 3];
            this.axes.NextPlot = 'add';
            this.axes.XGrid = 'off';
            this.axes.YGrid = 'off';
            this.axes.Box = 'on';
            this.axes.CLim = this.selector.lim();
            this.axes.XLabel.String = 'time';
            this.axes.YLabel.String = 'space';
            this.axes.FontSize = 11;
            colorbar(this.axes);
            colormap(this.axes,this.dropdown.Value);

            % Customise the axes toolbars
            axtoolbar(this.axes,{'export','datacursor','rotate'});
            
            % Construct the surface mesh for the transients (using zero data)
            this.surf0 = pcolor(this.axes,zeros(2,2));
            this.surf0.LineStyle = 'none';
            this.surf0.Clipping = 'off';
            this.surf0.FaceAlpha = 0.25;
            
            % Construct the surface mesh for the non-transients (using zero data)
            this.surf1 = pcolor(this.axes,zeros(2,2));
            this.surf1.LineStyle = 'none';
            this.surf1.Clipping = 'off';

            % apply the custom options (and render the image)
            this.options = opt;

            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';

            % listen for SelectionChanged events
            this.listener1 = listener(this.selector,'SelectionChanged',@(src,evnt) this.SelectorChanged());
            
            % listen for Redraw events
            this.listener2 = listener(sysobj,'redraw',@(src,evnt) this.Redraw(evnt));
        end
        
        function opt = get.options(this)
            opt.title    = this.tab.Title;
            opt.transients = this.menuTransients.Checked;
            opt.yreverse = this.menuYDir.Checked;
            opt.blend    = this.menuBlend.Checked;
            opt.clipping = this.menuClip.Checked;
            opt.modulo   = this.menuModulo.Checked;
            opt.colormap = this.dropdown.Value;
            opt.autostep = this.menuAutoStep.Checked;
            opt.selector = this.selector.cellspec();
        end
        
        function set.options(this,opt)   
            % check the incoming options and apply defaults to missing values
             opt = this.optcheck(opt);
             
            % update the selector
            this.selector.SelectByCell(opt.selector);
             
            % update the colormap dropdown
            this.dropdown.Value = opt.colormap;

            % update the axes colormap
            colormap(this.axes,opt.colormap);

            % update the tab title
            this.tab.Title = opt.title;
            
            % update the menu title
            this.menu.Text = opt.title;
                        
            % update the TRANSIENTS menu
            this.menuTransients.Checked = opt.transients;

            % update the YDIR menu
            this.menuYDir.Checked = opt.yreverse;
            
            % update the BLEND menu
            this.menuBlend.Checked = opt.blend;
            
            % update the CLIP menu
            this.menuClip.Checked = opt.clipping;
            
            % update the MODULO menu
            this.menuModulo.Checked = opt.modulo;
            
            % update the AUTOSTEP menu
            this.menuAutoStep.Checked = opt.autostep;
            
            % Redraw everything
            this.Render();
            drawnow;
        end
        
        function delete(this)
           %disp('bdSpaceTime.delete()');
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods (Access=private)

        % Listener for REDRAW events
        function Redraw(this,evnt)
            %disp('bdSpaceTime.Redraw()');
            %disp(evnt)
       
            % Get the current selector settings
            [xxxdef,xxxindx] = this.selector.Item();
            
            % if the solution (sol) has changed, or
            % if time slider value (tval) has changed, or 
            % if the selected item's limit has changed then
            if evnt.sol || evnt.tval || evnt.(xxxdef)(xxxindx).lim
                this.Render();      % Render the data
            end              
        end
        
        function Render(this)
            %disp('bdSpaceTime.Render()');

            % evaluate the selected variable at the selected time point
            [this.y,~,this.t,tindx0,tindx1,ttindx] = this.selector.Trajectory('autostep',this.menuAutoStep.Checked);

            % ensure that y is not 3D format
            nt = numel(this.t);
            this.y = reshape(this.y,[],nt,1);
            nr = size(this.y,1);

            % get the plot limits for the selected variable
            [plim,lim] = this.selector.lim();
            [tlim, ~, tlim1] = this.tlim(this.t,ttindx);

            % modulo the data (if appropriate)
            switch this.menuModulo.Checked
                case 'on'
                    % modulo the data
                    lo = lim(1);
                    hi = lim(2);   
                    this.y = mod(this.y-lo, hi-lo) + lo;
                case 'off'
                    % nothing to do
            end
            
            % special case of scalar data
            if nr==1
                % update the pcolor surface data (transients)
                this.surf0.XData = this.t(tindx0);
                this.surf0.YData = [0 0.5 1];
                this.surf0.CData = this.y([1 1 1],tindx0);
                this.surf0.ZData = this.y([1 1 1],tindx0);

                % update the pcolor surface data (non-transients)
                this.surf1.XData = this.t(tindx1);
                this.surf1.YData = [0 0.5 1];
                this.surf1.CData = this.y([1 1 1],tindx1);
                this.surf1.ZData = this.y([1 1 1],tindx1);

                % update the axes limits
                this.axes.YLim = [0 1];
                this.axes.ZLim = plim;
                this.axes.CLim = plim;
            else
                % update the pcolor surface data (transients)
                this.surf0.XData = this.t(tindx0);
                this.surf0.YData = 1:nr;
                this.surf0.CData = this.y(1:nr,tindx0);
                this.surf0.ZData = this.y(1:nr,tindx0);

                % update the pcolor surface data (non-transients)
                this.surf1.XData = this.t(tindx1);
                this.surf1.YData = 1:nr;
                this.surf1.CData = this.y(1:nr,tindx1);
                this.surf1.ZData = this.y(1:nr,tindx1);

                % update the axes limits
                this.axes.YLim = [1 nr];
                this.axes.ZLim = plim;
                this.axes.CLim = plim;
            end
            
            % reverse the Y axis (or not)
            switch this.menuYDir.Checked
                case 'on'
                    this.axes.YDir = 'reverse';
                otherwise
                    this.axes.YDir = 'normal';
            end
            
            % blend the colour facets (or not)
            switch this.menuBlend.Checked
                case 'on'
                    this.surf0.FaceColor = 'interp';
                    this.surf1.FaceColor = 'interp';
                otherwise
                    this.surf0.FaceColor = 'flat';
                    this.surf1.FaceColor = 'flat';
            end
            
            % clip the colour scale (or not)
            this.surf0.Clipping = this.menuClip.Checked;
            this.surf1.Clipping = this.menuClip.Checked;
            
            % Visibilty of transients. Update time limits
            switch this.menuTransients.Checked
                case 'on'
                    this.surf0.Visible = 'on';
                    this.axes.XLim = tlim + [-1e-9 +1e-9];
                case 'off'
                    this.surf0.Visible = 'off';
                    this.axes.XLim = tlim1 + [-1e-9 0];
            end
            
            % Update the time label
            switch this.menuAutoStep.Checked
                case 'on'
                    this.axes.XLabel.String = 'time (dt=auto)';
                case 'off'
                    this.axes.XLabel.String = sprintf('time (dt=%g)',this.sysobj.tstep);
            end

            
        end        
                
        % Selector Changed callback
        function SelectorChanged(this)
            %disp('bdSpaceTime.selectorChanged');
            this.Render();                  % Render the data
        end
        
        % Colormap DropDown callback
        function ColorMapChanged(this)
            mapname = this.dropdown.Value;  % Get the selected colormap
            switch mapname
                case 'circular'
                    % apply custom colormap
                    x = linspace(-pi,pi,64);
                    b = 0.5*sin(x-pi/2)+0.5;
                    r = 0.5*sin(x+pi/2)+0.5;
                    g = r;
                    colormap(this.axes,[r',g',b']);
                otherwise
                    % apply standard colormap
                    colormap(this.axes,mapname);
            end
        end
                      
        % Generic callback for checked menus. Used by CLIP, BLEND, MODULO, YDIR, etc
        function callbackMenu(this,menuitem)
            this.MenuToggle(menuitem);      % Toggle the menu state
            this.Render();                  % Render the data
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
            this.selector.Calibrate(tspan);
                                     
            % redraw all panels (because the new limits apply to all panels)
            this.sysobj.NotifyRedraw([]);
        end
               
        % RESET menu callback
        function callbackReset(this,menuitem)
            %disp('callbackReset');
            
            % delete all data tips
            objs = findobj(this.axes,'Type','datatip');
            delete(objs);

            % reset the viewing angle
            this.axes.View = [0 90];
            
            % render the data
            this.Render();
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
                % The panel is undocked from the gui so we need to close its figure too. 
                delete(fig);
            end
        end
        

    end
    
    methods (Static)
        
        function optout = optcheck(opt)
            % check the format of incoming options and apply defaults to missing values
            optout.title      = bdPanelBase.GetOption(opt, 'title', 'Space Time');
            optout.transients = bdPanelBase.GetOption(opt, 'transients', 'on');            
            optout.yreverse   = bdPanelBase.GetOption(opt, 'yreverse', 'on');
            optout.blend      = bdPanelBase.GetOption(opt, 'blend', 'off');
            optout.clipping   = bdPanelBase.GetOption(opt, 'clipping', 'off');
            optout.modulo     = bdPanelBase.GetOption(opt, 'modulo', 'off');
            optout.colormap   = bdPanelBase.GetOption(opt, 'colormap', 'parula');
            optout.autostep   = bdPanelBase.GetOption(opt, 'autostep', 'on');
            optout.selector   = bdPanelBase.GetOption(opt, 'selector', {1,1,1});
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning('Ignoring unknown panel option ''bdSpaceTime.%s''',newfields{idx});
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
        
    end
end

