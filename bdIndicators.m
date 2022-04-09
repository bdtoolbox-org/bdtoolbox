classdef bdIndicators < handle
    %bdIndicators  Control panel widget for bdGUI.
    %  This class is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2020a,2021a)

    % Copyright (C) 2020-2022 Stewart Heitmann <heitmann@bdtoolbox.org>
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
    
    events
        refresh
    end

    properties
        tspan
        busy = false;
        solvertic = 0;
        solvertoc = 0;
        interptic = 0;
        interptoc = 0;
        graphicstic = 0;
        graphicstoc = 0;
        nevolve = 0;
        progress = 0;
        errorid = [];
        errormsg = [];
    end
    
    methods
        function SolverInit(obj,tspan)
            %disp('bdIndicators.SolverInit');
            obj.tspan = tspan;
            obj.solvertic = tic();
            obj.busy = true;
            notify(obj,'refresh');
        end
        
        function SolverUpdate(obj,t)
            %disp('bdIndicators.SolverUpdate');
            obj.progress = 100.0*(t - obj.tspan(1))/(obj.tspan(2) - obj.tspan(1));
            obj.solvertoc = toc(obj.solvertic);
            notify(obj,'refresh');
        end
        
        function SolverDone(obj)
            %disp('bdIndicators.SolverDone');
            obj.progress = 100.0;
            obj.solvertoc = toc(obj.solvertic);
            notify(obj,'refresh');
        end

        function SolverHalt(obj)
            %disp('bdIndicators.SolverHalt');
            obj.solvertoc = toc(obj.solvertic);
            notify(obj,'refresh');
        end

        function InterpolatorInit(obj)
            %disp('bdIndicators.InterpInit');
            obj.interptic = tic();
            notify(obj,'refresh');            
        end
        
        function InterpolatorDone(obj)
            %disp('bdIndicators.InterpDone');
            obj.interptoc = toc(obj.interptic);
            notify(obj,'refresh');
        end
        
        function GraphicsInit(obj)
            %disp('bdIndicators.GraphicsInit');
            obj.graphicstic = tic;
            %obj.graphicstoc = 0;
            notify(obj,'refresh');
        end
        
        function GraphicsUpdate(obj)
            %disp('bdIndicators.GraphicsUpdate');
            obj.graphicstoc = toc(obj.graphicstic);
            notify(obj,'refresh');
        end
        
        function GraphicsDone(obj)
            %disp('bdIndicators.GraphicsDone');
            obj.graphicstoc = toc(obj.graphicstic);
            obj.busy = false;
            notify(obj,'refresh');
        end
        
        function ErrorUpdate(obj,errorid,errormsg)
            obj.errorid = errorid;
            obj.errormsg = errormsg;
            notify(obj,'refresh');
        end
        
        function Reset(obj)
            obj.busy = false;
            obj.solvertic = 0;
            obj.solvertic = 0;
            obj.solvertoc = 0;
            obj.interptic = 0;
            obj.interptoc = 0;
            obj.graphicstic = 0;
            obj.graphicstoc = 0;
            obj.nevolve = 0;
            obj.progress = 0;
            obj.errorid = [];
            obj.errormsg = [];
        end
                
    end
end

