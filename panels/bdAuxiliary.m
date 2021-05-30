classdef bdAuxiliary < bdPanelBase
    %bdAuxiliary Display panel for plotting model-specific functions
    % 
    %AUTHORS
    %  Stewart Heitmann (2018a,2018b,2020a,2021a)

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
        UserData            struct
    end
    
    properties (Access=private)
        sysobj              bdSystem
        tab                 matlab.ui.container.Tab    
        dropdown            matlab.ui.control.DropDown
        label               matlab.ui.control.Label
        menu                matlab.ui.container.Menu
        menuHold            matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu     
        listener1           event.listener
    end
    
    methods
        function this = bdAuxiliary(tabgrp,sysobj,opt)
            %disp('bdAuxiliary');
            
            % remember the parents
            this.sysobj = sysobj;
                        
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','Space Time', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');
            
            % construct the HOLD menu item
            this.menuHold = uimenu(this.menu, ...
                'Label', 'Hold All', ...
                'Tooltip', 'Hold the graphics', ...            
                'Callback', @(~,~) this.callbackHold() );
                                    
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
            this.tab = uitab(tabgrp, 'Title','Auxiliary', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'1x','2x'};
            GridLayout.RowHeight = {21,'1x'};
            GridLayout.ColumnSpacing = 50;
            GridLayout.RowSpacing = 10;
            GridLayout.Visible = 'off';

            % Create DropDown widget
            this.dropdown = uidropdown(GridLayout);
            this.dropdown.Layout.Row = 1;
            this.dropdown.Layout.Column = 1;
            this.dropdown.Items = {};
            this.dropdown.ItemsData = {};
            this.dropdown.Value = {};
            this.dropdown.ValueChangedFcn = @(~,~) this.dropdownChanged();
                     
            % Create Label widget
            this.label = uilabel(GridLayout);
            this.label.Layout.Row = 1;
            this.label.Layout.Column = 2;
            this.label.Text = 'No Auxiliary plot functions defined';
            this.label.VerticalAlignment = 'center';
            this.label.HorizontalAlignment = 'right';
            this.label.FontWeight = 'normal'; 
            this.label.FontColor = 'r';

            % Create axes
            this.axes = uiaxes(GridLayout);
            this.axes.Layout.Row = 2;
            this.axes.Layout.Column = [1 2];
            this.axes.NextPlot = 'add';
            this.axes.XGrid = 'off';
            this.axes.YGrid = 'off';
            this.axes.Box = 'on';
            this.axes.FontSize = 11;
                        
            % apply the custom options
            this.options = opt;
            
            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';
            
            % listen for Redraw events
            this.listener1 = listener(sysobj,'redraw',@(src,evnt) this.Redraw(evnt));
        end
        
        function opt = get.options(this)
            opt.title      = this.tab.Title;
            opt.hold       = this.menuHold.Checked;
            opt.auxfun     = this.dropdown.ItemsData;
        end
        
        function set.options(this,opt)   
            % check the incoming options and apply defaults to missing values
            opt = this.optcheck(opt);
             
            % update the tab title
            this.tab.Title = opt.title;
            
            % update the menu title
            this.menu.Text = opt.title;
            
            % update the HOLD menu
            this.menuHold.Checked = opt.hold;
            
            % update the dropdown menu for the auxiliary functions
            nitems = numel(opt.auxfun);
            if nitems>0
                Items = cell(nitems,1);
                for indx=1:nitems
                    Items{indx} = func2str(opt.auxfun{indx});
                end
                this.dropdown.Items = Items;
                this.dropdown.ItemsData = opt.auxfun;
                this.dropdown.Enable = 'on';
                this.label.Visible = 'off';
            else
                this.dropdown.Items = {};
                this.dropdown.ItemsData = {};
                this.dropdown.Value = {};
                this.dropdown.Enable = 'off';
                this.label.Visible = 'on';
            end

            % Redraw everything
            this.Render();
        end
        
        function delete(this)
           %disp('bdAuxiliary.delete()');
           delete(this.listener1);
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods (Access=private)

        % Listener for REDRAW events
        function Redraw(this,evnt)
            %disp('bdAuxiliary.Redraw()');
            if evnt.sol || evnt.tval
                this.Render();
            end              
        end
        
        function Render(this)
            %disp('Render');
            
            % get the currently selected plot function
            auxfun  = this.dropdown.Value;
            if isempty(auxfun)
                return          % nothing more to do
            end
            
            % if 'hold' menu is not checked then clear the axes
            switch this.menuHold.Checked
                case 'off'
                    cla(this.axes);
                    this.axes.NextPlot = 'add';
            end

            % Execute the auxiliary plot function according to the solver type
            switch this.sysobj.solvertype
                case 'odesolver'
                    % case of an ODE solver (eg ode45)
                    parcell = {this.sysobj.pardef.value};
                    if nargout(auxfun)==0
                        auxfun(this.axes,this.sysobj.tval,this.sysobj.sol,parcell{:});
                    else
                        this.UserData = auxfun(this.axes,this.sysobj.tval,this.sysobj.sol,parcell{:});
                    end

                case 'ddesolver'
                    % case of a DDE solver (eg dde23)
                    lagcell = {this.sysobj.lagdef.value};
                    parcell = {this.sysobj.pardef.value};
                    allcell = {lagcell{:} parcell{:}};
                    if nargout(auxfun)==0
                        auxfun(this.axes,this.sysobj.tval,this.sysobj.sol,allcell{:});
                    else
                        this.UserData = auxfun(this.axes,this.sysobj.tval,this.sysobj.sol,allcell{:});
                    end

                case 'sdesolver'
                    % case of an SDE solver
                    parcell = {this.sysobj.pardef.value};
                    if nargout(auxfun)==0
                        auxfun(this.axes,this.sysobj.tval,this.sysobj.sol,parcell{:});
                    else
                        this.UserData = auxfun(this.axes,this.sysobj.tval,this.sysobj.sol,parcell{:});
                    end                    
            end        

        end
        
        % Callback for DROPDOWN widget
        function dropdownChanged(this)
            %disp('dropdownChanged');
            this.Render();
        end
                                
        % Callback for HOLD menu
        function callbackHold(this)
            % Toggle the menu state
            this.MenuToggle(this.menuHold);
            
            % Render the data
            this.Render();
        end
              
        
        % CLEAR menu callback
        function callbackClear(this)
            %disp('callbackClear');
            cla(this.axes)
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
            optout.title = bdPanelBase.GetOption(opt, 'title', 'Auxiliary');
            optout.hold  = bdPanelBase.GetOption(opt, 'hold', 'off');
            if isfield(opt,'auxfun')
                optout.auxfun = opt.auxfun;
            else
                optout.auxfun = function_handle.empty();
            end
            %optout.selectorX  = bdPanelBase.GetOption(opt, 'selectorX', {1,1,1});
            %optout.selectorY  = bdPanelBase.GetOption(opt, 'selectorY', {1,1,1});
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning('Ignoring unknown panel option ''bdAuxiliary.%s''',newfields{idx});
            end
        end
        
    end
end

