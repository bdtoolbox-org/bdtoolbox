classdef bdCorrPanel < bdPanelBase
    %bdCorrPanel Display panel for plotting linear correlations in bdGUI
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a,2017c,2018a,2019a,2020a,2021a)

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
        Rimage              matlab.graphics.primitive.Image
        t                   % Time points at which the data was sampled (1 x t)
        Y                   % The sampled data points (n x t)
        R                   % Matrix of correlation cooefficients (n x n)
    end
    
    properties (Access=private)
        sysobj              bdSystem
        selector            bdSelector
        tab                 matlab.ui.container.Tab           
        label1              matlab.ui.control.Label
        label2              matlab.ui.control.Label
        textNaN             matlab.graphics.primitive.Text
        Rtable              matlab.ui.control.Table
        menu                matlab.ui.container.Menu
        menuTransients      matlab.ui.container.Menu
        menuDataTable       matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
        listener1           event.listener
        listener2           event.listener
    end
    
    methods
        function this = bdCorrPanel(tabgrp,sysobj,opt)
            %disp('bdCorrPanel');
            
            % remember the parents
            this.sysobj = sysobj;
                        
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','Space 2D', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');
            
            % construct the TRANSIENTS menu item
            this.menuTransients = uimenu(this.menu, ...
                'Label', 'Transients', ...
                'Checked', 'on', ...
                'Tag', 'transients', ...
                'Tooltip', 'Include the transient part of the trajectory in the correlation', ...
                'Callback', @(src,~) this.callbackMenu(src) );
                                               
            % construct the DataTable menu item
            this.menuDataTable = uimenu(this.menu, ...
                'Label', 'Table', ...
                'Checked', 'off', ...
                'Tag', 'table', ...
                'Tooltip', 'Show the coefficients as a table', ...
                'Callback', @(~,~) this.callbackTable() );

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
            this.tab = uitab(tabgrp, 'Title','Correlation', 'Tag',this.menu.Tag);
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

            % Create label1
            this.label1 = uilabel(GridLayout);
            this.label1.Layout.Row = 1;
            this.label1.Layout.Column = 2;
            this.label1.Text = 'corcoeff(?)';
            this.label1.VerticalAlignment = 'bottom';
            this.label1.HorizontalAlignment = 'center';
            this.label1.FontWeight = 'bold';            
            this.label1.FontSize = 14;
                        
            % Create label2
            this.label2 = uilabel(GridLayout);
            this.label2.Layout.Row = 1;
            this.label2.Layout.Column = 3;
            this.label2.Text = 'Excludes Transients';
            this.label2.VerticalAlignment = 'bottom';
            this.label2.HorizontalAlignment = 'center';
            this.label2.FontWeight = 'normal';            

            % Create axes
            this.axes = uiaxes(GridLayout);
            this.axes.Layout.Row = 2;
            this.axes.Layout.Column = [1 3];
            this.axes.NextPlot = 'add';
            this.axes.XGrid = 'off';
            this.axes.YGrid = 'off';
            this.axes.YDir = 'reverse';
            this.axes.Box = 'on';
            this.axes.CLim = [-1 1];
            this.axes.FontSize = 11;
            colorbar(this.axes);
            
            % construct a custom color map
            cmapG = [linspace(0,1,32)'; linspace(1,1,32)'];
            cmapB = [linspace(0,1,32)'; linspace(1,0,32)'];
            cmapR = [linspace(1,1,32)'; linspace(1,0,32)'];
            this.axes.Colormap = [cmapR, cmapG, cmapB];

            % Customise the axes toolbars
            axtoolbar(this.axes,{'export','datacursor'});
            
            % Create the image
            this.Rimage = image(this.axes,[]);
            this.Rimage.CDataMapping = 'scaled';
            
            % Construct the NaN text
            this.textNaN = text(this.axes,1,1,'NaN');
            this.textNaN.FontSize = 14;
            this.textNaN.VerticalAlignment = 'bottom';
            this.textNaN.HorizontalAlignment = 'left';
            
            % Construct the data table
            this.Rtable = uitable(GridLayout);
            this.Rtable.Layout.Row = 2;
            this.Rtable.Layout.Column = [1 3];
            this.Rtable.ColumnName = 'numbered';
            this.Rtable.RowName = 'numbered';
            this.Rtable.ColumnEditable = false;
            this.Rtable.ColumnFormat = {'LONGG'};
            this.Rtable.Visible = 'off';

            % apply the custom options (and render the data)
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
            opt.title      = this.tab.Title;
            opt.transients = this.menuTransients.Checked;
            opt.table      = this.menuDataTable.Checked;
            opt.selector   = this.selector.cellspec();
        end
        
        function set.options(this,opt)   
            % check the incoming options and apply defaults to missing values
             opt = this.optcheck(opt);
             
            % update the selector
            this.selector.SelectByCell(opt.selector);
             
            % update the tab title
            this.tab.Title = opt.title;
            
            % update the menu title
            this.menu.Text = opt.title;
                        
            % update the TRANSIENTS menu
            this.menuTransients.Checked = opt.transients;
            
            % update the TABLE menu
            this.menuDataTable.Checked = opt.table;

            % Redraw everything
            this.Render();
            drawnow;
        end
        
        function delete(this)
           %disp('bdCorrPanel.delete()');
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods (Access=private)

        % Listener for REDRAW events
        function Redraw(this,evnt)
            %disp('bdCorrPanel.Redraw()');
       
            % If Transients='on' then we compute the correlations
            % across the entire time span of the solution.
            % If Transients='off' then we only compute correlations
            % for the non-transient part of the solution.
            switch this.menuTransients.Checked
                case 'on'
                    % If the solution has changed then ....
                    if evnt.sol
                        this.Render();      % Render the data
                    end
                otherwise
                    % If the solution has changed, or
                    % if the time slider has changed then ....
                    if evnt.sol || evnt.tval
                        this.Render();      % Render the data
                    end
            end              
        end
        
        function Render(this)
            %disp('bdCorrPanel.Render()');
            
            % Evaluate the selected variable at fixed time steps.
            [Y,~,tdomain,tindx0,tindx1,ttindx] = this.selector.Trajectory('autostep','off');

            % Ensure that Y is not 3D format
            Y = reshape(Y,[],numel(tdomain),1);

            % Name of the selected variable
            name = this.selector.name();
            this.label1.Text = ['corcoeff(',name,')'];
            
            % If Transients='on' then we compute the correlations
            % across the entire time span of the solution.
            % If Transients='off' then we only compute correlations
            % for the non-transient part of the solution.
            switch this.menuTransients.Checked
                case 'on'
                    this.t = tdomain;
                    this.Y = Y;
                    this.label2.Text = 'Includes Transients';
                case 'off'
                    this.t = tdomain(tindx1);
                    this.Y = Y(:,tindx1);
                    this.label2.Text = 'Excludes Transients';
            end                    
            
            % compute the correlation coefficients
            this.R = corrcoef(this.Y');
           
            % update the cross-correlation matrix (image)
            this.Rimage.CData = this.R;
            this.axes.XLim = [0.5 size(this.R,1)+0.5];
            this.axes.YLim = [0.5 size(this.R,1)+0.5];
            
            % clean up the Tick labels if n is small.
            n = size(this.R,1);
            if n<=20
                this.axes.XTick = 1:n;
                this.axes.YTick = 1:n;
            else
                this.axes.XTickMode = 'auto';
                this.axes.YTickMode = 'auto';
            end

            % update the NaN warning text
            if any(isnan(this.R))
                this.textNaN.Visible = 'on';
            else
                this.textNaN.Visible = 'off';
            end
            this.textNaN.Position = [1,n,0];
            
            % update the data table
            this.Rtable.Data = this.R;
        end        
                
        % Selector Changed callback
        function SelectorChanged(this)
            %disp('bdCorrPanel.selectorChanged');
            this.Render();
        end
                              
        % Generic callback for menus with Checked states
        function callbackMenu(this,menuitem)
            this.MenuToggle(menuitem);      % Toggle the menu state
            this.Render();                  % Render the data
        end
        
        % TABLE menu callback
        function callbackTable(this)
            % Toggle the menu state
            this.MenuToggle(this.menuDataTable);
            switch this.menuDataTable.Checked
                case 'on'
                    this.Rimage.Visible = 'off';
                    this.Rtable.Visible = 'on';
                otherwise
                    this.Rimage.Visible = 'on';
                    this.Rtable.Visible = 'off';
            end
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
            optout.title      = bdPanelBase.GetOption(opt, 'title', 'Correlation');
            optout.transients = bdPanelBase.GetOption(opt, 'transients', 'on');
            optout.table      = bdPanelBase.GetOption(opt, 'table', 'off');
            optout.selector   = bdPanelBase.GetOption(opt, 'selector', {1,1,1});
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning('Ignoring unknown panel option ''bdCorrPanel.%s''',newfields{idx});
            end
        end
        
    end
end

