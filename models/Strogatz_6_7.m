function sys = Strogatz_6_7()
    % Strogatz_6_7  Example 6.7 from Strogatz's textbook
    % The damped pendulum
    %   theta' = v
    %   v' = -bv - sin(theta)
    % implemented for the Brain Dynamics Toolbox (bdtoolbox.org).
    %
    % Example:
    %   sys = Strogatz_6_7();       % construct the system struct
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
        struct('name','b', 'value',0.1, 'lim',[0 2])
        ];
    
    % ODE variable definitions
    sys.vardef = [
        struct('name','theta', 'value',-3, 'lim',[-pi pi])
        struct('name','v',     'value', 2, 'lim',[-3 3])
        ];

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = { 
        '$\textbf{Strogatz Example 6.7}$'
        ''
        'The linearly damped pendulum'
        '$\dot \theta = v$'
        '$\dot v = -b v - \sin(\theta)$'
        'where $b>0$ is the damping strength.'
        ''
        '$\textbf{Reference}$'
        'Steven H Strogatz (1994) Nonlinear Dynamics and Chaos. Westview Press.'
        };

    % Time Cylinder panel 
    sys.panels.bdTimeCylinder.azimuth = 5;

    % Phase Portrait panel
    sys.panels.bdPhasePortrait.nullclines = 'on';
    sys.panels.bdPhasePortrait.vectorfield = 'on';
    sys.panels.bdPhasePortrait.modulo = 'on';
      
    % Default time span
    sys.tspan = [0 40];
    sys.tstep = 0.1;

    % Specify the relevant ODE solvers
    sys.odesolver = {@ode23,@ode45};
    
    % ODE solver options (optional)
    sys.odeoption.RelTol = 1e-6;        % Relative Tolerance
end

% The ODE function.
function dY = odefun(t,Y,b)
    % incoming state variables
    theta = Y(1);
    v     = Y(2);

    % dynamical equations
    dtheta = v;
    dv     = -b*v - sin(theta);

    % return dYdt
    dY = [dtheta; dv];
end
