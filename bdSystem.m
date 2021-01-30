classdef bdSystem < handle
    %bdSystem  Internal system object for bdGUI.
    % 
    %AUTHORS
    %  Stewart Heitmann (2020a,2020b)

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
    
    properties (Constant=true)
        version = '2020b';      % version number of the toolbox
    end

    events
        redraw      % tell the panels to redraw themselves
        respond     % tell the panels it is their time to modify sysobj
        push        % tell the gui to push the undo-stack
    end
  
    properties (SetObservable)
        % system parameters
        pardef
        lagdef
        vardef
        
        % time domain
        tspan
        tstep
        tval
        
        % switches
        noisehold
        evolve
        perturb
        backward        
        halt
        
        % solver selection
        solveritem
        
        % solver options
        odeoption
        ddeoption
        sdeoption
        
        % solution structure
        sol
    end
    
    properties (Access=public)       
        % type of solver ('odesolver','ddesolver','sdesolver')
        solvertype     
        
        % ODE specific
        odefun = []
        odesolver = []
        
        % DDE specific
        ddefun = []
        ddesolver = []
        
        % SDE specific
        sdeF = []
        sdeG = []
        sdesolver = []
               
        % solution data (work in progress)
        tdomain
        vars
        
        % private switches
        recompute
        
        % progress indicators
        indicators  bdIndicators
    end

    properties (Access=private)
        timer
        laststate
        eventdata
        %presets
    end
        
    methods (Access=public) 
        function sysobj = bdSystem(sys,args)
            % bdSystem constructor
            arguments
                sys         struct
                args.sol    struct = []
            end
            
            % Init the progress indicators
            sysobj.indicators = bdIndicators();
            
            % Import the system structure
            sysobj.ImportSystem(sys);
        
            % init the REDRAW event data structure
            sysobj.eventdata = bdRedrawEvent(true,numel(sysobj.pardef),numel(sysobj.lagdef),numel(sysobj.vardef));
            sysobj.laststate.pardef = sysobj.pardef;
            sysobj.laststate.lagdef = sysobj.lagdef;
            sysobj.laststate.vardef = sysobj.vardef;

            % init the sol struct
            if isempty(args.sol)
                % initial the solution with NaNs
                sol = [];
                
                % time domain as start-and-end points only
                if sysobj.backward
                    sol.x = sysobj.tspan([2 1]);
                else
                    sol.x = sysobj.tspan;
                end
                
                % initialise solution with NaN
                Y0 = sysobj.GetVar0();
                n = numel(Y0);
                sol.y  = NaN(n,2);
                sol.yp = NaN(n,2);

                % statistics
                sol.stats.nsteps = 0;
                sol.stats.nfailed = 0;
                sol.stats.nfevals = 0;
                sol.solver = 'none';
                
                % update sysobj.sol in a single transaction
                sysobj.sol = sol;
            else
                % import the given sol struct
                bdSystem.solcheck(args.sol)
                if numel(GetVar0(sysobj)) ~= size(args.sol.y,1)
                    throw(MException('bdSystem:badsol','The sol and sys structs are incompatible'));
                end
                sysobj.sol = args.sol;
            end
            
            % Interpolate the solutions. Empty trajectories are filled with NaN.
            sysobj.Interpolate();
            
            % Listen to changes to the system properties
            addlistener(sysobj,'pardef',    'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'lagdef',    'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'vardef',    'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'tspan',     'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'tstep',     'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'tval',      'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'noisehold', 'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'evolve',    'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'perturb',   'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'backward',  'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'halt',      'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'solveritem','PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'odeoption', 'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'ddeoption', 'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'sdeoption', 'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            addlistener(sysobj,'sol',       'PostSet',@(src,evnt) sysobj.PropListener(src,evnt));
            
            % Init the timer object but don't start it         
            sysobj.timer = timer('BusyMode','drop', ...
                'ExecutionMode','fixedSpacing', ...
                'Period',0.05, ...
                'TimerFcn', @(~,~) sysobj.TimerFcn());
            
            % Notify all panels to redraw (and set the recompute flag)
            sysobj.NotifyRedraw([]);
            
            % If the caller gave us a precomputed sol structure then override
            % the recompute flag (set by the preceding call to NotifyRedraw).
            % This trick is acceptable because the timer isn't running yet.
            if ~isempty(args.sol)
                sysobj.recompute = false;
            end
        end
        
        function ImportSystem(sysobj,sys)
            % ImportSystem(sysobj,sys) imports the given sys structure (excluding sys.panels)
            % This function is called by the bdSystem constructor to initiate
            % a new model. It is also called by the bdGUI "undo/redo" menus
            % to restore the model to a previous state on the undo stack. 
            %disp('bdSystem.ImportSystem');
            
            % clean the system structure
            sys = bdSystem.syscheck(sys);
        
            % sys.pardef
            if ~isfield(sys,'pardef') || isempty(sys.pardef)
                sysobj.pardef = [];
            else
                sysobj.pardef = sys.pardef;
            end
            
            % sys.lagdef
            if ~isfield(sys,'lagdef') || isempty(sys.lagdef)
                sysobj.lagdef = [];
            else
                sysobj.lagdef = sys.lagdef;
            end
            
            % sys.vardef
            if ~isfield(sys,'vardef') || isempty(sys.vardef)
                sysobj.vardef = [];
            else
                sysobj.vardef = sys.vardef;
                solcount = 0;
                for idx=1:numel(sysobj.vardef)
                    len = numel(sysobj.vardef(idx).value);
                    sysobj.vardef(idx).solindx = (1:len) + solcount;
                    solcount = solcount + len;
                end
            end
            
            % case of ODE
            if isfield(sys,'odefun')
                sysobj.solvertype = 'odesolver';
                sysobj.odefun = sys.odefun;
                sysobj.odesolver = sys.odesolver;
                sysobj.odeoption = sys.odeoption;
            end
            
            % case of DDE
            if isfield(sys,'ddefun')
                sysobj.solvertype = 'ddesolver';                
                sysobj.ddefun = sys.ddefun;
                sysobj.ddesolver = sys.ddesolver;
                sysobj.ddeoption = sys.ddeoption;
            end
            
            % case of SDE
            if isfield(sys,'sdeF')
                sysobj.solvertype = 'sdesolver';
                sysobj.sdeF = sys.sdeF;
                sysobj.sdeG = sys.sdeG;
                sysobj.sdesolver = sys.sdesolver;
                sysobj.sdeoption = sys.sdeoption;
                sysobj.noisehold = sys.noisehold;
            end
            
            % solver selection
            sysobj.solveritem = sys.solveritem;
            
            % time domain
            sysobj.tspan = sys.tspan;
            sysobj.tstep = sys.tstep;
            sysobj.tval  = sys.tval;
            
            % switches
            sysobj.recompute = false;
            sysobj.perturb = sys.perturb;
            sysobj.evolve = sys.evolve;
            sysobj.backward = sys.backward;
            sysobj.halt = sys.halt;
            
            % reset the progress indicators
            sysobj.indicators.Reset();
        end
        
        function sys = ExportSystem(sysobj)
            % sys.solvertype
            sys.solvertype = sysobj.solvertype;
            
            % solver selection
            sys.solveritem = sysobj.solveritem;

            % solver-specific options
            switch sysobj.solvertype
                case 'odesolver'
                    sys.odefun    = sysobj.odefun;
                    sys.odesolver = sysobj.odesolver;
                    sys.odeoption = sysobj.odeoption;
                    sys.pardef    = sysobj.pardef;
                    sys.vardef    = sysobj.vardef;
                    
                    % remove any OutputFcn from odeoption 
                    if isfield(sys.odeoption,'OutputFcn')
                        sys.odeoption = rmfield(sys.odeoption,'OutputFcn');
                    end

                case 'ddesolver'
                    sys.ddefun    = sysobj.ddefun;
                    sys.ddesolver = sysobj.ddesolver;
                    sys.ddeoption = sysobj.ddeoption;
                    sys.pardef    = sysobj.pardef;
                    sys.lagdef    = sysobj.lagdef;
                    sys.vardef    = sysobj.vardef;
                    
                    % remove any OutputFcn from ddeoption 
                    if isfield(sys.ddeoption,'OutputFcn')
                        sys.ddeoption = rmfield(sys.ddeoption,'OutputFcn');
                    end
                    
                case 'sdesolver'
                    sys.sdeF      = sysobj.sdeF;
                    sys.sdeG      = sysobj.sdeG;
                    sys.sdesolver = sysobj.sdesolver;
                    sys.sdeoption = sysobj.sdeoption;
                    sys.pardef    = sysobj.pardef;
                    sys.vardef    = sysobj.vardef;
                    sys.noisehold = sysobj.noisehold;

                    % remove any OutputFcn from sdeoption 
                    if isfield(sys.sdeoption,'OutputFcn')
                        sys.sdeoption = rmfield(sys.sdeoption,'OutputFcn');
                    end
                    
                    % remove the sdeoption.randn field if it is empty 
                    if isfield(sys.sdeoption,'randn') && isempty(sys.sdeoption.randn)
                        sys.sdeoption = rmfield(sys.sdeoption,'randn');
                    end

            end
                   
           % generic options
           sys.tspan     = sysobj.tspan;
           sys.tstep     = sysobj.tstep;
           sys.tval      = sysobj.tval;
           sys.evolve    = sysobj.evolve;
           sys.perturb   = sysobj.perturb;
           sys.backward  = sysobj.backward;
           sys.halt      = sysobj.halt;
        end
        
        function lim = CalibratePar(sysobj,parindx)
            data = sysobj.pardef(parindx).value;
            lo = min(data(:),[],'omitnan');
            hi = max(data(:),[],'omitnan');
            lim = [lo hi];
            sysobj.pardef(parindx).lim = lim;
        end
        
        function lim = CalibrateLag(sysobj,lagindx)
            data = sysobj.lagdef(lagindx).value;
            lo = min(data(:),[],'omitnan');
            hi = max(data(:),[],'omitnan');
            lim = [lo hi];
            sysobj.lagdef(lagindx).lim = lim;
        end
        
        function lim = CalibrateVar0(sysobj,varindx)
            data = sysobj.vardef(varindx).value;
            lo = min(data(:),[],'omitnan');
            hi = max(data(:),[],'omitnan');
            lim = [lo hi];
            sysobj.vardef(varindx).lim = lim;
        end
        
        function lim = CalibrateVar(sysobj,varindx,tspan)
            % find the solution time steps within tspan=[t0 t1]
            tlo = min(tspan);
            thi = max(tspan);
            tindx = (sysobj.sol.x >= tlo) & (sysobj.sol.x <= thi);

            % get the row indexes for this variable in sol.y
            solindx = sysobj.vardef(varindx).solindx;
            
            % extract the solution data
            Y = sysobj.sol.y(solindx,tindx);

            % calculate the global min and max values of Y
            lo = min(min(Y,[],'omitnan'),[],'omitnan');
            hi = max(max(Y,[],'omitnan'),[],'omitnan');
            lim = [lo hi];
            
            % update the vardef entry
            sysobj.vardef(varindx).lim = lim;
        end
        
        function SetVar0(sysobj,Y0)
            % Assign initial conditions from a monolithic column vector.
            %disp('bdSystem.SetVar0');
            nvar = numel(sysobj.vardef);
            offset = 0;
            for indx=1:nvar
                len = numel(sysobj.vardef(indx).value);
                sysobj.vardef(indx).value(:) = Y0(offset+(1:len));
                offset = offset + len;
            end
        end
        
        function Y0 = GetVar0(sysobj)
            % Returns the initial conditions as a monolithic column vector.
            
            % Extract the value fields of vardef as a cell array
            Y0 = {sysobj.vardef.value}';

            % Convert each cell entry to a column vector
            for indx=1:numel(Y0)
                Y0{indx} = reshape(Y0{indx},[],1);
            end

            % Concatenate the column vectors to a simple vector
            Y0 = cell2mat(Y0);
        end
        
        function Y0 = GetVar0p(sysobj,amp)
            % Returns the perturbed initial conditions as a monolithic column vector.
            % Amp is the amplitude of the perturbation relative to each variable's plot limits.
            
            % Extract the value fields of vardef as a cell array
            Y0 = {sysobj.vardef.value}';
            
            % Extract the lim fields of vardef as a cell array
            L0 = {sysobj.vardef.lim}';
            
            % for each entry in Y0/L0
            for indx = 1:numel(Y0)
                % limits of the variable
                lo = L0{indx}(1);
                hi = L0{indx}(2);
                
                % size of the variable
                sz = size(Y0{indx});

                % uniform random perturbation scaled by 'amp'
                P0 = amp*(hi-lo)*(rand(sz)-0.5);
                
                % apply the perturbation and convert the cell entry to a column vector
                Y0{indx} = reshape(Y0{indx}+P0,[],1);
            end      
            
            % Concatenate the column vectors to a simple vector
            Y0 = cell2mat(Y0);
        end
        
        function [varindx,varsize] = GetVarIndex(sysobj,name)
            for varindx = 1:numel(sysobj.vardef)
                varname = sysobj.vardef(varindx).name;
                if isequal(varname,name)
                    varsize = size(sysobj.vardef(varindx).value);
                    return
                end
            end
            varindx = [];
            varsize = [];
        end
        
        function [parindx,parsize] = GetParIndex(sysobj,name)
            for parindx = 1:numel(sysobj.pardef)
                parname = sysobj.pardef(parindx).name;
                if isequal(parname,name)
                    parsize = size(sysobj.pardef(parindx).value);
                    return
                end
            end
            parindx = [];
            parsize = [];
        end
        
        function [lagindx,lagsize] = GetLagIndex(sysobj,name)
            for lagindx = 1:numel(sysobj.lagdef)
                lagname = sysobj.lagdef(lagindx).name;
                if isequal(lagname,name)
                    lagsize = size(sysobj.lagdef(lagindx).value);
                    return
                end
            end
            lagindx = [];
            lagsize = [];
        end
            
        function L = GetLags(sysobj)
            % Returns the lag parameters as a monolithic column vector.
            
            % Extract the value fields of lagdef as a cell array
            L = {sysobj.lagdef.value}';

            % Convert each cell entry to a column vector
            for indx=1:numel(L)
                L{indx} = reshape(L{indx},[],1);
            end

            % Concatenate the column vectors to a simple vector
            L = cell2mat(L);
        end
        
        function [tindx0,tindx1,ttindx,tdomain] = tindices(sysobj,tdomain)
            % Returns the indices of transient and non-transient parts of the time domain
            % where tindx0 is the transient part, tindx1 is the non-transient part, and
            % ttindx is the index of the time point in tdomain that is closest to the time
            % slider value (sysobj.tval).
            % If the tdomain parameter is empty then sysobj.tdomain is used instead.
            if isempty(tdomain)
                tdomain = sysobj.tdomain;
            end
            if sysobj.backward
                tindx1 = (tdomain<=sysobj.tval);
                tindx0 = ~tindx1;
                tindx0 = circshift(tindx0,1);
                tindx0(1) = 1;
                ttindx = sum(tindx0);
            else
                tindx1 = (tdomain>=sysobj.tval);
                tindx0 = ~tindx1;
                tindx0 = circshift(tindx0,1);
                tindx0(1) = 1;
                ttindx = sum(tindx0);
            end
        end
        
        function Solve(sysobj)
            %disp('Solve');
            
            % Get the system parameters as a cell array
            parms = {sysobj.pardef.value};

            % Get the initial conditions as a monolithic vector
            if sysobj.perturb
                Y0 = sysobj.GetVar0p(0.05);   % perturbed initial conditions
            else
                Y0 = sysobj.GetVar0();        % initial conditions
            end
            
            % The type of the solver function determines how we apply it 
            switch sysobj.solvertype
                case 'odesolver'
                    % case of an ODE solver (eg ode45)
                    option = odeset(sysobj.odeoption, 'OutputFcn',@sysobj.odeOutputFcn, 'OutputSel',[],'InitialStep',sysobj.tstep);
                    solver = sysobj.odesolver{sysobj.solveritem};
                    
                    % simulation time span
                    if sysobj.backward
                        tspan = sysobj.tspan([2 1]);    % integrate backwards
                    else
                        tspan = sysobj.tspan;           % integrate forwards
                    end
                    
                    % call the solver
                    sysobj.sol = solver(sysobj.odefun, ...
                        tspan, ...
                        Y0, ...
                        option, ...
                        parms{:});
                    
                case 'ddesolver'
                    % case of a DDE solver (eg dde23)
                    option = ddeset(sysobj.ddeoption, 'OutputFcn',@sysobj.odeOutputFcn, 'OutputSel',[], 'InitialStep',sysobj.tstep);
                    lags = sysobj.GetLags();
                    solver = sysobj.ddesolver{sysobj.solveritem};
                    
                    % call the solver (backwards integration is not meaningful for DDEs)
                    sysobj.sol = solver(sysobj.ddefun, ...
                        lags, ...
                        Y0, ...
                        sysobj.tspan, ...
                        option, ...
                        parms{:});

                case 'sdesolver'
                    % case of an SDE solver
                    option = sysobj.sdeoption;
                    option.OutputFcn = @sysobj.odeOutputFcn;
                    option.OutputSel = [];
                    option.InitialStep = sysobj.tstep;
                    solver = sysobj.sdesolver{sysobj.solveritem};
                    
                    % call the solver (backwards intergration is not supported)
                    sysobj.sol = solver(sysobj.sdeF, ...
                        sysobj.sdeG, ...
                        sysobj.tspan, ...
                        Y0, ...
                        option, ...
                        parms{:});                    
            end
            
            sysobj.laststate.sol = true;
            %disp('Solve Complete');
        end
                
        function Evolve(sysobj,nrep)
            %disp('Evolve');
            
            % If the system has not been solved at all then we do it now.
            if all(isnan(sysobj.sol.y),'all')
                % solve the system 
                sysobj.Solve();
                % count it as one repetition
                nrep = nrep - 1;
            end
            
            for rep = 1:nrep
                % extract the final state as a monolithic vector
                Y0 = sysobj.sol.y(:,end);
                
                % if the final state of the solution is not finite then abort
                if ~all(isfinite(Y0))
                    warning('Evolve halted. Solution has blown out.')
                    return
                end
                
                % update the initial conditions
                sysobj.SetVar0(Y0);
                
                % solve the system 
                sysobj.Solve();
                
                % update the indicators
                sysobj.indicators.nevolve = sysobj.indicators.nevolve + 1;
                
                % Notify everyone to redraw
                sysobj.NotifyRedraw([]);
            end
            %disp('Evolve Complete');
        end
        
        function Interpolate(sysobj)
            % Updates this.tdomain and this.vars from this.sol
            
            % enumerate the time domain
            if sysobj.backward      
                % backward time
                t0 = sysobj.tspan(2);
                t1 = sysobj.tspan(1);
                tstep = -sysobj.tstep;
            else
                % forward time
                t0 = sysobj.tspan(1);
                t1 = sysobj.tspan(2);
                tstep = sysobj.tstep;
            end
            sysobj.tdomain = t0:tstep:t1;
            nt = numel(sysobj.tdomain);
              
            % initialise sysobj.vars
            for idx=1:numel(sysobj.vardef)
                % get the name and shape of the state variable
                name = sysobj.vardef(idx).name;
                [nr,nc] = size(sysobj.vardef(idx).value);
                % initialise with NaN
                if nr>1 && nc>1
                    sysobj.vars.(name) = NaN(nr,nc,nt); 
                else
                    sysobj.vars.(name) = NaN(nr*nc,nt); 
                end
            end

            % special case of empty sol
            if ~isfield(sysobj.sol,'solver')
                return      % nothing more to do
            end

            % calculate the extent of time in the computed solution
            t0 = sysobj.sol.x(1);
            t1 = sysobj.sol.x(end);
            if sysobj.backward
                tidx = (sysobj.tdomain>=t1 & sysobj.tdomain<=t0);
            else
                tidx = (sysobj.tdomain>=t0 & sysobj.tdomain<=t1);
            end
            
            % special case of [t0 t1] not in the desired tdomain
            if ~any(tidx)
                return      % nothing more to do
            end
            
            % Interpolate the solution over the requested time points.
            switch sysobj.sol.solver
                case {'ode45','ode23','ode113','ode15s','ide23s','ode23t','ode23tb','dde23'}
                    % Use MATLAB deval for MATLAB solvers
                    Y = deval(sysobj.sol,sysobj.tdomain(tidx));
                    
                otherwise
                    % Use interpolation for third-party solvers.
                    % We need to transpose the output of interp1 when the input is
                    % a matrix but not when it is a vector.
                    if size(sysobj.sol.y,2)==1
                        % Do not transpose the result when the input is a vector
                        Y = interp1(sysobj.sol.x, sysobj.sol.y', sysobj.tdomain(tidx)); 
                    else
                        % Do transpose the result when the input is a matrix
                        Y = interp1(sysobj.sol.x, sysobj.sol.y', sysobj.tdomain(tidx))'; 
                    end
            end

            % copy the results into sysobj.vars
            for indx=1:numel(sysobj.vardef)
                % get the name and shape of the state variable
                name = sysobj.vardef(indx).name;
                [nr, nc] = size(sysobj.vardef(indx).value);
                % get the corresponding indicies in sol
                solindx = sysobj.vardef(indx).solindx;
                % copy the data from sol into vars
                if nr>1 && nc>1
                    sysobj.vars.(name)(:,:,tidx) = reshape(Y(solindx,:),nr,nc,[]);
                else
                    sysobj.vars.(name)(:,tidx) = reshape(Y(solindx,:),nr*nc,[]);
                end
            end   
        end
        
        function [Y,dY] = Eval(this,tdomain,varindx)
            % size of the variable
            [nr,nc] = size(this.vardef(varindx).value);
            
            % number of time steps
            nt = numel(tdomain);
                    
            % init results as 2D matrix of NaN
            Y = squeeze(NaN(nr*nc,nt));
            if nargout>1
                dY = Y;
            end

            % special case of empty sol
            if isempty(this.sol.x)
                return      % nothing more to do
            end

            % time limits of sol
            t0 = this.sol.x(1);
            t1 = this.sol.x(end);
            tidx = (tdomain>=t0 & tdomain<=t1);
            
            % special case of [t0 t1] not in tdomain
            if ~any(tidx)
                return      % nothing more to do
            end

            % sol indexes for varname
            solindx = this.vardef(varindx).solindx;
            
            % interpolate the solution
            switch this.sol.solver
                case {'ode45','ode23','ode113','ode15s','ide23s','ode23t','ode23tb','dde23'}
                    % Use MATLAB deval for MATLAB solvers
                    [y,dy] = deval(this.sol,tdomain(tidx),solindx);
                    Y(:,tidx) = y;
                    if nargout>1
                        dY(:,tidx) = dy;
                    end
                    
                otherwise
                    % Use interpolation for third-party solvers.
                    % We need to transpose the output of interp1 when the input is
                    % a matrix but not when it is a vector.
                    if size(solindx,2)==1
                        % Do not transpose the result when the input is a vector
                        Y  = interp1(this.sol.x, this.sol.y(solindx,:)', tdomain(tidx)); 
                    else
                        % Do ytranspose the result when the input is a matrix
                        Y  = interp1(this.sol.x, this.sol.y(solindx,:)', tdomain(tidx))'; 
                    end
            end
            
            % compute the final shape of Y and dY
            if nr==1
                % var has one row
                if nc==1
                    % var has one row and one column
                    % Return y as (1 x nt).
                    newshape = [1 nt];
                else
                    % var has one row and multiple columns
                    % Return y as (nc x nt)
                    newshape = [nc nt];
                end 
            else
                % var has multiple rows
                if nc==1
                    % var has multiple rows and one column
                    % Return y as (nr x nt)
                    newshape = [nr nt];
                else
                    % var has multiple rows and multiple columns
                    % Return y as (nr x nc x nt)
                    newshape = [nr nc nt];
                end 
            end

            % apply the new shape
            Y = reshape(Y,newshape);
            if nargout>1
                dY = reshape(dY,newshape);
            end
        end
              
        function TimerFcn(sysobj)
            try
                % recompute the solution if required
                if sysobj.recompute && ~sysobj.halt
                    %fprintf('bdSystem.TimerFcn: %s\n', datetime('now'));
                    
                    % evolve the initial conditions (if required)
                    if sysobj.evolve
                        % extract the final state as a monolithic vector
                        Y0 = sysobj.sol.y(:,end);
                
                        % if the final state of the solution is not finite then abort
                        if ~all(isfinite(Y0))
                            warning('Evolve halted. Solution has blown out.')
                            sysobj.halt = true;
                            sysobj.NotifyRedraw([]);
                            return
                        end
                        
                        % update the initial conditions
                        sysobj.SetVar0(Y0);
                
                        % update the indicators
                        sysobj.indicators.nevolve = sysobj.indicators.nevolve + 1;
                    end
                    
                    % call the solver 
                    sysobj.Solve();
                    
                    % interpolate the solution
                    sysobj.indicators.InterpolatorInit();
                    sysobj.Interpolate();
                    sysobj.indicators.InterpolatorDone();
                    
                    % redraw all the panels
                    sysobj.indicators.GraphicsInit();
                    sysobj.NotifyRedraw([]);
                    sysobj.indicators.GraphicsUpdate();
                    
                    % reset the recompute flag
                    sysobj.recompute = false;

                    % allow the panels to update the controls
                    notify(sysobj,'respond');
                    sysobj.indicators.GraphicsDone();
                end
            catch ME
                % display the warning
                %this.ui_warning.String = ME.identifier;
                %this.ui_warning.TooltipString = ME.message;
                %this.ui_warning.ForegroundColor = 'r';
                warning(ME.identifier,'%s',ME.message);
                for indx=1:size(ME.stack)
                    [~,filename,fileext] = fileparts(ME.stack(indx).file);
                    funcname = ME.stack(indx).name;
                    linenum  = num2str(ME.stack(indx).line);
                    disp([funcname, ': ', filename, fileext, ' line ', linenum]);
                end
                
                % halt the solver
                sysobj.halt = true;
                
                % notify the widgets to refresh themselves
                sysobj.NotifyRedraw([]);
            end
                
        end
        
        function TimerStart(sysobj)
            switch sysobj.timer.Running
                case 'off'
                    start(sysobj.timer);
            end               
        end
        
        function TimerStop(sysobj)
            switch sysobj.timer.Running
                case 'on'
                    stop(sysobj.timer);
            end               
        end
                
        function NotifyRedraw(sysobj,exlisteners)
            % NotifyRedraw issues a REDRAW event to all listeners except those
            % listed in the 'exlisteners' parameter. The listeners are typically
            % display panels and control panel widgets. Dialog boxes may be 
            % listeners too. The 'exlisteners' parameter provides a convenient
            % mechanism for a widget to issue a REDRAW to other widgets except
            % itself. The REDRAW event is accompanied by a custom event data
            % object (bdRedrawEvent) that tells the listener which properties
            % of sysobj have changed since the last REDRAW event. The NotifyRedraw
            % function is responsible for keeping track of those changes in the
            % sysobj.eventdata and sysobj.lastdata properties. It also sets the
            % sysobj.recompute=true flag if any of those changes require the
            % solver to recompute a new solution.
            %disp('NotifyRedraw');
            %dbstack()
            
            % eventdata indicates which sys fields have changed since laststate
            eventdata = sysobj.eventdata;
            
            % flag each pardef entry that has changed
            npardef = numel(sysobj.pardef);
            for indx=1:npardef
                eventdata.pardef(indx).value = ~isequal(sysobj.pardef(indx).value, sysobj.laststate.pardef(indx).value);
                eventdata.pardef(indx).lim   = ~isequal(sysobj.pardef(indx).lim,   sysobj.laststate.pardef(indx).lim);
            end
            
            % flag each lagdef entry that has changed
            nlagdef = numel(sysobj.lagdef);
            for indx=1:nlagdef
                eventdata.lagdef(indx).value = ~isequal(sysobj.lagdef(indx).value, sysobj.laststate.lagdef(indx).value);
                eventdata.lagdef(indx).lim   = ~isequal(sysobj.lagdef(indx).lim,   sysobj.laststate.lagdef(indx).lim);
            end
            
            % flag each vardef entry that has changed
            nvardef=numel(sysobj.vardef);
            for indx=1:nvardef
                eventdata.vardef(indx).value = ~isequal(sysobj.vardef(indx).value, sysobj.laststate.vardef(indx).value);
                eventdata.vardef(indx).lim   = ~isequal(sysobj.vardef(indx).lim,   sysobj.laststate.vardef(indx).lim);
            end
                        
            if any([eventdata.pardef.value]) || ...
               any([eventdata.lagdef.value]) || ...
               any([eventdata.vardef.value]) || ...
               eventdata.tspan || ...
               eventdata.tstep || ...
               eventdata.solveritem || ...
               eventdata.odeoption || ...
               eventdata.sdeoption || ...
               eventdata.ddeoption || ...
               (eventdata.evolve && sysobj.evolve)|| ...
               eventdata.perturb || ...
               eventdata.backward
                sysobj.recompute = true;      % flag a recompute for the solver timer
            end
            
            % solver-specific processing
            switch sysobj.solvertype
                case 'sdesolver'
                    % if we are using preordained random samples then ...
                    if isfield(sysobj.sdeoption,'randn') && ~isempty(sysobj.sdeoption.randn)
                        % number of random samples
                        r = size(sysobj.sdeoption.randn,2);
                        % number of time steps in the time domain
                        s = abs(sysobj.tspan(2) - sysobj.tspan(1)) / sysobj.tstep + 1;
                        % ensure the number of random sample matches the number of time steps
                        if r~=s
                            % Generate new noise samples. Doing so will trigger the property
                            % listener for sdeoption but it doesn't really matter at this stage.
                            sysobj.sdeoption.randn = randn(sysobj.sdeoption.NoiseSources,s);
                        end
                    end
            end
            
            % reset laststate
            sysobj.eventdata = bdRedrawEvent(false,npardef,nlagdef,nvardef);
            sysobj.laststate.pardef = sysobj.pardef;
            sysobj.laststate.lagdef = sysobj.lagdef;
            sysobj.laststate.vardef = sysobj.vardef;
            
            % disable listeners in the exclusion set
            for ix = 1:numel(exlisteners)
                exlisteners(ix).Enabled = false;
            end
            
            notify(sysobj,'redraw',eventdata);
            drawnow;
            
            % re-enable listeners in the exclusion set
            for ix = 1:numel(exlisteners)
                exlisteners(ix).Enabled = true;
            end
        end
        
        function delete(sysobj)
            sysobj.TimerStop();
        end
    end
    
    methods (Access=private)        
        function PropListener(sysobj,src,~)
            % Property listener that keeps track of which bdSystem properties
            % have changed by updating the matching field in bdSystem.eventdata 
            
            %disp(['bdSystem.PropListener:',src.Name]); 
            switch src.Name
                case 'pardef'
                    % nothing to do here
                case 'lagdef'
                    % nothing to do here
                case 'vardef'
                    % nothing to do here
                otherwise
                    % remember which property was changed
                    sysobj.eventdata.(src.Name) = true;
            end
        end
        
        function status = odeOutputFcn(sysobj,t,~,flag,varargin)
            % Callback for ODE solver output
            persistent tic0
            switch flag
                case 'init'
                    % reset the indicators
                    sysobj.indicators.SolverInit(t);
                    tic0 = tic;
                    
                case '' 
                    % update the indicators periodically
                    if toc(tic0) > 0.15
                        sysobj.indicators.SolverUpdate(t(end));
                        tic0 = tic;
                    end
                    
                case 'done'
                    sysobj.indicators.SolverDone();
            end 
            
            % return the state of the HALT button
            status = sysobj.halt;
        end
        
    end

    methods (Static)
        function sysout = syscheck(sys)
            % Checks a system structure for validity.
            %    sysout = bdSystem.syscheck(sys)
            % Validates the contents of sys and throws an exception if a
            % problem is found. If no problem is found then it returns a
            % 'safe' copy of sys in which all missing fields are filled
            % with their default values.
            
            % init empty output
            sysout = [];
            
            % check that sys is a struct
            if ~isstruct(sys)
               throw(MException('bdtoolkit:syscheck:badsys','The sys variable must be a struct'));
            end

            % silently remove obsolete fields (from version 2017c)
            if isfield(sys,'auxdef')
                sys = rmfield(sys,'auxdef');
            end
            if isfield(sys,'auxfun')
                sys = rmfield(sys,'auxfun');
            end
            if isfield(sys,'self')
                sys = rmfield(sys,'self');
            end
            
            % check for obsolete fields (from version 2016a)
            if isfield(sys,'pardef') && iscell(sys.pardef)
                throw(MException('bdtoolkit:syscheck:obsolete','The sys.pardef field changed from a cell array in 2016a to an array of structs in 2017a'));
            end
            if isfield(sys,'sdefun')
                throw(MException('bdtoolkit:syscheck:obsolete','The sys.odefun and sys.sdefun fields are obsolete for SDEs. They were replaced by sys.sdeF and sys.sdeG in 2017a'));
            end
            if isfield(sys,'gui')
                throw(MException('bdtoolkit:syscheck:obsolete','The sys.gui field is obsolete. It was renamed sys.panels after version 2016a'));        
            end
            if isfield(sys,'panels')
                if isfield(sys.panels,'bdCorrelationPanel')
                    throw(MException('bdtoolkit:syscheck:obsolete', 'The bdCorrelationPanel was renamed bdCorrPanel after version 2016a'));        
                end
                if isfield(sys.panels,'bdSpaceTimePortrait')
                    throw(MException('bdtoolkit:syscheck:obsolete', 'The bdSpaceTimePortrait was renamed bdSpaceTime after version 2016a'));        
                end
            end

            % check sys.pardef
            if ~isfield(sys,'pardef')
               throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef field is undefined'));
            end
            if ~isstruct(sys.pardef)
               throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef field must be a struct'));
            end
            if ~isfield(sys.pardef,'name')
               throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef.name field is undefined'));
            end
            if ~isfield(sys.pardef,'value')
               throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef.value field is undefined'));
            end
            % check each array entry
            for indx=1:numel(sys.pardef)
                % ensure the pardef.name field is a string
                if ~ischar(sys.pardef(indx).name)
                   throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef(%d).name field must be a string',indx));
                end
                % ensure the pardef.value field is numeric 
                if isempty(sys.pardef(indx).value) || ~isnumeric(sys.pardef(indx).value)
                   throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef(%d).value field must be numeric',indx));
                end
                % assign a default value to pardef.lim if it is missing  
                if ~isfield(sys.pardef(indx),'lim') || isempty(sys.pardef(indx).lim)
                    % default lim entries
                    lo = floor(min(sys.pardef(indx).value(:)) - 1e-6);
                    hi =  ceil(max(sys.pardef(indx).value(:)) + 1e-6);
                    sys.pardef(indx).lim = [lo,hi];
                end
                % ensure the pardef.lim field is [lo hi] only
                if ~isnumeric(sys.pardef(indx).lim) || numel(sys.pardef(indx).lim) ~= 2 || sys.pardef(indx).lim(1)>=sys.pardef(indx).lim(2)
                   throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef(%d).lim field does not contain valid [lower, upper] limits',indx));
                end
            end
            
            % check sys.vardef
            if ~isfield(sys,'vardef')
               throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef field is undefined'));
            end
            if ~isstruct(sys.vardef)
               throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef field must be a struct'));
            end
            if ~isfield(sys.vardef,'name')
               throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef.name field is undefined'));
            end
            if ~isfield(sys.vardef,'value')
               throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef.value field is undefined'));
            end
            % check each array entry
            offset = 0;
            for indx=1:numel(sys.vardef)
                % ensure the vardef.name field is a string
                if ~ischar(sys.vardef(indx).name)
                   throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef(%d).name field must be a string',indx));
                end
                % ensure the vardef.value field is numeric 
                if isempty(sys.vardef(indx).value) || ~isnumeric(sys.vardef(indx).value) 
                   throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef(%d).value field must be numeric',indx));
                end
                % assign a default value to vardef.lim if it is missing  
                if ~isfield(sys.vardef(indx),'lim') || isempty(sys.vardef(indx).lim)
                    % default lim entries
                    lo = floor(min(sys.vardef(indx).value(:)) - 1e-6);
                    hi =  ceil(max(sys.vardef(indx).value(:)) + 1e-6);
                    sys.vardef(indx).lim = [lo,hi];
                end
                % ensure the vardef.lim field is [lo hi] only
                if ~isnumeric(sys.vardef(indx).lim) || numel(sys.vardef(indx).lim) ~= 2 || sys.vardef(indx).lim(1)>=sys.vardef(indx).lim(2)
                   throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef(%d).lim field does not contain valid [lower, upper] limits',indx));
                end
                % assign the corresponding indices to sol
                len =  numel(sys.vardef(indx).value);
                sys.vardef(indx).solindx = (1:len) + offset;
                offset = offset + len;
            end
            
            % check sys.tspan = [0,1]
            if ~isfield(sys,'tspan')
                sys.tspan = [0 1];      
            end
            if ~isnumeric(sys.tspan)
                throw(MException('bdtoolkit:syscheck:tspan','The sys.tspan field must be numeric'));
            end
            if size(sys.tspan,1)~=1 || size(sys.tspan,2)~=2
                throw(MException('bdtoolkit:syscheck:tspan','The sys.tspan field must be size 1x2'));
            end
            if sys.tspan(1) > sys.tspan(2)
                throw(MException('bdtoolkit:syscheck:tspan','The values in sys.tspan=[t0 t1] must have t0<=t1'));
            end

            % check sys.tval = t0
            if ~isfield(sys,'tval')
                sys.tval = sys.tspan(1);      
            end
            % force tval to be bounded by tspan
            sys.tval = max(sys.tspan(1), sys.tval);
            sys.tval = min(sys.tspan(2), sys.tval);            

            % check sys.tstep = 1
            if ~isfield(sys,'tstep')
                sys.tstep = 1;      
            end
            
            % Must have sys.odefun or sys.ddefun or (sys.sdeF and sdeG)
            if ~isfield(sys,'odefun') && ~isfield(sys,'ddefun') && ~isfield(sys,'sdeF') && ~isfield(sys,'sdeG')
                throw(MException('bdtoolkit:syscheck:badfun','No function handles found for sys.odefun, sys.ddefun, sys.sdeF or sys.sdeG'));
            end
            
            % check sys.odefun is exclusive (if it exists)
            if isfield(sys,'odefun') && (isfield(sys,'ddefun') || isfield(sys,'sdeF') || isfield(sys,'sdeG'))
                throw(MException('bdtoolkit:syscheck:badfun','Function handles sys.ddefun, sys.sdeF, sys.sdeG cannot co-exist with sys.odefun'));
            end
            
            % check sys.ddefun is exclusive (if it exists)
            if isfield(sys,'ddefun') && (isfield(sys,'odefun') || isfield(sys,'sdeF') || isfield(sys,'sdeG'))
                throw(MException('bdtoolkit:syscheck:badfun','Function handles sys.odefun, sys.sdeF, sys.sdeG cannot co-exist with sys.ddefun'));
            end
            
            % check sys.sdeF (if it exists) is exclusive to sys.odefun and sys.ddefun
            if isfield(sys,'sdeF') && (isfield(sys,'odefun') || isfield(sys,'ddefun'))
                throw(MException('bdtoolkit:syscheck:badfun','Function handles sys.odefun, sys.ddefun cannot co-exist with sys.sdeF'));
            end
            
            % check sys.sdeG (if it exists) is exclusive to sys.odefun and sys.ddefun
            if isfield(sys,'sdeG') && (isfield(sys,'odefun') || isfield(sys,'ddefun'))
                throw(MException('bdtoolkit:syscheck:badfun','Function handles sys.odefun, sys.ddefun cannot co-exist with sys.sdeG'));
            end
            
            % check sys.sdeF and sys.sdeG co-exist
            if (isfield(sys,'sdeF') && ~isfield(sys,'sdeG')) || (~isfield(sys,'sdeF') && isfield(sys,'sdeG'))
                throw(MException('bdtoolkit:syscheck:badfun','Function handles sys.sdeF and sys,sdG must co-exist'));
            end
            
            % check sys.solveritem
            if ~isfield(sys,'solveritem')
                sys.solveritem = 1;
            end

            % case of ODE
            if isfield(sys,'odefun')
                % check sys.odefun is a function handle
                if ~isa(sys.odefun,'function_handle')
                    throw(MException('bdtoolkit:syscheck:odefun','The sys.odefun field must be a function handle'));
                end
                
                % check sys.odefun is in the search path
                if strcmp(func2str(sys.odefun),'UNKNOWN Function')
                    throw(MException('bdtoolkit:syscheck:odefun','The sys.odefun field contains a handle to a missing function.'));
                end
                
                % check sys.odesolver
                if ~isfield(sys,'odesolver')
                    sys.odesolver = {@ode45,@ode23,@ode113,@ode15s,@ode23s,@ode23t,@ode23tb,@odeEul};
                end
                if ~iscell(sys.odesolver)
                    throw(MException('bdtoolkit:syscheck:odesolver','The sys.odesolver field must be a cell array'));
                end
                if size(sys.odesolver,1)~=1 && size(sys.odesolver,2)~=1
                    throw(MException('bdtoolkit:syscheck:odesolver','The sys.odesolver cell array must be one dimensional'));
                end                    
                for indx=1:numel(sys.odesolver)
                    % check that each sys.odesolver is a function handle
                    if ~isa(sys.odesolver{indx},'function_handle')
                        throw(MException('bdtoolkit:syscheck:odesolver','The sys.odesolver{%d} cell must be a function handle',indx));
                    end
                    % check that each sys.odesolver is in the search path
                    if strcmp(func2str(sys.odesolver{indx}),'UNKNOWN Function')
                        throw(MException('bdtoolkit:syscheck:odesolver','The sys.odesolver{%d} cell contains a handle to a missing function.',indx));
                    end
                end

                % check sys.solveritem
                if sys.solveritem<1 || sys.solveritem > numel(sys.odesolver)
                    throw(MException('bdtoolkit:syscheck:solveritem','sys.solveritem = %d is out of bounds',sys.solveritem));
                end
                
                % check sys.odeoption
                if ~isfield(sys,'odeoption')
                    sys.odeoption = odeset();
                end
                if ~isstruct(sys.odeoption)
                    throw(MException('bdtoolkit:syscheck:odeoption','The sys.odeoption field must be a struct (see odeset)'));
                end
            end
            
            % case of DDE
            if isfield(sys,'ddefun')
                % check sys.ddefun
                if ~isa(sys.ddefun,'function_handle')
                    throw(MException('bdtoolkit:syscheck:ddefun','The sys.ddefun field must be a function handle'));
                end
                
                % check sys.ddefun is in the search path
                if strcmp(func2str(sys.ddefun),'UNKNOWN Function')
                    throw(MException('bdtoolkit:syscheck:ddefun','The sys.ddefun field contains a handle to a missing function.'));
                end
                
                % check sys.ddesolver
                if ~isfield(sys,'ddesolver')
                    sys.ddesolver = {@dde23};
                end
                if ~iscell(sys.ddesolver)
                    throw(MException('bdtoolkit:syscheck:ddesolver','The sys.ddesolver field must be a cell array'));
                end
                if size(sys.ddesolver,1)~=1 && size(sys.ddesolver,2)~=1
                    throw(MException('bdtoolkit:syscheck:ddesolver','The sys.ddesolver cell array must be one dimensional'));
                end                    
                for indx=1:numel(sys.ddesolver)
                    % check that each sys.ddesolver is a function handle
                    if ~isa(sys.ddesolver{indx},'function_handle')
                        throw(MException('bdtoolkit:syscheck:ddesolver','The sys.ddesolver{%d} cell must be a function handle',indx));
                    end
                    % check that each sys.ddesolver is in the search path
                    if strcmp(func2str(sys.ddesolver{indx}),'UNKNOWN Function')
                        throw(MException('bdtoolkit:syscheck:ddesolver','The sys.ddesolver{%d} cell contains a handle to a missing function.',indx));
                    end
                end

                % check sys.solveritem
                if sys.solveritem<1 || sys.solveritem > numel(sys.ddesolver)
                    throw(MException('bdtoolkit:syscheck:solveritem','sys.solveritem = %d is out of bounds',sys.solveritem));
                end
                
                % check sys.ddeoption
                if ~isfield(sys,'ddeoption')
                    sys.ddeoption = ddeset();
                end
                if ~isstruct(sys.ddeoption)
                    throw(MException('bdtoolkit:syscheck:ddeoption','The sys.ddeoption field must be a struct (see ddeset)'));
                end
                
                % check sys.lagdef
                if ~isfield(sys,'lagdef')
                    throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef field is undefined'));
                end
                if ~isstruct(sys.lagdef)
                    throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef field must be a struct'));
                end
                if ~isfield(sys.lagdef,'name')
                    throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef.name field is undefined'));
                end
                if ~isfield(sys.lagdef,'value')
                    throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef.value field is undefined'));
                end
                % check each array entry
                for indx=1:numel(sys.lagdef)
                    % ensure the lagdef.name field is a string
                    if ~ischar(sys.lagdef(indx).name)
                        throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef(%d).name field must be a string',indx));
                    end
                    % ensure the lagdef.value field is numeric
                    if isempty(sys.lagdef(indx).value) || ~isnumeric(sys.lagdef(indx).value)
                        throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef(%d).value field must be numeric',indx));
                    end
                    % assign a default value to lagdef.lim if it is missing  
                    if ~isfield(sys.lagdef(indx),'lim') || isempty(sys.lagdef(indx).lim)
                        % default lim entries
                        lo = floor(min(sys.lagdef(indx).value(:)) - 1e-6);
                        hi =  ceil(max(sys.lagdef(indx).value(:)) + 1e-6);
                        sys.lagdef(indx).lim = [lo,hi];
                    end
                    % ensure the lagdef.lim field is [lo hi] only
                    if ~isnumeric(sys.lagdef(indx).lim) || numel(sys.lagdef(indx).lim) ~= 2 || sys.lagdef(indx).lim(1)>=sys.lagdef(indx).lim(2)
                        throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef(%d).lim field does not contain valid [lower, upper] limits',indx));
                    end                    
                end
            end
            
            % case of SDE
            if isfield(sys,'sdeF')
                % check that sys.sdeF is a function handle
                if ~isa(sys.sdeF,'function_handle')
                    throw(MException('bdtoolkit:syscheck:sdeF','The sys.sdeF field must be a function handle'));
                end
                
                % check that sys.sdeF is in the search path
                if strcmp(func2str(sys.sdeF),'UNKNOWN Function')
                    throw(MException('bdtoolkit:syscheck:sdeF','The sys.sdeF field contains a handle to a missing function.'));
                end
                
                % check that sys.sdeG is a function handle
                if ~isa(sys.sdeG,'function_handle')
                    throw(MException('bdtoolkit:syscheck:sdeG','The sys.sdeG field must be a function handle'));
                end
                
                % check that sys.sdeG is in the search path
                if strcmp(func2str(sys.sdeG),'UNKNOWN Function')
                    throw(MException('bdtoolkit:syscheck:sdeG','The sys.sdeG field contains a handle to a missing function.'));
                end
                
                % check sys.sdesolver
                if ~isfield(sys,'sdesolver')
                    sys.sdesolver = {@sdeEM,@sdeSH};
                end
                if ~iscell(sys.sdesolver)
                    throw(MException('bdtoolkit:syscheck:sdesolver','The sys.sdesolver field must be a cell array'));
                end
                if size(sys.sdesolver,1)~=1 && size(sys.sdesolver,2)~=1
                    throw(MException('bdtoolkit:syscheck:sdesolver','The sys.sdesolver cell array must be one dimensional'));
                end                    
                for indx=1:numel(sys.sdesolver)
                    % check that each sys.sdesolver is a function handle
                    if ~isa(sys.sdesolver{indx},'function_handle')
                        throw(MException('bdtoolkit:syscheck:sdesolver','The sys.sdesolver{%d} cell must be a function handle',indx));
                    end
                    % check that each sys.sdesolver is in the search path
                    if strcmp(func2str(sys.sdesolver{indx}),'UNKNOWN Function')
                        throw(MException('bdtoolkit:syscheck:sdesolver','The sys.sdesolver{%d} cell contains a handle to a missing function.',indx));
                    end
                end
                
                % check sys.solveritem
                if sys.solveritem<1 || sys.solveritem > numel(sys.sdesolver)
                    throw(MException('bdtoolkit:syscheck:solveritem','sys.solveritem = %d is out of bounds',sys.solveritem));
                end

                % check sys.sdeoption
                if ~isfield(sys,'sdeoption')
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.sdeoption field is undefined'));
                end
                if ~isstruct(sys.sdeoption)
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.odeoption field must be a struct'));
                end
                
                % check sys.sdeoption.InitialStep
                if ~isfield(sys.sdeoption,'InitialStep')
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.sdeoption.InitialStep field is undefined'));
                end
                if ~isnumeric(sys.sdeoption.InitialStep) && ~isempty(sys.sdeoption.InitialStep)
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.odeoption.InitialStep field must be numeric'));
                end
                
                % check sys.sdeoption.NoiseSources
                if ~isfield(sys.sdeoption,'NoiseSources')
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.sdeoption.NoiseSources field is undefined'));
                end
                if ~isnumeric(sys.sdeoption.NoiseSources)
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.odeoption.NoiseSources field must be numeric'));
                end
                if numel(sys.sdeoption.NoiseSources)~=1
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.odeoption.NoiseSources field must be a scalar value'));
                end
                if mod(sys.sdeoption.NoiseSources,1)~=0
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.sdeoption.NoiseSources field must be an integer value'));
                end
                
                % check sys.sdeoption.randn (an optional parameter)
                if isfield(sys.sdeoption,'randn')
                    if ~isnumeric(sys.sdeoption.randn)
                        throw(MException('bdtoolkit:syscheck:sdeoption','The sys.odeoption.randn field must be numeric'));
                    end
                    if size(sys.sdeoption.randn,1) ~= sys.sdeoption.NoiseSources
                        throw(MException('bdtoolkit:syscheck:sdeoption','The number of rows in sys.sdeoption.randn must equal sys.sdeoption.NoiseSources')); 
                    end
                end
            end            
                
            % check sys.noisehold (an optional parameter)
            if isfield(sys,'noisehold')
                sys.noisehold = logical(sys.noisehold);
            else
                sys.noisehold = false;
            end

            % check sys.evolve (an optional parameter)
            if isfield(sys,'evolve')
                sys.evolve = logical(sys.evolve);
            else
                sys.evolve = false;
            end
            
            % check sys.perturb (an optional parameter)
            if isfield(sys,'perturb')
                sys.perturb = logical(sys.perturb);
            else
                sys.perturb = false;
            end
            
            % check sys.backward (an optional parameter)
            if isfield(sys,'backward') && ~isfield(sys,'ddefun')
                sys.backward = logical(sys.backward);
            else
                sys.backward = false;
            end
            
            % check sys.halt (an optional parameter)
            if isfield(sys,'halt')
                sys.halt = logical(sys.halt);
            else
                sys.halt = false;
            end
            
            % all tests have passed, return the updated sys.
            sysout = sys;
        end
             
        % Check of the format of the sol structure and throw an exception if errors are detected.
        function solcheck(sol)
            if ~isstruct(sol)
                throw(MException('bdSystem:solcheck:badsol','The sol variable must be a struct'));
            end
            if ~isfield(sol,'solver')
                throw(MException('bdSystem:solcheck:badsol','The sol.solver field is missing'));
            end
            if ~isfield(sol,'x')
                throw(MException('bdSystem:solcheck:badsol','The sol.x field is missing'));
            end
            if ~isfield(sol,'y')
                throw(MException('bdSystem:solcheck:badsol','The sol.y field is missing'));
            end
            if ~isfield(sol,'stats')
                throw(MException('bdSystem:solcheck:badsol','The sol.stats field is missing'));
            end
            if ~isstruct(sol.stats)
                throw(MException('bdSystem:solcheck:badsol','The sol.stats field must be a struct'));
            end
            if ~isfield(sol.stats,'nsteps')
                throw(MException('bdSystem:solcheck:badsol','The sol.stats.nsteps field is missing'));
            end
            if ~isfield(sol.stats,'nfailed')
                throw(MException('bdSystem:solcheck:badsol','The sol.stats.nfailed field is missing'));
            end
            if ~isfield(sol.stats,'nfevals')
                throw(MException('bdSystem:solcheck:badsol','The sol.stats.nfevals field is missing'));
            end    
        end

        % The functionality of bdSolve but without the error checking on sys
        function sol = solvesys(sys,tspan,solverfun,solvertype)
            % The type of the solver function determines how we apply it 
            switch solvertype
                case 'odesolver'
                    % case of an ODE solver (eg ode45)
                    y0 = bdGetValues(sys.vardef);
                    par = {sys.pardef.value};
                    sol = solverfun(sys.odefun, tspan, y0, sys.odeoption, par{:});

                case 'ddesolver'
                    % case of a DDE solver (eg dde23)
                    y0 = bdGetValues(sys.vardef);          
                    lag = bdGetValues(sys.lagdef); 
                    par = {sys.pardef.value};
                    sol = solverfun(sys.ddefun, lag, y0, tspan, sys.ddeoption, par{:});

                case 'sdesolver'
                    % case of an SDE solver
                    y0 = bdGetValues(sys.vardef);          
                    par = {sys.pardef.value};
                    sol = solverfun(sys.sdeF, sys.sdeG, tspan, y0, sys.sdeoption, par{:});

                case 'unsupported'
                    % case of an unsupported solver function
                    solvername = func2str(solverfun);
                    throw(MException('bdtoolkit:solve:solverfun','Unknown solvertype for solver ''@%s''. Specify an appropriate solvertype in the calling function.',solvername));
                otherwise
                    throw(MException('bdtoolkit:solve:solvertype','Invalid solvertype ''%s''',solvertype));
                end        
        end
        
    end
end

