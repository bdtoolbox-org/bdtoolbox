classdef bdSurrogate < bdPanelBase
    %bdSurrogate Display panel for the Surrogate data transform
    %   This display panel constructs phase-randomized surrogate data from
    %   simulated data by adding random numbers to the phase component of
    %   the data using an amplitude-adjusted algorithm. 
    %   
    %AUTHORS
    %  Stewart Heitmann (2017b,2017c,2018a,2020a,2021a)
    %  The transform itself is based on original code from Michael Breakspear.
    
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
        axes1       matlab.ui.control.UIAxes    % upper axes
        axes2       matlab.ui.control.UIAxes    % lower axes
        t           double                      % equi-spaced time points
        y           double                      % time series data
        ysurr       double                      % surrogate version of y
    end
    
    properties (Access=private)
        sysobj              bdSystem
        selector            bdSelector
        
        menu                matlab.ui.container.Menu
        menuMarkers         matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
        
        tab                 matlab.ui.container.Tab           
        label               matlab.ui.control.Label
        button              matlab.ui.control.Button
        
        trace1              matlab.graphics.primitive.Line
        trace2              matlab.graphics.primitive.Line
        
        line1               matlab.graphics.primitive.Line
        line2               matlab.graphics.primitive.Line
        
        marker1b            matlab.graphics.primitive.Line
        marker1c            matlab.graphics.primitive.Line
        marker2b            matlab.graphics.primitive.Line
        marker2c            matlab.graphics.primitive.Line

        listener1           event.listener
        listener2           event.listener
        listener3           event.listener
    end
    
    methods
        function this = bdSurrogate(tabgrp,sysobj,opt)
            %disp('bdSurrogate');
            
            % remember the parents
            this.sysobj = sysobj;
            
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','Surrogate', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');
            
            % construct the CALIBRATE menu item
            uimenu(this.menu, ...
                'Label', 'Calibrate', ...
                'Tooltip', 'Calibrate the axes to fit the data', ...
                'Callback', @(~,~) this.callbackCalibrate() );                        
            
            % construct the MARKERS menu item
            this.menuMarkers = uimenu(this.menu, ...
                'Label', 'Markers', ...
                'Checked', 'on', ...
                'Tag', 'markers', ...
                'Tooltip', 'Show the trajectory markers', ...               
                'Callback', @(src,~) this.callbackMarkers(src) );
                        
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
            this.tab = uitab(tabgrp, 'Title','Surrogate', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'1x','2x','1x'};
            GridLayout.RowHeight = {21,'1x','1x'};
            GridLayout.RowSpacing = 10;
            GridLayout.Visible = 'off';

            % Construct the selector object
            this.selector = bdSelector(sysobj,'vardef');                  
          
            % Create DropDownCombo for selector
            combo = this.selector.DropDownCombo(GridLayout);
            combo.Layout.Row = 1;
            combo.Layout.Column = 1;

            % Create label
            this.label = uilabel(GridLayout);
            this.label.Layout.Row = 1;
            this.label.Layout.Column = 2;
            this.label.Text = 'Not all background traces are shown';
            this.label.VerticalAlignment = 'center';
            this.label.HorizontalAlignment = 'center';
            this.label.FontColor = [0.5 0.5 0.5];
            this.label.Visible = 'on';

            % Create button
            this.button = uibutton(GridLayout);
            this.button.Layout.Row = 1;
            this.button.Layout.Column = 3;
            this.button.Text = 'Recompute';
            this.button.ButtonPushedFcn = @(~,~) this.callbackButton();
            
            % Create axes1
            this.axes1 = uiaxes(GridLayout);
            this.axes1.Layout.Row = 2;
            this.axes1.Layout.Column = [1 3];
            this.axes1.NextPlot = 'add';
            this.axes1.XLabel.String = 'time';
            this.axes1.FontSize = 11;            
            this.axes1.XGrid = 'off';
            this.axes1.YGrid = 'off';
            this.axes1.Box = 'on';
            this.axes1.XLim = sysobj.tspan + [-1e-9 1e-9];
            this.axes1.YLim = this.selector.lim();
            this.axes1.Title.String = 'Original';
            axtoolbar(this.axes1,{'export','datacursor'});
            
            % Create axes2
            this.axes2 = uiaxes(GridLayout);
            this.axes2.Layout.Row = 3;
            this.axes2.Layout.Column = [1 3];
            this.axes2.NextPlot = 'add';
            this.axes2.XLabel.String = 'time';
            this.axes2.FontSize = 11;
            this.axes2.XGrid = 'off';
            this.axes2.YGrid = 'off';
            this.axes2.Box = 'on';
            this.axes2.XLim = sysobj.tspan + [-1e-9 1e-9];
            this.axes2.YLim = this.selector.lim();              
            this.axes2.Title.String = 'Surrogate';
            axtoolbar(this.axes2,{'export','datacursor'});

            % Construct background traces (containing NaN)
            this.trace1 = line(this.axes1,NaN,NaN, 'LineStyle','-', 'color',[0.8 0.8 0.8], 'Linewidth',0.5, 'PickableParts','none');
            this.trace2 = line(this.axes2,NaN,NaN, 'LineStyle','-', 'color',[0.8 0.8 0.8], 'Linewidth',0.5, 'PickableParts','none');
            
            % Construct the line plots (containing NaN)
            this.line1 = line(this.axes1,NaN,NaN,'LineStyle','-','color','k','Linewidth',1.5);
            this.line2 = line(this.axes2,NaN,NaN,'LineStyle','-','color','k','Linewidth',1.5);

            % Construct the markers
            this.marker1b = line(this.axes1,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor','w');
            this.marker1c = line(this.axes1,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor',[0.6 0.6 0.6]);
            this.marker2b = line(this.axes2,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor','w');
            this.marker2c = line(this.axes2,NaN,NaN,'Marker','o','color','k','Linewidth',1.25,'MarkerFaceColor',[0.6 0.6 0.6]);

            % apply the custom options (and render the data)
            this.options = opt;

            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';

            % listen for Redraw events
            this.listener1 = listener(sysobj,'redraw',@(src,evnt) this.Redraw(evnt));
            
            % listen for SelectionChanged events
            this.listener2 = listener(this.selector,'SelectionChanged',@(src,evnt) this.SelectorChanged());
            
            % listen for SubscriptChanged events
            this.listener3 = listener(this.selector,'SubscriptChanged',@(src,evnt) this.SubscriptChanged());
                       
        end
        
        function opt = get.options(this)
            opt.title    = this.tab.Title;
            opt.markers  = this.menuMarkers.Checked;
            opt.selector = this.selector.cellspec();
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
                        
            % update the MARKERS menu
            this.menuMarkers.Checked = opt.markers;
            
            % Recompute the transform
            this.ComputeSurrogate();
            
            % Redraw everything
            this.RenderBackground();
            this.RenderForeground();
            drawnow;
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        function delete(this)
           %disp('bdSurrogate.delete()');
           delete(this.listener1);
           delete(this.listener2);
           delete(this.listener3);
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods (Access=private)

        % Listener for REDRAW events
        function Redraw(this,evnt)
            %disp('bdSurrogate.Redraw()');
       
             % If the solution (sol) or the time slider (tval) have changed
             % then recompute the surrogate data
             if evnt.sol || evnt.tval
                this.ComputeSurrogate();
                this.RenderBackground();
                this.RenderForeground();
             end
             
            % Get the current selector settings
            [xxxdef,xxxindx] = this.selector.Item();
            
            % If the plot limit has changed
            % then update the vertical plot limits
            if evnt.(xxxdef)(xxxindx).lim
                plim = this.selector.lim();
                this.axes1.YLim = plim;
                this.axes2.YLim = plim; 
            end
        end
        
        function ComputeSurrogate(this)
            % Evaluate the selected variable at fixed time steps.
            [Y,~,tdomain,~,tindx1] = this.selector.Trajectory('autostep','off');

            % Ensure that Y is not 3D format
            Y = reshape(Y,[],numel(tdomain),1);
                     
            % We only compute the surrogate data for the non-transient
            % part of the solution.
            this.t = tdomain(tindx1);
            this.y = Y(:,tindx1);
                  
            if numel(this.y) > 1
                % compute the surrogate data
                this.ysurr = this.ampsurr(this.y);
            else
                this.ysurr = this.y;
            end
        end
  
        % Render the background traces
        function RenderBackground(this)
            %disp('bdSurrogate.RenderBackground()');
            
            % Number of trajectories in our solution
            ny = size(this.y,1);        
                
            % Number of background traces to plot (100 at most)
            ntrace = min(ny,100);
            
            % Warn of suppressed traces
            if ntrace<ny
                this.label.Visible = 'on';
            else
                this.label.Visible = 'off';
            end
                
            % Update the background traces
            if ntrace>1
                % indicies of the selected trajectories
                yindx = round(linspace(1,ny,ntrace));

                % collate all trajectories into a single trace separated by NaN
                xtrace1 = (ones(ntrace,1)*[this.t NaN])';
                ytrace1 = [this.y(yindx,:), NaN(ntrace,1)]';
                xtrace1 = reshape(xtrace1,1,[]);
                ytrace1 = reshape(ytrace1,1,[]);

                % collate the surrogates into a single trace separated by NaN
                xtrace2 = (ones(ntrace,1)*[this.t NaN])';
                ytrace2 = [this.ysurr(yindx,:), NaN(ntrace,1)]';
                xtrace2 = reshape(xtrace2,1,[]);
                ytrace2 = reshape(ytrace2,1,[]);

                % update the line data
                set(this.trace1, 'XData',xtrace1, 'YData',ytrace1);                
                set(this.trace2, 'XData',xtrace2, 'YData',ytrace2);                    
            else
                set(this.trace1, 'XData',NaN, 'YData',NaN);
                set(this.trace2, 'XData',NaN, 'YData',NaN);
            end
            
            % update the time limits
            tlim = this.t([1 end]) + [-1e-9 1e-9];
            this.axes1.XLim = tlim;
            this.axes2.XLim = tlim;
            
            % update the time labels
            this.axes1.XLabel.String = sprintf('time (dt=%g)',this.sysobj.tstep);
            this.axes2.XLabel.String = sprintf('time (dt=%g)',this.sysobj.tstep);
        end
        
        % Render the trajectories
        function RenderForeground(this)
            %disp('bdSurrogate.RenderForeground()');
            
            % get the selected subscripts and convert to an index
            [rindx,cindx] = this.selector.subscripts();
            [nr,nc] = this.selector.vsize();
            indx = sub2ind([nr,nc],rindx,cindx);
            
            % update the foreground trajectory plot (upper axes)
            this.line1.XData = this.t;
            this.line1.YData = this.y(indx,:);
            
            % update the foreground surrogate plot (lower axes)
            this.line2.XData = this.t;
            this.line2.YData = this.ysurr(indx,:);

            % update the markers (upper axes)
            set(this.marker1b, 'XData',this.t(1),   'YData',this.y(indx,1));
            set(this.marker1c, 'XData',this.t(end), 'YData',this.y(indx,end));
            
            % update the markers (lower axes)
            set(this.marker2b, 'XData',this.t(1),   'YData',this.ysurr(indx,1));
            set(this.marker2c, 'XData',this.t(end), 'YData',this.ysurr(indx,end));

            % visibility of markers
            this.marker1b.Visible = this.menuMarkers.Checked;
            this.marker1c.Visible = this.menuMarkers.Checked;
            this.marker2b.Visible = this.menuMarkers.Checked;
            this.marker2c.Visible = this.menuMarkers.Checked;
                               
            % update the axes labels
            [~,~,name] = this.selector.name();
            this.axes1.YLabel.String = name;
            this.axes2.YLabel.String = name;     
        end
                
        % Selector Changed callback
        function SelectorChanged(this)
            %disp('bdSurrogate.SelectorChanged');
            
            % Recompute and render the result
            this.ComputeSurrogate();
            this.RenderBackground();
            this.RenderForeground();
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        % SubscriptChangedCallback
        function SubscriptChanged(this)
            %disp('bdSurrogate.SubscriptChanged');
            
            % Render the existing result
            this.RenderForeground();
                        
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
            
        % Recompute BUTTON callback
        function callbackButton(this)
            % Recompute and render the result
            this.ComputeSurrogate();
            this.RenderBackground();
            this.RenderForeground();
        end
        
        % CALIBRATE menu callback
        function callbackCalibrate(this)
            % time domain
            tspan = this.t([1 end]);
                        
            % Calibrate the plot limit via the selector
            lim = this.selector.Calibrate(tspan);
                                
            % Update the plot limits
            this.axes1.YLim = lim + [-1e-9 1e-9];
            this.axes2.YLim = lim + [-1e-9 1e-9]; 

            % redraw all panels (because the new limits apply to all panels)
            this.sysobj.NotifyRedraw([]);
        end
            
        % MARKERS menu callback
        function callbackMarkers(this,menuitem)
            this.MenuToggle(menuitem);
            this.RenderForeground();
                        
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
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
            
            % Push the new settings onto the UNDO stack
            notify(sysobj,'push');            
        end
        

    end
    
    methods (Static)
        
        function optout = optcheck(opt)
            % check the format of incoming options and apply defaults to missing values
            optout.title        = bdPanelBase.GetOption(opt, 'title', 'Surrogate');
            optout.transients   = bdPanelBase.GetOption(opt, 'transients', 'on');
            optout.markers      = bdPanelBase.GetOption(opt, 'markers', 'on');
            optout.selector     = bdPanelBase.GetOption(opt, 'selector', {1,1,1});
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning(sprintf('Ignoring unknown panel option ''bdSurrogate.%s''',newfields{idx}));
            end
        end
        
        % Creates surrogate multichannel data, by adding random numbers
        % to phase component of all channel data, using amplitude adjusted algorithm.
        % Derived from original code by Michael Breakspear.
        function y = ampsurr(x)
            [r,c] = size(x);
            if r < c
                x = x.';   % make each column a timeseries
            end;
            [n,cc] = size(x);
            m = 2^nextpow2(n);
            yy=zeros(n,cc);
            for i=1:cc    %create a gaussian timeseries with the same rank-order of x
               z=zeros(n,3); gs=sortrows(randn(n,1),1);
               z(:,1)=x(:,i); z(:,2)=[1:n]'; z=sortrows(z,1);
               z(:,3)=gs; z=sortrows(z,2); yy(:,i)=z(:,3);
            end
            phsrnd=zeros(m,cc);
            phsrnd(2:m/2,1)=rand(m/2-1,1)*2*pi; phsrnd(m/2+2:m,1)=-phsrnd(m/2:-1:2,1);
            for i=2:cc 
                phsrnd(:,i)=phsrnd(:,1);
            end
            m = 2^nextpow2(n);
            xx = fft(real(yy),m);
            phsrnd=zeros(m,cc);
            phsrnd(2:m/2,1)=rand(m/2-1,1)*2*pi; phsrnd(m/2+2:m,1)=-phsrnd(m/2:-1:2,1);
            for i=2:cc 
                phsrnd(:,i)=phsrnd(:,1);
            end
            xx = xx.*exp(phsrnd*sqrt(-1));
            xx = ifft(xx,m);
            xx = real(xx(1:n,:));
            y=zeros(n,cc);
            for i=1:cc    %reorder original timeseries to have the same rank-order of xx
               z=zeros(n,3); yst=sortrows(x(:,i));
               z(:,1)=xx(:,i); z(:,2)=[1:n]'; z=sortrows(z,1);
               z(:,3)=yst; z=sortrows(z,2); y(:,i)=z(:,3);
            end
            if r < c
               y = y.';
            end
            y=real(y);    %small imag. component created by rounding error
        end
        
    end
end

