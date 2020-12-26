classdef bdUndoStack < handle
    %bdUndoStack  Undo Stack for bdGUI.
    %  This class is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2020a)

    % Copyright (C) 2020 Stewart Heitmann <heitmann@bdtoolbox.org>
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
    
    properties (Access=private)
        sys         % circular array of sys structs
        npop        % number of pops available
        upop        % number of unpops available
    end
    
    methods
        function stackobj = bdUndoStack()
            stackobj.sys = cell(10,1);
            stackobj.npop = 0;
            stackobj.upop = 0;
        end
        
        % Push the system structure (sys) onto the stack
        function Push(stackobj,sys)
            %disp('bdUndoStack.Push(sys)');
            
            % Avoid stacking unnecessary duplicates
            if isequal(sys,stackobj.sys{1})
                %disp('Ignoring duplicate');
                return
            end
            
            % Right-shift the existing stack
            stackobj.sys = circshift(stackobj.sys,1);
            
            % Store the incoming sys in the first entry of the stack
            stackobj.sys{1} = sys;
            
            % Increment the pop capacity counter
            if stackobj.npop < numel(stackobj.sys)
                stackobj.npop = stackobj.npop + 1;
            end
            
            % Pushing eradicates the ability to reverse the last Pop
            stackobj.upop = 0;
        end
        
        % Pop the newest system structure (sys) off the stack
        function sys = Pop(stackobj)
            %disp('bdUndoStack.Pop()');
            
            if stackobj.npop==0
                sys = [];
                return
            else
                % Left-shift the stack entries
                stackobj.sys = circshift(stackobj.sys,-1);

                % return the first entry in the stack
                sys = stackobj.sys{1};             
                
                % Decrement the pop capacity counter
                stackobj.npop = stackobj.npop - 1;
                
                % Increment the unpop capacity counter
                if stackobj.upop < numel(stackobj.sys)
                    stackobj.upop = stackobj.upop + 1;
                end
            end
        end
        
        % Reverse the last Pop action
        function sys = UnPop(stackobj)
            %disp('bdUndoStack.UnPop()');

            if stackobj.upop==0
                % There are no more Pops to reverse.
                sys = [];
            else
                % Right-shift the existing stack
                stackobj.sys = circshift(stackobj.sys,1);
                
                % return the first entry in the stack
                sys = stackobj.sys{1};
                
                % Increment the pop capacity counter
                if stackobj.npop < numel(stackobj.sys)
                    stackobj.npop = stackobj.npop + 1;
                end
                
                % Decrement the unpop capacity counter
                stackobj.upop = stackobj.upop - 1;
            end
        end
        
        function flag = UndoStatus(stackobj)
            flag = (stackobj.npop > 1);
        end
        
        function flag = RedoStatus(stackobj)
            flag = (stackobj.upop > 0);
        end
        
    end
end

