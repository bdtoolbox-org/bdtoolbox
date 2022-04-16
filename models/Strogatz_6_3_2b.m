function sys = Strogatz_6_3_2b()
    % Strogatz_6_3_2b  Part 2 of example 6.3.2 from Strogatz's textbook
    % The nonlinear system in polar coordinates
    %   r' = a r^3
    %   theta' = 1
    % simulated with the Brain Dynamics Toolbox (bdtoolbox.org).
    %
    % Example:
    %   sys = Strogatz_6_3_2b();    % construct the system struct
    %   gui = bdGUI(sys);           % open the Brain Dynamics GUI
    %
    % Author
    %   Stewart Heitmann (2022)
    %
    % Reference
    %   Steven H Strogatz (1994) Nonlinear Dynamics and Chaos. Westview Press. 

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
        struct('name','a', 'value',0, 'lim',[-1 1])
        ];
    
    % ODE variable definitions
    sys.vardef = [
        struct('name','r', 'value',1, 'lim',[0 2])
        struct('name','theta', 'value',0, 'lim',[-pi pi])
        ];

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = { 
        '$\textbf{Strogatz Example 6.3.2b}$'
        ''
        'The nonlinear system in polar coordinates'
        '$\dot r = a r^3$'
        '$\dot \theta = 1$'
        'where $a$ is a parameter.'
        ''
        '$\textbf{Reference}$'
        'Steven H Strogatz (1994) Nonlinear Dynamics and Chaos. Westview Press.'
        };

    % Time Portrait for r(t)
    sys.panels.bdTimePortrait(1).selector1 = {[1]  [1]  [1]};
    sys.panels.bdTimePortrait(1).selector2 = {[1]  [1]  [1]};
    sys.panels.bdTimePortrait(1).modulo = 'off';

    % Time Portrait for theta(t)
    sys.panels.bdTimePortrait(2).selector1 = {[2]  [1]  [1]};
    sys.panels.bdTimePortrait(2).selector2 = {[2]  [1]  [1]};
    sys.panels.bdTimePortrait(2).modulo = 'on';
    
    % Time Cylinder for theta(t)
    sys.panels.bdTimeCylinder.selector = {[2]  [1]  [1]};

    % Default time span
    sys.tspan = [0 100];
    sys.tstep = 0.5;

    % Specify the relevant ODE solvers
    sys.odesolver = {@ode23,@ode45};
    
    % ODE solver options
    sys.odeoption.RelTol = 1e-6;        % Relative Tolerance
    sys.odeoption.MaxStep = 0.2;        % Maximum Time Step
end

% The ODE function.
function dY = odefun(t,Y,a)
    % incoming state variables
    r = Y(1);
    theta = Y(2);

    % dynamical equations
    dr = a*r^3;
    dtheta = 1;

    % return dYdt
    dY = [dr; dtheta];
end
