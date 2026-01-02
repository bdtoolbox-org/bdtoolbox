% HodgkinHuxley 1952 model of squid axon potential
%    C V' = Iapp - Ik - Ina - Il
% where
%    V is the membrane potential
%    C is the membrane capacitance
%    Iapp is the current injected into the membrane
%    Il = gl * (V-El) is the leak current
%    Ik = gk * n^4 * (V-Ek) is the potassium current
%    Ina = gna * m^3 * h * (V-Ena) is the sodium current
%
% The gating variables m, n and h satisfy the kinetics equations 
%    m' = alpha_m * (1 - m) - beta_m * m
%    n' = alpha_n * (1 - n) - beta_n * n
%    h' = alpha_h * (1 - h) - beta_h * h
% where
%    alpha_m = 0.1*(25-V)./(exp((25-V)./10)-1);
%    alpha_n = 0.01*(10-V)./(exp((10-V)./10)-1);
%    alpha_h = 0.07*exp(-V./20);
%    beta_m = 4*exp(-V./18);
%    beta_n = 0.125*exp(-V./80);
%    beta_h = 1./(exp((30-V)./10)+1);
%
% Example
%    sys = HodgkinHuxley1952;
%    gui = bdGUI(sys);
%
% Authors
%   Stewart Heitmann (2018b,2020a,2025,2026)
%
% References:
% Hodgkin and Huxley (1952) A quantitative description of membrane current
%   and its application to conduction and excitation in a nerve. J Physiol
%   117:165-181
% Nelson (2004) Electrophysiological Models In: Databasing the Brain: From
%   Data to Knowledge. Koslow and Subramaniam, eds. Wiley, New York.
% Heitmann and Breakspear (2026) Handbook for the Brain Dynamics Toolbox:
%   Version 2026a. Chapter 6. https://bdtoolbox.org.
function sys = HodgkinHuxley1952()
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % initial conditions
    V = 0;   
    [am,an,ah] = alpha(V);
    [bm,bn,bh] = beta(V);
    m0 = am / (am + bm); 
    n0 = an / (an + bn); 
    h0 = ah / (ah + bh); 

    % Our ODE parameters
    sys.pardef = [
        struct('name','C',     'value',1,      'lim',[0.1 2]); 
        struct('name','Iamp',  'value',0,      'lim',[0 20]);
        struct('name','Idur',  'value',80,     'lim',[0 200]);
        struct('name','gNa',   'value',120,    'lim',[0 200]);
        struct('name','gK',    'value',36,     'lim',[0 50]);
        struct('name','gL',    'value',0.3,    'lim',[0 1]);
        struct('name','ENa',   'value',115,    'lim',[-20 120]);
        struct('name','EK',    'value',-12,    'lim',[-20 120]);
        struct('name','EL',    'value',10.613, 'lim',[-20 120]);
        ];
               
    % Our ODE variables        
    sys.vardef = [ 
        struct('name','V',   'value',V,      'lim',[-20 120]);
        struct('name','m',   'value',m0,     'lim',[0 1]);
        struct('name','n',   'value',n0,     'lim',[0 1]);
        struct('name','h',   'value',h0,     'lim',[0 1])
        struct('name','Iapp','value',0,      'lim',[-10 20])        
        struct('name','IL',  'value',-3.183, 'lim',[-10 40])        
        struct('name','IK',  'value', 4.404, 'lim',[-100 1000])        
        struct('name','INa', 'value',-1.221, 'lim',[-1000 100])        
        struct('name','dVdt','value',0,      'lim',[-100 400])        
        ];
    
    % Default time span
    sys.tspan = [-20 100];
              
    % Default solver options
    sys.odesolver = {@ode15s};
    sys.odeoption = odeset('RelTol',1e-3, 'InitialStep',0.01);

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.latex = {
        '$\textbf{Hodgkin Huxley 1952}$'
        ''
        'The Hodgkin-Huxley (1952) equations describe the action potential'
        'in the squid giant axon by the kinetics of voltage-dependent sodium'
        'and potassium ion channels in the cell membrane. '
        ''
        'The differential equations are,'
        '{ }{ }{ } $C \; \dot V = I - I_{Na} - I_K - I_L + I_{app}$'
        '{ }{ }{ } $\tau_m(V) \; \dot m = m_{\infty}(V) - m$'
        '{ }{ }{ } $\tau_h(V) \; \dot h = h_{\infty}(V) - h$'
        '{ }{ }{ } $\tau_n(V) \; \dot n = n_{\infty}(V) - n$'
        'where'
        '{ }{ }{ } $V(t)~$ is the electrical potential across the membrane,'
        '{ }{ }{ } $m(t)~$ is the activation gate of the sodium channel,'
        '{ }{ }{ } $h(t)~$ is the inactivation gate of the sodium channel,'
        '{ }{ }{ } $n(t)~$ is the activation gate of the potassium channel,'
        '{ }{ }{ } $C~$ is the capacitance of the membrane.'
        ''
        'The membrane currents are as follows,'
        '{ }{ }{ } $I_{Na} = g_{Na}\; m^3 \; h \; (V-E_{Na})~$ is the sodium current,'
        '{ }{ }{ } $I_{K} = g_K \; n^4 \; (V-E_K)~$ is the potassium current,'
        '{ }{ }{ } $I_{L} = g_L \; (V-E_L)~$ is the membrane leak current,'
        'where'
        '{ }{ }{ } $g_{Na}, g_K, g_L~$ are the maximal conductances of the ion channels,'
        '{ }{ }{ } $E_{Na}, E_K, E_L~$ are the reversal potentials of the ion chanels.'
        ''
        '$I_{app}$ is a step current that is applied to the membrane. Specifically,'
        '{ }{ }{ } $I_{app} = I_{amp}$ for $0 {\leq} t {<} I_{dur}$ ,'
        '{ }{ }{ } $I_{app} = 0$ otherwise.'
        ''
        '$\textbf{Dummy variables}$'
        'The membrane currents $(I_{Na}, I_K, I_L, I_{app})$ are not returned by the ODE solver,'
        'so the model uses dummy variables to visualise them. The dummy variables'
        'track the dynamics but do not contribute to it. The exact values of the'
        'membrane currents can be viewed in the Auxilliary panel.'
        ''
        '$\textbf{References}$'
        'Hodgkin, Huxley (1952) A quantitative description of membrane current and'
        '{ }{ }{ } its application to conduction and excitation in a nerve. J Physiol 117'
        'Nelson (2004) Electrophysiological Models In: Databasing the Brain: From'
        '{ }{ }{ } Data to Knowledge. Koslow and Subramaniam, eds. Wiley, New York.'
        'Heitmann and Breakspear (2026) Handbook for the Brain Dynamics Toolbox:'
        '{ }{ }{ } Version 2026a. Chapter 6. https://bdtoolbox.org.'
        };
    
    % Time-Portrait panel
    sys.panels.bdTimePortrait(1).selector1={1 1 1};
    sys.panels.bdTimePortrait(1).selector2={5 1 1};
    sys.panels.bdTimePortrait(2).selector1={7 1 1};
    sys.panels.bdTimePortrait(2).selector2={8 1 1};
    
    % Phase-Portrait panel
    sys.panels.bdPhasePortrait.selectorX={1 1 1};
    sys.panels.bdPhasePortrait.selectorY={3 1 1};
    
    % Auxiliary Plot panel
    sys.panels.bdAuxiliary.auxfun = {@Voltage_Gates, @IK_Gates, @INa_Gates, @Iapp_Current, @IK_Current, @INa_Current, @IL_Current};

    % Solver panel
    sys.panels.bdSolverPanel = [];                 
end

% The ODE function
function [dY,Iapp,INa,IK,IL] = odefun(t,Y,C,Iamp,Idur,gNa,gK,gL,ENa,EK,EL)  
    % extract incoming variables from Y
    V = Y(1);
    m = Y(2);
    n = Y(3);
    h = Y(4);
    
    % Only apply the stimulus for t in [0 Idur]
    Iapp = 0;
    if t>=0 && t<Idur
        Iapp=Iamp;
    end
       
    % The ion-currents
    IL = gL * (V-EL);
    IK = gK * n^4 * (V-EK);
    INa = gNa * m^3 * h * (V-ENa);

    % Rate functions for the gating variables
    [am,an,ah] = alpha(V);
    [bm,bn,bh] = beta(V);
    
    minf = am / (am + bm); 
    ninf = an / (an + bn); 
    hinf = ah / (ah + bh); 
    
    taum = 1 / (am + bm);
    taun = 1 / (an + bn);
    tauh = 1 / (ah + bh);
    
    dV = (Iapp - IK - INa - IL)./C;
    dm = (minf - m)/taum;
    dn = (ninf - n)/taun;
    dh = (hinf - h)/tauh;

    % These dummy variables track internal states (Iapp,IL,IK,INa,dVdt) for
    % the purpose of visualization. They have no effect on the dynamics.
    Iapp_hat = Y(5);
    IL_hat   = Y(6);
    IK_hat   = Y(7);
    INa_hat  = Y(8);
    dV_hat   = Y(9);

    dIapp_hat = 1000*(Iapp-Iapp_hat);
    dIL_hat   = 1000*(IL-IL_hat);
    dIK_hat   = 1000*(IK-IK_hat);
    dINa_hat  = 1000*(INa-INa_hat);
    ddV_hat   = 1000*(dV-dV_hat);

    % return result
    dY = [dV; dm; dn; dh; dIapp_hat; dIL_hat; dIK_hat; dINa_hat; ddV_hat];
end

% Rate functions using the original HH convention (V=0 at rest)
function [am,an,ah] = alpha(V)
    
    % standard formulation for alpha_m(V)
    am = 0.1*(25-V)./(exp((25-V)./10)-1);

    % alpha_m(V) is indeterminate (0/0) when V=25 
    % Apply L'Hospitals's rule for V~25. 
    idx = (abs(V-25)<1e-3);
    am(idx) = 1.0./exp((25-V(idx))./10);

    % standard formulation for alpha_n(V) when V is not near 10
    an = 0.01*(10-V)./(exp((10-V)./10)-1);

    % alpha_n(V) is indeterminate (0/0) when V=10.
    % Apply L'Hospitals's rule for V~10. 
    idx = (abs(V-10)<1e-3);
    an(idx) = 0.1./exp((10-V(idx))./10);

    ah = 0.07*exp(-V./20);
end

% Rate functions using the original HH convention (V=0 at rest)
function [bm,bn,bh] = beta(V)
    bm = 4*exp(-V./18);
    bn = 0.125*exp(-V./80);
    bh = 1./(exp((30-V)./10)+1);
end

% Auxiliary function that plots the steady-states of the voltage-dependent gates
function UserData = Voltage_Gates(ax,tt,sol,C,Iamp,Idur,gNa,gK,gL,ENa,EK,EL)
    % Voltage domain of interest
    V = -50:150;
    
    % Steady-state Hodgkin-Huxley channel activations
    [am,an,ah] = alpha(V);
    [bm,bn,bh] = beta(V);
    minf = am ./ (am + bm); 
    ninf = an ./ (an + bn); 
    hinf = ah ./ (ah + bh); 

    % Plot minf, hinf and ninf.
    plot(ax, V, minf , 'b-', 'Linewidth',1.5);
    plot(ax, V, hinf , 'b--', 'Linewidth',1.5);
    plot(ax, V, ninf , 'r-', 'Linewidth',1.5);
    ylim(ax, [-0.1 1.1]);
    xlim(ax, [-50 150]);
    legend(ax, 'minf','hinf','ninf');
    title(ax, 'Gates at Steady-State Voltage'); 
    xlabel(ax, 'V');
    
    % Make a copy of the data accessible to the workspace
    UserData.V = V;
    UserData.minf = minf;
    UserData.hinf = hinf;
    UserData.ninf = ninf;
end

% Auxiliary function that plots the time course of the IK gates
function UserData = IK_Gates(ax,tt,sol,C,Iamp,Idur,gNa,gK,gL,ENa,EK,EL)
    % extract the solution data
    t = sol.x;
    V = sol.y(1,:);
    n = sol.y(3,:);

    % Plot the conductances.
    plot(ax, t, n.^4, 'k-', 'LineWidth',1.5);
    ylim(ax, [-0.1 1.1]);
    xlim(ax, [t(1) t(end)]);
    legend(ax, 'activation, n^4');
    title(ax, 'Time Course of IK Gate (n^4)'); 
    xlabel(ax, 'time');

    % Restrict zooming to the vertical axis
    ax.Interactions = zoomInteraction('Dimensions','y');
    
    % Make a copy of the data accessible to the workspace
    UserData.t = t;
    UserData.V = V;
    UserData.n = n;
end

% Auxiliary function that plots the time course of the INa gates
function UserData = INa_Gates(ax,tt,sol,C,Iamp,Idur,gNa,gK,gL,ENa,EK,EL)
    % extract the solution data
    t = sol.x;
    V = sol.y(1,:);
    m = sol.y(2,:);
    n = sol.y(3,:);
    h = sol.y(4,:);

    % Plot the conductances.
    plot(ax, t, m.^3, 'b-', 'Linewidth',1);
    plot(ax, t, h, 'b--', 'LineWidth',1);
    plot(ax, t, m.^3 .* h , 'k-', 'Linewidth',2);
    ylim(ax, [-0.1 1.1]);
    xlim(ax, [t(1) t(end)]);
    legend(ax, 'activation, m^3','inactivation, h','m^3h');
    title(ax, 'Time Course of INa Gates (m^3h)'); 
    xlabel(ax, 'time');

    % Restrict zooming to the vertical axis
    ax.Interactions = zoomInteraction('Dimensions','y');
    
    % Make a copy of the data accessible to the workspace
    UserData.t = t;
    UserData.V = V;
    UserData.m = m;
    UserData.h = h;
end

% Auxiliary function that plots the time course of Iapp
function UserData = Iapp_Current(ax,tt,sol,C,Iamp,Idur,gNa,gK,gL,ENa,EK,EL)
    % extract the computed solution
    t = sol.x;
    V = sol.y(1,:);
    n = sol.y(3,:);
    Iapp_hat = sol.y(5,:);

    % The analytic form of the solution
    Iapp = Iamp * (t>=0 & t<Idur);
    
    % plot the currents
    plot(ax, t,Iapp,'g','LineWidth',3);
    plot(ax, t,Iapp_hat,'k','LineWidth',1.5);
    xlim(ax, t([1 end]));
    ylim(ax, [-10 50]);
    xlabel(ax, 'time');
    ylabel(ax, 'current density');
    legend(ax, 'Iapp (exact)','Iapp (dummy)');
    title(ax, 'Stimulus Current (Iapp)'); 

    % Restrict zooming to the vertical axis
    ax.Interactions = zoomInteraction('Dimensions','y');

    % return data
    UserData = [];
    UserData.t = t;
    UserData.V = V;
    UserData.Iapp = Iapp;
end


% Auxiliary function that plots the time course of IL
function UserData = IL_Current(ax,tt,sol,C,Iamp,Idur,gNa,gK,gL,ENa,EK,EL)
    % extract the computed solution
    t = sol.x;
    V = sol.y(1,:);
    IL_hat = sol.y(6,:);

    % The analytic form of the solution
    IL = gL * (V-EL);
    
    % plot the currents
    plot(ax, t,IL,'g','LineWidth',3);
    plot(ax, t,IL_hat,'k','LineWidth',1.5);
    xlim(ax, t([1 end]));
    ylim(ax, [-10 40]);
    xlabel(ax, 'time');
    ylabel(ax, 'current density');
    legend(ax, 'IL (exact)','IL (dummy)');
    title(ax, 'Leak Current (IL)'); 

    % Restrict zooming to the vertical axis
    ax.Interactions = zoomInteraction('Dimensions','y');

    % return data
    UserData = [];
    UserData.t = t;
    UserData.V = V;
    UserData.IL = IL;
end

% Auxiliary function that plots the time course of IK
function UserData = IK_Current(ax,tt,sol,C,Iamp,Idur,gNa,gK,gL,ENa,EK,EL)
    % extract the computed solution
    t = sol.x;
    V = sol.y(1,:);
    n = sol.y(3,:);
    IK_hat = sol.y(7,:);

    % The analytic form of the solution
    IK = gK * n.^4 .* (V-EK);
    
    % plot the currents
    plot(ax, t,IK,'g','LineWidth',3);
    plot(ax, t,IK_hat,'k','LineWidth',1.5);
    xlim(ax, t([1 end]));
    ylim(ax, [-100 1000]);
    xlabel(ax, 'time');
    ylabel(ax, 'current density');
    legend(ax, 'IK (exact)','IK (dummy)');
    title(ax, 'Potassium Current (IK)'); 

    % Restrict zooming to the vertical axis
    ax.Interactions = zoomInteraction('Dimensions','y');

    % return data
    UserData = [];
    UserData.t = t;
    UserData.V = V;
    UserData.IK = IK;
end

% Auxiliary function that plots the time course of INa
function UserData = INa_Current(ax,tt,sol,C,Iamp,Idur,gNa,gK,gL,ENa,EK,EL)
    % extract the computed solution
    t = sol.x;
    V = sol.y(1,:);
    m = sol.y(2,:);
    h = sol.y(4,:);
    INa_hat = sol.y(8,:);

    % The analytic form of the solution
    INa = gNa * m.^3 .* h .* (V-ENa);
    
    % plot the currents
    plot(ax, t,INa,'g','LineWidth',3);
    plot(ax, t,INa_hat,'k','LineWidth',1.5);
    xlim(ax, t([1 end]));
    ylim(ax, [-1000 100]);
    xlabel(ax, 'time');
    ylabel(ax, 'current density');
    legend(ax, 'INa (exact)','INa (dummy)');
    title(ax, 'Sodium Current (INa)'); 

    % Restrict zooming to the vertical axis
    ax.Interactions = zoomInteraction('Dimensions','y');

    % return data
    UserData = [];
    UserData.t = t;
    UserData.V = V;
    UserData.INa = INa;
end
