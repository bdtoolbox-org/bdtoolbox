classdef bdControlTime < handle
    %bdControlTime  Control panel widget for bdGUI.
    %  This class is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2020a)

    % Copyright (C) 2020 Stewart Heitmann <heitmann@bdtoolbox.org>
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
        GridLayout          matlab.ui.container.GridLayout
        CheckBox            matlab.ui.control.CheckBox
        BackwardButton      matlab.ui.control.CheckBox
        EditField1          matlab.ui.control.NumericEditField
        EditField2          matlab.ui.control.NumericEditField
        EditField3          matlab.ui.control.NumericEditField
        EditField4          matlab.ui.control.NumericEditField
        Label1              matlab.ui.control.Label
        Label2              matlab.ui.control.Label
        Label3              matlab.ui.control.Label
        Slider              matlab.ui.control.Slider
        rlistener           event.listener
    end
    
    methods
        function this = bdControlTime(sysobj,uiparent)
            % Create the GridLayout
            this.GridLayout = uigridlayout(uiparent);
            this.GridLayout.ColumnWidth = {'1x','1x','1x','1x'};
            this.GridLayout.RowHeight = {'1x',21,21,21};
            this.GridLayout.ColumnSpacing = 5;
            this.GridLayout.RowSpacing = 5;
            this.GridLayout.Padding = [5 0 5 0];

            % Time Domain Checkbox
            this.CheckBox = uicheckbox(this.GridLayout);
            this.CheckBox.Text = 'Time Domain';
            this.CheckBox.FontWeight = 'bold';
            this.CheckBox.Layout.Row = 2;
            this.CheckBox.Layout.Column = [1 2];
            this.CheckBox.Value = 1;
            this.CheckBox.ValueChangedFcn = @(src,evnt) this.ModeChanged(src);
            
            % Backwards Checkbox
            this.BackwardButton = uicheckbox(this.GridLayout);
            this.BackwardButton.Text = 'Backward';
            this.BackwardButton.Value = sysobj.backward;
            this.BackwardButton.Layout.Row = 4;
            this.BackwardButton.Layout.Column = [1 2];
            this.BackwardButton.ValueChangedFcn = @(src,evnt) BackwardChanged(this,sysobj);
            this.BackwardButton.Tooltip = 'Integrate backwards in time';
            switch sysobj.solvertype
                case 'odesolver'
                    this.BackwardButton.Enable='on';
                otherwise
                    this.BackwardButton.Enable='off';
            end

            % Create EditField1 (t0)
            this.EditField1 = uieditfield(this.GridLayout, 'numeric');
            this.EditField1.Layout.Row = 3;
            this.EditField1.Layout.Column = 1;
            this.EditField1.HorizontalAlignment = 'center';
            this.EditField1.Visible = 'off';
            this.EditField1.ValueChangedFcn = @(~,~) EditField1Changed(this,sysobj);
            this.EditField1.Tooltip = 'Start';
            
            % Create EditField2 (t1)
            this.EditField2 = uieditfield(this.GridLayout, 'numeric');
            this.EditField2.Layout.Row = 3;
            this.EditField2.Layout.Column = 2;
            this.EditField2.HorizontalAlignment = 'center';
            this.EditField2.Visible = 'off';
            this.EditField2.ValueChangedFcn = @(~,~) EditField2Changed(this,sysobj);
            this.EditField2.Tooltip = 'Finish';
            
            % Create EditField3 (tval)
            this.EditField3 = uieditfield(this.GridLayout, 'numeric');
            this.EditField3.Layout.Row = 3;
            this.EditField3.Layout.Column = 3;
            this.EditField3.HorizontalAlignment = 'center';
            this.EditField3.ValueChangedFcn = @(~,~) EditField3Changed(this,sysobj);
            %this.EditField3.Tooltip = 'tval';
            
            % Create EditField4 (tstep)
            this.EditField4 = uieditfield(this.GridLayout, 'numeric');
            this.EditField4.Layout.Row = 3;
            this.EditField4.Layout.Column = 4;
            this.EditField4.HorizontalAlignment = 'center';
            this.EditField4.Visible = 'on';
            this.EditField4.ValueChangedFcn = @(~,~) EditField4Changed(this,sysobj);
            this.EditField4.Tooltip = 'Interpolation time step';
                       
            %Create Label1 (tval)
            this.Label1 = uilabel(this.GridLayout);
            this.Label1.Text = 'time';
            this.Label1.HorizontalAlignment = 'center';
            this.Label1.VerticalAlignment = 'bottom';
            this.Label1.Layout.Row = 2;
            this.Label1.Layout.Column = 3;
            this.Label1.Visible = 'on';

            %Create Label2 (tstep)
            this.Label2 = uilabel(this.GridLayout);
            this.Label2.Text = 'step';
            this.Label2.HorizontalAlignment = 'center';
            this.Label2.VerticalAlignment = 'bottom';
            this.Label2.Layout.Row = 2;
            this.Label2.Layout.Column = 4;
            this.Label2.Visible = 'on';
            
            %Create Label3 (bdtoolbox)
            this.Label3 = uilabel(this.GridLayout);
            this.Label3.Text = 'bdtoolbox.org';
            this.Label3.HorizontalAlignment = 'right';
            this.Label3.VerticalAlignment = 'bottom';
            this.Label3.FontWeight = 'normal';
            this.Label3.FontSize = 16;
            this.Label3.FontColor = [0.75 0.75 0.75];
            this.Label3.Layout.Row = 4;
            this.Label3.Layout.Column = [2 4];
            this.Label3.Visible = 'on';
            
            % Create Slider
            this.Slider = uislider(this.GridLayout);
            this.Slider.Limits = [0 1];
            this.Slider.Layout.Row = 3;
            this.Slider.Layout.Column = [1 2];
            this.Slider.MajorTicks = [];
            this.Slider.MinorTicks = [];
            %this.Slider.Interruptible = 'off';
            %this.Slider.BusyAction = 'queue';
            this.Slider.ValueChangingFcn = @(~,evnt) SliderChanging(this,sysobj,evnt);
           
            % update the widget values
            t0 = sysobj.tspan(1);
            t1 = sysobj.tspan(2);
            tstep = sysobj.tstep;
            tval = sysobj.tval;
            WriteWidgets(this,t0,t1,tval,tstep);
            
            % listen to sysobj for REDRAW events
            this.rlistener = listener(sysobj,'redraw',@(src,evnt) this.Redraw(src,evnt));
        end
        
        function ModeChanged(this,checkbox)
            %disp('bdControlTime.ModeChanged');
            if checkbox.Value
                this.EditField1.Visible = 'off';
                this.EditField2.Visible = 'off';
                %this.EditField4.Visible = 'off';
                %this.Label1.Visible = 'off';
                %this.Label2.Visible = 'off';
                %this.BackwardButton.Visible = 'on';
                this.Slider.Visible = 'on';
            else
                this.EditField1.Visible = 'on';
                this.EditField2.Visible = 'on';
                %this.EditField4.Visible = 'on';
                %this.Label1.Visible = 'on';
                %this.Label2.Visible = 'on';
                %this.BackwardButton.Visible = 'off';
                this.Slider.Visible = 'off';
            end                        
        end
        
        function BackwardChanged(this,sysobj)
            %disp('bdControlTime.BackwardChanged');
            sysobj.backward = this.BackwardButton.Value;
            sysobj.NotifyRedraw([]);
        end
        
        % Callback for t0
        function EditField1Changed(this,sysobj)
            %disp('bdControlTime.EditField1Changed');
            
            % read the widgets (t0 has changed)
            [t0,t1,tval,tstep] = ReadWidgets(this);
            
            % ensure t1 is not less than t0
            if t1<t0
                t1 = t0;
            end
            
            % ensure tval is not less than t0
            if tval<t0
                tval = t0;
            end
            
            % ensure tval is not greater than t1
            if tval>t1
                tval = t1;
            end
            
            % update the widgets
            WriteWidgets(this,t0,t1,tval,tstep);

            % update sysobj
            this.WriteSys(sysobj,t0,t1,tval,tstep);
            
            % notify everything to redraw (excluding self)
            sysobj.NotifyRedraw(this.rlistener);
        end
        
        function EditField2Changed(this,sysobj)
            %disp('bdControlTime.EditField2Changed');
            
            % read the widgets (t1 has changed)
            [t0,t1,tval,tstep] = ReadWidgets(this);
            
            % ensure t0 is not greater than t1
            if t1<t0
                t0 = t1;
            end
            
            % ensure tval is not less than t0
            if tval<t0
                tval = t0;
            end
            
            % ensure tval is not greater than t1
            if tval>t1
                tval = t1;
            end
            
            % update the widgets
            WriteWidgets(this,t0,t1,tval,tstep);

            % update sysobj
            this.WriteSys(sysobj,t0,t1,tval,tstep);

            % notify everything to redraw (excluding self)
            sysobj.NotifyRedraw(this.rlistener);
        end
        
        function EditField3Changed(this,sysobj)
            %disp('bdControlTime.EditField3Changed');
            
            % read the widgets (tt has changed)
            [t0,t1,tval,tstep] = ReadWidgets(this);

            % ensure t0 is not greater than tval
            if tval<t0
                t0 = tval;
            end
            
            % ensure t1 is not less than tval
            if t1<tval
                t1 = tval;
            end
            
            % update the widgets
            WriteWidgets(this,t0,t1,tval,tstep);

            % update sysobj
            this.WriteSys(sysobj,t0,t1,tval,tstep);

            % notify everything to redraw (excluding self)
            sysobj.NotifyRedraw(this.rlistener);
        end
        
        function EditField4Changed(this,sysobj)
            %disp('bdControlTime.EditField4Changed');
            
            % read the widgets (tstep has changed)
            tstep = this.EditField4.Value;
            
            % ensure tstep>0
            if tstep<0
                tstep = abs(tstep);
            end
            
            % ensure tstep is not too small
            if tstep < 1e-10
                tstep = 1e-10;
            end
                        
            % update the widgets
            this.EditField4.Value = tstep;

            % update sysobj
            sysobj.tstep = tstep;

            % redraw the widgets (and anything else)
            sysobj.NotifyRedraw([]);
        end
        
        function SliderChanging(this,sysobj,evnt)
            %disp('bdControlTime.SliderChanging');

            % read the widgets
            t0 = this.EditField1.Value;
            t1 = this.EditField2.Value;
            tval = (t1-t0) * evnt.Value + t0;
            
            % update widgets
            this.EditField3.Value = tval;

            % update sysobj
            sysobj.tval = tval;

            % notify everything to redraw (excluding self)
            sysobj.NotifyRedraw(this.rlistener);
        end
        
        function [t0,t1,tval,tstep] = ReadWidgets(this)
            %disp('bdControlTime.ReadWidgets');
            t0 = this.EditField1.Value;
            t1 = this.EditField2.Value;
            tval = this.EditField3.Value;
            tstep = this.EditField4.Value;
        end
        
        function WriteWidgets(this,t0,t1,tval,tstep)
            %disp('bdControlTime.WriteWidgets');
            % compute slider position
            if t1==t0
                ss = 0.5;
            else
                ss = (tval-t0)./(t1-t0);
            end

            % update widgets
            this.EditField1.Value = t0;
            this.EditField2.Value = t1;
            this.EditField3.Value = tval;
            this.EditField4.Value = tstep;
            this.Slider.Value = ss;
        end
        
        function Redraw(this,sysobj,sysevent)
            %disp('bdControlTime.Redraw()')
            %dbstack()
            
            % if sysobj.tspan or sysobj.tval or sysobj.tstep has changed then ...
            if sysevent.tspan || sysevent.tval || sysevent.tstep
                % Read the current values from sysobj
                [t0,t1,tval,tstep] = this.ReadSys(sysobj);
                % Update the widgets with those values
                this.WriteWidgets(t0,t1,tval,tstep)
            end
           
            % if sysobj.backward has changed then ...
            if sysevent.backward
                this.BackwardButton.Value = sysobj.backward;
            end
        end        
    end

    methods(Static)
        
        function [t0,t1,tval,tstep] = ReadSys(sysobj)
            %disp('bdControlTime.ReadSys()')
            t0 = sysobj.tspan(1);
            t1 = sysobj.tspan(2);
            tval = sysobj.tval;
            tstep = sysobj.tstep;
        end
        
        function WriteSys(sysobj,t0,t1,tval,tstep)
            %disp('bdControlTime.WriteSys()')
            if ~isequal(sysobj.tspan,[t0 t1])
                sysobj.tspan = [t0 t1];
            end
            if sysobj.tval ~= tval
                sysobj.tval = tval;
            end
            if sysobj.tstep ~= tstep
                sysobj.tstep = tstep;
            end
        end
        
    end

end

