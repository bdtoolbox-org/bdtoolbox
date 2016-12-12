classdef bdControl < handle
    % bdControl  Control panel for the Brain Dynamics Toolbox.
    %   This class is part of the toolbox graphic user interface.
    %   It is not intended to be called directly by users.
    
    % Copyright (c) 2016, Stewart Heitmann <heitmann@ego.id.au>
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
        sys         % user-supplied system definition
        sol = []    % solution struct returned by the matlab solver
        solx = []   % auxiliary variables (computed by sys.auxfun)
        solvermap   % maps the solver functions to name and type strings
        solveridx   % index of the active solver
    end
    
    properties (Access=private)
        fig         % handle of parent figure
        hlt         % handle to HALT button
        cpustart    % cpu start time
        cpu         % handle to cpu clock
        pro         % handle to progress counter
    end
    
    events
        recompute   % signals that sol must be recomputed
        redraw      % signals that sol must be replotted
    end
    
    methods
        function this = bdControl(panel,sys)
            % working copy of the system struct
            this.sys = sys;
            
            % contrsuct the solver map
            this.solvermap = bdUtils.solverMap(sys); 
            
            % currently active solver
            this.solveridx = 1;            
            
            % remember the parent figure
            this.fig = ancestor(panel,'figure');
            
            % get parent geometry
            panelw = panel.Position(3);
            panelh = panel.Position(4);

            % Begin placing widgets at the top left of parent.
            % We use the UserData field of each widget to remember its
            % preferred vertical position. It makes resizing easier.
            yoffset = 0;
            posw = panelw - 10;
            boxw = 50;
            boxh = 20;
            rowh = 22;            
                                 
            % next row
            yoffset = yoffset + rowh;                                    
            
            % parameter title
            uicontrol('Style','text', ...
                'String','Parameters', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Position',[0 panelh-yoffset posw boxh]);
            
            % ODE parameter widgets
            for parindx=1:size(sys.pardef,1)
                parstr = sys.pardef{parindx,1};    % parameter name (string)
                parval = sys.pardef{parindx,2};    % parameter value (vector)
       
                % switch depending on parval being a scalar, vector or matrix
                switch ScalarVectorMatrix(parval)
                    case 1  % parval is a scalar              
                        % next row
                        yoffset = yoffset + rowh;
            
                        % construct edit box for the scalar
                        uicontrol('Style','edit', ...
                            'String',num2str(parval,'%0.4g'), ...
                            'Value',parval, ...
                            'HorizontalAlignment','right', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Callback', @(hObj,~) this.ScalarParameter(hObj,parindx), ...
                            'Position',[0 panelh-yoffset boxw boxh]);
                        
                        % string label
                        uicontrol('Style','text', ...
                            'String',parstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);
                        
                    case 2  % parval is a vector
                        % next row
                        yoffset = yoffset + rowh;

                        % construct bar graph widget for the vector
                        ax = axes('parent', panel, ...
                            'Units','pixels', ...
                            'Position',[0 panelh-yoffset boxw boxh]);
                        bar(ax,parval, ...
                            'ButtonDownFcn', @(hObj,~) this.VectorParameter(hObj,parstr,parindx) );
                        xlim([0.5 numel(parval)+0.5]);
                        set(ax,'Tag','bdControlWidget', 'UserData',yoffset);
                        axis 'off';
                        
                        % string label
                        uicontrol('Style','text', ...
                            'String',parstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);

                    case 3  % parval is a matrix
                        % next row
                        yoffset = yoffset + boxw + 2;

                        % construct image widget for the matrix
                        ax = axes('parent', panel, ...
                            'Units','pixels', ...
                            'Position',[0 panelh-yoffset boxw boxw]);
                        imagesc(parval(:,:,1), 'Parent',ax, ...
                            'ButtonDownFcn', @(hObj,~) this.MatrixParameter(hObj,parstr,parindx) );
                        axis off;
                        set(ax,'Tag','bdControlWidget', 'UserData',yoffset); 

                        % string label
                        uicontrol('Style','text', ...
                            'String',parstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset-15, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-(yoffset-15) posw-boxw-10 boxh]);
                end
            end
           
            % DDE lag widgets (if applicable)
            if isfield(sys,'lagdef')
                % next row
                yoffset = yoffset + 1.5*rowh;                                    

                % lag title
                uicontrol('Style','text', ...
                    'String','Time Lags', ...
                    'HorizontalAlignment','left', ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'FontWeight','bold', ...
                    'Parent', panel, ...
                    'UserData', yoffset, ...
                    'Tag', 'bdControlWidget', ...
                    'Position',[0 panelh-yoffset posw boxh]);

                % for each lagdef entry
                for lagindx=1:size(sys.lagdef,1)
                    lagstr = sys.lagdef{lagindx,1};    % lag name (string)
                    lagval = sys.lagdef{lagindx,2};    % lag value (vector)

                    % switch depending on lagval being a scalar, vector or matrix
                    switch ScalarVectorMatrix(lagval)
                        case 1  % lagval is a scalar              
                            % next row
                            yoffset = yoffset + rowh;

                            % construct edit box for the scalar
                            uicontrol('Style','edit', ...
                                'String',num2str(lagval,'%0.4g'), ...
                                'Value',lagval, ...
                                'HorizontalAlignment','right', ...
                                'FontUnits','pixels', ...
                                'FontSize',12, ...
                                'Parent', panel, ...
                                'UserData', yoffset, ...
                                'Tag', 'bdControlWidget', ...
                                'Callback', @(hObj,~) this.ScalarLag(hObj,lagindx), ...
                                'Position',[0 panelh-yoffset boxw boxh]);

                            % string label
                            uicontrol('Style','text', ...
                                'String',lagstr, ...
                                'HorizontalAlignment','left', ...
                                'FontUnits','pixels', ...
                                'FontSize',12, ...
                                'Parent', panel, ...
                                'UserData', yoffset, ...
                                'Tag', 'bdControlWidget', ...
                                'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);

                        case 2  % lagval is a vector
                            % next row
                            yoffset = yoffset + rowh;

                            % construct bar graph widget for the vector
                            ax = axes('parent', panel, ...
                                'Units','pixels', ...
                                'Position',[0 panelh-yoffset boxw boxh]);
                            bar(ax,lagval, ...
                                'ButtonDownFcn', @(hObj,~) this.VectorLag(hObj,lagstr,lagindx) );
                            xlim([0.5 numel(lagval)+0.5]);
                            set(ax,'Tag','bdControlWidget', 'UserData',yoffset);
                            axis 'off';

                            % string label
                            uicontrol('Style','text', ...
                                'String',lagstr, ...
                                'HorizontalAlignment','left', ...
                                'FontUnits','pixels', ...
                                'FontSize',12, ...
                                'Parent', panel, ...
                                'UserData', yoffset, ...
                                'Tag', 'bdControlWidget', ...
                                'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);

                        case 3  % parval is a matrix
                            % next row
                            yoffset = yoffset + boxw + 2;

                            % construct image widget for the matrix
                            ax = axes('parent', panel, ...
                                'Units','pixels', ...
                                'Position',[0 panelh-yoffset boxw boxw]);
                            imagesc(lagval, 'Parent',ax, ...
                                'ButtonDownFcn', @(hObj,~) this.MatrixLag(hObj,lagstr,lagindx) );
                            axis off;
                            set(ax,'Tag','bdControlWidget', 'UserData',yoffset); 

                            % string label
                            uicontrol('Style','text', ...
                                'String',lagstr, ...
                                'HorizontalAlignment','left', ...
                                'FontUnits','pixels', ...
                                'FontSize',12, ...
                                'Parent', panel, ...
                                'UserData', yoffset-15, ...
                                'Tag', 'bdControlWidget', ...
                                'Position',[boxw+5 panelh-(yoffset-15) posw-boxw-10 boxh]);
                    end
                end                
            end            
            
            % next row
            yoffset = yoffset + 1.5*rowh;

            % variable title
            uicontrol('Style','text',...
                'String','Initial Conditions', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Position',[0 panelh-yoffset posw boxh]);
            
            % ODE variable widgets (initial conditions)
            for varindx=1:size(sys.vardef,1)
                varstr = sys.vardef{varindx,1};    % variable name (string)
                varval = sys.vardef{varindx,2};    % variable initial value (vector)

                % switch depending on varval being a scalar, vector or matrix
                switch ScalarVectorMatrix(varval)
                    case 1  % varval is a scalar              
                        % next row
                        yoffset = yoffset + rowh;
                
                        % construct edit box for the scalar
                        uicontrol('Style','edit', ...
                            'String',num2str(varval,'%0.4g'), ...
                            'Value',varval, ...
                            'HorizontalAlignment','right', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Callback', @(hObj,~) this.ScalarVariable(hObj,varindx), ...
                            'Position',[0 panelh-yoffset boxw boxh]);

                        % string label
                        uicontrol('Style','text', ...
                            'String',varstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);
                        
                    case 2  % varval is a vector
                        % next row
                        yoffset = yoffset + rowh;
                        
                        % construct bar graph widget for thr vector
                        ax = axes('parent', panel, ...
                            'Units','pixels', ... 
                            'Position',[0 panelh-yoffset boxw boxh]);
                        bar(ax,varval, ...
                            'ButtonDownFcn', @(hObj,~) this.VectorVariable(hObj,varstr,varindx) );
                        xlim([0.5 numel(varval)+0.5]);
                        set(ax,'Tag','bdControlWidget', 'UserData',yoffset);
                        axis 'off';

                        % string label
                        uicontrol('Style','text', ...
                            'String',varstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);
                        
                    case 3  % varval is a matrix
                        % next row
                        yoffset = yoffset + boxw + 5;
                        
                        % construct image widget for the matrix
                        ax = axes('parent', panel, ...
                            'Units','pixels', ...
                            'Position',[0 panelh-yoffset+2.5 boxw boxw]);
                        imagesc(varval, 'Parent',ax, ...
                            'ButtonDownFcn', @(hObj,~) this.MatrixVariable(hObj,varstr,varindx) );
                        axis off;
                        set(ax,'Tag','bdControlWidget', 'UserData',yoffset);                         
                        
                        % string label
                        uicontrol('Style','text', ...
                            'String',varstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset+17.5, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-yoffset+17.5 posw-boxw-10 boxh]);                        
                end

            end
            
            % next row
            yoffset = yoffset + 1.5*rowh;                        

            % time domain
            uicontrol('Style','text',...
                'String','Time Domain', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Position',[0 panelh-yoffset posw boxh]);
            
            % next row
            yoffset = yoffset + rowh;

            % start time
            uicontrol('Style','edit', ...
                'String',num2str(sys.tspan(1),'%0.4g'), ...
                'Value', sys.tspan(1), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Callback', @(src,~) this.ScalarTspan(src,1), ...
                'Position',[0 panelh-yoffset boxw boxh]);
            
            % end time
            uicontrol('Style','edit', ...
                'String',num2str(sys.tspan(2),'%0.4g'), ...
                'Value', sys.tspan(2), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Callback', @(src,~) this.ScalarTspan(src,2), ...
                'Position',[boxw+5 panelh-yoffset boxw boxh]);
          
            % next row
            yoffset = yoffset + 1.5*rowh;                        

            % Solver Heading
            uicontrol('Style','text', ...
                'String','CPU Time', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Position',[0 panelh-yoffset 2*boxw+5 boxh]);

            % next row
            yoffset = yoffset + boxh - 5;                        

            % CPU time 
            this.cpu = uicontrol('Style','text',...
                'String','CPU 0.0s', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'ToolTipString','CPU time (secs)', ...
                'Position',[0 panelh-yoffset boxw boxh]);

            % Progress counter  
            this.pro = uicontrol('Style','text',...
                'String','0%', ...
                'HorizontalAlignment','right', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
                'ForegroundColor', [0.5 0.5 0.5], ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'ToolTipString','solver progress', ...
                'Position',[boxw+5 panelh-yoffset boxw boxh]);

            % next row
            yoffset = yoffset + 1.5*boxh;                        

            % HALT button
            this.hlt = uicontrol('Style','radio', ...
                'String','HALT', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'ForegroundColor', 'r', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'ToolTipString', 'Halt the solver', ...
                'Callback', @(~,~) this.HaltCallback(), ...
                'Position',[0 panelh-yoffset 2*boxw+5 boxh]);
           
            % register a callback for resizing the panel
            set(panel,'SizeChangedFcn', @(~,~) SizeChanged(this,panel));
            
            % listen for recompute events
            addlistener(this,'recompute',@(~,~) RecomputeListener(this));
        end
               
    end
    
    
    methods (Access=private)  
        % Callback for panel resizing. This function relies on each
        % widget having its desired yoffset stored in its UserData field.
        function SizeChanged(this,panel)
            % get new parent geometry
            panelh = panel.Position(4);
            
            % find all widgets in the control panel
            objs = findobj(panel,'Tag','bdControlWidget');
            
            % for each widget, adjust its y position according to its preferred position
            for indx = 1:numel(objs)
                obj = objs(indx);                       % get the widget handle
                yoffset = obj.UserData;                 % retrieve the preferred y position from UserData.
                obj.Position(2) = panelh - yoffset;     % apply the preferred y position
            end            
        end
        
        % Callback for ODE parameter edit box
        function ScalarParameter(this,editObj,parindx)
            this.ScalarCallback(editObj);
            this.sys.pardef{parindx,2} = editObj.Value;
            notify(this,'recompute');
        end
        
        % Callback for DDE lag edit box
        function ScalarLag(this,editObj,lagindx)
            this.ScalarCallback(editObj);
            this.sys.lagdef{lagindx,2} = editObj.Value;
            notify(this,'recompute');
        end
        
        % Callback for ODE variable edit box
        function ScalarVariable(this,editObj,varindx)
            this.ScalarCallback(editObj);
            this.sys.vardef{varindx,2} = editObj.Value;
            notify(this,'recompute');
        end

        % Callback for ODE time domain edit box
        function ScalarTspan(this,hObj,tindx)
            this.ScalarCallback(hObj);
            this.sys.tspan(tindx) = hObj.Value;
            notify(this,'recompute');            
        end

        % Callback for generic scalar edit box
        function ScalarCallback(this,hObj)
            % ensure hObj is still valid
            if ~isvalid(hObj)
                % The object no longer exists. User must have closed the parent window.
                return
            end
            
            % get the incoming value
            val = str2double(hObj.String);
            if isnan(val)
                dlg = errordlg(['Invalid Number ''', hObj.String, ''''],'Invalid number','modal');
                val = hObj.Value;           % restore the previous value                
                uiwait(dlg);                % wait for dialog box to close
            else
                hObj.Value = val;           % remember the new value
            end            
            
            % update the edit box string
            hObj.String = num2str(val,'%0.4g');
        end
        
        % Callback for ODE parameter vector widget
        function VectorParameter(this,barObj,name,parindx)
            this.VectorCallback(barObj,name);
            this.sys.pardef{parindx,2} = reshape(barObj.YData, size(this.sys.pardef{parindx,2}));
            notify(this,'recompute');
        end

        % Callback for DDE lag vector widget
        function VectorLag(this,barObj,name,lagindx)
            this.VectorCallback(barObj,name);
            this.sys.lagdef{lagindx,2} = reshape(barObj.YData, size(this.sys.lagdef{lagindx,2}));
            notify(this,'recompute');
        end
        
        % Callback for ODE variable vector widget
        function VectorVariable(this,barObj,name,varindx)
            this.VectorCallback(barObj,name);
            this.sys.vardef{varindx,2} = reshape(barObj.YData, size(this.sys.vardef{varindx,2}));
            notify(this,'recompute');
        end
        
        % Callback for generic vector widget
        function VectorCallback(this,barObj,name)
            % ensure hObj is still valid
            if ~isvalid(barObj)
                % The object no longer exists. User must have closed the parent window.
                return
            end
            
            % retrive the current data from the bar graph
            data = barObj.YData;
            
            % open the vector editor            
            data = bdEditVector(data,['Vector ',name], name);
            
            % update the bar graph data
            set(barObj,'Ydata',data);
        end
        
        % Callback for ODE parameter matrix widget
        function MatrixParameter(this,imObj,name,parindx)
            % open dialog box for editing a matrix
            this.sys.pardef{parindx,2} = bdEditMatrix(this.sys.pardef{parindx,2},name);
            % update the image data in the control panel
            set(imObj,'CData',this.sys.pardef{parindx,2});
            notify(this,'recompute');
        end

        % Callback for DDE lag matrix widget
        function MatrixLag(this,imObj,name,lagindx)
            % open dialog box for editing a matrix
            this.sys.lagdef{lagindx,2} = bdEditMatrix(this.sys.lagdef{lagindx,2},name);
            % update the image data in the control panel
            set(imObj,'CData',this.sys.lagdef{lagindx,2});
            notify(this,'recompute');
        end

        % Callback for ODE varoable matrix widget
        function MatrixVariable(this,imObj,name,varindx)
            % open dialog box for editing a matrix
            this.sys.vardef{varindx,2} = bdEditMatrix(this.sys.vardef{varindx,2},name);
            % update the image data in the control panel
            set(imObj,'CData',this.sys.vardef{varindx,2});
            notify(this,'recompute');
        end
        
        % Listener for the compute flag
        function RecomputeListener(this)
            % Do nothing if the HALT button is active
            if this.hlt.Value
                return
            end
            
            % Change mouse cursor to hourglass
            set(this.fig,'Pointer','watch');
            drawnow;

            % determine the active solver
            solverfunc = this.solvermap(this.solveridx).solverfunc;
            solvertype = this.solvermap(this.solveridx).solvertype;
            
            % We use the ODE OutputFcn to track progress in our solver
            % and to detect halt events. We specify tspan so that OutputFcn
            % is called 11 times. These correspond to 0%, 10%, ... , 100%
            % progress of the solver.
            tspan = linspace(this.sys.tspan(1), this.sys.tspan(2), 11);
            switch solvertype
                case 'odesolver'
                    this.sys.odeoption = odeset(this.sys.odeoption, 'OutputFcn',@this.odeplot, 'OutputSel',[]);
                case 'ddesolver'
                    this.sys.ddeoption = ddeset(this.sys.ddeoption, 'OutputFcn',@this.odeplot, 'OutputSel',[]);
                case 'sdesolver'
                    this.sys.sdeoption = odeset(this.sys.sdeoption, 'OutputFcn',@this.odeplot, 'OutputSel',[]);
            end

            % Call the solver
            [this.sol,this.solx] = bdSolve(this.sys,tspan,solverfunc,solvertype);
            
            % notify all listeners that a redraw is required
            notify(this,'redraw');
            
            % Change mouse cursor to arrow
            set(this.fig,'Pointer','arrow');
        end
        
        % ODE solver callback function
        function status = odeplot(this,tspan,~,flag,varargin)
            switch flag
                case 'init'
                    this.cpustart = cputime;
                case ''
                    cpu = cputime - this.cpustart;
                    this.cpu.String = num2str(cpu,'%5.2fs');
                    this.pro.String = num2str(100*tspan(1)/this.sys.tspan(2),'%3.0f%%');
                    drawnow;
                case 'done'
                   if this.hlt.Value~=1
                        cpu = cputime - this.cpustart;
                        this.cpu.String = num2str(cpu,'%5.2fs');
                        this.pro.String = '100%';
                        drawnow;
                   end
            end   
            % return the state of the HALT button
            status = this.hlt.Value;
        end

        % HALT button callback
        function HaltCallback(this)
            if this.hlt.Value==1
                %this.cpu.String = '0.00s';
                %this.pro.String = '0%';
                this.cpu.ForegroundColor = [0.5 0.5 0.5];
            else
                this.cpu.ForegroundColor = [0 0 0];
                notify(this,'recompute');  
            end
        end
    end               
end

% Utility function to classify X as
% scalar (1), vector (2) or matrix (3)
function val = ScalarVectorMatrix(X)
    [nr,nc] = size(X);
    if nr*nc==1
        val = 1;        % X is scalar (1x1)
    elseif nr==1 || nc==1
        val = 2;        % X is vector (1xn) or (nx1)
    else
        val = 3;        % X is matrix (mxn)
    end
end


