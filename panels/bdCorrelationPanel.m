classdef bdCorrelationPanel < handle
    %bdCorrelationPanel - Brain Dynamics GUI panel for cross-correlations.
    %   Displays cross-correlations between variables of a dynamical
    %   system.
    %
    %SYS OPTIONS
    %   sys.gui.bdCorrelationPanel.title      Name of the panel (optional)
    %
    %AUTHORS
    %  Stewart Heitmann (2016a)

    % Copyright (C) 2016, QIMR Berghofer Medical Research Institute
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
        R       % matrix of correlation cooefficients
    end
    
    properties (Access=private) 
        tab             % handle to uitab object
        ax              % handle to plot axes
        img             % handle to axes image
        popup           % handle to variable selector
        varMap          % maps entries in vardef to rows in sol.y
        auxMap          % maps entries in auxdef to rows in sal
    end
    
    methods
        function this = bdCorrelationPanel(tabgroup,control)
            if ~isfield(control.sys.gui,'bdCorrelationPanel')
                return      % we aren't wanted so quietly do nothing.
            end
            
            % sys.gui.bdCorrelationPanel.title (optional)
            if isfield(control.sys.gui.bdCorrelationPanel,'title')
                title = control.sys.gui.bdCorrelationPanel.title;
            else
                title = 'Correlation';
            end

           % map vardef entries to rows in sol
            this.varMap = bdUtils.varMap(control.sys.vardef);
            if isfield(control.sys,'auxdef')
                % map auxdef entries to rows in sal
                this.auxMap = bdUtils.varMap(control.sys.auxdef);
            else
                % construct empty maps
                this.auxMap = bdUtils.varMap([]);
            end
            
            % construct the uitab
            this.tab = uitab(tabgroup,'title',title, 'Units','pixels');
            
            % get tab geometry
            parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % plot axes
            posx = 50;
            posy = 80;
            posw = parentw-120;
            posh = parenth-90;
            this.ax = axes('Parent',this.tab, ...
                'Units','pixels', ...
                'Position',[posx posy posw posh]);           

            % plot image (empty)
            this.img = imagesc([],'Parent',this.ax);
            xlabel('node', 'FontSize',16);
            ylabel('node', 'FontSize',16);
                        
            % Force CLim to manual mode and add a colorbar
            this.ax.CLim = [-1 1];
            this.ax.CLimMode = 'manual';
            colorbar('peer',this.ax);
            
            % var selector
            posx = 10;
            posy = 10;
            posw = 100;
            posh = 20;

            %popuplist = {this.solMap.name, this.salMap.name};
            popuplist = {this.varMap.name, this.auxMap.name};
            this.popup = uicontrol('Style','popup', ...
                'String', popuplist, ...
                'Value', 1, ...
                'Callback', @(~,~) this.selectorCallback(control), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.tab, ...
                'Position',[posx posy posw posh]);

            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));

            % listen to the control panel for redraw events
            addlistener(control,'redraw',@(~,~) this.render(control));    
        end
        
        function render(this,control)
            %disp('bdCorrelationPanel.render()')
            
            % Cross-correlation assumes equi-spaced time steps. However
            % many of our solver are auto-steppers, so we must interpolate
            % the solution to ensure that our time steps are equi-spaced.
            % How we interpolate depends on the type of solver.

            % Determine the type of the active solver
            solvertype = control.solvermap(control.solveridx).solvertype;

            % We must also be mindful that interpolating solutions from
            % stochastic differential equations is difficult because the value
            % returned must be drawn from a specific distribution dependent on
            % any already determined surrounding points and time- and state-
            % dependent diffusion rate.
            switch solvertype
                case 'sde'
                    % We have not yet implemented correct interpolation of 
                    % stochastic processes. We know the SDE solver uses
                    % fixed time steps so we use the solver's own time steps
                    % as our interpolant time steps.
                    tinterp = find(control.sol.x>=0);

                otherwise
                    % We assume that interpolation is correct for all
                    % other solvers. We choose the number of time
                    % steps of the interpolant to be similar to the
                    % number of steps chosen by the solver. This avoids
                    % over-sampling and under-sampling by our interpolation.
                    % The number of time steps we choose need not be exact.
                    tinterp = linspace(0,control.sol.x(end),numel(control.sol.x));                        
            end

            % read the variable selector
            popindx = this.popup.Value;

            % number of row entries in vardef and varMap
            nvardef = size(this.varMap,1);
     
            % if the user selected a variable from vardef then ...
            if popindx <= nvardef
                % the popup index corresponds to a vardef entry.
                solrows = this.varMap(popindx).solindx;                
                
                % interpolate the solution
                %Y = control.deval(tinterp,solrows)';                
                Y = bdEval(control.sol,tinterp,solrows);
            else
                % the popup index refers to an auxilary variable 
                solrows = this.auxMap(popindx-nvardef).solindx;
                
                % interpolate the aux solution
                %Y = interp1(control.sol.x,control.sal(solrows,:)',tinterp);                
                Y = bdEval(control.solx,tinterp,solrows);
            end
            
            % compute the cross correlation
            if size(Y,2)==1
                this.R = 1;
            else
                this.R = corr(Y');
                nanindx = isnan(this.R);
                this.R(nanindx) = 1;
            end
                
            % update the cross-correlation matrix (image)
            this.img.CData = this.R; % * size(colormap,1);
            xlim(this.ax,[0.5 size(this.R,1)+0.5]);
            ylim(this.ax,[0.5 size(this.R,1)+0.5]);  
            
            % clean up the Tick labels if n is small.
            n = size(this.R,1);
            if n<=20
                set(this.ax,'XTick',1:n);
                set(this.ax,'YTick',1:n);
            end

        end
    end
    
    
    methods (Access=private)
        
        % Callback for panel resizing. 
        function SizeChanged(this,parent)
            % get new parent geometry
            parentw = parent.Position(3);
            parenth = parent.Position(4);            
            % resize the axes
            this.ax.Position = [50, 80, parentw-120, parenth-90];
        end
         
        % Callback ffor the plot variable selectors
        function selectorCallback(this,control)
            this.render(control);
        end
        
    end
    
end

