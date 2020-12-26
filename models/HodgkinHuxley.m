% HodgkinHuxley Classic Hodgkin-Huxley model of squid axon potential
%    Cm V' = Im - Ik - Ina - Il
% where
%    V is the membrane potential
%    Cm is the membrane capacitance
%    Im is the current injected into the membrane
%    Il = gl * (V-El) is the leak current
%    Ik = gk * n^4 * (V-Ek) is the potassium current
%    Ina = gna * m^3 * h * (V-Ena) is the sodium current
%
% The gating variables m, n and h satisfy the kinetics equations 
%    m' = alpha_m * (1 - m) - beta_m * m
%    n' = alpha_n * (1 - n) - beta_n * n
%    h' = alpha_h * (1 - h) - beta_h * h
% where
%    alpha_m = 0.1 * (-V+25)/(exp((-V+25)/10)-1)  
%    alpha_n = 0.01 * (-V+10)/(exp((-V+10)/10)-1)  
%    alpha_h = 0.07 * exp(-V/20)
%    beta_m = 4 * exp(-V/18)
%    beta_n = 0.125 * exp(-V/80)
%    beta_h = 1/*exp((-V+30)/10)+1))
%
% Example
%    sys = HodgkinHuxley;
%    gui = bdGUI(sys);
%
% Authors
%   Stewart Heitmann (2018b,2020a)
%
% References:
% Hodgkin and Huxley (1952) A quantitative description of membrane current
%   and its application to conduction and excitation in a nerve. J Physiol
%   117:165-181
% Hansel, Mato, Meunier (1993) Phase Dynamics for Weakly Coupled Hodgkin-
%   Huxley Neurons. Europhys Lett 23(5)
function sys = HodgkinHuxley()
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    sys.pardef = [
        struct('name','C',     'value',1,      'lim',[0.1 2]); 
        struct('name','I',     'value',0,      'lim',[0 15]);
        struct('name','gNa',   'value',120,    'lim',[0 200]);
        struct('name','gK',    'value',36,     'lim',[0 50]);
        struct('name','gL',    'value',0.3,    'lim',[0 1]);
        struct('name','ENa',   'value',50,     'lim',[-100 100]);
        struct('name','EK',    'value',-77,    'lim',[-100 100]);
        struct('name','EL',    'value',-54.4,  'lim',[-100 100]);
        ];
               
    % Our ODE variables        
    sys.vardef = [ 
        struct('name','V', 'value',-65,      'lim',[-90 50]);
        struct('name','m', 'value',0.0527,   'lim',[0 1]);
        struct('name','n', 'value',0.317,    'lim',[0 1]);
        struct('name','h', 'value',0.597,    'lim',[0 1])
        ];
    
    % Default time span
    sys.tspan = [0 100];
              
    % Default solver options
    sys.odeoption = odeset('RelTol',1e-6, 'InitialStep',0.01);

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.latex = {
        '$\textbf{HodgkinHuxley}$'
        ''
        'The Hodgkin-Huxley (1952) equations describe the action potential'
        'in the squid giant axon by the kinetics of voltage-dependent sodium'
        'and potassium ion channels in the cell membrane. '
        ''
        'The differential equations are,'
        '{ }{ }{ } $C \; \dot V = I - I_{Na} - I_K - I_L$'
        '{ }{ }{ } $\tau_m(V) \; \dot m = m_{\infty}(V) - m$'
        '{ }{ }{ } $\tau_h(V) \; \dot h = h_{\infty}(V) - h$'
        '{ }{ }{ } $\tau_n(V) \; \dot n = n_{\infty}(V) - n$'
        'where'
        '{ }{ }{ } $V(t)~$ is the electrical potential across the membrane,'
        '{ }{ }{ } $m(t)~$ is the activation variable of the sodium channel,'
        '{ }{ }{ } $h(t)~$ is the inactivation variable of the sodium channel,'
        '{ }{ }{ } $n(t)~$ is the activation variable of the potassium channel,'
        '{ }{ }{ } $C~$ is the membrane capacitance,'
        '{ }{ }{ } $I~$ is an external current that is applied to the membrane,'
        '{ }{ }{ } $I_{Na} = g_{Na}\; m^3 \; h \; (V-E_{Na})~$ is the sodium current,'
        '{ }{ }{ } $I_{K} = g_K \; n^4 \; (V-E_K)~$ is the potassium current,'
        '{ }{ }{ } $I_{L} = g_L \; (V-E_L)~$ is the membrane leak current,'
        '{ }{ }{ } $g_{Na}, g_K, g_L~$ are the maximal conductances of the ion channels,'
        '{ }{ }{ } $E_{Na}, E_K, E_L~$ are the reversal potentials of the ion chanels.'
        ''
        'The external current ($I$) is the principal parameter of interest.'
        ''
        '$\textbf{References}$'
        'Hodgkin, Huxley (1952) A quantitative description of membrane current and'
        '{ }{ }{ } its application to conduction and excitation in a nerve. J Physiol 117'
        'Hansel, Mato, Meunier (1993) Phase Dynamics for Weakly Coupled Hodgkin-'
        '{ }{ }{ } Huxley Neurons. Europhys Lett 23 (5)'
        'Handbook for the Brain Dynamics Toolbox (Version 2018b), Chapter 6.'
        };
    
    % Time-Portrait panel
    sys.panels.bdTimePortrait = [];
    
    % Phase-Portrait panel
    sys.panels.bdPhasePortrait = [];
    
    % Auxiliary Plot panel
    sys.panels.bdAuxiliary.auxfun = {@sodium,@potassium,@combined,@VoltageGates,@IonCurrents};

    % Solver panel
    sys.panels.bdSolverPanel = [];                 
end

% The ODE function
function [dY,INa,IK,IL] = odefun(~,Y,C,I,gNa,gK,gL,ENa,EK,EL)  
    % extract incoming variables from Y
    V = Y(1);
    m = Y(2);
    n = Y(3);
    h = Y(4);
    
    IL = gL * (V-EL);
    IK = gK * n^4 * (V-EK);
    INa = gNa * m^3 * h * (V-ENa);

    am = 0.1*(V+40)/(1-exp((-V-40)/10));
    an = 0.01*(V+55)/(1-exp((-V-55)/10));
    ah = 0.07*exp((-V-65)/20);
    
    bm = 4*exp((-V-65)/18);
    bn = 0.125*exp((-V-65)/80);
    bh = 1/(1+exp((-V-35)/10));
    
    minf = am / (am + bm); 
    ninf = an / (an + bn); 
    hinf = ah / (ah + bh); 
    
    taum = 1 / (am + bm);
    taun = 1 / (an + bn);
    tauh = 1 / (ah + bh);
    
    dV = (I - IK - INa - IL)./C;
    dm = (minf - m)/taum;
    dn = (ninf - n)/taun;
    dh = (hinf - h)/tauh;

    % return result
    dY = [dV; dm; dn; dh];
end

% Auxiliary function that plots the time course of activation and inactivation of the sodium ion channel
function UserData = sodium(ax,tt,sol,C,I,gNa,gK,gL,ENa,EK,EL)
    % extract the solution data
    t = sol.x;
    V = sol.y(1,:);
    m = sol.y(2,:);
    n = sol.y(3,:);
    h = sol.y(4,:);

    % Plot the conductances.
    plot(ax, t, m.^3, 'b-');
    plot(ax, t, h, 'b--');
    plot(ax, t, m.^3 .* h , 'k-', 'Linewidth',1.5);
    ylim(ax, [-0.1 1.1]);
    xlim(ax, [t(1) t(end)]);
    legend(ax, 'activation, m^3','inactivation, h','combined, m^3h');
    title(ax, 'sodium channel activation and inactivation'); 
    xlabel(ax, 'time');
    
    % Make a copy of the data accessible to the workspace
    UserData.t = t;
    UserData.V = V;
    UserData.m = m;
    UserData.n = n;
    UserData.h = h;
end

% Auxiliary function that plots the time course of activation of the potassium ion channel
function UserData = potassium(ax,tt,sol,C,I,gNa,gK,gL,ENa,EK,EL)
    % extract the solution data
    t = sol.x;
    V = sol.y(1,:);
    m = sol.y(2,:);
    n = sol.y(3,:);
    h = sol.y(4,:);

    % Plot the conductances.
    plot(ax, t, n.^4 , 'r-', 'Linewidth',1.5);
    ylim(ax, [-0.1 1.1]);
    xlim(ax, [t(1) t(end)]);
    legend(ax, 'activation, n^4');
    title(ax, 'potassium channel activation'); 
    xlabel(ax, 'time');
    
    % Make a copy of the data accessible to the workspace
    UserData.t = t;
    UserData.V = V;
    UserData.m = m;
    UserData.n = n;
    UserData.h = h;
end

% Auxiliary function that plots the time course of sodium and postassium activation combined
function UserData = combined(ax,tt,sol,C,I,gNa,gK,gL,ENa,EK,EL)
    % extract the solution data
    t = sol.x;
    V = sol.y(1,:);
    m = sol.y(2,:);
    n = sol.y(3,:);
    h = sol.y(4,:);

    % Plot the conductances.
    plot(ax, t, m.^3 .* h , 'k-', 'Linewidth',1.5);
    plot(ax, t, n.^4 , 'r-', 'Linewidth',1.5);
    ylim(ax, [-0.1 1.1]);
    xlim(ax, [t(1) t(end)]);
    legend(ax, 'sodium','potassium');
    title(ax, 'sodium and potassium channel activation'); 
    xlabel(ax, 'time');
    
    % Make a copy of the data accessible to the workspace
    UserData.t = t;
    UserData.V = V;
    UserData.m = m;
    UserData.n = n;
    UserData.h = h;    
end

% Auxiliary function that plots steady-state voltage-dependent channel activations
function UserData = VoltageGates(ax,tt,sol,C,I,gNa,gK,gL,ENa,EK,EL)
    % Voltage domain of interest
    V = linspace(-90,50,201);
    
    % Steady-state Hodgkin-Huxley channel activations
    am = 0.1*(V+40)./(1-exp((-V-40)./10));
    an = 0.01*(V+55)./(1-exp((-V-55)./10));
    ah = 0.07*exp((-V-65)./20);
    
    bm = 4*exp((-V-65)./18);
    bn = 0.125*exp((-V-65)./80);
    bh = 1./(1+exp((-V-35)./10));
    
    minf = am ./ (am + bm); 
    ninf = an ./ (an + bn); 
    hinf = ah ./ (ah + bh); 

    % Plot minf, hinf and ninf.
    plot(ax, V, minf , 'b-', 'Linewidth',1.5);
    plot(ax, V, hinf , 'b--', 'Linewidth',1.5);
    plot(ax, V, ninf , 'r-', 'Linewidth',1.5);
    ylim(ax, [-0.1 1.1]);
    xlim(ax, [-90 50]);
    legend(ax, 'minf','hinf','ninf');
    title(ax, 'Steady-state Voltage-dependent Channel Activations'); 
    xlabel(ax, 'V');
    
    % Make a copy of the data accessible to the workspace
    UserData.V = V;
    UserData.minf = minf;
    UserData.hinf = hinf;
    UserData.ninf = ninf;
end

% Auxiliary function that plots the ion currents
function UserData = IonCurrents(ax,tt,sol,C,I,gNa,gK,gL,ENa,EK,EL)
    % initilaise the data vectors
    UserData.t   = sol.x;
    UserData.INa = NaN(size(sol.x));
    UserData.IK  = NaN(size(sol.x));
    UserData.IL  = NaN(size(sol.x));
    
    % for each time step in the solution
    for tindx = 1:numel(sol.x)
        % get the solution vector for this time step
        Y = sol.y(:,tindx);
        t = sol.x(tindx);
        
        % call the ODE to reconstruct the ionic currents
        [~,INa,IK,IL] = odefun(t,Y,C,I,gNa,gK,gL,ENa,EK,EL);
        
        % accumulate the results in UserData
        UserData.INa(tindx) = INa;
        UserData.IK(tindx)  = IK;
        UserData.IL(tindx)  = IL;
    end
    
    % plot the ionic currents
    plot(ax, UserData.t,UserData.INa,'r');
    plot(ax, UserData.t,UserData.IK,'b');
    plot(ax, UserData.t,UserData.IL,'g');
    plot(ax, UserData.t,UserData.INa+UserData.IK+UserData.IL,'k', 'Linewidth',1.5);
    xlim(ax, UserData.t([1 end]));
    ylim(ax, [-800 800]);
    xlabel(ax, 'time');
    ylabel(ax, 'current density');
    legend(ax, 'INa','IK','IL','combined');
    title(ax, 'Ionic Currents'); 
end

