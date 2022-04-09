classdef bdRedrawEvent <event.EventData
    %bdRedrawEvent  Event data for bdSystem REDRAW events.
    % 
    %AUTHORS
    %  Stewart Heitmann (2020a)

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
    
    properties
        pardef      struct
        lagdef      struct
        vardef      struct
        tspan       logical
        tstep       logical
        tval        logical
        noisehold   logical
        evolve      logical
        perturb     logical
        backward    logical
        halt        logical
        solveritem  logical
        odeoption   logical
        ddeoption   logical
        sdeoption   logical
        sol         logical
        panels      logical
    end
   
    methods
        function this = bdRedrawEvent(val,npardef,nlagdef,nvardef)
            % pardef array of structs
            this.pardef = struct('value',{},'lim',{});
            for idx=1:npardef
                this.pardef(idx,1) = struct('value',val,'lim',val);
            end
            
            % lagdef array of structs
            this.lagdef = struct('value',{},'lim',{});
            for idx=1:nlagdef
                this.lagdef(idx,1) = struct('value',val,'lim',val);
            end
            
            % vardef array of structs
            this.vardef = struct('value',{},'lim',{});
            for idx=1:nvardef
                this.vardef(idx,1) = struct('value',val,'lim',val);
            end
            
            % other fields
            this.tspan        = val;
            this.tstep        = val;
            this.tval         = val;
            this.noisehold    = val;
            this.evolve       = val;
            this.perturb      = val;
            this.backward     = val;
            this.halt         = val;
            this.solveritem   = val;
            this.odeoption    = val;
            this.ddeoption    = val;
            this.sdeoption    = val;       
            this.sol          = val;
            this.panels       = val;
        end
    end
end

