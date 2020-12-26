classdef bdPanelMgr < handle
    %bdPanelMgr  Panel Manager class for bdGUI.
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
    
    properties
        TabGroup            matlab.ui.container.TabGroup    % handle to gui.TabGroup
        sysobj              bdSystem                        % handle to sysobj
        panelhands          struct                          % panel handles by name
    end
    
    methods
        % Constructor
        function this = bdPanelMgr(tabgrp,sysobj)
            this.TabGroup = tabgrp;
            this.sysobj = sysobj;
            this.panelhands = struct();
        end
        
        % Construct a new instance of the named panel with the given panel options
        function panelobj = NewPanel(this,panelname,opt)       
            % check the name of the panel
            pname = meta.class.fromName(panelname);
            if isempty(pname)
                warning('Display panel %s.m was not found.',panelname);
                return
            end
                
            % check the base class is bdPanel
            basename = findobj(pname.SuperclassList,'Name','bdPanelBase');
            if isempty(basename)
                warning('%s.m is not a display panel because it is not derived from bdPanel.',panelname);
                return
            end
            
            % replace empty opt with empty struct
            if isempty(opt)
                opt = struct();
            end
            
            % use the panel's own optcheck function to clean the options
            optcheckcmd = sprintf('%s.optcheck',panelname);
            opt = feval(optcheckcmd,opt);

            % call the panel's constructor, eg: bdTimePotrait(tabgrp,sysobj,opt)
            panelobj = feval(panelname,this.TabGroup,this.sysobj,opt);
                    
            % keep a copy of the handle in this.panelhndls
            if ~isfield(this.panelhands,panelname)
                this.panelhands.(panelname) = panelobj;
            else
                this.panelhands.(panelname)(end+1) = panelobj;
            end
            
            % remove stale handle from this.panelhands
            this.CleanPanelHands();
            
            % Push the new settings onto the UNDO stack
            %notify(this.sysobj,'push');
        end
              
        % Reconfigure the display panels as described in the 'panels' struct
        function ImportPanels(this,panels)
            % remove stale handle from this.panelhands
            this.CleanPanelHands();
            
            % get the field names in the panels struct
            panelnames = fieldnames(panels);

            % for each panel class
            for cindx = 1:numel(panelnames)
                % class name of the display panel
                panelname = panelnames{cindx};
                            
                % number of instances of the incoming display panel
                nin = numel(panels.(panelname));
                
                % number of existing instances
                if isfield(this.panelhands,panelname)
                    nout = numel(this.panelhands.(panelname));
                else
                    nout = 0;
                end
                
                % for each instance of the incoming panel
                for pindx = 1:nin
                    % extract the incoming panel options
                    opt = panels.(panelname)(pindx);

                    if pindx <= nout
                        % apply the incoming panel options to the existing panel object
                        this.panelhands.(panelname)(pindx).options = opt;
                    else
                        % construct a new panel object
                        this.NewPanel(panelname,opt);
                    end
                    drawnow;
                end
                
                if nout > 0
                    % delete any leftover instances from panelhands
                    while numel(this.panelhands.(panelname)) > nin
                        delete(this.panelhands.(panelname)(end));
                        this.panelhands.(panelname)(end) = [];
                    end
                end
            end
        end
        
        % Export a description of the current display panels in the 'panels' struct
        function panels = ExportPanels(this)
            %disp('bdPanelMgr.ExportPanels');
            
             % remove stale handle from this.panelhands
            this.CleanPanelHands();
           
            % init the output struct
            panels = struct();
            
            % get the names of the current panel classes
            panelnames = fieldnames(this.panelhands);
            
            % for each panel class
            for indx1 = 1:numel(panelnames)
                % class name of the current display panel
                panelname = panelnames{indx1};

                % for each instance of the display panel
                for idx2=1:numel(this.panelhands.(panelname))
                    % return the panel options
                    panels.(panelname)(idx2) = this.panelhands.(panelname)(idx2).options;
                end
            end
        end
        
        % Populate the New-Panel menus according the contents of the bdtoolkit/panels directory
        function PanelMenus(this,rootmenu,panels)
            %disp('bdPanelMgr.PanelMenus');

            % find all panel classes in the bdtoolkit/panels directory
            panelspath = what('panels');
            if isempty(panelspath)
                msg = {'The ''bdtoolkit/panels'' directory was not found.'
                'Ensure it is in the matlab search PATH. See Chapter 1'
                'of the Handbook for the Brain Dynamics Toolbox.'
                ''
                };
                uiwait( errordlg(msg,'Missing Display Panels') );
                throw(MException('bdGUI:badpath','The ''panels'' directory was not found'));
            end

            % add the found panels to the menu ...
            for indx = 1:numel(panelspath.m)
                % get the classname of the panel
                [~,panelclass] = fileparts(panelspath.m{indx});
                
                % get the subclass and title of the panel
                mc = meta.class.fromName(panelclass);
                mb = findobj(mc.SuperclassList,'Name','bdPanelBase');
                if isempty(mb)
                    warning([panelspath.m{indx} ' is not a subclass of bdPanelBase.']);
                    continue
                end
                
                % if predefined options exist for this panel then use them as defaults
                if isfield(panels,panelclass)
                    opt = panels.(panelclass);
                else
                    % use the panel's own optcheck function to get the default options
                    optcheckcmd = sprintf('%s.optcheck',panelclass);
                    opt = feval(optcheckcmd,struct());
                end
                
                if isfield(opt,'title')
                    label = opt.title;
                else
                    label = classname;
                end
                
                % add a menu item for this panel class
                uimenu('Parent',rootmenu, ...
                       'Label', label, ...
                       'Callback', @(~,~) this.NewPanel(panelclass,opt));
            end
                                    
        end       
        
        % Remove any stale handles from panelhands
        function CleanPanelHands(this)
            % for each field in this.panelhands
            panelnames = fieldnames(this.panelhands);
            for indx = 1:numel(panelnames)
                panelname = panelnames{indx};
                panelcount = numel(this.panelhands.(panelname));

                % for each instance of the panel (in reverse order)
                for indx2 = panelcount:-1:1
                    % remove handles to invalid classes
                    if ~isvalid(this.panelhands.(panelname)(indx2))
                        this.panelhands.(panelname)(indx2) = [];
                    end
                end
                
                % remove empty fields altogether
                if isempty(this.panelhands.(panelname))
                    this.panelhands = rmfield(this.panelhands,panelname);
                end
            end    
        end

    end
    
    methods (Static)
        
        function panelsout = panelscheck(panels)
            % init the output structure
            panelsout = struct();
            
            % get the field names in the incoming panels struct
            panelnames = fieldnames(panels);
            
            % for each panel class
            for cindx = 1:numel(panelnames)
                % class name of the display panel
                panelname = panelnames{cindx};
                            
                % check that a panel class of that name exists
                pname = meta.class.fromName(panelname);
                if isempty(pname)
                    warning('Display panel %s.m was not found.',panelname);
                    continue
                end
                
                % check the base class is bdPanelBase
                basename = findobj(pname.SuperclassList,'Name','bdPanelBase');
                if isempty(basename)
                    warning('%s.m is not a display panel because it is not derived from bdPanelBase.',panelname);
                    continue
                end
   
                % command to call the panel's own optcheck function
                optcheckcmd = sprintf('%s.optcheck',panelname);

                % if the incoming options are empty then ...
                if isempty(panels.(panelname))
                    % use the panel's own optcheck function to construct the default options
                    panelsout.(panelname) = feval(optcheckcmd,struct());
                else
                    % for each instance of the incoming panel options
                    for pindx = 1:numel(panels.(panelname))
                        % extract the incoming panel options
                        opt = panels.(panelname)(pindx);

                        % use the panel's own optcheck function to clean the options
                        panelsout.(panelname)(pindx) = feval(optcheckcmd,opt);
                    end
                end
            end
        end
    end
end

