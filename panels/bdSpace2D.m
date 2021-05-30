classdef bdSpace2D < bdPanelBase
    %bdSpace2D Brain Dynamics GUI panel for 2D spatial plots.
    %  The Space2D panel plots a snapshot of a matrix-based (2D) state variable.
    %
    %AUTHORS
    %  Stewart Heitmann (2018b,2020a,2021a)

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
        img                 matlab.graphics.primitive.Image
        cdata               double
    end
    
    properties (Access=private)
        sysobj              bdSystem
        selector            bdSelector
        tab                 matlab.ui.container.Tab           
        label               matlab.ui.control.Label
        dropdown            matlab.ui.control.DropDown
        menu                matlab.ui.container.Menu
        menuModulo          matlab.ui.container.Menu
        menuYDir            matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
        listener1           event.listener
        listener2           event.listener
    end
    
    methods
        function this = bdSpace2D(tabgrp,sysobj,opt)
            %disp('bdSpace2D');
            
            % remember the parents
            this.sysobj = sysobj;
                        
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','Space 2D', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');
            
            % construct the CALIBRATE menu item
            uimenu(this.menu, ...
                'Label', 'Calibrate', ...
                'Tooltip', 'Calibrate the colour limits to fit the data', ...
                'Callback', @(~,~) this.callbackCalibrate() );
            
            % construct the MODULO menu item
            this.menuModulo = uimenu(this.menu, ...
                'Label', 'Modulo', ...
                'Checked', 'off', ...
                'Tag', 'modulo', ...
                'Tooltip', 'Wrap the colour scale at its limits', ...            
                'Callback', @(src,~) this.callbackModulo(src) );
                                               
            % construct the YDIR menu item
            this.menuYDir = uimenu(this.menu, ...
                'Label', 'YDir Reverse', ...
                'Checked', 'on', ...
                'Tag', 'YDir', ...
                'Tooltip', 'Reverse the direction of the y-axis', ...            
                'Callback', @(src,~) this.callbackYDir(src) );

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
            this.tab = uitab(tabgrp, 'Title','Space 2D', 'Tag',this.menu.Tag);
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

            % Create time label
            this.label = uilabel(GridLayout);
            this.label.Layout.Row = 1;
            this.label.Layout.Column = 2;
            this.label.Text = 't=?';
            this.label.VerticalAlignment = 'bottom';
            this.label.HorizontalAlignment = 'center';
            this.label.FontWeight = 'bold';            
            this.label.FontSize = 14;
            
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
            this.axes.XLabel.String = 'space';
            this.axes.YLabel.String = 'space';
            this.axes.FontSize = 11;
            colorbar(this.axes);
            colormap(this.axes,this.dropdown.Value);

            % Customise the axes toolbars
            axtoolbar(this.axes,{'export','datacursor'});
            
            % Create the image
            this.img = image(this.axes,[]);
            this.img.CDataMapping = 'scaled';
            
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
            opt.title = this.tab.Title;
            opt.modulo = this.menuModulo.Checked;
            opt.yreverse = this.menuYDir.Checked;
            opt.colormap = this.dropdown.Value;
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
                        
            % update the YDIR menu
            this.menuYDir.Checked = opt.yreverse;
            
            % update the MODULO menu
            this.menuModulo.Checked = opt.modulo;
            
            % Redraw everything
            this.Render();
            drawnow;
        end
        
        function delete(this)
           %disp('bdSpace2D.delete()');
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods (Access=private)

        % Listener for REDRAW events
        function Redraw(this,evnt)
            %disp('bdSpace2D.Redraw()');
            %disp(evnt)
       
            % Get the current selector settings
            [xxxdef,xxxindx] = this.selector.Item();
            
            % If the selected item's limit has changed then
            if evnt.(xxxdef)(xxxindx).lim
                % Update the axes color limits
                this.axes.CLim = this.selector.lim();
            end  

            % if the solution (sol) has changed, or
            % if time slider value (tval) has changed then ....
            if evnt.sol || evnt.tval
                % Render the image data
                this.Render();
            end              
        end
        
        function Render(this)
            %disp('bdSpace2D.Render()');

            % get the time slider value
            tval = this.sysobj.tval;
                        
            % evaluate the selected variable at the selected time point
            this.cdata = this.selector.Eval(tval);
            
            % modulo the data (if appropriate)
            switch this.menuModulo.Checked
                case 'on'
                    % get the plot limits for the selected variable
                    [~,lim] = this.selector.lim();
                    % modulo the cdata
                    lo = lim(1);
                    hi = lim(2);   
                    this.cdata = mod(this.cdata-lo, hi-lo) + lo;
                case 'off'
                    % nothing to do
            end
            
            % update the image contents
            this.img.CData = this.cdata;

            % update the axes limits
            [nr,nc] = size(this.cdata);
            this.axes.XLim = [0.5 nc];
            this.axes.YLim = [0.5 nr];
            
            % reverse the Y axis (or not)
            switch this.menuYDir.Checked
                case 'on'
                    this.axes.YDir = 'reverse';
                otherwise
                    this.axes.YDir = 'normal';
            end
            
            % update the title
            this.label.Text = sprintf('t=%g',tval);
        end        
                
        % Selector Changed callback
        function SelectorChanged(this)
            %disp('bdSpace2D.selectorChanged');
            this.Render();
        end
        
        % Colormap DropDown callback
        function ColorMapChanged(this)
            % Get the selected colormap
            mapname = this.dropdown.Value;
            
            % Apply it to the axes
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
                      
        % CALIBRATE menu callback
        function callbackCalibrate(this)
            % get the time slider value
            tval = this.sysobj.tval;
                        
            % evaluate the selected variable at the selected time point
            data = this.selector.Eval(tval);
            
            % find the min and max data values (in the absence of modulo)
            cmin = min(data(:));
            cmax = max(data(:));
            
            % update the limits
            this.selector.lim([cmin cmax]);
             
            % redraw all panels (because the new limits apply to all panels)
            this.sysobj.NotifyRedraw([]);
        end
               
        % MODULO menu callback
        function callbackModulo(this,menuitem)
            % update the menu state
            this.MenuToggle(menuitem);
            % render the data
            this.Render();
        end
        
        % YDIR menu callback
        function callbackYDir(this,menuitem)
            % Toggle the menu state
            this.MenuToggle(menuitem);
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
                % The panel is undocked from the gui. Its figure should be closed too. 
                delete(fig);
            end
        end
        

    end
    
    methods (Static)
        
        function optout = optcheck(opt)
            % check the format of incoming options and apply defaults to missing values
            optout.title    = bdPanelBase.GetOption(opt, 'title', 'Space 2D');
            optout.modulo   = bdPanelBase.GetOption(opt, 'modulo', 'off');
            optout.yreverse = bdPanelBase.GetOption(opt, 'yreverse', 'on');
            optout.colormap = bdPanelBase.GetOption(opt, 'colormap', 'parula');
            optout.selector = bdPanelBase.GetOption(opt, 'selector', {1,1,1});
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning('Ignoring unknown panel option ''bdSpace2D.%s''',newfields{idx});
            end
        end
        
    end
end

