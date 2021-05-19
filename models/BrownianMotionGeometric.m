% BrownianMotionGeometric  bdtoolbox model of geometric Brownian motion
%   The Ito form of the Stochastic Differential Equation (SDE) is
%        dy(t) = mu*y(t)*dt + sigma*y(t)*dW(t)
%   where the drift and diffusion coefficients are both proproptional to y(t).
%
% Example:
%   n = 100;                            % number of random processes
%   sys = BrownianMotionGeometric(n);   % construct the system struct
%   gui = bdGUI(sys);                   % open the Brain Dynamics GUI
%
% Authors
%   Stewart Heitmann (2016a,2017a,2018a,2020a,2021a)

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
function sys = BrownianMotionGeometric(n)
    % Handles to our SDE functions
    sys.sdeF   = @sdeF;                 % deterministic coefficients
    sys.sdeG   = @sdeG;                 % stochastic coefficients

    % Our SDE parameters
    sys.pardef = [ 
        struct('name','mu',    'value', 0.5,  'lim',[0 1])
        struct('name','sigma', 'value', 0.5,  'lim',[0 1])
        ];
               
    % Our SDE variables
    sys.vardef =  struct('name','Y', 'value',ones(n,1), 'lim',[0 20]);
    
    % Default time span
    sys.tspan = [0 5];
    sys.tstep = 0.01;
              
   % Specify SDE solvers and default options
    sys.sdesolver = {@sdeEM};           % Relevant SDE solvers
    sys.sdeoption.InitialStep = 0.01;   % SDE solver step size (optional)
    sys.sdeoption.NoiseSources = n;     % Number of driving Wiener processes

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '$\textbf{Geometric Brownian Motion}$'
        ''
        'The Ito Stochastic Differential Equation is'
        '{ }{ }{ } $dY = \mu\,Y\,dt + \sigma\,Y\,dW_t$'
        'where'
        '{ }{ }{ } $Y(t)\;$ is the random variable,'
        '{ }{ }{ } $\mu\;$ is the drift parameter,'
        '{ }{ }{ } $\sigma\;$ is the diffusion parameter.'
        ''
        'The random variable $Y(t)\;$ is normally distributed with mean $Y_0 \exp(\mu t)\;$'
        'and variance $Y_0^2 \exp(2\mu t) (\exp(\sigma^2 t) - 1)$.'
        ''
        sprintf('This simulation has n=%d independent processes',n)        
        };
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = [];
end

% The deterministic coefficient function.
function F = sdeF(t,Y,mu,sigma) 
    F = mu.*Y;
end

% The noise coefficient function.
function G = sdeG(t,Y,mu,sigma)
    n = numel(Y);
    G = sigma.*Y.*eye(n,n);
end
