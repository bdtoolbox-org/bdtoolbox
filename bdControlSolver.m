classdef bdControlSolver < handle
    %bdControlSolver  Control panel widget for bdGUI.
    %  This class is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2020a,2021a)

    % Copyright (C) 2020-2021 Stewart Heitmann <heitmann@bdtoolbox.org>
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
    
    properties (Access=public)
        fig                 matlab.ui.Figure
        GridLayout          matlab.ui.container.GridLayout
        DropDown            matlab.ui.control.DropDown
        RunButton           matlab.ui.control.Button
        HaltButton          matlab.ui.control.StateButton
        Label1              matlab.ui.control.Label
        Label2              matlab.ui.control.Label
        Label3              matlab.ui.control.Label
        Label4              matlab.ui.control.Label
        Label5              matlab.ui.control.Label
        Label6              matlab.ui.control.Label
        Label7              matlab.ui.control.Label
        Label8              matlab.ui.control.Label
        Label9              matlab.ui.control.Label
        Label10             matlab.ui.control.Label
        Label11             matlab.ui.control.Label
        Label12             matlab.ui.control.Label
        Label13             matlab.ui.control.Label
        Label14             matlab.ui.control.Label
        Label15             matlab.ui.control.Label
        Label16             matlab.ui.control.Label
        Label17             matlab.ui.control.Label
        Label18             matlab.ui.control.Label
        rlistener           event.listener
        plistener           event.listener
    end
    
    methods
        function this = bdControlSolver(sysobj,uiparent)
            % Keep a handle to the parent figure
            this.fig = ancestor(uiparent,'figure');
            
            % Create the GridLayout
            this.GridLayout = uigridlayout(uiparent);
            this.GridLayout.ColumnWidth = {50,50,50,50,50,50,50,50,50,50,'1x'};
            this.GridLayout.RowHeight = {'1x',21,21};
            this.GridLayout.ColumnSpacing = 5;
            this.GridLayout.RowSpacing = 5;
            this.GridLayout.Padding = [0 0 0 0];
            
            % Create DropDown
            this.DropDown = uidropdown(this.GridLayout);
            this.DropDown.Layout.Row = 2;
            this.DropDown.Layout.Column = [1 2];
            switch sysobj.solvertype
                case 'odesolver'
                    items = sysobj.odesolver;
                case 'ddesolver'                    
                    items = sysobj.ddesolver;
                case 'sdesolver'
                    items = sysobj.sdesolver;
            end
            for idx=1:numel(items)
                items{idx} = func2str(items{idx});
            end
            this.DropDown.Items = items;
            this.DropDown.ItemsData = 1:numel(items);
            this.DropDown.Value = sysobj.solveritem;
            this.DropDown.ValueChangedFcn = @(src,evnt) DropDownCallback(this,sysobj,src);

            % Create RUN button
            this.RunButton = uibutton(this.GridLayout, 'push');
            this.RunButton.ButtonPushedFcn = @(src,evnt) RunButtonCallback(this,sysobj);
            this.RunButton.Text = 'RUN';
            %this.RunButton.Tooltip = 'One-shot';
            %this.RunButton.BackgroundColor = [0.75 1 0.75];
            this.RunButton.FontWeight = 'normal';
            this.RunButton.Layout.Row = 3;
            this.RunButton.Layout.Column = 1;

            % Create HALT button
            this.HaltButton = uibutton(this.GridLayout, 'state');
            this.HaltButton.ValueChangedFcn = @(src,evnt) HaltButtonCallback(this,sysobj);
            this.HaltButton.Text = 'HALT';
            %this.HaltButton.Tooltip = 'Halt the solver';
            this.HaltButton.FontWeight = 'normal';
            %this.HaltButton.FontColor = 'r';
            %this.HaltButton.BackgroundColor = [1 0.75 0.75];
            this.HaltButton.Layout.Row = 3;
            this.HaltButton.Layout.Column = 2;
            
            % Create Label1 (nsteps)
            this.Label1 = uilabel(this.GridLayout);
            this.Label1.Text = 'nsteps';
            this.Label1.HorizontalAlignment = 'center';
            this.Label1.VerticalAlignment = 'bottom';
            this.Label1.Layout.Row = 2;
            this.Label1.Layout.Column = 3;

            % Create Label2
            this.Label2 = uilabel(this.GridLayout);
            this.Label2.Tooltip = 'number of steps taken by the solver';
            this.Label2.Text = '0';
            this.Label2.HorizontalAlignment = 'center';
            this.Label2.VerticalAlignment = 'top';
            this.Label2.Layout.Row = 3;
            this.Label2.Layout.Column = 3;
            
            % Create Label3 (nfailed)
            this.Label3 = uilabel(this.GridLayout);
            this.Label3.Text = 'nfailed';
            this.Label3.HorizontalAlignment = 'center';
            this.Label3.VerticalAlignment = 'bottom';
            this.Label3.Layout.Row = 2;
            this.Label3.Layout.Column = 4;

            % Create Label4
            this.Label4 = uilabel(this.GridLayout);
            this.Label4.Tooltip = 'number of failed steps';
            this.Label4.Text = '0';
            this.Label4.HorizontalAlignment = 'center';
            this.Label4.VerticalAlignment = 'top';
            this.Label4.Layout.Row = 3;
            this.Label4.Layout.Column = 4;
            
            % Create Label5 (nfevals)
            this.Label5 = uilabel(this.GridLayout);
            this.Label5.Text = 'nfevals';
            this.Label5.HorizontalAlignment = 'center';
            this.Label5.VerticalAlignment = 'bottom';
            this.Label5.Layout.Row = 2;
            this.Label5.Layout.Column = 5;

            % Create Label6
            this.Label6 = uilabel(this.GridLayout);
            this.Label6.Tooltip = 'number of function evaluations';
            this.Label6.Text = '0';
            this.Label6.HorizontalAlignment = 'center';
            this.Label6.VerticalAlignment = 'top';
            this.Label6.Layout.Row = 3;
            this.Label6.Layout.Column = 5;
            
            % Create Label7 (nevolve)
            this.Label7 = uilabel(this.GridLayout);
            this.Label7.Text = 'nevolve';
            this.Label7.HorizontalAlignment = 'center';
            this.Label7.VerticalAlignment = 'bottom';
            this.Label7.Layout.Row = 2;
            this.Label7.Layout.Column = 6;

            % Create Label8
            this.Label8 = uilabel(this.GridLayout);
            this.Label8.Tooltip = 'number of evolutions';
            this.Label8.Text = '0';
            this.Label8.HorizontalAlignment = 'center';
            this.Label8.VerticalAlignment = 'top';
            this.Label8.Layout.Row = 3;
            this.Label8.Layout.Column = 6;
            
            % Create Label9 (Progress)
            this.Label9 = uilabel(this.GridLayout);
            this.Label9.Text = 'Progress';
            this.Label9.HorizontalAlignment = 'center';
            this.Label9.VerticalAlignment = 'bottom';
            this.Label9.Layout.Row = 2;
            this.Label9.Layout.Column = 7;

            % Create Label10
            this.Label10 = uilabel(this.GridLayout);
            this.Label10.Tooltip = 'progress of the solver';
            this.Label10.Text = '0%';
            this.Label10.HorizontalAlignment = 'center';
            this.Label10.VerticalAlignment = 'top';
            this.Label10.Layout.Row = 3;
            this.Label10.Layout.Column = 7;
            
            % Create Label11 (Solver)
            this.Label11 = uilabel(this.GridLayout);
            this.Label11.Text = 'Solver';
            this.Label11.HorizontalAlignment = 'center';
            this.Label11.VerticalAlignment = 'bottom';
            this.Label11.Layout.Row = 2;
            this.Label11.Layout.Column = 8;

            % Create Label12
            this.Label12 = uilabel(this.GridLayout);
            this.Label12.Tooltip = 'CPU time used by the solver';
            this.Label12.Text = '0.00s';
            this.Label12.HorizontalAlignment = 'center';
            this.Label12.VerticalAlignment = 'top';
            this.Label12.Layout.Row = 3;
            this.Label12.Layout.Column = 8;
            
            % Create Label13 (Interp)
            this.Label13 = uilabel(this.GridLayout);
            this.Label13.Text = 'Interp';
            this.Label13.HorizontalAlignment = 'center';
            this.Label13.VerticalAlignment = 'bottom';
            this.Label13.Layout.Row = 2;
            this.Label13.Layout.Column = 9;

            % Create Label14
            this.Label14 = uilabel(this.GridLayout);
            this.Label14.Tooltip = 'CPU time used by the interpolator';
            this.Label14.Text = '0.00s';
            this.Label14.HorizontalAlignment = 'center';
            this.Label14.VerticalAlignment = 'top';
            this.Label14.Layout.Row = 3;
            this.Label14.Layout.Column = 9;
            
            % Create Label15 (Graphics)
            this.Label15 = uilabel(this.GridLayout);
            this.Label15.Text = 'Graphics';
            this.Label15.HorizontalAlignment = 'center';
            this.Label15.VerticalAlignment = 'bottom';
            this.Label15.Layout.Row = 2;
            this.Label15.Layout.Column = 10;

            % Create Label16
            this.Label16 = uilabel(this.GridLayout);
            this.Label16.Tooltip = 'CPU time used by the display panels';
            this.Label16.Text = '0.00s';
            this.Label16.HorizontalAlignment = 'center';
            this.Label16.VerticalAlignment = 'top';
            this.Label16.Layout.Row = 3;
            this.Label16.Layout.Column = 10;
                  
            % Create Label17 (Error)
            this.Label17 = uilabel(this.GridLayout);
            this.Label17.Text = '   Error';
            this.Label17.HorizontalAlignment = 'left';
            this.Label17.VerticalAlignment = 'bottom';
            this.Label17.Layout.Row = 2;
            this.Label17.Layout.Column = 11;

            % Create Label18
            this.Label18 = uilabel(this.GridLayout);
            this.Label18.Tooltip = '';
            this.Label18.Text = '   none';
            this.Label18.HorizontalAlignment = 'left';
            this.Label18.VerticalAlignment = 'top';
            this.Label18.Layout.Row = 3;
            this.Label18.Layout.Column = 11;

            % update our widgets to reflect the contents of sysobj
            this.UpdateWidgets(sysobj);
     
            % listen to sysobj for REDRAW events
            this.rlistener = listener(sysobj,'redraw',@(src,evnt) this.Redraw(src,evnt));
            
            % listen to sysobj.indicators for REFRESH events
            this.plistener = listener(sysobj.indicators,'refresh',@(~,~) this.Progress(sysobj));
        end

        function delete(this)
            %disp('bdControlSolver.delete');
            delete(this.rlistener);
            delete(this.plistener);
        end
        
        % Callback for the solver DropDown selector
        function DropDownCallback(this,sysobj,dropdown)
            %disp('bdControlSolver.DropDownCallback');
            % update sysobj
            sysobj.solveritem = dropdown.Value;
            % notify everyone (excluding self) to redraw
            sysobj.NotifyRedraw(this.rlistener);
        end
        
        % Callback for the RUN button. 
        function RunButtonCallback(~,sysobj,~)
            %disp('bdControlSolver.RunButtonCallback');
            
            % disable the halt state (if enabled)
            if sysobj.halt
                sysobj.halt = false;
                sysobj.NotifyRedraw([]);
            end
            
            % force a recompute on the next timer loop
            sysobj.recompute = true;
        end
        
        % Callback for the HALT button
        function HaltButtonCallback(this,sysobj,~)
            %disp('bdControlSolver.HALTButtonCallback');
            
            % update sysobj
            if this.HaltButton.Value
                sysobj.halt = true;
            else
                sysobj.halt = false;
                
                % Force everything to redraw
                npardef = numel(sysobj.pardef);
                nlagdef = numel(sysobj.lagdef);
                nvardef = numel(sysobj.vardef);
                eventdata = bdRedrawEvent(true,npardef,nlagdef,nvardef);
                notify(sysobj,'redraw',eventdata);

                % Flag a recompute
                sysobj.recompute = true;

                % Restart the timer in case it has failed
                sysobj.TimerStart();
            end
            
            % update our widgets
            this.UpdateWidgets(sysobj);
            
            % notify everyone (excluding self) to redraw
            sysobj.NotifyRedraw(this.rlistener);
        end
                
        function Redraw(this,sysobj,sysevent)
            %disp('bdControlSolver.Redraw');
            
            % if sysobj.halt has changed then ...
            if sysevent.halt
                % update our widgets
                this.UpdateWidgets(sysobj);
            end
            
            % if sysobj,solveritem has changed then ...
            if sysevent.solveritem
                this.DropDown.Value = sysobj.solveritem;
            end
           
            % if sysobj.sol has changed then ...
            if sysevent.sol
                % update the solver stats
                this.Label2.Text = sprintf('%d',sysobj.sol.stats.nsteps);
                this.Label4.Text = sprintf('%d',sysobj.sol.stats.nfailed);
                this.Label6.Text = sprintf('%d',sysobj.sol.stats.nfevals);
                this.Label8.Text = sprintf('%d',sysobj.indicators.nevolve);
            end
        end       
        
        function UpdateWidgets(this,sysobj)
            % update the RUN and HALT buttons
            if sysobj.halt
                this.HaltButton.Value = 1;
                rgb = 'r';
                this.fig.Pointer = 'arrow';
            else
                this.HaltButton.Value = 0;
                rgb = 'k';
            end
            
            % Update the widget colors
            this.Label1.FontColor = rgb;
            this.Label2.FontColor = rgb;
            this.Label3.FontColor = rgb;
            this.Label4.FontColor = rgb;
            this.Label5.FontColor = rgb;
            this.Label6.FontColor = rgb;
            this.Label7.FontColor = rgb;
            this.Label8.FontColor = rgb;
            this.Label9.FontColor = rgb;
            this.Label10.FontColor = rgb;
            this.Label11.FontColor = rgb;
            this.Label12.FontColor = rgb;
            this.Label13.FontColor = rgb;
            this.Label14.FontColor = rgb;
            this.Label15.FontColor = rgb;
            this.Label16.FontColor = rgb;
        end
         
        function Progress(this,sysobj)
            %disp('bdControlSolver.Progress');
            
            if sysobj.indicators.busy
                % disable the indicators
                this.Label2.Enable = 'off';
                this.Label4.Enable = 'off';
                this.Label6.Enable = 'off';
                this.Label14.Enable = 'off';
                this.Label16.Enable = 'off';
                % set the mouse pointer to 'watch'
                this.fig.Pointer = 'watch';
            else
                % enable the indicators
                this.Label2.Enable = 'on';
                this.Label4.Enable = 'on';
                this.Label6.Enable = 'on';
                this.Label14.Enable = 'on';
                this.Label16.Enable = 'on';
                % set the mouse pointer to 'arrow'
                this.fig.Pointer = 'arrow';
            end
            
            % update the Solver progress and CPU time
            this.Label10.Text = sprintf('%0.0f%%',sysobj.indicators.progress);
            this.Label12.Text = sprintf('%0.2fs',sysobj.indicators.solvertoc);

            % update the Interpolator CPU time
            this.Label14.Text = sprintf('%0.2fs',sysobj.indicators.interptoc);

            % update the Graphics CPU time
            this.Label16.Text = sprintf('%0.2fs',sysobj.indicators.graphicstoc);     

            % update the error message
            if isempty(sysobj.indicators.errorid)
                % No error message to display
                this.Label18.Text = '   none';
                this.Label18.Tooltip = '';
                this.Label18.FontColor = 'k';
                this.Label17.FontColor = 'k';
            else
                % Display the error message
                this.Label18.Text = ['   ' sysobj.indicators.errorid];
                this.Label18.Tooltip = sysobj.indicators.errormsg;
                this.Label18.FontColor = 'r';
                this.Label17.FontColor = 'r';
            end
        end
        
    end
     
end

