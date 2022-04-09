classdef bdDFDY < bdPanelBase
    %bdDFDY Display the Jacobian (dFdY).
    %
    %AUTHORS
    %Stewart Heitmann (2022a)   
    
    % Copyright (C) 2022 Stewart Heitmann
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
        t
        Y
        dFdY
        trace
        det
    end
    
    properties (Access=private)
        sysobj              bdSystem
        tab                 matlab.ui.container.Tab 
        Jlabel              matlab.ui.control.Label
        Jtable              matlab.ui.control.Table
        Trlabel             matlab.ui.control.Label
        Detlabel            matlab.ui.control.Label
        Slabel              matlab.ui.control.Label
        menu                matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
            
        rlistener           event.listener
    end
    
    methods
        function this = bdDFDY(tabgrp,sysobj,opt)
            %disp('bdDFDY');
            
            % remember the parents
            this.sysobj = sysobj;
            
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','dFdY', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');
                                    
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
            this.tab = uitab(tabgrp, 'Title','dFdY', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'1x','1x','1x'};
            GridLayout.RowHeight = {20,'1x',20};
            GridLayout.RowSpacing = 10;
            GridLayout.Visible = 'off';

            % Construct the Jacobian label
            this.Jlabel = uilabel(GridLayout);
            this.Jlabel.Layout.Row = 1;
            this.Jlabel.Layout.Column = [1 3];
            this.Jlabel.HorizontalAlignment = 'center';
            this.Jlabel.Text = 'The Jacobian (dF/dY) is only defined for ODEs';
           
            % Construct the Jacobian table
            this.Jtable = uitable(GridLayout);
            this.Jtable.Layout.Row = 2;
            this.Jtable.Layout.Column = [1 3];
            this.Jtable.ColumnEditable = false;
            this.Jtable.ColumnFormat = {'LONGG'};
                        
            % Populate the Jacobian table
            n = size(this.sysobj.sol.y,1);
            this.Jtable.ColumnName = cell(1,n);
            this.Jtable.RowName = cell(1,n);
            for indx=1:n
                this.Jtable.ColumnName{indx} = sprintf('dY%d',indx);
                this.Jtable.RowName{indx} = sprintf('dF%d',indx);
            end
            this.Jtable.Data = nan(n);

            % Construct the Trace label
            this.Trlabel = uilabel(GridLayout);
            this.Trlabel.Layout.Row = 3;
            this.Trlabel.Layout.Column = 1;
            this.Trlabel.HorizontalAlignment = 'left';
            this.Trlabel.Text = 'Trace = NaN';

            % Construct the Determinant label
            this.Detlabel = uilabel(GridLayout);
            this.Detlabel.Layout.Row = 3;
            this.Detlabel.Layout.Column = 2;
            this.Detlabel.HorizontalAlignment = 'center';
            this.Detlabel.Text = 'Determinant = NaN';

            % Construct the Stability label
            this.Slabel = uilabel(GridLayout);
            this.Slabel.Layout.Row = 3;
            this.Slabel.Layout.Column = 3;
            this.Slabel.HorizontalAlignment = 'right';
            this.Slabel.Text = '';

            % apply the custom options (calls the RecomputeRedraw function)
            this.options = opt;

            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';
            
            % listen for Redraw events
            this.rlistener = listener(sysobj,'redraw',@(src,evnt) this.Redraw(evnt));
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

            % Recompute the Jacobian and redraw the panel
            this.RecomputeRedraw();
        end
        
        function delete(this)
           %disp('bdDFDY.delete()');
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods (Access=private)

        % Listener for REDRAW events
        function Redraw(this,evnt)
            %disp('bdDFDY.Redraw()');
            %disp(evnt) 
            if evnt.sol || evnt.tval
                % Recompute the redraw eigenvalues
                this.RecomputeRedraw();
            end          
        end

        function RecomputeRedraw(this)
            %disp('bdDFDY.RecomputeRedraw()');

            switch this.sysobj.solvertype 
                case 'odesolver'
                    try
                        % recompute the Jacobian at Y(t)
                        this.t = this.sysobj.tval;
                        this.Y = bdEval(this.sysobj.sol,this.t);
                        this.dFdY = this.sysobj.Jacobian(this.t,this.Y);
    
                        % update the Jacobian table
                        this.Jtable.Data = this.dFdY;
    
                        % update the Jacobian label
                        this.Jlabel.Text = sprintf('Jacobian (dF/dY) evaluated at Y(t=%0.4g)',this.t);
                    catch
                        n = numel(this.sysobj.GetVar0);
                        this.dFdY = NaN(n);
                        this.Jtable.Data = NaN(n);
                        this.Jlabel.Text = sprintf('Error: Failed to evaluate F(Y) at Y(t=%0.4g)',this.t);
                    end

                    % recompute the trace and determinant
                    this.trace = trace(this.dFdY);
                    this.det = det(this.dFdY);
                    
                    % update the trace and determinant labels
                    this.Trlabel.Text = sprintf('Trace = %0.5g',this.trace);
                    this.Detlabel.Text = sprintf('Determinant = %0.5g',this.det);

                    % update the stability label
                    if this.det<0
                        % saddles
                        this.Slabel.Text = 'Saddle';
                    elseif this.det>0
                        % nodes, spirals, centers
                        if (this.trace^2 - 4*this.det) >= 0
                            % nodes
                            if this.trace>0
                                % unstable nodes
                                this.Slabel.Text = 'Unstable Node';
                            else
                                % stable nodes
                                this.Slabel.Text = 'Stable Node';
                            end
                        else
                            % spirals
                            if this.trace>0
                                % unstable spiral
                                this.Slabel.Text = 'Unstable Spiral';
                            elseif this.trace<0
                                % stable spiral
                                this.Slabel.Text = 'Stable Spiral';
                            else
                                % centers
                                this.Slabel.Text = 'Center';
                            end
                        end
                    elseif this.det==0
                        % neutral
                        this.Slabel.Text = 'Neutral';
                    else
                        % det is NaN
                        this.Slabel.Text = '';
                    end

                otherwise
                    % nothing to do
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
            optout.title       = bdPanelBase.GetOption(opt, 'title', 'dFdY');
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning('Ignoring unknown panel option ''bdDFDY.%s''',newfields{idx});
            end
        end
                
    end
end

