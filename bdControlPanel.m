classdef bdControlPanel < handle
    %bdControlPanel  Control panel widget for bdGUI.
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
    
    properties (SetObservable)
        parmode = true  
        lagmode = true
        varmode = true
    end
    
    properties (Access=public)
        GridLayout          matlab.ui.container.GridLayout
        ParCheckBox         matlab.ui.control.CheckBox
        LagCheckBox         matlab.ui.control.CheckBox
        VarCheckBox         matlab.ui.control.CheckBox
        NoiseHoldCheckBox   matlab.ui.control.CheckBox
        PerturbCheckBox     matlab.ui.control.CheckBox
        EvolveCheckBox      matlab.ui.control.CheckBox

        rlistener           event.listener
    end
    
    methods
        function this = bdControlPanel(sysobj,uiparent)
            % Default RowHeight
            RowHeight = 21;
            
            % Create the GridLayout
            this.GridLayout = uigridlayout(uiparent);
            this.GridLayout.ColumnWidth = {'1x','1x','1x','1x'};
            this.GridLayout.RowHeight = {};
            this.GridLayout.ColumnSpacing = 5;
            this.GridLayout.RowSpacing = 5;
            this.GridLayout.Scrollable = 'on';
            this.GridLayout.Padding = [5 40 5 0];

            % Start with the first row
            gridrow = 1;       
            this.GridLayout.RowHeight{gridrow} = RowHeight;

            % Parameters Checkbox
            this.ParCheckBox = uicheckbox(this.GridLayout);
            this.ParCheckBox.Text = 'Parameters';
            this.ParCheckBox.FontWeight = 'bold';
            this.ParCheckBox.Layout.Row = gridrow;
            this.ParCheckBox.Layout.Column = [1 4];
            this.ParCheckBox.Value = 1;
            this.ParCheckBox.ValueChangedFcn = @(src,evnt) this.ModeChanged('parmode',src);
            
            % Parameter Widgets
            for idx = 1:numel(sysobj.pardef)
                % next row
                gridrow = gridrow + 1;
                % construct the relevant control widget
                switch this.numdims(sysobj.pardef(idx).value)
                    case 0
                        % construct control widget for a scalar value
                        bdControlScalar(sysobj,this,'pardef',idx,'parmode',this.GridLayout,gridrow);
                        this.GridLayout.RowHeight{gridrow} = RowHeight;
                    case 1
                        %construct control widget for a vector value
                        bdControlVector(sysobj,this,'pardef',idx,'parmode',this.GridLayout,gridrow);                        
                        this.GridLayout.RowHeight{gridrow} = RowHeight;
                    case 2
                        %construct control widget for a matrix value
                        bdControlMatrix(sysobj,this,'pardef',idx,'parmode',this.GridLayout,gridrow);                        
                        this.GridLayout.RowHeight{gridrow} = 2.5*RowHeight;
                end                
            end
            
            % empty row
            gridrow = gridrow+1;
            this.GridLayout.RowHeight{gridrow} = RowHeight/2;
            
            switch sysobj.solvertype
                case 'ddesolver'
                    % next row
                    gridrow = gridrow+1;
                    
                    % Time Lags Checkbox
                    this.LagCheckBox = uicheckbox(this.GridLayout);
                    this.LagCheckBox.Text = 'Time Lags';
                    this.LagCheckBox.FontWeight = 'bold';
                    this.LagCheckBox.Layout.Row = gridrow;
                    this.LagCheckBox.Layout.Column = [1 4];
                    this.LagCheckBox.Value = 1;
                    this.LagCheckBox.ValueChangedFcn = @(src,evnt) this.ModeChanged('lagmode',src);
                    this.GridLayout.RowHeight{gridrow} = RowHeight;

                    % Lag Parameter Widgets
                    for idx = 1:numel(sysobj.lagdef)
                        % next row
                        gridrow = gridrow + 1;
                        this.GridLayout.RowHeight{gridrow} = RowHeight;
                        % construct the relevant control widget
                        switch this.numdims(sysobj.lagdef(idx).value)
                            case 0
                                % construct control widget for a scalar value
                                bdControlScalar(sysobj,this,'lagdef',idx,'lagmode',this.GridLayout,gridrow);
                            case 1
                                %construct control widget for a vector value
                                bdControlVector(sysobj,this,'lagdef',idx,'lagmode',this.GridLayout,gridrow);                        
                            case 2
                                %construct control widget for a matrix value
                                bdControlMatrix(sysobj,this,'lagdef',idx,'lagmode',this.GridLayout,gridrow);                        
                                this.GridLayout.RowHeight{gridrow} = 2.5*RowHeight;
                        end                
                    end

                    % empty row
                    gridrow = gridrow+1;
                    this.GridLayout.RowHeight{gridrow} = RowHeight/2;
                    
                case 'sdesolver'
                    % next row
                    gridrow = gridrow+1;
                    
                    % Noise Samples Heading
                    NoiseLabel = uilabel(this.GridLayout);
                    NoiseLabel.Text = 'Noise Samples';
                    NoiseLabel.FontWeight = 'bold';
                    NoiseLabel.Layout.Row = gridrow;
                    NoiseLabel.Layout.Column = [1 4];
                    this.GridLayout.RowHeight{gridrow} = RowHeight;                    

                    % next row
                    gridrow = gridrow+1;

                    % Noise Hold Checkbox
                    this.NoiseHoldCheckBox = uicheckbox(this.GridLayout);
                    this.NoiseHoldCheckBox.Text = 'Hold';
                    this.NoiseHoldCheckBox.Layout.Row = gridrow;
                    this.NoiseHoldCheckBox.Layout.Column = 1;
                    this.GridLayout.RowHeight{gridrow} = RowHeight;                    
                    this.NoiseHoldCheckBox.Value = sysobj.noisehold;
                    this.NoiseHoldCheckBox.ValueChangedFcn = @(~,~) this.NoiseHoldChanged(sysobj);

                   % empty row
                    gridrow = gridrow+1;
                    this.GridLayout.RowHeight{gridrow} = RowHeight/2;
            end
            
            % next row
            gridrow = gridrow+1;
            this.GridLayout.RowHeight{gridrow} = RowHeight;

            % Initial Conditions Checkbox
            this.VarCheckBox = uicheckbox(this.GridLayout);
            this.VarCheckBox.Text = 'Initial Conditions';
            this.VarCheckBox.FontWeight = 'bold';
            this.VarCheckBox.Layout.Row = gridrow;
            this.VarCheckBox.Layout.Column = [1 4];
            this.VarCheckBox.Value = 1;
            this.VarCheckBox.ValueChangedFcn = @(src,evnt) this.ModeChanged('varmode',src);
            
            % Initial Conditions Widgets
            for idx = 1:numel(sysobj.vardef)
                % next row
                gridrow = gridrow + 1;
                this.GridLayout.RowHeight{gridrow} = RowHeight;
                
                % construct the relevant control widget
                switch this.numdims(sysobj.vardef(idx).value)
                    case 0
                        % construct control widget for a scalar value
                        bdControlScalar(sysobj,this,'vardef',idx,'varmode',this.GridLayout,gridrow);
                    case 1
                        %construct control widget for a vector value
                        bdControlVector(sysobj,this,'vardef',idx,'varmode',this.GridLayout,gridrow);                        
                    case 2
                        %construct control widget for a matrix value
                        bdControlMatrix(sysobj,this,'vardef',idx,'varmode',this.GridLayout,gridrow);                        
                        this.GridLayout.RowHeight{gridrow} = 2.5*RowHeight;
                end
            end
            
            % next row
            gridrow = gridrow+1;
            this.GridLayout.RowHeight{gridrow} = RowHeight;
            
            minigrid = uigridlayout(this.GridLayout);
            minigrid.Layout.Row = gridrow;
            minigrid.Layout.Column = [1 3];
            minigrid.ColumnWidth = {'1x','1x'};
            minigrid.RowHeight = {RowHeight};
            minigrid.Padding = [0 0 0 0];

            % Evolve Checkbox
            this.EvolveCheckBox = uicheckbox(minigrid);
            this.EvolveCheckBox.Text = 'Evolve';
            this.EvolveCheckBox.Tooltip = 'Evolve the initial conditions';
            this.EvolveCheckBox.Layout.Row = 1;
            this.EvolveCheckBox.Layout.Column = 1;
            this.EvolveCheckBox.Value = sysobj.evolve;
            this.EvolveCheckBox.ValueChangedFcn = @(~,~) this.EvolveChanged(sysobj);

            % Perturb Checkbox
            this.PerturbCheckBox = uicheckbox(minigrid);
            this.PerturbCheckBox.Text = 'Perturb';
            this.PerturbCheckBox.Tooltip = 'Perturb the initial conditions';
            this.PerturbCheckBox.Layout.Row = 1;
            this.PerturbCheckBox.Layout.Column = 2;
            this.PerturbCheckBox.Value = sysobj.perturb;
            this.PerturbCheckBox.ValueChangedFcn = @(~,~) this.PerturbChanged(sysobj);

%             EVOLVE button
%             this.EvolveButton = uibutton(this.GridLayout);
%             this.EvolveButton.Text = 'EVOL';
%             this.EvolveButton.Layout.Row = gridrow;
%             this.EvolveButton.Layout.Column = 3;
%             this.EvolveButton.Tooltip = 'Evolve the Initial Conditions';
%             this.EvolveButton.ButtonPushedFcn = @(src,evnt) EvolveButtonCallback(this,sysobj);

            % RAND button
            RandButton = uibutton(this.GridLayout);
            RandButton.Text = 'RAND';
            RandButton.Layout.Row = gridrow;
            RandButton.Layout.Column = 4;
            RandButton.Tooltip = 'Random Initial Conditions';
            RandButton.ButtonPushedFcn = @(src,evnt) RandButtonCallback(this,sysobj);
            RandButton.Interruptible = 'off';
            RandButton.BusyAction = 'cancel';

            % listen to sysobj for REDRAW events
            this.rlistener = listener(sysobj,'redraw',@(src,evnt) this.Redraw(src,evnt));       
        end

        function delete(this)
            delete(this.rlistener);
        end
        
        function ModeChanged(this,xxxmode,checkbox)
            this.(xxxmode) = checkbox.Value;
        end

        function NoiseHoldChanged(this,sysobj)
            % update sysobj
            sysobj.noisehold = this.NoiseHoldCheckBox.Value;
            if sysobj.noisehold
                % number of noise sources
                r = sysobj.sdeoption.NoiseSources;
                % number of time steps
                s = abs(sysobj.tspan(2) - sysobj.tspan(1)) / sysobj.tstep + 1;
                if isempty(sysobj.sol.dW)
                    % generate pre-ordained noise samples
                    sysobj.sdeoption.randn = randn(r,s);
                else
                    % re-use the current noise samples as pre-ordained noise
                    sysobj.sdeoption.randn = sysobj.sol.dW ./ sqrt(sysobj.tstep);
                end
            else
                % let the solver generate the noise samples
                sysobj.sdeoption.randn=[];
            end
            % notify all panels (except self) to redraw
            sysobj.NotifyRedraw(this.rlistener);
        end
        
        function EvolveChanged(this,sysobj)
            %disp('bdControlPanel.EvolveChanged');
            % update sysobj
            sysobj.evolve = this.EvolveCheckBox.Value;
            % if we have just started evolving then reset the nevolve counter
            if sysobj.evolve
                sysobj.indicators.nevolve = 0;
            end
            % notify all panels (except self) to redraw
            sysobj.NotifyRedraw(this.rlistener);
        end
        
        function PerturbChanged(this,sysobj)
            %disp('bdControlPanel.PerturbChanged');
            % update sysobj
            sysobj.perturb = this.PerturbCheckBox.Value;
            % notify all panels (except self) to redraw
            sysobj.NotifyRedraw(this.rlistener);
        end

        function RandButtonCallback(this,sysobj)
            % randomize the initial conditions in sysobj.vardef.value
            for indx = 1:numel(sysobj.vardef)
                lo = sysobj.vardef(indx).lim(1);
                if isinf(lo)
                    lo = -realmax/10;
                end
                hi = sysobj.vardef(indx).lim(2);
                if isinf(hi)
                    hi = realmax/10;
                end
                sz = size(sysobj.vardef(indx).value);
                sysobj.vardef(indx).value = (hi-lo)*rand(sz) + lo;
            end
            
            % notify all panels (except self) to redraw
            sysobj.NotifyRedraw(this.rlistener);
        end
        
        function Redraw(this,sysobj,sysevent)
            %disp('bdControlPanel.Redraw');
            
            % if sysobj.noisehold has changed then ...
            if sysevent.noisehold && ~isempty(sysobj.noisehold)
                % update the NoiseHold Checkbox
                this.NoiseHoldCheckBox.Value = sysobj.noisehold;
            end
            
            % if sysobj.evolve has changed then ...
            if sysevent.evolve
                % update the Evolve Checkbox
                this.EvolveCheckBox.Value = sysobj.evolve;
            end
            
            % if sysobj.perturb has changed then ...
            if sysevent.perturb
                % update the Perturb Checkbox
                this.PerturbCheckBox.Value = sysobj.perturb;
            end            
        end        
    
    end
    
    methods (Static)
        % Utility function to classify X as scalar (returns 0), vector (returns 1) or matrix (returns 2)
        function val = numdims(X)
            [nr,nc] = size(X);
            if nr*nc==1
                val = 0;        % X is scalar (1x1)
            elseif nr==1 || nc==1
                val = 1;        % X is vector (1xn) or (nx1)
            else
                val = 2;        % X is matrix (mxn)
            end
        end
    
    end
 
end

