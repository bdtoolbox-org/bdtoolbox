# Release Notes
# Brain Dynamics Toolbox

## Version 2023a
Released 12 Nov 2023

The dde23a solver was removed. It is superseded by the improved dde23 solver that ships with Matlab R2023b. The BTF2003DDE and WilleBakerEx3 models were updated accordingly. The Hilbert panel (bdHilbert) was modified to automatically zero-mean the time series before applying the transform.

Requires Matlab R2020a or newer. Matlab R2023b is recommended for solving DDEs.

## Version 2022b
Released 12 Sep 2022

New example model (HopfRC) demonstrating the normal form of the Hopf bifurcation in polar coordinates. Fixed a bug in bGUI when multiple panels directories were found in the matlab PATH. 

Requires Matlab R2020a or newer.


## Version 2022a
Released 17 April 2022

Added new display panels for computing the Jacobian and its eigenvalues. Added support for matlab's new ode78 and ode89 solvers. Improved the rendering of vector fields in the 2D phase portrait. Added the Lotka-Volterra model. Added examples from chapters 5 and 6 of Strogatz's (1994) textbook on nonlinear dynamics and chaos.

Requires Matlab R2020a or newer.


## Version 2021a
Released 7 June 2021

Value spinners were included in the control panel and the slider behaviour was altered so that values are only applied when the slider is released. This fixes a fatal race condition in Matlab R2020b and R2021a. The loading of the graphical interface was improved by providing more visual feedback during startup. Similarly, the mouse pointer now switches to a 'busy' icon during long computations. The Undo/Redo stack was removed for simplicity. Error messages are now shown in the solver toolbar. The Brownian Motion model (SDE) was replaced by separate examples of Arithmetic and Geometric Brownian Motion.

Requires Matlab R2020a or newer.


## Version 2020b
Released 31 Jan 2021

Minor bug fixes and improvements. No new features.

Requires Matlab 2019b or newer.

## Version 2020a
Released 26 Dec 2020

This release is a complete rewrite of the graphical interface for the new matlab (R2019b and above) uitools interface which allows for much richer instrumentation than before. Other new features include the ability to integrate backwards in time, an 'undo/redo' menu, and the ability to undock display panels from the main window. All of the display panels have been rewritten from scratch and some (Phase Portrait, Bifurcation panel) have been split into 2D and 3D variants. Other new panels include the Time Cylinder and the System Log. The Trap panel and the BOLD HRF panel have been deprecated.

Sadly the matlab uitools interface does not export traditional matlab .fig files, so that feature is no longer available in bdGUI. Annoyingly, the uitools interface does not support data cursors on images either. Hence the Space2D and Correlation display panels in bdGUI have lost their data cursors. Hopefuly matlab will restore datacursors for images in future. The LaTeX interpreter also operates slightly differently under uitools. LaTeX formatting commands, such as \textbf, must now be enclosed in mathmode delimiters ($...$).

Requires Matlab 2019b or newer.

## Version 2019a
Released 6 Aug 2019

This release includes new example scripts for the Morris-Lecar neuron and Tsodyk's (1999) inhibition-stabilised neuron. As well as examples of Partial Differential Equations such as the scalar wave equations and the Fisher-Kolmogorov equations. The damped-and-driven pendulum is included too. The Breakspear-Terry-Friston (2003) model has been revamped. New command-line tools (bdSetPar, bdSetVar, bdSetLag, bdGetPar, bdGetVar, bdGetLag) make it easier to manipulate models in user-defined scripts. The nullclines in the Phase-Portrait have been made smoother. Trajectory end-points in most panels are now marked with a dark filled circle. The correlation panel has an improved colormap.

Requires Matlab 2015a or newer.

## Version 2018b
Released 21 Oct 2018

This release includes new example scripts for the Hodgkin-Huxley model of the action potential, the Wilson-Cowan model of excitatory-inhibitory dynamics, the Epileptor model of seizure dynamics and the Haemodynamic model of the BOLD response. It also inlcudes new display panels for plotting state variables that have two spatial dimensions (bdSpace2D) and for computing the BOLD response for any state variable (bdBoldHRF). The Auxiliary panel (bdAuxiliary) panel has been improved to allow user-data to be accessible to the workspace. New functions bdSetValues and bdEvolve have been added to the command-line tools. The bdLoadMatrix function has been removed. The HALT, EVOLVE and PERTRUB graphical buttons can now be controlled from the workspace interface. Their initial states can also be specified in the system structure. A RUN button has been added to the graphical interface. It replaces the RAND button when the EVOLVE mode is active. A matrix transpose bug in the BTF2003/SDE/DDE models was fixed. A drawing bug in the phase-portrait 3D View menu was fixed. Chapters 5 and 6 of the Handbook were revised substantially.

Requires Matlab 2014b or newer.

## Version 2018a
Released 20 Mar 2018.

This release is a major overhaul of the graphical user interface and the design of the display panel classes. Notable additions are slider controls and the capability to evolve the initial conditions to follow a solution in paramater space. Bifurcation plots and Auxiliary panels have also been added. The auxiliary panel replaces the old auxiliary variables.

Requires Matlab 2014b or newer.

## Version 2017c
Released 16 Nov 2017.

This release coincides with the first edition of the Handbook of the Brain Dynamics Toolbox.
New features of the toolbox include:
(i) Improved dialog boxes for editing vector and matrix parameters.
(ii) The ability to load previously computed solutions into the GUI at startup.
(iii) Improved error handling for systems with missing functions.
(iv) The inclusion of the Liley neural-mass model (DFCL2009) from Dafilis, Frascoli Cadusch & Liley (2009).
(v)  Improved license checking in the Hilbert and Correlation panels.
(vi) Improved scrolling in the System-Save dialog box.
(vii) Replacement of the BTF2003ODE model (Breakspear, Terry & Friston, 2003) with BTF2003.
(viii) Bug fixes to the existing BTF2003SDE and BTF2003DDE models.
(iix) Renaming of the MultiplicativeNoise model to KloedenPlaten446.

Requires Matlab 2014b or newer.

## Version 2017b
Released 21 June 2017. 

Major new features include:
(i) Equation parameters and variables can now be directly manipulated from the workspace via the new bdGUI class properties (par, var0, var, lag, t).
(ii) The System-Save menu now includes solution variables and display panel outputs.
(iii) Three new display panels were added (bdHilbert, bdSurrogate, bdTrapPanel).
(iv) Six new models were added (BTF2003ODE, BTF2003DDE, BTF2003SDE, FRRB2012, FRRB2012b, RFB2017).
(v) Scrollbars were added to the Equations panel. (vi) All panels were refined to make their outputs more accessible to the workspace.

Requires Matlab 2014b or newer.

## Version 2017a
Released 21 March 2017.

Major new features include:
(i) Dynamic loading of GUI plot panels.
(ii) Enhanced GUI class properties allow the solver output and panel objects to be accessed directly. 
(iii) New *sys* struct fromat with more flexible syntax for defining system parameters and variables.
(iv) Improved validation of *sys* structs.
(v) Time and Phase portraits now support graphic hold.
(vi) All example models have been revised.
 
**This version is not backwards compatible with version 2016a.** In particular: 
(i) *sys.pardef, sys.vardef, sys.auxdef, sys.lagdef* were changed from cell arrays to struct arrays; 
(ii) *sys.gui* was renamed *sys.panels*;
(iii) SDE function handles were renamed *sys.sdeF* and *sys.sdeG*;
(iv) *bdCorrelationPanel* was renamed *bdCorrPanel*;
(v) *bdSpaceTimePortrait* was renamed *bdSpaceTime*;
(vi) *odeEuler* was renamed *odeEul*;
(vii) *sdeIto* was renamed *sdeEM*;
(viii) *sdeStratonovich* was renamed *sdeSH*;
(ix) *bdVerify* was renamed *bdSysCheck*;
(x) *bdUtils* was renamed *bd*;
(xi) The *gui.control* property was replaced by *gui.sys, gui.sol* and *gui.sox*;
(xii) The *sys* fields *tspan*, *odesolver*, *odeoption*, *ddesolver* and *ddeoption* are no longer mandatory.

**Important message to users migrating from 2016a to 2017a.** Scripts written for 2016a will need to be modified to accommodate the changes above. We recommend using *bdSysCheck* when migrating old code. It detects obsolete and invalid *sys* fields. 

Requires Matlab 2014b or newer.


## Version 2016a
Released 24 Dec 2016.

The first public release of the Brain Dynamics Toolbox.

Requires Matlab 2014b or newer.