function sys = Strogatz_6_6_3()
    % Strogatz_6_6_3  Example 6.6.3 from Strogatz's textbook
    % Symmetrical system with a homoclinic orbit
    %   x' = -2*cos(x) - cos(y) 
    %   y' = -2*cos(y) - cos(x)
    % implemented for the Brain Dynamics Toolbox (bdtoolbox.org).
    %
    % Example:
    %   sys = Strogatz_6_6_3();     % construct the system struct
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
        struct('name','a', 'value',2, 'lim',[0 5])
        ];
    
    % ODE variable definitions
    sys.vardef = [
        struct('name','x', 'value',1, 'lim',[-2*pi 2*pi])
        struct('name','y', 'value',1, 'lim',[-2*pi 2*pi])
        ];

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = { 
        '$\textbf{Strogatz Example 6.6.3}$'
        ''
        'Symmetrical system that is reversible but not conservative'
        '$\dot x = -a \cos(x) - \cos(y)$'
        '$\dot y = -a \cos(y) - \cos(x)$'
        'where $a=2$ is a parameter.'
        ''
        '$\textbf{Reference}$'
        'Steven H Strogatz (1994) Nonlinear Dynamics and Chaos. Westview Press.'
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
    sys.odesolver = {@ode23,@ode45};
    
    % ODE solver options (optional)
    sys.odeoption.RelTol = 1e-6;        % Relative Tolerance
end

% The ODE function.
function dY = odefun(t,Y,a)
    % incoming state variables
    x = Y(1);
    y = Y(2);

    % dynamical equations
    dx = -a*cos(x) - cos(y);
    dy = -a*cos(y) - cos(x);

    % return dYdt
    dY = [dx; dy];
end
