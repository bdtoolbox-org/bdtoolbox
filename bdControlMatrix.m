classdef bdControlMatrix < handle 
    %bdControlMatrix  Control panel widget for bdGUI.
    %  This class is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2017d,2018a,2019a,2020a,2020b,2021a)
    
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
    
    properties
        SubLayout
        EditField1   matlab.ui.control.NumericEditField
        EditField2   matlab.ui.control.NumericEditField
        RandButton   matlab.ui.control.Button
        PerbButton   matlab.ui.control.Button
        AxesPanel    matlab.ui.container.Panel
        Axes         matlab.ui.control.UIAxes
        Image        matlab.graphics.primitive.Image
        Button       matlab.ui.control.Button
        listener1    event.listener
        listener2    event.proplistener
        dialogbox    bdDialogMatrix
    end
    
    methods
        function this = bdControlMatrix(sysobj,cpanel,xxxdef,xxxindx,xxxmode,gridlayout,gridrow)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here

            this.dialogbox = bdDialogMatrix(sysobj,xxxdef,xxxindx);
            
            % Extract data from sysobj
            name  = sysobj.(xxxdef)(xxxindx).name;
            value = sysobj.(xxxdef)(xxxindx).value;
            limit = sysobj.(xxxdef)(xxxindx).lim;
                      
            % Create a nested gridlayout that spans the first two columns of the parent gridlayout
            this.SubLayout = uigridlayout(gridlayout);
            this.SubLayout.ColumnWidth = {'1x','1x'};
            this.SubLayout.RowHeight = {'1x',21,'1x'};
            this.SubLayout.ColumnSpacing = 5;
            this.SubLayout.RowSpacing = 0;
            this.SubLayout.Padding = [0 0 0 0];
            this.SubLayout.Layout.Row = gridrow;
            this.SubLayout.Layout.Column = [1 2];
            
            % Create EditField1
            this.EditField1 = uieditfield(this.SubLayout, 'numeric');
            this.EditField1.Layout.Row = 2;
            this.EditField1.Layout.Column = 1;
            this.EditField1.HorizontalAlignment = 'center';
            this.EditField1.Value = limit(1);
            this.EditField1.Visible = 'off';
            this.EditField1.ValueChangedFcn = @(~,~) EditField1ValueChanged(this,sysobj,xxxdef,xxxindx);
            this.EditField1.Tooltip = ['Lower limit of ''',name,''''];
            
            % Create EditField2
            this.EditField2 = uieditfield(this.SubLayout, 'numeric');
            this.EditField2.Layout.Row = 2;
            this.EditField2.Layout.Column = 2;
            this.EditField2.HorizontalAlignment = 'center';
            this.EditField2.Value = limit(2);
            this.EditField2.Visible = 'off';
            this.EditField2.ValueChangedFcn = @(~,~) EditField2ValueChanged(this,sysobj,xxxdef,xxxindx);
            this.EditField2.Tooltip = ['Upper limit of ''',name,''''];
            
            % Create RAND Button
            this.RandButton = uibutton(this.SubLayout, 'push');
            this.RandButton.Layout.Row = 2;
            this.RandButton.Layout.Column = 1;
            this.RandButton.Text = 'RAND';
            this.RandButton.Visible = 'on';
            this.RandButton.ButtonPushedFcn = @(~,~) RandButtonPushedFcn(this,sysobj,xxxdef,xxxindx);
            this.RandButton.Tooltip = ['Random ''',name,''''];
            this.RandButton.Interruptible = 'off';
            this.RandButton.BusyAction = 'cancel';

            % Create PERB Button
            this.PerbButton = uibutton(this.SubLayout, 'push');
            this.PerbButton.Layout.Row = 2;
            this.PerbButton.Layout.Column = 2;
            this.PerbButton.Text = 'PERB';
            this.RandButton.Visible = 'on';
            this.PerbButton.ButtonPushedFcn = @(~,~) PerbButtonPushedFcn(this,sysobj,xxxdef,xxxindx);
            this.PerbButton.Tooltip = ['Perturb ''',name,''''];
            this.PerbButton.Interruptible = 'off';
            this.PerbButton.BusyAction = 'cancel';

             % Create Panel for the Axes
            this.AxesPanel = uipanel(gridlayout);
            this.AxesPanel.Layout.Row = gridrow;
            this.AxesPanel.Layout.Column = 3;

            % Create Axes for the data image
            this.Axes = uiaxes(this.AxesPanel);
            this.Axes.Toolbar.Visible = 'off';
            this.Axes.Interactions = [];
            this.Axes.BackgroundColor = 'w';
            this.Axes.XTick = [];
            this.Axes.YTick = [];
            this.Axes.XAxis.TickLabels = {};
            this.Axes.YAxis.TickLabels = {};
            this.Axes.XAxis.LimitsMode = 'manual';
            this.Axes.YAxis.LimitsMode = 'manual';
            this.Axes.XAxis.Visible = 'off';
            this.Axes.YAxis.Visible = 'off';
            this.Axes.XLim = [0.5 size(value,1)+0.5];
            this.Axes.YLim = [0.5 size(value,2)+0.5];
            this.Axes.Box = 'off';
            this.Axes.Position = [-4 -4 this.AxesPanel.InnerPosition(3)+10 this.AxesPanel.InnerPosition(4)+10];
            axis(this.Axes,'off');

            % Create Image
            this.Image = imagesc(value(:,:,1),'Parent',this.Axes,limit);
            this.Image.HitTest = 'off';
                       
            % Add callback to the AxesPanel to resize the Axes
            this.AxesPanel.AutoResizeChildren='off';
            this.AxesPanel.SizeChangedFcn = @(~,~) this.AxesPanelSizeChangedFcn();

            % Create Button
            this.Button = uibutton(gridlayout, 'push');
            this.Button.Layout.Row = gridrow;
            this.Button.Layout.Column = 4;
            this.Button.Text = name;
            this.Button.ButtonPushedFcn = @(~,~) ButtonPushedFcn(this,sysobj,xxxdef,xxxindx);
            this.Button.Tooltip = ['More options for ''',name,''''];
            this.Button.Interruptible = 'off';
            this.Button.BusyAction = 'cancel';
            [r,c,p] = size(value);
            if p>1
                this.Button.Tooltip = sprintf('%s [%dx%dx%d]',name,r,c,p);
            else
                this.Button.Tooltip = sprintf('%s [%dx%d]',name,r,c);
            end
           
            % listen to sysobj for REDRAW events
            this.listener1 = listener(sysobj,'redraw',@(src,evnt) this.Redraw(src,evnt,xxxdef,xxxindx));

            % listen to cpanel for changes to the xxxmode switch
            this.listener2 = listener(cpanel,xxxmode,'PostSet', @(src,evnt) this.ModeListener(cpanel,xxxmode));
        end
        
        function delete(this)
            %disp 'bdControlMatrix.delete'
            delete(this.listener1);
            delete(this.listener2);
            delete(this.dialogbox);
        end
        
        function mode(this,flag)            
            %disp('bdControlMatrix.mode()');
            if flag
                this.EditField1.Visible = 'off';
                this.EditField2.Visible = 'off';
                this.RandButton.Visible = 'on';
                this.PerbButton.Visible = 'on';
            else
                this.EditField1.Visible = 'on';
                this.EditField2.Visible = 'on';
                this.RandButton.Visible = 'off';
                this.PerbButton.Visible = 'off';
            end                        
        end                
    end
    
    % Callbacks that handle component events
    methods (Access = private)
            
        function Redraw(this,sysobj,sysevent,xxxdef,xxxindx)
            %disp 'bdControlMatrix.Redraw()'
            
            % Extract data from sysobj
            value = sysobj.(xxxdef)(xxxindx).value;
            limit = sysobj.(xxxdef)(xxxindx).lim;

            % Extract data status from sysevent
            value_changed = sysevent.(xxxdef)(xxxindx).value;
            limit_changed = sysevent.(xxxdef)(xxxindx).lim;

            % if the limit in sysobj has changed then ...
            if limit_changed
                % update lower and upper edit field widgets
                this.EditField1.Value = limit(1);
                this.EditField2.Value = limit(2);
                
                % update the colour scale limits of the image
                this.Axes.CLim = limit + [-1e-6 1e-6];
            end
            
            % if the value in sysobj has changed then ...
            if value_changed
                % update the image data (use only the first plane of 3D data)
                this.Image.CData = value(:,:,1);
            end            
        end
        
        % Listener for cpanel.xxxmode events
        function ModeListener(this,cpanel,xxxmode)
            %disp('bdControlMatrix.ModeListener');
            
            % extract the relevant mode flag from cpanel
            flag = cpanel.(xxxmode);
            
            % apply the mode to this widget
            this.mode(flag);
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
        
        % RAND Button callback
        function RandButtonPushedFcn(this,sysobj,xxxdef,xxxindx)
            % retrieve the relevant data from sysobj
            limit = sysobj.(xxxdef)(xxxindx).lim;
            value = sysobj.(xxxdef)(xxxindx).value;

            % generate uniform random data between the lower and upper limits
            lo = limit(1);
            hi = limit(2);
            sz = size(value);
            value = (hi-lo)*rand(sz) + lo;           

            % write the data back to sysobj
            sysobj.(xxxdef)(xxxindx).value = value;
                           
            % update the image data (use only the first plane of 3D data)
            this.Image.CData = value(:,:,1);

            % notify everything to redraw (excluding self)
            sysobj.NotifyRedraw(this.listener1);            
        end
        
        % PERB Button callback
        function PerbButtonPushedFcn(this,sysobj,xxxdef,xxxindx)
            % retrieve the relevant data from sysobj
            limit = sysobj.(xxxdef)(xxxindx).lim;
            value = sysobj.(xxxdef)(xxxindx).value;

            % apply a uniform random perturbation to the data
            lo = limit(1);
            hi = limit(2);
            sz = size(value);
            value = value + 0.05*(hi-lo)*(rand(sz)-0.5);
            
            % write the data back to sysobj
            sysobj.(xxxdef)(xxxindx).value = value;
            
            % update the image data (use only the first plane of 3D data)
            this.Image.CData = value(:,:,1);

            % notify everything to redraw (excluding self)
            sysobj.NotifyRedraw(this.listener1);            
        end
        
        % ButtonPushedFcn callback
        function ButtonPushedFcn(this,sysobj,xxxdef,xxxindx)
            name = sysobj.(xxxdef)(xxxindx).name;
            switch xxxdef
                case 'pardef'
                    title = ['Parameter ''',name,''''];
                case 'lagdef'
                    title = ['Lag Parameter ''',name,''''];
                case 'vardef'
                    title = ['Initial Condition ''',name,''''];
            end
            fig = ancestor(this.Button,'figure');
            xpos = fig.Position(1) + randi(100);
            ypos = fig.Position(2) + randi(100);
            this.dialogbox.OpenFigure(xpos,ypos,title);
        end
        
        % AxesPanel Resize callback
        function AxesPanelSizeChangedFcn(this)
            %disp('bdControlMatrix.AxesPanelSizeChangedFcn()');
            w = this.AxesPanel.InnerPosition(3);
            h = this.AxesPanel.InnerPosition(4);
            this.Axes.Position = [-4 -4 w+10 h+10];
        end  
        
    end
end
