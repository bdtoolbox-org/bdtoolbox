function sys = LotkaVolterra()
    % LotkaVolterra  The Lotka-Volterra predator-prey equations.
    % The two-dimensional nonlinear system
    %   x' =  a*x - b*x*y
    %   y' = -c*y + d*x*y 
    % implemented for the Brain Dynamics Toolbox.
    %
    % Example:
    %   sys = LotkaVolterra();            % construct the system struct
    %   gui = bdGUI(sys);                 % open the Brain Dynamics GUI
    %
    % Author
    %   Stewart Heitmann (2022)

    % Copyright (C) 2022 Stewart Heitmann
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

    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % ODE parameter definitions
    sys.pardef = [
        struct('name','a', 'value',1, 'lim',[0 5])
        struct('name','b', 'value',1, 'lim',[0 5])
        struct('name','c', 'value',1, 'lim',[0 5])
        struct('name','d', 'value',1, 'lim',[0 5])
        ];
    
    % ODE variable definitions
    sys.vardef = [
        struct('name','x', 'value',3, 'lim',[0 5])
        struct('name','y', 'value',3, 'lim',[0 5])
        ];

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = { 
        '$\textbf{The Lotka-Volterra predator-prey equations}$'
        ''
        '$\dot x = a x - b x y$'
        '$\dot y = -c y + d x y$'
        ''
        'where'
        ''
        '$x(t)$ is the prey population,'
        '$y(t)$ is the predator population,'
        '$a$ is the growth rate of the prey,'
        '$b$ is the predation rate on the prey,'
        '$c$ is the death rate of the predators,'
        '$d$ is the growth rate of the predators,'
        };

    % Time Portrait panel 
    sys.panels.bdTimePortrait = [];

    % Phase Portrait panel
    sys.panels.bdPhasePortrait.nullclines = 'on';
    sys.panels.bdPhasePortrait.vectorfield = 'on';
      
    % Default time span
    sys.tspan = [0 40];
    sys.tstep = 0.1;

    % Specify the relevant ODE solvers
    sys.odesolver = {@ode45,@ode23};
    
    % ODE solver options
    sys.odeoption.RelTol = 1e-6;        % Relative Tolerance
end

% The ODE function.
function dY = odefun(t,Y,a,b,c,d)
    % incoming state variables
    x = Y(1);
    y = Y(2);

    % dynamical equations
    dx =  a*x - b*x*y;
    dy = -c*y + d*x*y;

    % return dYdt
    dY = [dx; dy];
end
