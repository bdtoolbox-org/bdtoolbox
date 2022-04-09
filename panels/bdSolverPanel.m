classdef bdSolverPanel < bdPanelBase
    %bdSolverPanel Display panel for solver options in bdGUI.
    %   The solver panel allows the user to modify the various options
    %   for the solver algorithm, such as the error tolerances and step
    %   size control.
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a,2018a,2020a,2021a)

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
        axes1               matlab.ui.control.UIAxes
        axes2               matlab.ui.control.UIAxes
    end
    
    properties (Access=private)
        sysobj              bdSystem
        tab                 matlab.ui.container.Tab           
        menu                matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
        AbsTol              matlab.ui.control.EditField
        RelTol              matlab.ui.control.EditField
        InitialStep         matlab.ui.control.EditField
        MaxStep             matlab.ui.control.EditField

        line1               matlab.graphics.primitive.Line
        line2               matlab.graphics.primitive.Line
                    
        listener1           event.listener
    end
    
    methods
        function this = bdSolverPanel(tabgrp,sysobj,opt)
            %disp('bdSolverPanel');
            
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
                'Tooltip', 'Calibrate the axes1 to fit the data', ...
                'Callback', @(~,~) this.callbackCalibrate() );
                                    
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
            this.tab = uitab(tabgrp, 'Title','Solver', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'1x','1x','1x','1x','1x'};
            GridLayout.RowHeight = {'1x','1x',21,21};
            GridLayout.ColumnSpacing = 10;
            GridLayout.RowSpacing = 0;
            GridLayout.Visible = 'off';

            % Create axes1
            this.axes1 = uiaxes(GridLayout);
            this.axes1.Layout.Row = 1;
            this.axes1.Layout.Column = [1 5];
            this.axes1.NextPlot = 'add';
            this.axes1.XGrid = 'on';
            this.axes1.YGrid = 'on';
            this.axes1.Box = 'on';
            this.axes1.FontSize = 11;
            this.axes1.XLabel.String = ' ';
            this.axes1.YLabel.String = 'norm dY';
            axtoolbar(this.axes1,{});
            
            % Create axes2
            this.axes2 = uiaxes(GridLayout);
            this.axes2.Layout.Row = 2;
            this.axes2.Layout.Column = [1 5];
            this.axes2.NextPlot = 'add';
            this.axes2.XGrid = 'on';
            this.axes2.YGrid = 'on';
            this.axes2.Box = 'on';
            this.axes2.FontSize = 11;
            this.axes2.XLabel.String = 'time';
            this.axes2.YLabel.String = 'time step (dt)';
            axtoolbar(this.axes2,{});
            
            % Construct the line plots (containing NaN)
            this.line1 = line(this.axes1,NaN,NaN,'color','k','Linewidth',1);
            this.line2 = line(this.axes2,NaN,NaN,'color','k','Linewidth',1);
                        
            % Construct ABSTOL label
            label = uilabel(GridLayout);
            label.Layout.Row = 3;
            label.Layout.Column = 1;
            label.Text = 'AbsTol';
            label.HorizontalAlignment = 'center';
            
            % Construct ABSTOL edit box
            this.AbsTol = uieditfield(GridLayout);
            this.AbsTol.Layout.Row = 4;
            this.AbsTol.Layout.Column = 1;
            this.AbsTol.HorizontalAlignment = 'center';
            this.AbsTol.ValueChangedFcn = @(src,~) callbackEditField(this,src,'AbsTol');

            % Construct RELTOL label
            label = uilabel(GridLayout);
            label.Layout.Row = 3;
            label.Layout.Column = 2;
            label.Text = 'RelTol';
            label.HorizontalAlignment = 'center';
            
            % Construct RELTOL edit box
            this.RelTol = uieditfield(GridLayout);
            this.RelTol.Layout.Row = 4;
            this.RelTol.Layout.Column = 2;
            this.RelTol.HorizontalAlignment = 'center';
            this.RelTol.ValueChangedFcn = @(src,~) callbackEditField(this,src,'RelTol');
   
            % Construct INITIALSTEP label
            label = uilabel(GridLayout);
            label.Layout.Row = 3;
            label.Layout.Column = 4;
            label.Text = 'InitialStep';
            label.HorizontalAlignment = 'center';

            % Construct INITIALSTEP edit box
            this.InitialStep = uieditfield(GridLayout);
            this.InitialStep.Layout.Row = 4;
            this.InitialStep.Layout.Column = 4;
            this.InitialStep.HorizontalAlignment = 'center';
            this.InitialStep.Enable = 'off';
            
            % Construct MAXSTEP label
            label = uilabel(GridLayout);
            label.Layout.Row = 3;
            label.Layout.Column = 5;
            label.Text = 'MaxStep';
            label.HorizontalAlignment = 'center';
            
            % Construct MAXSTEP edit box
            this.MaxStep = uieditfield(GridLayout);
            this.MaxStep.Layout.Row = 4;
            this.MaxStep.Layout.Column = 5;
            this.MaxStep.HorizontalAlignment = 'center';
            this.MaxStep.ValueChangedFcn = @(src,~) callbackEditField(this,src,'MaxStep');
            
            % initialise the edit box values
            switch this.sysobj.solvertype
                case 'odesolver'
                    this.AbsTol.Value = num2str(odeget(this.sysobj.odeoption,'AbsTol'));
                    this.RelTol.Value = num2str(odeget(this.sysobj.odeoption,'RelTol'));
                    this.InitialStep.Value = num2str(this.sysobj.tstep);
                    this.MaxStep.Value = num2str(odeget(this.sysobj.odeoption,'MaxStep'));
                case 'ddesolver'
                    this.AbsTol.Value = num2str(odeget(this.sysobj.ddeoption,'AbsTol'));
                    this.RelTol.Value = num2str(odeget(this.sysobj.ddeoption,'RelTol'));
                    this.InitialStep.Value = num2str(this.sysobj.tstep);
                    this.MaxStep.Value = num2str(odeget(this.sysobj.ddeoption,'MaxStep'));
                case 'sdesolver'
                    this.AbsTol.Value = num2str(odeget(this.sysobj.sdeoption,'AbsTol'));
                    this.RelTol.Value = num2str(odeget(this.sysobj.sdeoption,'RelTol'));
                    this.InitialStep.Value = num2str(this.sysobj.tstep);
                    this.MaxStep.Value = num2str(odeget(this.sysobj.sdeoption,'MaxStep'));
            end          
            
            % apply the custom options (and render the image)
            this.options = opt;

            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';

            % render the data
            this.Render();
            
            % listen for Redraw events
            this.listener1 = listener(sysobj,'redraw',@(src,evnt) this.Redraw(evnt));            
        end
        
        function opt = get.options(this)
            opt.title = this.tab.Title;
        end
        
        function set.options(this,opt)   
            % check the incoming options and apply defaults to missing values
            opt = this.optcheck(opt);

            % update the tab title
            this.tab.Title = opt.title;
            
            % update the menu title
            this.menu.Text = opt.title;
                                    
            % Redraw everything
            this.Render();
        end
        
        function delete(this)
           %disp('bdSolverPanel.delete()');
           delete(this.listener1);
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods %(Access=private)

        % Listener for REDRAW events
        function Redraw(this,evnt)
            %disp('bdSolverPanel.Redraw()');
            %disp(evnt)      
            if evnt.tstep
                this.InitialStep.Value = num2str(this.sysobj.tstep);
            end
            if evnt.sol
                this.Render();
            end                        
        end
                        
        function Render(this)
            %disp('bdSolverPanel.Render()');

            % compute the time increments
            dt = diff(this.sysobj.sol.x);
            
            % compute dy
            dy = diff(this.sysobj.sol.y,1,2);

            % time points
            t = this.sysobj.sol.x;
            
            % plot the norm of dy (upper axes)
            nrm = sqrt( sum(dy.^2,1) );
            [this.line1.XData,this.line1.YData] = stairs(t,nrm([1:end,end]));

            % plot the time steps (lower axes)
            [this.line2.XData,this.line2.YData] = stairs(t,dt([1:end,end]));
            
            % adjust the horizontal plot limits
            this.axes1.XLim = this.sysobj.tspan + [-1e-9 1e-9];   
            this.axes2.XLim = this.sysobj.tspan + [-1e-9 1e-9];   
            
            % calibrate the vertical plot limits (if necessary)
            switch this.axes1.YLimMode
                case 'manual'
                    % do nothing
                case 'auto'
                    % calibrate the axes
                    this.callbackCalibrate();
            end
        end        
              
        function callbackEditField(this,src,fieldname)
            % get the existing value of the solver option
            switch this.sysobj.solvertype
                case 'odesolver'
                    oldval = odeget(this.sysobj.odeoption,fieldname);
                case 'ddesolver'
                    oldval = ddeget(this.sysobj.ddeoption,fieldname);
                case 'sdesolver'
                    oldval = odeget(this.sysobj.sdeoption,fieldname);
            end
            
            % convert the edit Field string into an odeoption value
            if isempty(src.Value)
                value = [];
            else    
                value = str2double(src.Value);
                if isnan(value)
                    % invalid number
                    dlg = errordlg(['''', src.Value, ''' is not a valid number'],'Invalid Number','modal');
                    % restore the old value
                    src.Value = sprintf('%s',oldval);
                    % wait for dialog box to close
                    uiwait(dlg);
                    return
                end
            end

            % update the solver options
            switch this.sysobj.solvertype
                case 'odesolver'
                    this.sysobj.odeoption.(fieldname) = value;
                case 'ddesolver'
                    this.sysobj.ddeoption.(fieldname) = value;
                case 'sdesolver'
                    this.sysobj.sdeoption.(fieldname) = value;
                    this.sysobj.sdeoption.randn = [];
            end

            % tell the solver to recompute
            this.sysobj.NotifyRedraw(this.listener1);
        end           
                
        % CALIBRATE menu callback
        function callbackCalibrate(this)
            ymax1 = max(this.line1.YData);  
            ymax2 = max(this.line2.YData);
            if isnan(ymax1)
                ymax1=1;
            end
            if isnan(ymax2)
                ymax2=1;
            end;
            this.axes1.YLim = [0 1.2*ymax1];
            this.axes2.YLim = [0 1.2*ymax2];
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
            optout.title       = bdPanelBase.GetOption(opt, 'title', 'Solver');
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning('Ignoring unknown panel option ''bdSolverPanel.%s''',newfields{idx});
            end
        end        
        
    end
end

