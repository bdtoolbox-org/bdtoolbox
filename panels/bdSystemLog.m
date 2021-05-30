classdef bdSystemLog < bdPanelBase
    %bdSystemLog Display system events for debugging purposes
    %AUTHORS
    %  Stewart Heitmann (2020a,2021a)

    % Copyright (C) 2020-2021 Stewart Heitmann
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
        
    properties (Dependent)
        options
    end
    
    properties (Access=public)
        textarea            matlab.ui.control.TextArea
    end
    
    properties (Access=private)
        sysobj              bdSystem
        tab                 matlab.ui.container.Tab
        menu                matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
        listener1           event.listener        
        listener2           event.listener        
        listener3           event.listener        
    end
    
    methods
        function this = bdSystemLog(tabgrp,sysobj,opt)
            %disp('bdSystemLog');
            
            % remember the parents
            this.sysobj = sysobj;
                        
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','System Log', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');
            
            % construct the CLEAR menu item
            uimenu(this.menu, ...
                'Label', 'Clear', ...
                'Tooltip', 'Clear the messages', ...            
                'Callback', @(src,~) this.callbackClear() );

            % construct the DOCK menu item
            this.menuDock = uimenu(this.menu, ...
                'Label', 'Undock', ...
                'Tooltip', 'Undock the display panel', ...            
                'Callback', @(src,~) this.callbackDock(src,tabgrp) );

            % construct the CLOSE menu item
            uimenu(this.menu, ...
                'Separator','on', ...
                'Label','Close', ...
                'Tooltip', 'Close the display panel', ...            
                'Callback', @(~,~) this.callbackClose(fig) );

            % Create Tab and give it the focus. The tab should have the same
            % Tag as the panel menu so that each can be found by the other.
            this.tab = uitab(tabgrp, 'Title','System Log', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'1x'};
            GridLayout.RowHeight = {'1x'};
            GridLayout.Padding = [10 10 10 10];
            GridLayout.Visible = 'off';
            
            % Create text area
            this.textarea = uitextarea(GridLayout);
            this.textarea.Layout.Row = 1;
            this.textarea.Layout.Column = 1;
            this.textarea.FontName = 'Courier';
            this.textarea.Value = 'System Log';
            this.textarea.Editable = 'off';
            this.textarea.Visible = 'on';
            
            % apply the custom options (and render the image)
            this.options = opt;

            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';
            
            % listen for Redraw events
            this.listener1 = listener(sysobj,'redraw',@(~,evnt) this.Redraw(evnt)); 
            
            % listen for Respond events
            this.listener2 = listener(sysobj,'respond',@(~,~) this.Respond());  
        end
        
        function opt = get.options(this)
            opt.title = this.tab.Title;
        end
        
        function set.options(this,opt)   
            % check the incoming options and apply defaults to missing values
            opt = this.optcheck(opt);
             
            % update the tab title
            this.tab.Title = opt.title;
            
            % update the menu title
            this.menu.Text = opt.title;
        end
        
        function delete(this)
           %disp('bdSystemLog.delete()');
           delete(this.listener1);
           delete(this.listener2);
           delete(this.listener3);
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods (Access=private)
        
        % Listener for REDRAW events
        function Redraw(this,evnt)
            datestr = datetime('now','Format','HH:mm:ss');
            prefix  = sprintf('%s REDRAW event',datestr);
            
            % pardef
            for idx=1:numel(evnt.pardef)
                if evnt.pardef(idx).value
                    this.textarea.Value(end+1) = {sprintf('%s: pardef(%d).value',prefix,idx)};
                end
                if evnt.pardef(idx).lim
                    this.textarea.Value(end+1) = {sprintf('%s: pardef(%d).lim',prefix,idx)};
                end
            end
            
            % lagdef
            for idx=1:numel(evnt.lagdef)
                if evnt.lagdef(idx).value
                    this.textarea.Value(end+1) = {sprintf('%s: lagdef(%d).value',prefix,idx)};
                end
                if evnt.lagdef(idx).lim
                    this.textarea.Value(end+1) = {sprintf('%s: lagdef(%d).lim',prefix,idx)};
                end
            end
            
            % vardef
            for idx=1:numel(evnt.vardef)
                if evnt.vardef(idx).value
                    this.textarea.Value(end+1) = {sprintf('%s: vardef(%d).value',prefix,idx)};
                end
                if evnt.vardef(idx).lim
                    this.textarea.Value(end+1) = {sprintf('%s: vardef(%d).lim',prefix,idx)};
                end
            end
            
            % all other fields
            for fnames = {'tspan','tstep','tval','noisehold','evolve','perturb','backward','halt','solveritem','odeoption','ddeoption','sdeoption','sol','panels'}
                fname = fnames{:};
                if evnt.(fname)
                    this.textarea.Value(end+1) = {sprintf('%s: %s',prefix,fname)};
                end
            end
            
            % discard old messages
            this.trimlog();
        end
        
        % Listener for RESPOND event
        function Respond(this)
            datestr = datetime('now','Format','HH:mm:ss');
            this.textarea.Value(end+1) = {sprintf('%s RESPOND event',datestr)};
            this.trimlog();
        end
        
        % Discard old messages
        function trimlog(this)
            ntrim = numel(this.textarea.Value) - 30;
            if ntrim > 0
                this.textarea.Value(1:ntrim) = [];
            end
        end
        
        % CLEAR menu callback
        function callbackClear(this)
            %disp('callbackClear');
            this.textarea.Value = 'System Log';
        end
        
        % DOCK menu callback
        function callbackDock(this,menuitem,tabgrp)
            %disp('callbackDock');
            switch menuitem.Label
                case 'Undock'
                    newfig = bdPanelBase.Undock(this.tab,this.menu);
                    newfig.DeleteFcn = @(src,~) this.delete();
                    menuitem.Label='Dock';
                    menuitem.Tooltip='Dock the display panel';
                case 'Dock'
                    bdPanelBase.Dock(this.tab,this.menu,tabgrp);
                    menuitem.Label='Undock';
                    menuitem.Tooltip='Undock the display panel';
            end
        end
        
        % CLOSE menu callback
        function callbackClose(this,guifig)
            % find the parents of the panel tab 
            tabgrp = ancestor(this.tab,'uitabgroup');
            fig = ancestor(this.tab,'figure');
            
            % remember sysobj
            sysobj = this.sysobj;
            
            % delete the panel
            delete(this);
            
            % reveal the menu of the newly selected panel 
            bdPanelBase.FocusMenu(tabgrp);
            
            % if the parent figure is not the same as the gui figure then ...
            if fig ~= guifig
                % The panel is undocked from the gui. Its figure should be closed too. 
                delete(fig);
            end
        end
        
    end
    
    methods (Static)
        
        function optout = optcheck(opt)
            % check the format of incoming options and apply defaults to missing values
            optout.title    = bdPanelBase.GetOption(opt, 'title', 'System Log');
            
            % warn of unrecognised field in the incoming options
            infields  = fieldnames(opt);                % the field names we were given
            outfields = fieldnames(optout);             % the field names we expected
            newfields = setdiff(infields,outfields);    % unrecognised field names
            for idx=1:numel(newfields)
                warning('Ignoring unknown panel option ''%s.%s''',mfilename, newfields{idx});
            end
        end
        
    end
end

