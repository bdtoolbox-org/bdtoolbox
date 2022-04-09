%odeEul  Solve ODE using the fixed-step Euler method.
%   SOL = odeEul(ODEFUN,TSPAN,Y0,OPTIONS,...)
%   uses a fixed-step Euler method to integrate a system of Ordinary 
%   Differential Equations of the form 
%      dy/dt = F(t,y,...)
% 
%   The method integrates the equations for time span TSPAN=[T0 TFINAL]
%   from initial conditions Y0. ODEFUN is a handle to the user-defined
%   F(t,y,...) function which an (nx1) vector Y and retruns an (nx1)
%   vector dYdt, for example:
%
%   function dY = odefun(t,Y,theta,mu)  
%       dY = theta .* (mu - Y);
%   end
%
%   Solver-specific options are passed via the OPTIONS struct.
%
%   OPTIONS =
%       InitialStep: [dt]          integrator time step (default=1)
%         OutputFcn: @(t,Y,flag)   handle to user-defined output function
%
%   The solution is returned in the SOL struct as per ode45, ode23, etc.
%   The solution variables can be interpolated using bdEval.
%
%   SOL =
%       x: [1xt]  time points
%       y: [nxt]  y(t) values
%      yp: [nxt]  y'(t) values
%
%EXAMPLE
%  % anonymous versions of F() function shown above.
%  odefun = @(t,Y,theta,mu) theta.*(mu - Y);
%  tspan = [0 10];                  % time domain
%  n = 13;                          % number of equations
%  Y0 = ones(n,1);                  % initial conditions
%  options.InitialStep = 0.01;      % step size, dt
%  theta = 1;                       % model-specific parameter
%  mu = -1;                         % model-specific parameter
%  sol = odeEul(odefun,tspan,Y0,options,theta,mu);
%  T = linspace(0,10,100);          % time domain of interest
%  Y = bdEval(sol,T);               % interpolate
%  plot(T,Y);                       % plot the results
%
%AUTHORS
%  Stewart Heitmann (2016a,2017a,2018a,2020a)

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
function sol = odeEul(ode,tspan,y0,options,varargin)
    % The InitialStep option defines our time step
    dt = odeget(options,'InitialStep');
    if isempty(dt)
        % Default InitialStep
        dt = 1;
        warning('odeEul:InitialStep','Step size is undefined. Using InitialStep=%g',dt);
    end

    % span the time domain in fixed steps
    if tspan(1)<=tspan(end)
        sol.x = tspan(1):dt:tspan(end);     % forward simulation
        dt = abs(dt);                       % force dt to be positive
    else
        sol.x = tspan(1):-dt:tspan(end);    % backward simulation
        dt = -abs(dt);                      % force dt to be negative
    end
    tcount = numel(sol.x);

    % allocate space for the results
    sol.y = NaN(numel(y0),tcount);      % values of y(t)
    sol.yp = sol.y;                     % values of dy(t)/dt

    % miscellaneous output
    sol.solver = mfilename;
    sol.extdata.odefun = ode;
    sol.extdata.options = options;
    sol.ex21tdata.varargin = varargin;
    
    % Get the OutputFcn callback.
    OutputFcn = odeget(options,'OutputFcn');
    if ~isempty(OutputFcn)
        % initialize the OutputFcn
        OutputFcn(tspan,sol.y(:,1),'init');
    end
    
    % Fixed-step Euler method
    sol.y(:,1) = y0;
    for indx=1:tcount-1 
        % Execute the OutputFcn (if it exists)
        if ~isempty(OutputFcn)
            % call the output function
            status = OutputFcn(sol.x(indx),sol.y(:,indx),'');
            if status==1
                % User has cancelled the operation.
                sol.stats.nsteps = indx;
                sol.stats.nfailed = 0;
                sol.stats.nfevals = tcount;
                % cleanup the OutputFcn
                OutputFcn([],[],'done');
                return
            end          
        end
        
        % Euler step
        sol.yp(:,indx) = ode(sol.x(indx), sol.y(:,indx), varargin{:});     % y'(t) = F(t,y(t))
        sol.y(:,indx+1) = sol.y(:,indx) + sol.yp(:,indx) * dt;             % y(t+1) = y(t) + y'(t)*dt       
        
        % Check the Euler step for overflow
        if any(~isfinite(sol.y(:,indx+1)))
            msg = num2str(sol.x(indx),'Failure at t=%g. The numerical values are no longer finite.');
            warning('odeEul:Overflow',msg);
            sol.stats.nsteps = indx;
            sol.stats.nfailed = 1;
            sol.stats.nfevals = tcount;
            % cleanup the OutputFcn
            OutputFcn([],[],'done');
            return
        end
    end
    
    % Complete the final Euler step
    sol.yp(:,end) = ode(sol.x(end), sol.y(:,end), varargin{:});            % y'(t) = F(t,y(t))

    % Check the final Euler step for overflow
    if any(~isfinite(sol.y(:,end)))
        msg = num2str(sol.x(end),'Failure at t=%g. The numerical values are no longer finite.');
        warning('odeEul:Overflow',msg);
        sol.stats.nsteps = tcount;
        sol.stats.nfailed = 1;
        sol.stats.nfevals = tcount;
        % cleanup the OutputFcn
        OutputFcn([],[],'done');
        return
    end
    
    % Execute the OutputFcn for the final entry in tspan.
    if ~isempty(OutputFcn)
        % call the output function
        status = OutputFcn(sol.x(end),sol.y(:,end),'');
        if status==1
            % User has cancelled the operation.
            sol.stats.nsteps = tcount;
            sol.stats.nfailed = 0;
            sol.stats.nfevals = tcount;
            % cleanup the OutputFcn
            OutputFcn([],[],'done');
            return
        end        
        % cleanup the OutputFcn
        OutputFcn([],[],'done');
    end
        
    % Stats
    sol.stats.nsteps = tcount;
    sol.stats.nfailed = 0;
    sol.stats.nfevals = tcount;
end
