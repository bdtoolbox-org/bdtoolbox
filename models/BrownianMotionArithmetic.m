% BrownianMotionArithmetic  bdtoolbox model of arithmetic Brownian motion
%   Brownian motion with drift is called Arithmetic Brownian Motion.
%   The Stochastic Differential Equation (SDE) is
%        dy(t) = mu*dt + sigma*dW(t)
%   where mu is the drift coefficient and sigma is the diffusion coefficient.
%
% Example:
%   n = 100;                            % number of random processes
%   sys = BrownianMotionArithmetic(n);  % construct the system struct
%   gui = bdGUI(sys);                   % open the Brain Dynamics GUI
%
% Authors
%   Stewart Heitmann (2021a)

% Copyright (C) 2021-2022 Stewart Heitmann
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
function sys = BrownianMotionArithmetic(n)
    % Handles to our SDE functions
    sys.sdeF   = @sdeF;                 % deterministic coefficients
    sys.sdeG   = @sdeG;                 % stochastic coefficients

    % Our SDE parameters
    sys.pardef = [ 
        struct('name','mu',    'value', 1, 'lim',[-2 2])
        struct('name','sigma', 'value', 1, 'lim',[0 3])
        ];
               
    % Our SDE variables
    sys.vardef =  struct('name','Y', 'value',5*ones(n,1), 'lim',[0 20]);
    
    % Default time span
    sys.tspan = [0 10];
    sys.tstep = 0.01;
              
   % Specify SDE solvers and default options
    sys.sdesolver = {@sdeEM,@sdeSH};    % Relevant SDE solvers
    sys.sdeoption.InitialStep = 0.01;   % SDE solver step size (optional)
    sys.sdeoption.NoiseSources = n;     % Number of driving Wiener processes

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '$\textbf{Arithmetic Brownian Motion}$'
        ''
        'Brownian motion with drift is called arithmetic Brownian motion.'
        ''
        'The Stochastic Differential Equation is'
        '{ }{ }{ } $dY = \mu\,dt + \sigma\,dW_t$'
        'where'
        '{ }{ }{ } $Y(t)\;$ is the random variable,'
        '{ }{ }{ } $\mu\;$ is the drift coefficient,'
        '{ }{ }{ } $\sigma\;$ is the diffusion coefficient.'
        ''
        'The random variable $Y(t)\;$ is normally distributed with mean $Y(0){+}\mu t\;$'
        'and variance $\sigma^2 t$.'
        ''
        sprintf('This simulation has n=%d independent processes',n)
        };
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = [];
end

% The drift function.
function F = sdeF(t,Y,mu,sigma)
    n = numel(Y);
    F = mu*ones(n,1);
end

% The diffusion function.
function G = sdeG(t,Y,mu,sigma)
    n = numel(Y);
    G = sigma * eye(n);
end
