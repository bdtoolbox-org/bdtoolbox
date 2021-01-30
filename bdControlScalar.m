classdef bdControlScalar < handle 
   %bdControlScalar  Control panel widget for bdGUI.
    %  This class is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2018a,2018b,2020a,2020b)

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
    
    properties
        EditField1   matlab.ui.control.NumericEditField
        EditField2   matlab.ui.control.NumericEditField
        EditField3   matlab.ui.control.NumericEditField
        Button       matlab.ui.control.Button
        Slider       matlab.ui.control.Slider
        %DecrButton   matlab.ui.control.Button
        %IncrButton   matlab.ui.control.Button
        RandButton   matlab.ui.control.Button
        PerbButton   matlab.ui.control.Button
        widgetmode
        listener1    event.listener
        listener2    event.proplistener
    end
    
    methods
        function this = bdControlScalar(sysobj,cpanel,xxxdef,xxxindx,xxxmode,gridlayout,gridrow)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here

            % Extract data from sysobj
            name  = sysobj.(xxxdef)(xxxindx).name;
            value = sysobj.(xxxdef)(xxxindx).value;
            limit = sysobj.(xxxdef)(xxxindx).lim;
                        
            % Create EditField1
            this.EditField1 = uieditfield(gridlayout, 'numeric');
            this.EditField1.Layout.Row = gridrow;
            this.EditField1.Layout.Column = 1;
            this.EditField1.HorizontalAlignment = 'center';
            this.EditField1.Value = limit(1);
            this.EditField1.Visible = 'off';
            this.EditField1.ValueChangedFcn = @(~,~) EditField1ValueChanged(this,sysobj,xxxdef,xxxindx);
            this.EditField1.Tooltip = ['Lower limit of ''',name,''''];
            
            % Create EditField2
            this.EditField2 = uieditfield(gridlayout, 'numeric');
            this.EditField2.Layout.Row = gridrow;
            this.EditField2.Layout.Column = 2;
            this.EditField2.HorizontalAlignment = 'center';
            this.EditField2.Value = limit(2);
            this.EditField2.Visible = 'off';
            this.EditField2.ValueChangedFcn = @(~,~) EditField2ValueChanged(this,sysobj,xxxdef,xxxindx);
            this.EditField2.Tooltip = ['Upper limit of ''',name,''''];
            
            % Create EditField3
            this.EditField3 = uieditfield(gridlayout, 'numeric');
            this.EditField3.Layout.Row = gridrow;
            this.EditField3.Layout.Column = 3;
            this.EditField3.HorizontalAlignment = 'center';
            this.EditField3.Value = value;
            this.EditField3.ValueChangedFcn = @(~,~) EditField3ValueChanged(this,sysobj,xxxdef,xxxindx);
            %this.EditField3.Tooltip = ['''',name,''''];
            
%             spinnerR = uispinner(gridlayout);
%             spinnerR.Layout.Row = gridrow;
%             spinnerR.Layout.Column = 3;
%             spinnerR.Value = 1;
%             spinnerR.Step = 1;
%             spinnerR.Limits = [0 1];
%             spinnerR.Enable = 'on';
%             spinnerR.LowerLimitInclusive = 'on';
%             spinnerR.UpperLimitInclusive = 'on';
%             spinnerR.RoundFractionalValues = 'on';
%             spinnerR.Tooltip = 'row subscript';
%             spinnerR.ValueChangingFcn = @(~,evnt) this.EditField3ValueChanged(evnt,sysobj,xxxdef,xxxindx);
% 
            % Create Button
            this.Button = uibutton(gridlayout, 'push');
            this.Button.Layout.Row = gridrow;
            this.Button.Layout.Column = 4;
            this.Button.Text = name;
            this.Button.ButtonPushedFcn = @(~,~) ButtonPushedFcn(this,sysobj,xxxdef,xxxindx,cpanel);
            %this.Button.Tooltip = sprintf('%s=%g',name,value);
            %this.Button.Tooltip = 'Toggle slider/buttons';
            this.Button.Interruptible = 'off';
            this.Button.BusyAction = 'cancel';

            % Widget mode (0=slider, 1=RAND/PERM)
            this.widgetmode = 0;

            % Compute the slider value
            slidervalue = (value-limit(1))./(limit(2)-limit(1));
            slidervalue = max(slidervalue,0);
            slidervalue = min(slidervalue,1);

            % Create Slider
            this.Slider = uislider(gridlayout);
            this.Slider.Limits = [0 1];
            this.Slider.Layout.Row = gridrow;
            this.Slider.Layout.Column = [1 2];
            this.Slider.Value = slidervalue;
            this.Slider.MajorTicksMode = 'manual';
            this.Slider.MinorTicksMode = 'manual';
            this.Slider.MajorTicks = [];
            this.Slider.MinorTicks = [];
            this.Slider.Interruptible = 'off';
            this.Slider.BusyAction = 'queue';
            %this.Slider.Tooltip = ['Slider for ''',name,''''];
            this.Slider.ValueChangingFcn = @(~,evnt) SliderValueChanging(this,sysobj,xxxdef,xxxindx,evnt);

            
%             % Create DECR Button
%             this.DecrButton = uibutton(gridlayout, 'push');
%             this.DecrButton.Layout.Row = gridrow;
%             this.DecrButton.Layout.Column = 1;
%             this.DecrButton.Text = 'DECR';
%             this.DecrButton.Visible = 'off';
%             this.DecrButton.ButtonPushedFcn = @(~,~) DecrButtonPushed(this,sysobj,xxxdef,xxxindx);
%             this.DecrButton.Tooltip = ['Decrement ''',name,''''];
%             this.DecrButton.Interruptible = 'off';
%             this.DecrButton.BusyAction = 'cancel';
%             
%             % Create INCR Button
%             this.IncrButton = uibutton(gridlayout, 'push');
%             this.IncrButton.Layout.Row = gridrow;
%             this.IncrButton.Layout.Column = 2;
%             this.IncrButton.Text = 'INCR';
%             this.IncrButton.Visible = 'off';
%             this.IncrButton.ButtonPushedFcn = @(~,~) IncrButtonPushed(this,sysobj,xxxdef,xxxindx);
%             this.IncrButton.Tooltip = ['Increment ''',name,''''];
%             this.IncrButton.Interruptible = 'off';
%             this.IncrButton.BusyAction = 'cancel';

            % Create RAND Button
            this.RandButton = uibutton(gridlayout, 'push');
            this.RandButton.Layout.Row = gridrow;
            this.RandButton.Layout.Column = 1;
            this.RandButton.Text = 'RAND';
            this.RandButton.Visible = 'off';
            this.RandButton.ButtonPushedFcn = @(~,~) RandButtonPushed(this,sysobj,xxxdef,xxxindx);
            this.RandButton.Tooltip = ['Random ''',name,''''];
            this.RandButton.Interruptible = 'off';
            this.RandButton.BusyAction = 'cancel';
            
            % Create PERB Button
            this.PerbButton = uibutton(gridlayout, 'push');
            this.PerbButton.Layout.Row = gridrow;
            this.PerbButton.Layout.Column = 2;
            this.PerbButton.Text = 'PERB';
            this.PerbButton.Visible = 'off';
            this.PerbButton.ButtonPushedFcn = @(~,~) PerbButtonPushed(this,sysobj,xxxdef,xxxindx);
            this.PerbButton.Tooltip = ['Perturb ''',name,''''];
            this.PerbButton.Interruptible = 'off';
            this.PerbButton.BusyAction = 'cancel';

            % listen to sysobj for REDRAW events
            this.listener1 = listener(sysobj,'redraw',@(src,evnt) this.Redraw(src,evnt,xxxdef,xxxindx));

            % listen to cpanel for changes to the xxxmode switch
            this.listener2 = listener(cpanel,xxxmode,'PostSet', @(src,evnt) this.ModeListener(cpanel,xxxmode));
        end
        
        function delete(this)
            %disp 'bdControlScalar.delete'
            delete(this.listener1);
            delete(this.listener2);
            %delete(this.dialogbox);
        end
        
        function mode(this,flag)            
            %disp('bdControlScalar.mode()');
            if flag
                this.EditField1.Visible = 'off';
                this.EditField2.Visible = 'off';
                switch this.widgetmode
                    case 0
                        this.Slider.Visible = 'on';
                        this.RandButton.Visible = 'off';
                        this.PerbButton.Visible = 'off';
                    case 1
                        this.Slider.Visible = 'off';
                        this.RandButton.Visible = 'on';
                        this.PerbButton.Visible = 'on';
                end
            else
                this.EditField1.Visible = 'on';
                this.EditField2.Visible = 'on';
                this.Slider.Visible = 'off';
                this.RandButton.Visible = 'off';
                this.PerbButton.Visible = 'off';
            end                        
        end                
    end
    
    % Callbacks that handle component events
    methods (Access = private)
            
        function Redraw(this,sysobj,sysevent,xxxdef,xxxindx)
            %disp 'bdControlScalar.Redraw()'
            
            % Extract data from sysobj
            name  = sysobj.(xxxdef)(xxxindx).name;
            value = sysobj.(xxxdef)(xxxindx).value;
            limit = sysobj.(xxxdef)(xxxindx).lim;
            
            % Extract data status from sysevent
            value_changed = sysevent.(xxxdef)(xxxindx).value;
            limit_changed = sysevent.(xxxdef)(xxxindx).lim;
            
            % if the lim in sysobj has changed then ...
            if limit_changed
                % update lower and upper edit field widgets
                this.EditField1.Value = limit(1);
                this.EditField2.Value = limit(2);
            end
            
            % if the value in sysobj has changed then ...
            if value_changed
                % update the value edit field widget
                this.EditField3.Value = value;
                % update the Tooltip
                this.Button.Tooltip = sprintf('%s=%g',name,value);
            end
            
            % if either the limit or the value in sysobj has changed then ...
            if limit_changed || value_changed
                % update the slider widget
                val = (value-limit(1))./(limit(2)-limit(1));
                val = max(val,0);
                val = min(val,1);
                this.Slider.Value = val;
            end
        end
        
        % Listener for cpanel.xxxmode events
        function ModeListener(this,cpanel,xxxmode)
            %disp('bdControlScalar.ModeListener');
            
            % extract the relevant mode flag from cpanel
            flag = cpanel.(xxxmode);
            
            % apply the mode to this widget
            this.mode(flag);
        end
        
        % ButtonPushedFcn callback
        function ButtonPushedFcn(this,~,xxxdef,xxxindx,cpanel)
            % toggle the widget mode
            this.widgetmode = mod(this.widgetmode+1,2);

            % extract the xxxmode flag from cpanel
            switch xxxdef
                case 'pardef'
                    flag = cpanel.parmode;
                case 'lagdef'
                    flag = cpanel.lagmode;
                case 'vardef'
                    flag = cpanel.varmode;
            end

            % (re)apply the xxxmode to this widget
            this.mode(flag);
        end

        % Slider Value Changing callback
        function SliderValueChanging(this,sysobj,xxxdef,xxxindx,event)
            %disp('SliderValueChanging');
            
            % extract the relevant fields from sysobj
            limit = sysobj.(xxxdef)(xxxindx).lim;

            % convert slider value to editbox value
            val = event.Value;
            value = limit(1) + val*(limit(2)-limit(1));
            
            % update the edit field widget
            this.EditField3.Value = value;

            % update sysobj
            sysobj.(xxxdef)(xxxindx).value = value;
            
            % notify everything to redraw (excluding self)
            sysobj.NotifyRedraw(this.listener1);
        end

        % EditField1 Value Changed callback
        function EditField1ValueChanged(this,sysobj,xxxdef,xxxindx)
            % extract the relevant fields from sysobj
            limit = sysobj.(xxxdef)(xxxindx).lim;
            
            % extract value from widget
            value = this.EditField1.Value;
            
            % apply it to the lower limit
            limit(1) = value;
            
            % adjust the upper limit if necessary
            if limit(2)<limit(1)
                limit(2) = value;
            end
            
            % write the new limits back to sysobj
            sysobj.(xxxdef)(xxxindx).lim = limit;
            
            % notify everything to redraw (including self)
            sysobj.NotifyRedraw([]);            
        end
        
        % EditField2 Value Changed callback
        function EditField2ValueChanged(this,sysobj,xxxdef,xxxindx)
            % extract the relevant fields from sysobj
            limit = sysobj.(xxxdef)(xxxindx).lim;
            
            % extract value from widget
            value = this.EditField2.Value;
            
            % apply it to the upper limit
            limit(2) = value;
            
            % adjust the lower limit if necessary
            if limit(1)>limit(2)
                limit(1) = value;
            end
            
            % write the new limits back to sysobj
            sysobj.(xxxdef)(xxxindx).lim = limit;
            
            % notify everything to redraw (including self)
            sysobj.NotifyRedraw([]);            
        end
        
        % EditField3 Value Changed callback
        function EditField3ValueChanged(this,sysobj,xxxdef,xxxindx)
            % write the new value in sysobj
            sysobj.(xxxdef)(xxxindx).value = this.EditField3.Value;
            
            % notify everything to redraw (including self)
            sysobj.NotifyRedraw([]);       
                        
            % notify the solver to recompute the solution
            %notify(sysobj,'recompute');
        end
        
%         % DecrButton callback
%         function DecrButtonPushed(this,sysobj,xxxdef,xxxindx)
%             disp('DecrButtonPushed');
%             
%             % retrieve the relevant data from sysobj
%             value = sysobj.(xxxdef)(xxxindx).value;
%             limit = sysobj.(xxxdef)(xxxindx).lim;
% 
%             % apply a uniform decrement (5%) to the data 
%             lo = limit(1);
%             hi = limit(2);
%             value = value - 0.05*(hi-lo);
% 
%             % do not exceed the lower limit
%             value = max(value,lo);
% 
%             % write the data back to sysobj
%             sysobj.(xxxdef)(xxxindx).value = value;
% 
%             % notify everything to redraw (including self)
%             sysobj.NotifyRedraw([]);       
%         end
% 
%         % IncrButton callback
%         function IncrButtonPushed(this,sysobj,xxxdef,xxxindx)
%             disp('IncrButtonPushed');
%             
%             % retrieve the relevant data from sysobj
%             value = sysobj.(xxxdef)(xxxindx).value;
%             limit = sysobj.(xxxdef)(xxxindx).lim;
% 
%             % apply a uniform increment (5%) to the data 
%             lo = limit(1);
%             hi = limit(2);
%             value = value + 0.05*(hi-lo);
%             
%             % do not exceed the upper limit
%             value = min(value,hi);
% 
%             % write the data back to sysobj
%             sysobj.(xxxdef)(xxxindx).value = value;
% 
%             % notify everything to redraw (including self)
%             sysobj.NotifyRedraw([]);       
%         end
        
        % RandButton callback
        function RandButtonPushed(~,sysobj,xxxdef,xxxindx)
            %disp('RandButtonPushed');
            
            % retrieve the relevant data from sysobj
            limit = sysobj.(xxxdef)(xxxindx).lim;

            % generate uniform random data between the lower and upper limits
            lo = limit(1);
            hi = limit(2);
            value = (hi-lo)*rand + lo;           

            % write the data back to sysobj
            sysobj.(xxxdef)(xxxindx).value = value;

            % notify everything to redraw (including self)
            sysobj.NotifyRedraw([]);       
        end
        
        % PerbButton callback
        function PerbButtonPushed(~,sysobj,xxxdef,xxxindx)
            % retrieve the relevant data from sysobj
            limit = sysobj.(xxxdef)(xxxindx).lim;
            value = sysobj.(xxxdef)(xxxindx).value;

            % apply a uniform random perturbation to the data
            lo = limit(1);
            hi = limit(2);
            value = value + 0.05*(hi-lo)*(rand-0.5);
            
            % write the data back to sysobj
            sysobj.(xxxdef)(xxxindx).value = value;

            % notify everything to redraw (including self)
            sysobj.NotifyRedraw([]);       
        end
        
    end
end
