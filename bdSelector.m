classdef bdSelector < handle 
    %bdSelector  Selector object for use in bdGUI display panels.
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
    
    events
        SelectionChanged
        SubscriptChanged
    end

    properties (Access=private)
        sysobj       bdSystem
        itemdata     struct
        itemindx
        menuitems    matlab.ui.container.Menu
        dropdown     matlab.ui.control.DropDown
        spinnerR     matlab.ui.control.Spinner
        spinnerC     matlab.ui.control.Spinner
    end
    
    methods (Access=public)
        function this = bdSelector(sysobj,varargin)
            % remember our parents
            this.sysobj = sysobj;
            
            % initiate an empty list of selector items
            this.itemdata = struct('xxxdef',{},'xxxindx',{},'rindx',{},'cindx',{});
            this.itemindx = 0;
            
            % add any selector items that were given as input parameters
            for argindx = 1:numel(varargin)
                xxxdef = varargin{argindx};
                switch xxxdef
                    case {'pardef','lagdef','vardef'}
                        this.AddItems(xxxdef);
                    otherwise
                        error(['bdSelector(sysobj,...): invalid input parameter ''' xxxdef '''']);
                end
            end
        end
        
        function AddItem(this,xxxdef,xxxindx)
            switch xxxdef
                case 'pardef'
                case 'lagdef'
                case 'vardef'
                otherwise
                    error('xxxdef must be ''pardef'', ''vardef'' or ''lagdef''');
            end
            this.itemdata(end+1) = struct('xxxdef',xxxdef, 'xxxindx',xxxindx, 'rindx',1, 'cindx',1);
            if this.itemindx==0
                this.itemindx=1;
            end
        end
        
        function AddItems(this,xxxdef)
            switch xxxdef
                case 'pardef'
                case 'lagdef'
                case 'vardef'
                otherwise
                    error('xxxdef must be ''pardef'', ''vardef'' or ''lagdef''');
            end
            nindx = numel(this.sysobj.(xxxdef));
            for indx = 1:nindx
                this.itemdata(end+1) = struct('xxxdef',xxxdef, 'xxxindx',indx, 'rindx',1, 'cindx',1);
            end
            if this.itemindx==0 && ~isempty(this.itemdata)
                this.itemindx=1;
            end
        end
        
        function SelectByIndex(this,itemindx)
            % select the item by index
            n = numel(this.itemdata);
            itemindx = max(1,min(n,itemindx));
            this.itemindx = itemindx;
            % update the widgets
            this.RefreshMenuItems();
            this.RefreshDropDown();
        end
        
        function SelectByName(this,name)
            for indx = 1:numel(this.itemdata)
                xxxdef  = this.itemdata(indx).xxxdef;
                xxxindx = this.itemdata(indx).xxxindx;
                xxxname = this.sysobj.(xxxdef)(xxxindx).name;
                if isequal(xxxname,name)
                    % select the item 
                    this.itemindx = indx;
                    % update the widgets
                    this.RefreshMenuItems();
                    this.RefreshDropDown();
                    return
                end
            end
            warning(['Ignoring unrecognised selection ''',name,'''']);
        end
        
        function SelectByCell(this,cellspec)
            % Valid input formats are:
            %   cellspec = {'x'}
            %   cellspec = {'x',21}
            %   cellspec = {'x',3,7}
            %   cellspec = {1}
            %   cellspec = {1,21}
            %   cellspec = {1,3,7}
            
            % select the item specified in cellspec{1}
            if ischar(cellspec{1})
                this.SelectByName(cellspec{1});     % eg cellspec={'x'}
            else
                this.SelectByIndex(cellspec{1});    % eg cellspec={1}
            end

            % data size of the newly selected item
            [nr,nc] = this.vsize();
            
            % current subscripts of the newly selected item
            [rindx,cindx] = this.subscripts();
            
            % determine the new subscripts
            switch numel(cellspec)
                case 2
                    % eg cellspec={'x',32} 
                    [rindx,cindx] = ind2sub([nr,nc],cellspec{2});
                case 3
                    % eg cellspec={'x',5,7} 
                    rindx = cellspec{2};
                    cindx = cellspec{3};
            end
                
            % safety checks
            rindx = max(1,min(nr,rindx));
            cindx = max(1,min(nc,cindx));
            
            % apply the new subscripts
            this.itemdata(this.itemindx).rindx = rindx;
            this.itemdata(this.itemindx).cindx = cindx;
                    
            % update the widgets
            this.RefreshMenuItems();
            this.RefreshDropDown();
        end
        
        function SelectByOption(this,opt,fieldname)
            if isfield(opt,fieldname)
                cellspec = opt.(fieldname);
                if ~iscell(cellspec)
                    warning('option.%s should be a cell eg {1,1,1}',fieldname);
                    return
                end
                if numel(cellspec)<1 || numel(cellspec)>3
                    warning('option.%s must contain 1,2 or 3 values',fieldname);
                    return
                end
                this.SelectByCell(cellspec);
            end
        end
        
        function [xxxdef,xxxindx,rindx,cindx] = Item(this)
            assert(this.itemindx~=0,'Selector has no items');
            xxxdef  = this.itemdata(this.itemindx).xxxdef;
            xxxindx = this.itemdata(this.itemindx).xxxindx;
            rindx   = this.itemdata(this.itemindx).rindx;
            cindx   = this.itemdata(this.itemindx).cindx;
        end
        
        function spec = cellspec(this)
            rindx = this.itemdata(this.itemindx).rindx;
            cindx = this.itemdata(this.itemindx).cindx;
            spec = {this.itemindx, rindx, cindx};
        end
        
        function [name1,name2,name3] = name(this)
            assert(this.itemindx~=0,'Selector has no items');
            xxxdef  = this.itemdata(this.itemindx).xxxdef;
            xxxindx = this.itemdata(this.itemindx).xxxindx;
            rindx   = this.itemdata(this.itemindx).rindx;
            cindx   = this.itemdata(this.itemindx).cindx;
            [nr,nc] = size(this.sysobj.(xxxdef)(xxxindx).value);
            name1 = this.sysobj.(xxxdef)(xxxindx).name;
            if nr==1 && nc==1
                name2 = name1;
                name3 = name1;
            else
                name2 = sprintf('%s: [%dx%d]',name1,nr,nc);
                name3 = sprintf('{%s} {(%d,%d)}',name1,rindx,cindx);
            end
        end
        
        function value = value(this)
            assert(this.itemindx~=0,'Selector has no items');
            xxxdef  = this.itemdata(this.itemindx).xxxdef;
            xxxindx = this.itemdata(this.itemindx).xxxindx;
            value = this.sysobj.(xxxdef)(xxxindx).value;
        end
        
        function [nr,nc] = vsize(this)
            assert(this.itemindx~=0,'Selector has no items');
            xxxdef  = this.itemdata(this.itemindx).xxxdef;
            xxxindx = this.itemdata(this.itemindx).xxxindx;
            [nr,nc] = size(this.sysobj.(xxxdef)(xxxindx).value);
        end
        
        function [rindx,cindx] = subscripts(this)
            assert(this.itemindx~=0,'Selector has no items');
            rindx = this.itemdata(this.itemindx).rindx;
            cindx = this.itemdata(this.itemindx).cindx;
        end
        
        function [plim,lim] = lim(this,newlim)
            assert(this.itemindx~=0,'Selector has no items');
            xxxdef  = this.itemdata(this.itemindx).xxxdef;
            xxxindx = this.itemdata(this.itemindx).xxxindx;
            lim = this.sysobj.(xxxdef)(xxxindx).lim;
            plim = lim + [-1e-9 1e-9];
            if nargin>1
                assert(isequal(size(newlim),[1 2]),'invalid limit');
                this.sysobj.(xxxdef)(xxxindx).lim = newlim;
            end
        end
        
        function [solindx,subindx] = solindx(this)
            assert(this.itemindx~=0,'Selector has no items');
            xxxdef  = this.itemdata(this.itemindx).xxxdef;
            xxxindx = this.itemdata(this.itemindx).xxxindx;
            rindx   = this.itemdata(this.itemindx).rindx;
            cindx   = this.itemdata(this.itemindx).cindx;
            vsize   = size(this.sysobj.(xxxdef)(xxxindx).value);
            rcindx  = sub2ind(vsize,rindx,cindx);
            
            switch xxxdef
                case 'vardef'
                    solindx = this.sysobj.(xxxdef)(xxxindx).solindx;
                    subindx = solindx(rcindx);
                otherwise
                    solindx = [];
                    subindx = [];
            end
        end

        function [Y,t] = solY(this)
            assert(this.itemindx~=0,'Selector has no items');
            xxxdef  = this.itemdata(this.itemindx).xxxdef;
            xxxindx = this.itemdata(this.itemindx).xxxindx;
            [nr,nc] = size(this.sysobj.(xxxdef)(xxxindx).value);
            t = this.sysobj.sol.x;
            nt = numel(t);
            switch xxxdef
                case 'vardef'
                    solindx = this.sysobj.vardef(xxxindx).solindx;
                    Y = this.sysobj.sol.y(solindx,:);
                case {'pardef','lagdef'}
                    Y = NaN(nr,nc,nt);
                    for indx=1:nt
                        Y(:,:,indx) = this.sysobj.(xxxdef)(xxxindx).value;
                    end
            end
            
            % compute the final shape of Y
            if nr==1
                % var has one row
                if nc==1
                    % var has one row and one column
                    % Return y as (1 x nt).
                    newshape = [1 nt];
                else
                    % var has one row and multiple columns
                    % Return y as (nc x nt)
                    newshape = [nc nt];
                end 
            else
                % var has multiple rows
                if nc==1
                    % var has multiple rows and one column
                    % Return y as (nr x nt)
                    newshape = [nr nt];
                else
                    % var has multiple rows and multiple columns
                    % Return y as (nr x nc x nt)
                    newshape = [nr nc nt];
                end 
            end

            % apply the new shape to Y
            Y = reshape(Y,newshape);
        end
        
        function [Y,dY] = Eval(this,tdomain)
            assert(this.itemindx~=0,'Selector has no items');
            xxxdef  = this.itemdata(this.itemindx).xxxdef;
            xxxindx = this.itemdata(this.itemindx).xxxindx;
            switch xxxdef
                case 'vardef'
                    [Y,dY] = this.sysobj.Eval(tdomain,xxxindx);
                case {'pardef','lagdef'}
                    [~,~,~,~,~,nt] = this.sysobj.TimeDomain();
                    [nr,nc] = size(this.sysobj.(xxxdef)(xxxindx).value);
                    Y = NaN(nr,nc,nt);
                    for indx=1:nt
                        Y(:,:,indx) = this.sysobj.(xxxdef)(xxxindx).value;
                    end
                    dY = zeros(nr,nc,nt);
            end
        end
        
        % Returns the time series for the currently selected item
        function [Y,Ysub,tdomain,tindx0,tindx1,ttindx] = Trajectory(this,args)
            arguments
                this            bdSelector
                args.autostep   matlab.lang.OnOffSwitchState = 'off'
            end

            assert(this.itemindx~=0,'Selector has no items');
            
            % get the currently selected item
            xxxdef  = this.itemdata(this.itemindx).xxxdef;
            xxxindx = this.itemdata(this.itemindx).xxxindx;
            rindx = this.itemdata(this.itemindx).rindx;
            cindx = this.itemdata(this.itemindx).cindx;
            name = this.sysobj.(xxxdef)(xxxindx).name;
            [nr,nc] = size(this.sysobj.(xxxdef)(xxxindx).value);
            
            switch xxxdef
                case 'vardef'
                    % return a state variable
                    if args.autostep
                        % use variable time steps
                        solindx = this.sysobj.(xxxdef)(xxxindx).solindx;
                        tdomain = this.sysobj.sol.x;
                        Y = this.sysobj.sol.y(solindx,:);
                        if nr>1 && nc>1
                            Y = reshape(Y,nr,nc,[]);
                        else
                            Y = reshape(Y,nr*nc,[]);
                        end
                    else
                        % use fixed time steps
                        tdomain = this.sysobj.tdomain;
                        Y = this.sysobj.vars.(name);
                    end
                    
                case {'pardef','lagdef'}
                    % return a parameter constant as a time series
                    if args.autostep
                        % use variable time steps
                        tdomain = this.sysobj.sol.x;
                    else
                        % use fixed time steps
                        tdomain = this.sysobj.tdomain;
                    end            
                    nt = numel(tdomain);
                    [nr,nc] = size(this.sysobj.(xxxdef)(xxxindx).value);
                    if nr>1 && nc>1
                        % Return Y as 3D matrix
                        Y = NaN(nr,nc,nt);
                        for indx=1:nt
                            Y(:,:,indx) = this.sysobj.(xxxdef)(xxxindx).value;
                        end
                    else
                        % Return Y as 2D matrix
                        Y = NaN(nr*nc,nt);
                        for indx=1:nt
                            Y(:,indx) = this.sysobj.(xxxdef)(xxxindx).value;
                        end
                    end
            end
            
            % if the second output argument was requested then ...
            if nargout>1
                if nr>1 && nc>1
                    Ysub(1,:) = Y(rindx,cindx,:);
                else
                    Ysub(1,:) = Y(rindx*cindx,:);
                end
            end
            
            % if the forth (or higher) output argument was requested
            if nargout>3
                [tindx0,tindx1,ttindx] = this.sysobj.tindices(tdomain);
            end
        end
        
        function lim = Calibrate(this,tspan)
            assert(this.itemindx~=0,'Selector has no items');
            xxxdef  = this.itemdata(this.itemindx).xxxdef;
            xxxindx = this.itemdata(this.itemindx).xxxindx;
            switch xxxdef
                case 'pardef'
                    lim = this.sysobj.CalibratePar(xxxindx);
                case 'lagdef'
                    lim = this.sysobj.CalibrateLag(xxxindx);
                case 'vardef'
                    lim = this.sysobj.CalibrateVar(xxxindx,tspan);
            end
        end
        
        function menuitems = Menu(this,rootmenu)
            for indx=1:numel(this.itemdata)
                xxxdef  = this.itemdata(indx).xxxdef;
                xxxindx = this.itemdata(indx).xxxindx;
                [nr,nc] = size(this.sysobj.(xxxdef)(xxxindx).value);
                name = this.sysobj.(xxxdef)(xxxindx).name;
                
                if nr==1 && nc==1
                    label = name;
                else
                    label = sprintf('%s: [%dx%d]',name,nr,nc);
                end

                if indx==this.itemindx
                    checked='on';
                else
                    checked='off';
                end
                this.menuitems(end+1) = uimenu('Parent',rootmenu, ...
                       'Label',label, ...
                       'Checked',checked, ...
                       'UserData',indx, ...
                       'Callback',@(src,~) this.MenuCallback(indx));                 
            end
            
            % return the handles of the menuitems
            menuitems = this.menuitems;
        end               
        
        function dropdown = DropDown(this,uiparent)
            % Enumerate DropDown items
            nitems = numel(this.itemdata);
            Items = cell(nitems,1);
            for indx=1:numel(this.itemdata)
                xxxdef  = this.itemdata(indx).xxxdef;
                xxxindx = this.itemdata(indx).xxxindx;
                [nr,nc] = size(this.sysobj.(xxxdef)(xxxindx).value);
                name = this.sysobj.(xxxdef)(xxxindx).name;
                if nr==1 && nc==1
                    Items{indx} = name;
                else
                    Items{indx} = sprintf('%s: [%dx%d]',name,nr,nc);
                end
            end
            
            % Create DropDown
            this.dropdown = uidropdown(uiparent);
            this.dropdown.Items = Items;
            this.dropdown.ItemsData = 1:numel(Items);
            if isempty(Items)
                this.dropdown.Value = {};
            else
                this.dropdown.Value = this.itemindx;
            end
            this.dropdown.ValueChangedFcn = @(~,evnt) this.DropDownCallback(evnt);
            
            % Return the handle to the DropDown widget
            dropdown = this.dropdown;
        end
        
        function spinner = SpinnerR(this,uiparent)
            % Delete any previous spinner
            delete(this.spinnerR);
            
            % Create Spinner
            this.spinnerR = uispinner(uiparent);
            this.spinnerR.Value = 1;
            this.spinnerR.Step = 1;
            this.spinnerR.Limits = [0 1];
            this.spinnerR.Enable = 'off';
            this.spinnerR.LowerLimitInclusive = 'on';
            this.spinnerR.UpperLimitInclusive = 'on';
            this.spinnerR.RoundFractionalValues = 'on';
            this.spinnerR.Tooltip = 'row subscript';
            %this.spinnerR.Interruptible = 'off';
            %this.spinnerR.BusyAction = 'queue';
            this.spinnerR.ValueChangingFcn = @(~,evnt) this.SpinnerRcallback(evnt);
            
            % return a handle
            spinner = this.spinnerR;
            
            % Update the Spinner
            this.RefreshSpinners();            
        end
        
        function spinner = SpinnerC(this,uiparent)
            % Delete any previous spinner
            delete(this.spinnerC);
            
            % Create Spinner
            this.spinnerC = uispinner(uiparent);
            this.spinnerC.Value = 1;
            this.spinnerC.Step = 1;
            this.spinnerC.Limits = [0 1];
            this.spinnerC.Enable = 'off';
            this.spinnerC.LowerLimitInclusive = 'on';
            this.spinnerC.UpperLimitInclusive = 'on';
            this.spinnerC.RoundFractionalValues = 'on';
            this.spinnerC.Tooltip = 'column subscript';
            %this.spinnerC.Interruptible = 'off';
            %this.spinnerC.BusyAction = 'queue';
            this.spinnerC.ValueChangingFcn = @(~,evnt) this.SpinnerCcallback(evnt);
            
            % return a handle
            spinner = this.spinnerC;
            
            % Update the Spinner
            this.RefreshSpinners();            
        end
        
        function [gridlayout,checkbox,dropdown,spinnerR,spinnerC] = DropDownCombo(this,uiparent)
            gridlayout = uigridlayout(uiparent);
            gridlayout.RowHeight = {'1x'};
            gridlayout.ColumnWidth = {21,'1x','1x'};
            gridlayout.RowSpacing = 0;
            gridlayout.ColumnSpacing = 0;
            gridlayout.Padding =[0 0 0 0];

            checkbox = uicheckbox(gridlayout, 'Text','', 'Value',1);
            checkbox.Layout.Row = 1;
            checkbox.Layout.Column = 1;
            checkbox.ValueChangedFcn = @checkboxCallback;
            
            dropdown = this.DropDown(gridlayout);
            dropdown.Layout.Row = 1;
            dropdown.Layout.Column = [2 3];
            dropdown.Visible = 'on';
            
            spinnerR = this.SpinnerR(gridlayout);
            spinnerR.Layout.Row = 1;
            spinnerR.Layout.Column = 2;
            spinnerR.Visible = 'off';
            spinnerR.Tooltip = '';
            
            spinnerC = this.SpinnerC(gridlayout);
            spinnerC.Layout.Row = 1;
            spinnerC.Layout.Column = 3;
            spinnerC.Visible = 'off';
            spinnerC.Tooltip = 'subscripts';
            
            function checkboxCallback(~,evnt)
                switch evnt.Value
                    case 0
                        dropdown.Visible = 'off';
                        spinnerR.Visible = 'on';
                        spinnerC.Visible = 'on';
                    case 1
                        dropdown.Visible = 'on';
                        spinnerR.Visible = 'off';
                        spinnerC.Visible = 'off';
                end
            end
        end

        function RefreshMenuItems(this)
            %disp('RefreshMenuItems');          
            % update the Checked status of the menu items
            if isvalid(this.menuitems)
                for indx = 1:numel(this.menuitems)
                    if this.menuitems(indx).UserData == this.itemindx
                        this.menuitems(indx).Checked = 'on';
                    else
                        this.menuitems(indx).Checked = 'off';
                    end
                end
            end
        end
        
        function RefreshDropDown(this)
            %disp('RefreshDropDown');
            if isvalid(this.dropdown)
                this.dropdown.Value = this.itemindx;
            end
            this.RefreshSpinners();
        end
        
        function RefreshSpinners(this)
            %disp('RefreshSpinners');
            [nrows,ncols] = this.vsize();        % size of the current item's value
            [rindx,cindx] = this.subscripts();   % subscripts for the current item

            % Refresh spinnerR (if it exists)
            if isvalid(this.spinnerR)
                if nrows>1
                    this.spinnerR.Limits = [1 nrows];
                    this.spinnerR.Enable = 'on';
                    this.spinnerR.Value = rindx;
                else
                    this.spinnerR.Limits = [0 1];
                    this.spinnerR.Enable = 'off';
                    this.spinnerR.Value = 1;
                end
            end
            
           % Refresh spinnerC (if it exists)
            if isvalid(this.spinnerC)
                if ncols>1
                    this.spinnerC.Limits = [1 ncols];
                    this.spinnerC.Enable = 'on';
                    this.spinnerC.Value = cindx;
                else
                    this.spinnerC.Limits = [0 1];
                    this.spinnerC.Enable = 'off';
                    this.spinnerC.Value = 1;
                end
            end
        end
        
    end
    
    methods (Access=private)
        
        function MenuCallback(this,indx)
            %fprintf('MenuCallback(%d)\n',indx);
            this.itemindx = indx;                               % select the new item
            this.RefreshMenuItems();                            % refresh the menu items
            this.RefreshDropDown();                             % refresh the dropdown/spinners
            notify(this,'SelectionChanged');                    % notify the rest of the world
        end
        
        function DropDownCallback(this,evnt)
            %disp('DropDownCallback');
            this.itemindx = evnt.Value;                         % select the new item
            this.RefreshMenuItems();                            % refresh the menu items
            this.RefreshSpinners();                             % refresh the spinners only
            notify(this,'SelectionChanged');                    % notify the rest of the world
        end

        function SpinnerRcallback(this,evnt)
            %disp('SpinnerRcallback');
            this.itemdata(this.itemindx).rindx = evnt.Value;    % change the current item
            notify(this,'SubscriptChanged');                    % notify the rest of the world
        end
        
        function SpinnerCcallback(this,evnt)
            %disp('SpinnerCcallback');
            this.itemdata(this.itemindx).cindx = evnt.Value;    % change the current item
            notify(this,'SubscriptChanged');                    % notify the rest of the world
        end
             
    end
    
end
