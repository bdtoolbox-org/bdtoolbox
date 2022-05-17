function sys = HopfRC()
    % HopfRC  Normal form of the Hopf bifurcation in polar coordinates
    %    dr/dt = (r^2-alpha)*r
    %    dtheta/dt =  omega
    % where the radius of the limit cycle is sqrt(alpha).
    %
    % Example:
    %   sys = HopfRC();         % construct the system struct
    %   gui = bdGUI(sys);       % open the Brain Dynamics GUI
    %
    % Authors
    %   Stewart Heitmann (2022b)

    % Copyright (C) 2022 Stewart Heitmann. All rights reserved.
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
    sys.pardef = [ struct('name','alpha', 'value',0.25, 'lim',[-1 1]) ];
    
    % ODE variable definitions
    sys.vardef = [
        struct('name','r',     'value',1, 'lim',[0 2]) 
        struct('name','theta', 'value',0, 'lim',[-pi pi]) 
        ];

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = { 
        '$\textbf{Hopf RC}$'
        ''
        'Normal form of the supercritical Hopf bifurcation in polar coordinates'
        '$\qquad\dot r = (\alpha - r^2) \, r $'
        '$\qquad \dot \theta = 1$'
        'where the radius of the limit cycle is $\sqrt \alpha$.'
        };

    % Time Portrait panel 
    sys.panels.bdTimePortrait.autostep='off';
    sys.panels.bdTimePortrait.modulo='on';

    % Time Cylinder panel
    sys.panels.bdTimeCylinder.selector={2,1,1};
    sys.panels.bdTimeCylinder.azimuth=5;
    sys.panels.bdTimeCylinder.autostep='off';
  
    % Solver panel
    sys.panels.bdSolverPanel = [];
    
    % Time span
    sys.tspan = [0 20];
    sys.tstep = 0.1;

    % Specify the relevant ODE solvers (optional)
    sys.odesolver = {@ode45};
    
    % ODE solver options (optional)
    sys.odeoption.RelTol = 1e-6;        % Relative Tolerance
end

% The ODE function.
function dY = odefun(~,Y,alpha) 
    % extract incoming states
    r = Y(1);
    theta = Y(2);
    
    % Hopf normal form
    dr = (alpha-r^2)*r;
    dtheta = 1;
    
    % Return results
    dY = [dr; dtheta];
end
