classdef bdLatexPanel < bdPanelBase
    %bdLatexPanel Display panel for rendering LaTeX equations in bdGUI.
    %It renders the LaTeX strings found in the sys.panels.bdLatexPanel.latex
    %field of the system structure.
    %
    %AUTHORS
    %Stewart Heitmann (2016a,2017a,2017b,2017c,2018a,2020a)   
    
    % Copyright (C) 2016-2020 QIMR Berghofer Medical Research Institute
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
        axes                matlab.ui.control.UIAxes
        textarea            matlab.ui.control.TextArea
    end
    
    properties (Access=private)
        sysobj              bdSystem
        tab                 matlab.ui.container.Tab
        scrollpanel         matlab.ui.container.Panel
        menu                matlab.ui.container.Menu
        menuDock            matlab.ui.container.Menu
    end
    
    methods
        function this = bdLatexPanel(tabgrp,sysobj,opt)
            %disp('bdLatexPanel');
            
            % remember the parents
            this.sysobj = sysobj;
                        
            % get the parent figure of the TabGroup
            fig = ancestor(tabgrp,'figure');
            
            % Create the panel menu and assign it a unique Tag to identify it.
            this.menu = uimenu('Parent',fig, ...
                'Label','Equations', ...
                'Tag', bdPanelBase.FocusMenuID(), ...     % unique Tag used by the FocusMenu function
                'Visible','off');
            
            % construct the EDIT menu item
            uimenu(this.menu, ...
                'Label', 'Edit', ...
                'Tooltip', 'Edit the latex markup', ...            
                'Callback', @(src,~) this.callbackEdit(src) );

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
            this.tab = uitab(tabgrp, 'Title','Equations', 'Tag',this.menu.Tag);
            tabgrp.SelectedTab = this.tab;
            
            % Create GridLayout within the Tab
            GridLayout = uigridlayout(this.tab);
            GridLayout.ColumnWidth = {'1x'};
            GridLayout.RowHeight = {'1x'};
            GridLayout.Padding = [10 10 10 10];
            GridLayout.Visible = 'off';
            
            % Create scrollable panel
            this.scrollpanel = uipanel(GridLayout);
            this.scrollpanel.Layout.Row = 1;
            this.scrollpanel.Layout.Column = 1;
            this.scrollpanel.BackgroundColor = [1 1 1];
            this.scrollpanel.Scrollable = 'on';
            this.scrollpanel.AutoResizeChildren = 'off';
            this.scrollpanel.SizeChangedFcn = @(~,~) callbackSizeChanged(this);
            
            % Create axes in the scrollable panel
            this.axes = uiaxes(this.scrollpanel);
            this.axes.NextPlot = 'add';
            this.axes.XTick = [];
            this.axes.YTick = [];
            this.axes.Units = 'pixels';
            this.axes.Position = [1 1 100 100];
            this.axes.XGrid = 'off';
            this.axes.YGrid = 'off';
            this.axes.Box = 'off';
            this.axes.XColor = 'w';
            this.axes.YColor = 'w';
            this.axes.BackgroundColor = 'w';
            this.axes.Visible = 'on';
            this.axes.Toolbar.Visible = 'off';
            this.axes.HitTest = 'off';
            disableDefaultInteractivity(this.axes);

            % Create text area (overlaying the axes/panel)
            this.textarea = uitextarea(GridLayout);
            this.textarea.Layout.Row = 1;
            this.textarea.Layout.Column = 1;
            this.textarea.FontName = 'Courier';
            this.textarea.Visible = 'off';
                   
            % apply the custom options (and render the image)
            this.options = opt;

            % make our panel menu visible and hide the others
            bdPanelBase.FocusMenu(tabgrp);
            
            % make the grid visible
            GridLayout.Visible = 'on';   
        end
        
        function opt = get.options(this)
            opt.title = this.tab.Title;
            opt.latex = this.textarea.Value;
            opt.fontsize = this.axes.FontSize;
        end
        
        function set.options(this,opt)   
            % check the incoming options and apply defaults to missing values
            opt = this.optcheck(opt);
             
            % update the tab title
            this.tab.Title = opt.title;
            
            % update the menu title
            this.menu.Text = opt.title;
                                   
            % update the latex source
            this.textarea.Value = opt.latex;
            
            % update the font size
            this.axes.FontSize = opt.fontsize;
            
            % Redraw everything
            this.Render();
            
            % Push the new settings onto the UNDO stack
            notify(this.sysobj,'push');
        end
        
        function delete(this)
           %disp('bdLatexPanel.delete()');
           delete(this.menu);
           delete(this.tab);
        end
    end
    
    methods (Access=private)

        function Render(this)
            %disp('bdLatexPanel.Render()');
            
            % Number of latex strings to render
            ntext = numel(this.textarea.Value);
            
            % Text geometry
            fontsize = this.axes.FontSize;

            % Delete existing Text objects
            textobjs = findobj(this.axes,'Type','Text');
            delete(textobjs);

            % Track the maximal text width
            maxtextw = 100;
            
            % Copy text from the Text Area into the Axes.
            % Start at the bottom line and work upwards.
            % Note that matlab does not update Extent properties with exact
            % values until after the graphics have been rendered. Hence the
            % widths and heights of the text objects in this code will be
            % slightly out when this code block is run for the first time.
            ypos = 1;
            for indx = ntext:-1:1
                textobj = text(this.axes,1,ypos, ...
                    this.textarea.Value{indx}, ...
                    'interpreter','latex', ...
                    'Units','pixels', ...
                    'FontUnits','pixels', ...
                    'FontSize',fontsize, ...
                    'VerticalAlignment','bottom', ...
                    'PickableParts','none'); 
                
                % track the maximal text width
                textw = textobj.Extent(1) + textobj.Extent(3) + 10;
                maxtextw = max(maxtextw,textw);     
                
                % next line position
                if isempty(this.textarea.Value{indx})
                    % empty lines are half height
                    ypos = ypos + fontsize/2;
                else
                    % non-empty lines are full height
                    ypos = textobj.Extent(2) + 1.025*textobj.Extent(4);
                end                
            end                  
                      
            % Resize the axes (vertically) based on the final (highest) text object
            ytop = textobj.Extent(2) + textobj.Extent(4);
            ybot = this.scrollpanel.Position(4) - this.axes.Position(4);
            this.axes.Position(4) = ytop + 10;            
            this.axes.Position(2) = max(ybot,1);

            % Resize the axes (horizontally)
            this.axes.Position(1) = 1;
            this.axes.Position(3) = maxtextw;
        end        
               
        % Scrollpanel SIZECHANGED callback
        function callbackSizeChanged(this)
            %disp('bdLatexPanel.callbackSizeChanged');
            % Resize the axes (vertically) based on the geometry of the first line of text
            ybot = this.scrollpanel.Position(4) - this.axes.Position(4);
            this.axes.Position(2) = max(ybot,1);
        end
        
        % EDIT menu callback
        function callbackEdit(this,menuitem)
            %disp('callbackEdit');
            this.MenuToggle(menuitem);      % Toggle the menu state
            switch menuitem.Checked
                case 'on'
                    % Show the Text Area and hide the Axes
                    this.textarea.Visible = 'on';
                    this.scrollpanel.Visible = 'off';
                otherwise
                    % Render the latex, hide the Text Area and show the Axes
                    this.Render();
                    this.textarea.Visible = 'off';
                    this.scrollpanel.Visible = 'on';
                    % Push the new settings onto the UNDO stack
                    notify(this.sysobj,'push');
            end
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
            sysobjhnd = this.sysobj;
            
            % delete the panel
            delete(this);
            
            % reveal the menu of the newly selected panel 
            bdPanelBase.FocusMenu(tabgrp);
            
            % if the parent figure is not the same as the gui figure then ...
            if fig ~= guifig
                % The panel is undocked from the gui. Its figure should be closed too. 
                delete(fig);
            end
            
            % Push the new settings onto the UNDO stack
            notify(sysobjhnd,'push');
        end
        
    end
    
    methods (Static)
        
        function optout = optcheck(opt)
            % check the format of incoming options and apply defaults to missing values
            optout.title    = bdPanelBase.GetOption(opt, 'title', 'Equations');
            optout.latex    = bdPanelBase.GetOption(opt, 'latex', {'your latex equations here'});
            optout.fontsize = bdPanelBase.GetOption(opt, 'fontsize', 16);
            
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

