% BTF2003SDE  Stochastic variant of Breakspear, Terry and Friston (2003)
%   Modulation of excitatory synaptic coupling facilitates synchronization
%   and complex dynamics in a biophysical model of neuronal dynamics.
%   Network: Comput. Neural Syst., 14 (2003) 703-732  
%   PII: S0954-898X(03)55346-5
%
% Usage:
%   sys = BTF2003SDE(Kij)
%   where Kij is an (nxn) connectivity matrix in which the entry at row i
%   and column j is the weight of the connection from node i to node j.
%
% Example:
%   load cocomac047 CIJ         % Load a connectivity matrix. 
%   sys = BTF2003SDE(CIJ);      % Construct the system struct.
%   gui = bdGUI(sys);           % Open the Brain Dynamics GUI.

% Authors
%   Stewart Heitmann (2017b,2017c,2018a,2019a,2020a)

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
function sys = BTF2003SDE(Kij)
    % determine the number of nodes from Kij
    n = size(Kij,1);

    % Warn if the diagonals of Kij are non-zero
    if any(diag(Kij))
        warning('The diagonal entries of Kij should be zero to avoid double-dipping on self connections');
    end
    
    % Handle to our SDE functions
    sys.sdeF = @sdeF;
    sys.sdeG = @sdeG;
    
    % System parameters from Table 1 of Breakspear, Terry & Friston (2003)
    sys.pardef = [
        % Connection Matrix (nxn) 
        struct('name','Kij',   'value',  Kij);            
                   
        % Connection weights
        struct('name','aee',    'value', 0.4);
        struct('name','aei',    'value', 2.0);
        struct('name','aie',    'value', 2.0);
        struct('name','ane',    'value', 1.0);
        struct('name','ani',    'value', 0.4);

        % Time constant of inhibition
        struct('name','b',    'value',  0.10);

        % Relative contribution of excitatory connection between versus within enembles
        struct('name','C',    'value',  0);

        % Relative contribution of NMDA versus AMPA receptors
        struct('name','r',    'value',  0.25); 

        % Temperature scaling factor                   
        struct('name','phi',  'value',  0.7);

        % Ion channel parameters
        struct('name','gCa',  'value', 1.10);           % Conductance of Ca
        struct('name','gK',   'value', 2.00);           % Conductance of K
        struct('name','gNa',  'value', 6.70);           % Conductance of Na
        struct('name','gL',   'value', 0.50);           % Conductance of Leak
        struct('name','VCa',  'value',  1.00);          % Nernst Potential of Ca
        struct('name','VK',   'value', -0.70);          % Nernst Potential of K
        struct('name','VNa',  'value',  0.53);          % Nernst Potential of Na
        struct('name','VL',   'value', -0.50);          % Nernst Potential of Leak
                   
        % Gain parameters
        struct('name','VT',  'value', 0.0);     % Firing threshold VT
        struct('name','ZT',  'value', 0.0);     % Firing threshold ZT
        struct('name','TCa', 'value',-0.01);    % Firing threshold TCa
        struct('name','TK',  'value', 0.00);    % Firing threshold TK
        struct('name','TNa', 'value', 0.30);    % Firing threshold TNa      
        struct('name','deltaV', 'value', 0.7);  % Firing fun slope deltaV
        struct('name','deltaZ', 'value', 0.7);  % Firing fun slope deltaZ
        struct('name','deltaCa','value',0.15);  % Firing fun slope deltaCa
        struct('name','deltaK', 'value',0.30);  % Firing fun slope deltaK
        struct('name','deltaNa', 'value',0.15); % Firing fun slope deltaNa]     

        % Strength of subcortical input
        struct('name','I',    'value', 0.3);
        
        % Noise volatility parameters
        struct('name','alpha', 'value', 0);
        struct('name','beta',  'value', 0);
        ];
               
    % System state variables
    sys.vardef = [ struct('name','V', 'value',rand(n,1)./2.3 - 0.1670, 'lim',[-0.6 0.6]);  % Mean firing rate of excitatory cells
                   struct('name','W', 'value',rand(n,1)./2.6 + 0.27, 'lim',[0 0.9]);       % Proportion of open K channels
                   struct('name','Z', 'value',rand(n,1)./10, 'lim',[0 0.3]) ];             % Mean firing rate of inhibitory cells
               
    % Integration time span
    sys.tspan = [0 1000]; 
    sys.tstep = 0.1;
   
    % SDE solver options
    sys.sdesolver = {@sdeEM};           % Euler-Murayama solvers
    sys.sdeoption.InitialStep = 0.1;    % SDE solver step size (optional)
    sys.sdeoption.NoiseSources = n;     % Number of Wiener noise processes

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '$\textbf{BTF2003SDE}$'
        'Breakspear, Terry \& Friston (2003) Network: Comput Neural Syst (14).'
        'Stochastic variant of a network of neural masses comprising densely connected local ensembles of'
        'excitatory and inhibitory neurons with long-range excitatory coupling between ensembles.'
        '{ }{ }{ } $dV^{(j)} = -\big(g_{Ca} + (1-C)\,r\,a_{ee} Q_V^{(j)} + C\,r\,a_{ee}\,\langle Q_V \rangle^{(j)}\big)\,m_{Ca}^{(j)}\,(V^{(j)} {-} V_{Ca}) \, dt $'
        '{ }{ }{ } { }{ }{ } { }{ }{ } { }{ }{ } $ - \, \big(g_{Na}\,m_{Na}^{(j)} + (1{-}C)\,a_{ee}\,Q_V^{(j)} + C\,a_{ee}\, \langle Q_V \rangle^{(j)} \big)\,(V^{(j)} {-} V_{Na}) \, dt $'
        '{ }{ }{ } { }{ }{ } { }{ }{ } { }{ }{ }  $ - \, g_K\,W^{(j)}\,(V^{(j)} {-} V_K) \, dt$'
        '{ }{ }{ } { }{ }{ } { }{ }{ } { }{ }{ }  $ - \, g_L\,(V^{(j)} {-} V_L) \, dt$'
        '{ }{ }{ } { }{ }{ } { }{ }{ } { }{ }{ }  $ - \, a_{ie}\,Z^{(j)}\,Q_Z^{(j)} \, dt$'
        '{ }{ }{ } { }{ }{ } { }{ }{ } { }{ }{ }  $ + \, a_{ne}\,I \, dt $'
        '{ }{ }{ } { }{ }{ } { }{ }{ } { }{ }{ } $ + \, a_{ne}\, \Big(\alpha + \beta\,V^{(j)} \Big) \, d\xi^{(j)},$'
        ''
        '{ }{ }{ } $dW^{(j)} = \frac{\phi}{\tau}\,(m_K^{(j)} {-} W^{(j)}) \, dt ,$'
        ''
        '{ }{ }{ } $dZ^{(j)} = b\,(a_{ni}\,I + a_{ei}\,V^{(j)}\,Q_V^{(j)}) \, dt ,$'
        'where'
        '{ }{ }{ } $V^{(j)}~$ is the average membrane potential of excitatory cells in the $j^{th}\;$ neural ensemble,'
        '{ }{ }{ } $W^{(j)}~$ is the proportion of open Potassium channels in the $j^{th}\;$ neural ensemble,'
        '{ }{ }{ } $Z^{(j)}~$ is the average membrane potential of inhibitory cells in the $j^{th}\;$ neural ensemble,'
        '{ }{ }{ } $d\xi^{(j)}$ is a Wiener noise process associated with the $j^{th}\;$ neural ensemble,'
        '{ }{ }{ } $m_{ion}^{(j)} = \frac{1}{2} \big(1 + \tanh((V^{(j)}{-}V_{ion})/\delta_{ion})\big)~$ is the proportion of open ion channels for a given $V$,'
        '{ }{ }{ } $Q_{V}^{(j)} = \frac{1}{2} \big(1 + \tanh((V^{(j)}{-}V_{T})/\delta_{V})\big)~$ is the mean firing rate of excitatory cells in the $j^{th}\;$ ensemble,'
        '{ }{ }{ } $Q_{Z}^{(j)} = \frac{1}{2} \big(1 + \tanh((Z^{(j)}{-}Z_{T})/\delta_{Z})\big)~$ is the mean firing rate of inhibitory cells in the $j^{th}\;$ ensemble,'
        '{ }{ }{ } $\langle Q \rangle^{(j)} = \sum_i Q_V^{(i)} K_{ij} / k^{(j)}~$ is the connectivity-weighted input to the $j^{th}\;$ ensemble,'
        '{ }{ }{ } $K_{ij}~$ is the network connection weight from ensemble $i\;$ to ensemble $j\;$ (diagonals should be zero),'
        '{ }{ }{ } $k^{(j)} = \sum_i K_{ij}~$ is the sum of incoming connection weights to ensemble $j$,'
        '{ }{ }{ } $a_{ee},a_{ei},a_{ie},a_{ne},a_{ni}~$ are the connection weights ($a_{ei}\;$ denotes excitatory-to-inhibitory),'
        '{ }{ }{ } b is the time constant of inhibition, '
        '{ }{ }{ } r is the number of NMDA receptors relative to the number of AMPA receptors,'
        '{ }{ }{ } phi $=\frac{\phi}{\tau}~$ is the temperature scaling factor,'
        '{ }{ }{ } $g_{Ca},g_{K},g_{Na},g_L~$ are the ion conducances,'
        '{ }{ }{ } $V_{Ca},V_{K},V_{Na},V_L~$ are the Nernst potentials,'
        '{ }{ }{ } $V_T,Z_T,T_{Ca},T_K,T_{Na}~$ are the gain thresholds,'
        '{ }{ }{ } $\delta_V,\delta_Z,\delta_{Ca},\delta_K,\delta_{Na}~$ are the gain slopes,'
        '{ }{ }{ } $I~$ is the strength of the subcortical input.'
        '{ }{ }{ } $\alpha\;$ and $\beta\;$ are the volatility of the additive and multiplicative noise terms, respectively.'
        };
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];
 
    % Include the Phase Portrait panel in the GUI
    sys.panels.bdPhasePortrait = [];

    % Include the Space-Time panel in the GUI
    sys.panels.bdSpaceTime = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = []; 
end

% The deterministic part of the model
%   dY = sdeF(t,Y,Kij,a,b,r,phi,gion,Vion,thrsh,delta,I,alpha,beta) 
% is from Breakspear, Terry & Friston (2003) Network: Comp Neural Syst (14).
function dY = sdeF(~,Y,Kij,aee,aei,aie,ane,ani,b,C,r,phi,gCa,gK,gNa,gL,VCa,VK,VNa,VL,VT,ZT,TCa,TK,TNa,deltaV,deltaZ,deltaCa,deltaK,deltaNa,I,~,~)  
    % Extract incoming values from Y
    Y = reshape(Y,[],3);        % reshape Y to 3 columns
    V = Y(:,1);                 % 1st column of Y contains vector V
    W = Y(:,2);                 % 2nd column of Y contains vector W    
    Z = Y(:,3);                 % 3rd column of Y contains vector Z
    
    % firing-rate functions
    Qv = gain(V, VT, deltaV);       % (nx1) vector
    Qz = gain(Z, ZT, deltaZ);       % (nx1) vector

    % fraction of open channels
    mCa = gain(V, TCa, deltaCa);    % (nx1) vector
    mK  = gain(V, TK,  deltaK );    % (nx1) vector
    mNa = gain(V, TNa, deltaNa);    % (nx1) vector
    
    % Compute Mean firing rates
    k = sum(Kij,2);                 % (nx1) vector
    QvMean = (Kij*Qv)./k;           % (nx1) vector
    QvMean(isnan(QvMean)) = 0;    

    % excitatory cell dynamics
    dV = -(gCa + (1-C).*r.*aee.*Qv + C.*r.*aee.*QvMean).*mCa.*(V-VCa) ...
         - gK.*W.*(V-VK) ...
         - gL.*(V-VL) ... 
         - (gNa.*mNa + (1-C).*aee.*Qv + C.*aee.*QvMean).*(V-VNa) ...
         + ane.*I ...
         - aie.*Qz.*Z;
     
    % K cell dynamics
    dW = phi.*(mK-W);
    
    % inhibitory cell dynamics
    dZ = b.*(ani.*I + aei.*Qv.*V);

    % return a column vector
    dY = [dV; dW; dZ]; 
end

% The stochastic part of the model
%   G = sdeG(t,Y,Kij,a,b,r,phi,gion,Vion,thrsh,delta,I,alpha,beta) 
% returns the (Nxm) noise coefficients where N=3n is the number of state
% variables and m=n is the number of noise sources. In this case
% noise is only applied to the first state variable (which is V).
function G = sdeG(~,Y,~,~,~,~,ane,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~,alpha,beta)
    % Extract incoming values from Y
    Y = reshape(Y,[],3);        % reshape Y to 3 columns
    V = Y(:,1);                 % 1st column of Y contains vector V
    n = numel(V);               % number of network nodes (neural masses)

    % Construct the noise coefficient matrix (3n x n).
    % Each network node has an independent noise source. There are no
    % common noise sources. Hence all non-diagonal entries of the matrix
    % are zero. Furthermore, noise is only applied to the V variables.
    % Hence only the first n entries of the diagonal are non-zero.
    U = diag(ane*(alpha + beta.*V));    % (nxn) diagonal matrix of noise coefficients
    Z = zeros(n);                       % (nxn) matrix of zeros
    G = [U;Z;Z];                        % (3n x n) matrix of noise cooefficents
end

% Non-linear gain function
function f = gain(VAR,C1,C2)
    f = 0.5*(1+tanh((VAR-C1)./C2));
end
