classdef bdDialogMatrix < handle
    %bdDialogMatrix  Dialog box for bdGUI.
    %  This class is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2020a,2021a,2026a)

    % Copyright (C) 2020-2026 Stewart Heitmann <heitmann@bdtoolbox.org>
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
        sysobj              bdSystem
        xxxdef              char
        xxxindx             
        
        UIFigure            matlab.ui.Figure
        SettingsMenu        matlab.ui.container.Menu
        CalibrateMenu       matlab.ui.container.Menu
        CloseMenu           matlab.ui.container.Menu
        ValuesMenu          matlab.ui.container.Menu
        RandomMenu          matlab.ui.container.Menu
        PerturbMenu         matlab.ui.container.Menu
        ShuffleMenu         matlab.ui.container.Menu
        GridLayout          matlab.ui.container.GridLayout
        FillEditField       matlab.ui.control.EditField
        FillEditLabel       matlab.ui.control.Label
        LowerEditField      matlab.ui.control.NumericEditField
        LowerEditLabel      matlab.ui.control.Label
        UpperEditField      matlab.ui.control.NumericEditField
        UpperEditLabel      matlab.ui.control.Label
        TabGroup            matlab.ui.container.TabGroup
        Tab1                matlab.ui.container.Tab
        Tab2                matlab.ui.container.Tab
        Tab3                matlab.ui.container.Tab
        Tab4                matlab.ui.container.Tab
        GridLayout1         matlab.ui.container.GridLayout
        GridLayout2         matlab.ui.container.GridLayout
        GridLayout3         matlab.ui.container.GridLayout
        GridLayout4         matlab.ui.container.GridLayout
        UIAxes1             matlab.ui.control.UIAxes
        UIAxes2             matlab.ui.control.UIAxes
        UIAxes3             matlab.ui.control.UIAxes
        UITable             matlab.ui.control.Table
        Image               matlab.graphics.primitive.Image
        Histogram           matlab.graphics.chart.primitive.Histogram
        Statistics          matlab.ui.control.Table
        elistener           event.listener
    end
    
    methods
        function this = bdDialogMatrix(sysobj,xxxdef,xxxindx)
            this.sysobj = sysobj;
            this.xxxdef = xxxdef;
            this.xxxindx = xxxindx;
        end
                
        function OpenFigure(this,x,y,title)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            % Raise any pre-existing figure
            if isvalid(this.UIFigure)
                this.UIFigure.Visible = 'off';
                this.UIFigure.Visible = 'on';
                return
            end
            
            % Extract the relevant data from sysobj
            name  = this.sysobj.(this.xxxdef)(this.xxxindx).name;
            value = this.sysobj.(this.xxxdef)(this.xxxindx).value;
            limit = this.sysobj.(this.xxxdef)(this.xxxindx).lim;
            safelimit = limit + [-1e-9 1e-9];
            
            % Construct a new figure
            this.UIFigure = uifigure('Visible','off');
            this.UIFigure.Position = [x,y,350,380];
            this.UIFigure.Name = title;
            this.UIFigure.CloseRequestFcn = @(src,evnt) CloseFigure(this);
            
            % Create SettingsMenu
            this.SettingsMenu = uimenu(this.UIFigure);
            this.SettingsMenu.Text = 'Settings';
            
            % Create CalibrateMenu
            this.CalibrateMenu = uimenu(this.SettingsMenu);
            this.CalibrateMenu.Text = 'Calibrate';
            this.CalibrateMenu.Tooltip = 'Calibrate the lower and upper limits';
            this.CalibrateMenu.MenuSelectedFcn = @(src,evnt) CalibrateMenuSelected(this);

            % Create CloseMenu
            this.CloseMenu = uimenu(this.SettingsMenu);
            this.CloseMenu.Separator = 'on';
            this.CloseMenu.Text = 'Close';
            this.CloseMenu.Tooltip = 'Close the window';
            this.CloseMenu.MenuSelectedFcn = @(src,evnt) CloseFigure(this);
            
            % Create ValuesMenu
            this.ValuesMenu = uimenu(this.UIFigure);
            this.ValuesMenu.Text = 'Values';
            
            % Create RandomMenu
            this.RandomMenu = uimenu(this.ValuesMenu);
            this.RandomMenu.Text = 'Random';
            this.RandomMenu.Tooltip = 'Assign uniform random values';
            this.RandomMenu.MenuSelectedFcn = @(src,evnt) RandomMenuSelected(this);

            % Create PerturbMenu
            this.PerturbMenu = uimenu(this.ValuesMenu);
            this.PerturbMenu.Text = 'Perturb';
            this.PerturbMenu.Tooltip = 'Perturb all values by a small amount';
            this.PerturbMenu.MenuSelectedFcn = @(src,evnt) PerturbMenuSelected(this);

            % Create ShuffleMenu
            this.ShuffleMenu = uimenu(this.ValuesMenu);
            this.ShuffleMenu.Text = 'Shuffle';
            this.ShuffleMenu.Tooltip = 'Shuffle the order of the data';
            this.ShuffleMenu.MenuSelectedFcn = @(src,evnt) ShuffleMenuSelected(this);

            % Create Grid Layout
            this.GridLayout = uigridlayout(this.UIFigure);
            this.GridLayout.ColumnWidth = {'1x','1x','1x'};
            this.GridLayout.RowHeight = {'1x',25,25};
            this.GridLayout.ColumnSpacing = 20;
            this.GridLayout.RowSpacing = 1;
            
            % Create FillEditLabel
            this.FillEditLabel = uilabel(this.GridLayout);
            this.FillEditLabel.HorizontalAlignment = 'center';
            this.FillEditLabel.VerticalAlignment = 'bottom';
            this.FillEditLabel.Layout.Row = 2;
            this.FillEditLabel.Layout.Column = 1;
            this.FillEditLabel.Text = 'Fill Value';

            % Create FillEditField
            this.FillEditField = uieditfield(this.GridLayout);
            this.FillEditField.HorizontalAlignment = 'center';
            this.FillEditField.Layout.Row = 3;
            this.FillEditField.Layout.Column = 1;
            this.FillEditField.ValueChangedFcn = @(src,evnt) FillEditCallback(this);
            this.FillEditField.Tooltip = 'Fill the table with this value';

            % Create LowerEditLabel
            this.LowerEditLabel = uilabel(this.GridLayout);
            this.LowerEditLabel.HorizontalAlignment = 'center';
            this.LowerEditLabel.VerticalAlignment = 'bottom';
            this.LowerEditLabel.Layout.Row = 2;
            this.LowerEditLabel.Layout.Column = 2;
            this.LowerEditLabel.Text = 'Lower Limit';

            % Create LowerEditField
            this.LowerEditField = uieditfield(this.GridLayout, 'numeric');
            this.LowerEditField.HorizontalAlignment = 'center';
            this.LowerEditField.Layout.Row = 3;
            this.LowerEditField.Layout.Column = 2;
            this.LowerEditField.Value = limit(1);
            this.LowerEditField.ValueChangedFcn = @(src,evnt) LowerEditCallback(this);
            this.LowerEditField.Tooltip = 'Lower limit for plotted data';

            % Create UpperEditLabel
            this.UpperEditLabel = uilabel(this.GridLayout);
            this.UpperEditLabel.HorizontalAlignment = 'center';
            this.UpperEditLabel.VerticalAlignment = 'bottom';
            this.UpperEditLabel.Layout.Row = 2;
            this.UpperEditLabel.Layout.Column = 3;
            this.UpperEditLabel.Text = 'Upper Limit';

            % Create UpperEditField
            this.UpperEditField = uieditfield(this.GridLayout, 'numeric');
            this.UpperEditField.HorizontalAlignment = 'center';
            this.UpperEditField.Layout.Row = 3;
            this.UpperEditField.Layout.Column = 3;
            this.UpperEditField.Value = limit(2);
            this.UpperEditField.ValueChangedFcn = @(src,evnt) UpperEditCallback(this);
            this.UpperEditField.Tooltip = 'Upper limit for plotted data';

            % Create TabGroup
            this.TabGroup = uitabgroup(this.GridLayout);
            this.TabGroup.Layout.Row = 1;
            this.TabGroup.Layout.Column = [1 3];
            
            % Create Tab1
            this.Tab1 = uitab(this.TabGroup);
            this.Tab1.Title = 'Values';

            % Create Tab2
            this.Tab2 = uitab(this.TabGroup);
            this.Tab2.Title = 'Image';
            
            % Create Tab3
            this.Tab3 = uitab(this.TabGroup);
            this.Tab3.Title = 'Histogram';

            % Create Tab4
            this.Tab4 = uitab(this.TabGroup);
            this.Tab4.Title = 'Statistics';

            % Select Tab2 by default
            this.TabGroup.SelectedTab = this.Tab2;
            
            % Create GridLayout1 within Tab1
            this.GridLayout1 = uigridlayout(this.Tab1);
            this.GridLayout1.ColumnWidth = {'1x'};
            this.GridLayout1.RowHeight = {'1x'};

            % Create GridLayout2 within Tab2
            this.GridLayout2 = uigridlayout(this.Tab2);
            this.GridLayout2.ColumnWidth = {'1x'};
            this.GridLayout2.RowHeight = {'1x'};

            % Create GridLayout3 within Tab3
            this.GridLayout3 = uigridlayout(this.Tab3);
            this.GridLayout3.ColumnWidth = {'1x'};
            this.GridLayout3.RowHeight = {'1x'};

            % Create GridLayout4 within Tab4
            this.GridLayout4 = uigridlayout(this.Tab4);
            this.GridLayout4.ColumnWidth = {'1x'};
            this.GridLayout4.RowHeight = {'1x'};

            % Create UITable
            this.UITable = uitable(this.GridLayout1);
            this.UITable.Layout.Row = 1;
            this.UITable.Layout.Column = [1 2];
            this.UITable.ColumnName = 'numbered';
            this.UITable.RowName = 'numbered';
            this.UITable.ColumnEditable = true;
            this.UITable.ColumnFormat = {'LONGG'};
            this.UITable.Data = value;
            this.UITable.DisplayDataChangedFcn = @(src,evnt) UITableDataChanged(this,evnt);
            addStyle(this.UITable, uistyle('HorizontalAlignment','center'));
            
            % Create UIAxes1 (for Image)
            this.UIAxes1 = uiaxes(this.GridLayout2);
            this.UIAxes1.Layout.Row = 1;
            this.UIAxes1.Layout.Column = 1;
            this.UIAxes1.Title.String = sprintf('%s [%dx%d]',name,size(value,1),size(value,2));
            
            % Create Image in UIAxes1
            this.Image = imagesc(value(:,:,1),'Parent',this.UIAxes1,safelimit);
            this.UIAxes1.XLim = [0.5 size(value,2)+0.5];
            this.UIAxes1.YLim = [0.5 size(value,1)+0.5];

            % Create UIAxes2 (for Histogram)
            this.UIAxes2 = uiaxes(this.GridLayout3);
            this.UIAxes2.Layout.Row = 1;
            this.UIAxes2.Layout.Column = 1;
            this.UIAxes2.Title.String = name;
            this.UIAxes2.Title.String = sprintf('%s [%dx%d]',name,size(value,1),size(value,2));
            this.UIAxes2.YLabel.String = 'probability';
            this.UIAxes2.YGrid = 'on';
            this.UIAxes2.XLim = safelimit;
            this.UIAxes2.YLim = [0 1];

            % Create Histogram in UIAxes2
            this.Histogram = histogram(this.UIAxes2,value(:));
            this.Histogram.Normalization = 'probability';
            this.Histogram.BinEdges = linspace(limit(1),limit(2),21);

            % Create Statistics Table
            this.Statistics = uitable(this.GridLayout4);
            this.Statistics.Layout.Row = 1;
            this.Statistics.Layout.Column = 1;
            this.Statistics.ColumnName = [];
            this.Statistics.RowName = {'min','max','mean','std','var'};
            this.Statistics.ColumnEditable = false;
            this.Statistics.ColumnFormat = {'numeric'};
            this.Statistics.Data = [min(value(:)); max(value(:)); mean(value(:)); std(value(:)); var(value(:))];
            addStyle(this.Statistics, uistyle('HorizontalAlignment','center'));
            
            % make the figure visible
            this.UIFigure.Visible='on';
            
            % listen to sysobj for REDRAW events
            this.elistener = listener(this.sysobj,'redraw',@(~,evnt) this.Redraw(evnt));
        end
        
        function delete(this)
            delete(this.elistener);
            delete(this.UIFigure);
        end
        
        function CloseFigure(this)
            delete(this.elistener);
            delete(this.UIFigure);
        end
        
    end
    
    % Callbacks that handle component events
    %methods (Access = private)
    methods (Access = public)
        
        function Redraw(this,sysevent)
            %disp('bdDialogMatrix.Redraw');

            % Extract data status from sysevent
            value_changed = sysevent.(this.xxxdef)(this.xxxindx).value;
            limit_changed = sysevent.(this.xxxdef)(this.xxxindx).lim;

            % if sysobj value has changed then ...
            if value_changed
                % extract the data from sysobj
                value = this.sysobj.(this.xxxdef)(this.xxxindx).value;

                % update the UITable
                this.UITable.Data = value;
            
                % update the Image
                this.Image.CData = value(:,:);

                % update the histogram data
                this.Histogram.Data = value(:);
            
                % update the statistics
                this.Statistics.Data = [min(value(:)); max(value(:)); mean(value(:)); std(value(:)); var(value(:))];
            end
            
            % if sysobj lim has changed then ...
            if limit_changed
                % extract the limits from sysobj
                limit = this.sysobj.(this.xxxdef)(this.xxxindx).lim;

                % construct safe limits for plotting
                axlim = limit + [-1e-9 1e-9];

                % update the Image colour limits
                caxis(this.UIAxes1, axlim);
                
                % update the histogram limits
                this.Histogram.BinEdges = linspace(limit(1),limit(2),21);
                this.UIAxes2.YLim = [0 1];
                this.UIAxes2.XLim = axlim;

                % update lower and upper edit fields
                this.LowerEditField.Value = limit(1);
                this.UpperEditField.Value = limit(2);
            end
        end
        
        % Menu selected function: CalibrateMenu
        function CalibrateMenuSelected(this)
            %disp('CalibrateMenuSelected');
            
            % Calibrate the limits in sysobj
            switch this.xxxdef
                case 'pardef'
                    this.sysobj.CalibratePar(this.xxxindx);
                case 'lagdef'
                    this.sysobj.CalibrateLag(this.xxxindx);
                case 'vardef'
                    this.sysobj.CalibrateVar0(this.xxxindx);
            end
            
            % notify everything (including self) to redraw
            this.sysobj.NotifyRedraw([]);
        end

        % Menu selected function: RandomMenu
        function RandomMenuSelected(this)
            %disp('RandomMenuSelected');
            
            % retrieve the relevant data from sysobj
            limit = this.sysobj.(this.xxxdef)(this.xxxindx).lim;
            value = this.sysobj.(this.xxxdef)(this.xxxindx).value;

            % generate uniform random data between the lower and upper limits
            lo = limit(1);
            hi = limit(2);
            sz = size(value);
            value = (hi-lo)*rand(sz) + lo;           

            % write the data back to sysobj
            this.sysobj.(this.xxxdef)(this.xxxindx).value = value;
            
            % update the UITable
            this.UITable.Data = value;
            
            % update the Image
            this.Image.CData = value(:,:);

            % update the histogram data
            this.Histogram.Data = value(:);
            
            % update the statistics
            this.Statistics.Data = [min(value(:)); max(value(:)); mean(value(:)); std(value(:)); var(value(:))];
                       
            % notify everything to redraw (excluding self)
            this.sysobj.NotifyRedraw(this.elistener);
         end
        
        % Menu selected function: PerturbMenu
        function PerturbMenuSelected(this)
            % retrieve the relevant data from sysobj
            limit = this.sysobj.(this.xxxdef)(this.xxxindx).lim;
            value = this.sysobj.(this.xxxdef)(this.xxxindx).value;

            % thisly a uniform random perturbation to the data
            lo = limit(1);
            hi = limit(2);
            sz = size(value);
            value = value + 0.05*(hi-lo)*(rand(sz)-0.5);
            
            % write the data back to sysobj
            this.sysobj.(this.xxxdef)(this.xxxindx).value = value;
            
            % update the UITable
            this.UITable.Data = value;
            
            % update the Image
            this.Image.CData = value(:,:);

            % update the histogram data
            this.Histogram.Data = value(:);
            
            % update the statistics
            this.Statistics.Data = [min(value(:)); max(value(:)); mean(value(:)); std(value(:)); var(value(:))];
                       
            % notify everything to redraw (excluding self)
            this.sysobj.NotifyRedraw(this.elistener);
        end

        % Menu selected function: ShuffleMenu
        function ShuffleMenuSelected(this)
            % retrieve the relevant data from sysobj
            value = this.sysobj.(this.xxxdef)(this.xxxindx).value;
            sz = size(value);

            % shuffle the order
            len = numel(value);
            idx = randperm(len);
            value = reshape(value(idx),sz);
            
            % write the data back to sysobj
            this.sysobj.(this.xxxdef)(this.xxxindx).value = value;
            
            % update the UITable
            this.UITable.Data = value;
            
            % update the Image
            this.Image.CData = value(:,:);

            % update the histogram data
            this.Histogram.Data = value(:);
            
            % update the statistics
            this.Statistics.Data = [min(value(:)); max(value(:)); mean(value(:)); std(value(:)); var(value(:))];
                       
            % notify everything to redraw (excluding self)
            this.sysobj.NotifyRedraw(this.elistener);
        end
        
        % FillEditField callback function
        function FillEditCallback(this)
            % extract the current value from sysobj
            value = this.sysobj.(this.xxxdef)(this.xxxindx).value;
            
            % convert EditField text to number
            str = this.FillEditField.Value;
            if ~isempty(str)
                val = str2double(str);
                if isnan(val)
                    this.FillEditField.Value='NaN';
                else
                    % Blank the FillEditField
                    this.FillEditField.Value='';
                    
                    % Fill the data
                    value(:) = val;
                    
                    % write value back to sysobj
                    this.sysobj.(this.xxxdef)(this.xxxindx).value = value;
            
                    % update the UITable
                    this.UITable.Data = value;
            
                    % update the Image
                    this.Image.CData = value(:,:);

                    % update the histogram data
                    this.Histogram.Data = value(:);
            
                    % update the statistics
                    this.Statistics.Data = [min(value(:)); max(value(:)); mean(value(:)); std(value(:)); var(value(:))];
                       
                    % notify everything to redraw (excluding self)
                    this.sysobj.NotifyRedraw(this.elistener);
                end
            end
        end        
        
        % LowerEditField callback function
        function LowerEditCallback(this)
            % get the upper and lower limits
            lo = this.LowerEditField.Value;
            hi = this.UpperEditField.Value;
            
            % adjust the upper limit if necessary
            hi = max(lo,hi);

            % write the limit back to sysobj
            this.sysobj.(this.xxxdef)(this.xxxindx).lim = [lo hi];

            % notify everything (including self) to redraw
            this.sysobj.NotifyRedraw([]);
        end        
        
        % UpperEditField callback function
        function UpperEditCallback(this,evnt)
            % get the upper and lower limits
            lo = this.LowerEditField.Value;
            hi = this.UpperEditField.Value;
            
            % adjust the lower limit if necessary
            lo = min(lo,hi);

            % write the limit back to sysobj
            this.sysobj.(this.xxxdef)(this.xxxindx).lim = [lo hi];

            % notify everything (including self) to redraw
            this.sysobj.NotifyRedraw([]);
        end        

        % UITable Data Changed by User
        function UITableDataChanged(this,evnt)
            %disp('UITableDataChanged');

            % extract the value from UITable
            value = this.UITable.Data;

            % write the value into sysobj
            this.sysobj.(this.xxxdef)(this.xxxindx).value = value;

            % update the Image
            this.Image.CData = value(:,:);

            % update the histogram data
            this.Histogram.Data = value(:);

            % update the statistics
            this.Statistics.Data = [min(value(:)); max(value(:)); mean(value(:)); std(value(:)); var(value(:))];
            
            % notify everything (excluding self) to redraw
            this.sysobj.NotifyRedraw(this.elistener);
        end
        
    end
end
