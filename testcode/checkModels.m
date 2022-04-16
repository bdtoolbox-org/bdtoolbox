% This script runs bdSysCheck on selected models

if ~exist('bdSysCheck.m', 'file')
    error('bdtoolbox is not in the matlab path');
end

if ~exist('LinearODE.m', 'file')
    error('bdtoolbox/models is not in the matlab path');
end

%if ~exist('sdeEM.m', 'file')
%    error('bdtoolkit/solvers is not in the matlab path');
%end

%%
disp 'TESTING BOLDHRF';
sys = BOLDHRF();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING BrownianMotionArithmetic';
n = 100;
sys = BrownianMotionArithmetic(n);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING BrownianMotionGeometric';
n = 100;
sys = BrownianMotionGeometric(n);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING BTF2003';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = BTF2003(Kij);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING BTF2003DDE';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = BTF2003DDE(Kij);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING BTF2003SDE';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = BTF2003SDE(Kij);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING DFCL2009';
sys = DFCL2009();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING EI0D';
sys = EI0D();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING EIE0D';
sys = EIE0D();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING EI1D';
sys = EI1D(200);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING EIE1D';
sys = EIE1D(200);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Epileptor2014ODE';
sys = Epileptor2014ODE();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Epileptor2014SDE';
sys = Epileptor2014SDE();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING FisherKolmogorov1D (periodic)';
sys = FisherKolmogorov1D(200,'periodic');
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING FisherKolmogorov1D (reflecting)';
sys = FisherKolmogorov1D(200,'reflecting');
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING FisherKolmogorov1D (free)';
sys = FisherKolmogorov1D(200,'free');
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING FitzhughNagumo';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = FitzhughNagumo(rand(n));
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING FRRB2012';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = FRRB2012(n);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING FRRB2012b';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = FRRB2012b(Kij);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING HindmarshRose';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = HindmarshRose(rand(n));
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING HodgkinHuxley';
sys = HodgkinHuxley();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING HopfieldNet';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = HopfieldNet(n);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING HopfXY';
sys = HopfXY();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING KloedenPlaten446';
sys = KloedenPlaten446();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING KuramotoNet';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = KuramotoNet(Kij);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING KuramotoSakaguchi';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
Aij = rand(n);
sys = KuramotoSakaguchi(Kij,Aij);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING LinearODE';
sys = LinearODE();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Lorenz';
sys = Lorenz();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING LotkaVolterra';
sys = LotkaVolterra();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING MorrisLecar';
sys = MorrisLecar('Hopf');
bdSysCheck(sys,'run','on');
sys = MorrisLecar('SNLC');
bdSysCheck(sys,'run','on');
sys = MorrisLecar('Homoclinic');
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING MorrisLecar1D';
sys = MorrisLecar1D(100);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING OrnsteinUhlenbeck';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = OrnsteinUhlenbeck(n);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Othmer1997';
sys = Othmer1997();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Pendulum';
sys = Pendulum();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Pospischil2008('RS')';
sys = Pospischil2008('RS');
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Pospischil2008('FS')';
sys = Pospischil2008('FS');
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Pospischil2008('IB')';
sys = Pospischil2008('IB');
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING RFB2017';
sys = RFB2017();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_5_1_1';
sys = Strogatz_5_1_1();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_5_1_2';
sys = Strogatz_5_1_2();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_5_2_1';
sys = Strogatz_5_2_1();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_5_2_5';
sys = Strogatz_5_2_5();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_5_2_6';
sys = Strogatz_5_2_6();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_5_3_1';
sys = Strogatz_5_3_1();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_1_1';
sys = Strogatz_6_1_1();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_3_1';
sys = Strogatz_6_3_1();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_3_2a';
sys = Strogatz_6_3_2a();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_3_2b';
sys = Strogatz_6_3_2b();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_4';
sys = Strogatz_6_4();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_5_2';
sys = Strogatz_6_5_2();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_6_1';
sys = Strogatz_6_6_1();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_6_2';
sys = Strogatz_6_6_2();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_6_3';
sys = Strogatz_6_6_3();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_7';
sys = Strogatz_6_7();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Strogatz_6_8_3';
sys = Strogatz_6_8_3();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING SwiftHohenberg1D';
n = 300;
disp(num2str(n,'n=%d'));
dx = 0.25;
disp(num2str(dx,'dx=%f'));
sys = SwiftHohenberg1D(n,dx);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING Tsodyks1997';
sys = Tsodyks1997();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING VanDerPolOscillators';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = VanDerPolOscillators(rand(n));
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING WaveEquation1D';
n = 100;
sys = WaveEquation1D(n,'periodic');
bdSysCheck(sys,'run','on');
sys = WaveEquation1D(n,'reflecting');
bdSysCheck(sys,'run','on');
sys = WaveEquation1D(n,'free');
bdSysCheck(sys,'run','on');
sys = WaveEquation1D(n,'absorbing');
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING WaveEquation2D';
n = 100;
sys = WaveEquation2D(n,'periodic');
bdSysCheck(sys,'run','on');
sys = WaveEquation2D(n,'reflecting');
bdSysCheck(sys,'run','on');
sys = WaveEquation2D(n,'free');
bdSysCheck(sys,'run','on');
sys = WaveEquation2D(n,'absorbing');
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING WilleBakerEx3';
sys = WilleBakerEx3();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING WilsonCowan';
sys = WilsonCowan();
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING WilsonCowanNet';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n,n);
Je = rand(n,1);
Ji = rand(n,1);
sys = WilsonCowanNet(Kij,Je,Ji);
bdSysCheck(sys,'run','on');
disp '===';

%%
disp 'TESTING WilsonCowanRing';
n = 100;                           % number of spatial steps
dx = 0.5;                          % length of each spatial step (mm)
  
% Gaussian coupling kernels
gauss1d = @(x,sigma) exp(-x.^2/sigma^2)./(sigma*sqrt(pi));
sigmaE = 2;                        % spread of excitatory gaussian
sigmaI = 4;                        % spread of inhibitory gaussian
kernelx = -10:dx:10;               % spatial domain of kernel (mm)
Ke = gauss1d(kernelx,sigmaE)*dx;   % excitatory coupling kernel
Ki = gauss1d(kernelx,sigmaI)*dx;   % inhibitory coupling kernel
 
% Injection currents
Je = 0.7;
Ji = 0;
 
% Construct the model and check the system structure
sys = WilsonCowanRing(n,Ke,Ki,Je,Ji);
bdSysCheck(sys,'run','on');
disp '===';
