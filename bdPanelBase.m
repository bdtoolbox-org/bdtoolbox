classdef bdPanelBase < handle
    % Base class for display panels in the Brain Dynamics Toolbox GUI.
    %
    % AUTHORS
    % Stewart Heitmann (2018a,2020a,2021a)   
    
    % Copyright (C) 2016-2021 QIMR Berghofer Medical Research Institute
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
    
    properties (Abstract=true,Dependent=true)
        options struct      % panel-specific options
    end

    methods (Abstract,Static)
        optcheck(opt)
    end
    
    methods (Access=public)
        
    end
    
    methods (Static)
        
        % Toggle the Checked state of the given menuitem and return the new state 
        function Checked = MenuToggle(menuitem)
            % toggle the menu 
            switch menuitem.Checked
                case 'on'
                    menuitem.Checked='off';
                case 'off'
                    menuitem.Checked='on';
            end
            % return the new state
            Checked = menuitem.Checked;
        end
               
        % Returns the value of 'opt.fieldname'. If that fieldname does not
        % exist then it returns the given 'val' in its place.
        function val = GetOption(opt,fieldname,val)
            if ~isempty(opt) && isfield(opt,fieldname)
                if isequal(class(opt.(fieldname)),class(val))
                    val = opt.(fieldname);
                elseif isequal(class(opt.(fieldname)),'matlab.lang.OnOffSwitchState') && isequal(class(val),'char')
                    % special case where char (eg 'on') and OnOffState are interoperable 
                    val = opt.(fieldname);
                else
                    warning(sprintf('option.%s should be %s not %s',fieldname,class(val), class(opt.(fieldname))));
                end
            end
        end
        
        function Tag = FocusMenuID()
            % return a unique Tag Identifier
            Tag = sprintf('FocusMenu-%d',randi(1e10));
        end
        
        function FocusMenu(tabgrp)
            %disp('FocusMenu');
            
            % get the parent figure
            fig = ancestor(tabgrp,'figure');
            
            % get the currently selected tab
            tab = tabgrp.SelectedTab;
                        
            % if there is a currently selected tab then ...
            if ~isempty(tab)
                % get the Tag of the panel menu associated with this tab
                FocusMenuTag = tab.Tag;
                
                % ensure the 'Brain Dynamics Toolbox' background text is hidden
                tabgrp.UserData.label1.Visible = 'off';
                tabgrp.UserData.label2.Visible = 'off';
            else
                % there is no current tab so use an empty Tag
                FocusMenuTag = [];
                
                % ensure the 'Brain Dynamics Toolbox' background text is visible
                tabgrp.UserData.label1.Visible = 'on';
                tabgrp.UserData.label2.Visible = 'on';
            end
            
            % find all panel menus in the parent figure
            objs = findobj(fig,'Type','uimenu', '-regexp', 'Tag','FocusMenu-[\d]')';
            
            % hide all panel menus except that of the currently selected tab
            for obj = objs
                switch obj.Tag
                    case FocusMenuTag
                       obj.Visible = 'on';
                    otherwise
                       obj.Visible = 'off';
               end
           end
        end
        
        function newfig = Undock(tab,menu)
            % get the current parent figure
            guifig = ancestor(tab,'figure');
                  
            % create a new figure (with the same Tag as the GUI figure)
            newfig = uifigure('Tag',guifig.Tag);
            
            % create a gridlayout for the figure
            GridLayout = uigridlayout(newfig);
            GridLayout.ColumnWidth = {'1x'};
            GridLayout.RowHeight = {'1x'};
            GridLayout.Padding = [10 10 5 10];
            
            % create a tabgroup for the figure
            tabgrp = uitabgroup(GridLayout);
            tabgrp.Layout.Row = 1;
            tabgrp.Layout.Column = 1;

            % get the old tabgroup
            oldtabgrp = tab.Parent;
            
            % move the panel tab to the new tabgroup
            tab.Parent = tabgrp;     
            
            % move the panel menu to the new figure
            menu.Parent = newfig;
            
            % update the menu focus of the old tabgroup
            bdPanelBase.FocusMenu(oldtabgrp);
        end
        
        function Dock(tab,menu,guitabgrp)
            % get the handle to the gui figure
            guifig = ancestor(guitabgrp,'figure');
            
            % get handle to the undocked figure
            oldfig = ancestor(tab,'figure');
            
            % move the panel tab back to the GUI tabgroup
            tab.Parent = guitabgrp;     
            guitabgrp.SelectedTab = tab;
            
            % move the panel menu back to the GUI figure
            menu.Parent = guifig;
            
            % update the menu focus of the GUI tabgroup
            bdPanelBase.FocusMenu(guitabgrp);
            
            % close the undocked figure
            oldfig.DeleteFcn = [];
            delete(oldfig);
        end        
         
    end
end

