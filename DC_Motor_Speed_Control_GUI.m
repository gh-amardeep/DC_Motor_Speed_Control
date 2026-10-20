function fig = DC_Motor_Speed_Control_GUI()
%DC_MOTOR_SPEED_CONTROL_GUI  Interactive P / PI / PD / PID speed control of a DC motor.
%
%   Run with:   DC_Motor_Speed_Control_GUI
%
%   Model (linearized, constant field):
%       Va = La*di/dt + Ra*i + Ke*w        J*dw/dt + B*w = Kt*i        dtheta/dt = w
%       D(s)     = (La*s + Ra)*(J*s + B) + Kt*Ke
%       P_i(s)   = (J*s + B)/D(s)          P_w(s) = Kt/D(s)          P_theta(s) = Kt/(s*D(s))
%
%   Unity negative feedback on SPEED, error e = w_ref - w, controller output = Va:
%       X(s)/Wref(s) = P_X(s)*C(s) / (1 + P_w(s)*C(s))
%
%   Writing C = Nc/Dc and clearing fractions, the common factor D(s) cancels
%   EXACTLY (done analytically, which is numerically safer than minreal):
%       Dcl(s)        = D(s)*Dc(s) + Kt*Nc(s)        (closed-loop characteristic polynomial)
%       I(s)/Wref(s)  = (J*s + B)*Nc(s) / Dcl(s)
%       W(s)/Wref(s)  =  Kt*Nc(s)       / Dcl(s)
%       Th(s)/Wref(s) =  Kt*Nc(s)       / (s*Dcl(s))
%   These equal P_X*C/(1 + P_w*C) identically.
%
%   NOTE: Kt = Ke = 0.0395 are ILLUSTRATIVE PLACEHOLDER values. Replace them with
%   datasheet values for your motor.
%
%   Requires: MATLAB R2019b or newer (uifigure/uigridlayout/uitable with table data)
%             and the Control System Toolbox (tf, lsim).

% ------------------------------------------------------------------------
% Toolbox check
% ------------------------------------------------------------------------
if ~hasControlToolbox()
    msg = ['The Control System Toolbox is required (functions tf and lsim) ' ...
           'but is not available in this MATLAB installation or license.'];
    tmpFig = uifigure('Name','Control System Toolbox required');
    uialert(tmpFig, msg, 'Toolbox Missing', 'Icon', 'error');
    error('DCMotorGUI:NoToolbox', '%s', msg);
end

% ------------------------------------------------------------------------
% Defaults and constants
% ------------------------------------------------------------------------
DEF.La    = 0.12;       % H
DEF.Ra    = 7;          % Ohm
DEF.J     = 2.12e-6;    % kg.m^2
DEF.B     = 6.04e-6;    % N.m.s/rad
DEF.Kt    = 0.0395;     % N.m/A   (illustrative placeholder)
DEF.Ke    = 0.0395;     % V.s/rad (illustrative placeholder)
DEF.wref  = 10;         % rad/s
DEF.T     = 5;          % s
DEF.names = {'P','PI','PD','PID'};
DEF.gains = [0.05 0    0;       % P   : Kp Ki Kd
             0.05 0.20 0;       % PI
             0.05 0    0.001;   % PD
             0.05 0.20 0.001];  % PID

NPTS = 1001;                    % number of time samples per simulation

COL.bg     = [0.94 0.94 0.94];  % window background
COL.panel  = [0.98 0.98 0.98];  % section background
COL.blue   = [0.00 0.32 0.60];  % blue section headers
COL.ok     = [0.00 0.40 0.10];
COL.warn   = [0.78 0.42 0.00];
COL.err    = [0.75 0.00 0.00];
COL.info   = [0.20 0.20 0.20];

% ------------------------------------------------------------------------
% Build the interface
% ------------------------------------------------------------------------
fig = uifigure('Name','DC Motor Speed Control - P, PI, PD, PID', ...
               'Position',[40 40 1400 850], 'Color',COL.bg);

mainGrid = uigridlayout(fig,[1 2]);
mainGrid.ColumnWidth   = {450,'1x'};
mainGrid.RowHeight     = {'1x'};
mainGrid.Padding       = [8 8 8 8];
mainGrid.ColumnSpacing = 8;
mainGrid.BackgroundColor = COL.bg;

% ---- Left column: simulation settings -----------------------------------
leftGrid = uigridlayout(mainGrid,[6 1]);
leftGrid.Layout.Column = 1;
leftGrid.RowHeight     = {180,104,76,246,120,'1x'};
leftGrid.Padding       = [0 0 0 0];
leftGrid.RowSpacing    = 6;
leftGrid.BackgroundColor = COL.bg;
leftGrid.Scrollable    = 'on';

% A. Motor parameters
motorGrid = createSection(leftGrid,1,'A. Motor parameters', ...
                          {26,26,26,40}, {110,'1x',110,'1x'}, COL);
addLabel(motorGrid,'La [H]',2,1);
edLa = addNumField(motorGrid,DEF.La,2,2,0,Inf,'off');
addLabel(motorGrid,'Ra [Ohm]',2,3);
edRa = addNumField(motorGrid,DEF.Ra,2,4,0,Inf,'off');
addLabel(motorGrid,'J [kg.m^2]',3,1);
edJ  = addNumField(motorGrid,DEF.J,3,2,0,Inf,'off');
addLabel(motorGrid,'B [N.m.s/rad]',3,3);
edB  = addNumField(motorGrid,DEF.B,3,4,0,Inf,'on');
addLabel(motorGrid,'Kt [N.m/A] *',4,1);
edKt = addNumField(motorGrid,DEF.Kt,4,2,0,Inf,'off');
addLabel(motorGrid,'Ke [V.s/rad] *',4,3);
edKe = addNumField(motorGrid,DEF.Ke,4,4,0,Inf,'off');
noteMotor = addLabel(motorGrid,['* Kt and Ke are illustrative placeholder values - ' ...
                                'replace them with your motor''s datasheet values.'],5,1);
noteMotor.Layout.Column = [1 4];
noteMotor.WordWrap = 'on';
noteMotor.FontAngle = 'italic';
noteMotor.FontSize = 11;
noteMotor.FontColor = COL.err;

% B. Reference input
refGrid = createSection(leftGrid,2,'B. Reference input', ...
                        {26,26}, {170,'1x'}, COL);
addLabel(refGrid,'Reference speed [rad/s]',2,1);
edWref = addNumField(refGrid,DEF.wref,2,2,-Inf,Inf,'on');
addLabel(refGrid,'Simulation duration [s]',3,1);
edTsim = addNumField(refGrid,DEF.T,3,2,0,1000,'off');

% C. Controller selection
ctrlGrid = createSection(leftGrid,3,'C. Controller selection', ...
                         {28}, {170,'1x'}, COL);
addLabel(ctrlGrid,'Selected controller',2,1);
ddCtrl = uidropdown(ctrlGrid,'Items',DEF.names,'Value','P','FontSize',12, ...
                    'ValueChangedFcn',@onControllerChanged);
ddCtrl.Layout.Row = 2;  ddCtrl.Layout.Column = 2;

% D. Independent controller gain table
tblGrid = createSection(leftGrid,4,'D. Controller gains (editable)', ...
                        {150,48}, {'1x'}, COL);
tblGains = uitable(tblGrid, ...
                   'Data',makeGainTable(DEF), ...
                   'ColumnEditable',[false true true true], ...
                   'ColumnWidth',{105,100,100,100}, ...
                   'RowName',{}, ...
                   'ColumnSortable',false, ...
                   'FontSize',13, ...
                   'CellEditCallback',@onTableEdited);
tblGains.Layout.Row = 2;
noteTbl = addLabel(tblGrid,['Double-click a cell to edit; press Enter or click another cell ' ...
                            'to commit. Each controller keeps its own gains. Unused gains are ' ...
                            'ignored: P uses Kp; PI uses Kp, Ki; PD uses Kp, Kd; PID uses all.'],3,1);
noteTbl.WordWrap = 'on';
noteTbl.FontSize = 11;
noteTbl.FontColor = [0.3 0.3 0.3];

% Actions
btnGrid = createSection(leftGrid,5,'Actions',{34,34},{'1x','1x'},COL);
btnRun = uibutton(btnGrid,'push','Text','Run Selected Controller', ...
                  'FontSize',13,'FontWeight','bold', ...
                  'BackgroundColor',COL.blue,'FontColor',[1 1 1], ...
                  'ButtonPushedFcn',@(~,~) runSelected(''));
btnRun.Layout.Row = 2;  btnRun.Layout.Column = [1 2];
btnAll = uibutton(btnGrid,'push','Text','Show All Controllers', ...
                  'FontSize',12,'ButtonPushedFcn',@(~,~) runAll());
btnAll.Layout.Row = 3;  btnAll.Layout.Column = 1;
btnReset = uibutton(btnGrid,'push','Text','Reset Defaults', ...
                    'FontSize',12,'ButtonPushedFcn',@onReset);
btnReset.Layout.Row = 3;  btnReset.Layout.Column = 2;

% Status
statGrid = createSection(leftGrid,6,'Status',{'1x'},{'1x'},COL);
statusLabel = uilabel(statGrid,'Text','Ready.','WordWrap','on', ...
                      'VerticalAlignment','top','FontSize',12,'FontColor',COL.info);
statusLabel.Layout.Row = 2;

% ---- Right column: three vertically stacked plots -----------------------
rightGrid = uigridlayout(mainGrid,[3 1]);
rightGrid.Layout.Column = 2;
rightGrid.RowHeight     = {'1x','1x','1x'};
rightGrid.ColumnWidth   = {'1x'};
rightGrid.Padding       = [0 0 0 0];
rightGrid.RowSpacing    = 8;
rightGrid.BackgroundColor = COL.bg;

axI  = uiaxes(rightGrid);  axI.Layout.Row  = 1;
axTh = uiaxes(rightGrid);  axTh.Layout.Row = 2;
axW  = uiaxes(rightGrid);  axW.Layout.Row  = 3;
prepareAxes(axI, 'Armature Current i(t)',   'Current i(t) [A]',            DEF.T,[0 0 0]);
prepareAxes(axTh,'Angular Position \theta(t)','Position \theta(t) [rad]', DEF.T,[0 0 0]);
prepareAxes(axW, 'Angular Speed \omega(t)', 'Speed \omega(t) [rad/s]',    DEF.T,[0 0 0]);

highlightSelectedRow();
drawnow;

% ---- Initial default simulation so all three axes are populated ---------
runSelected('');

% ========================================================================
%                          NESTED CALLBACKS / HELPERS
%   (nested so they share the UI handles defined above)
% ========================================================================

    function onControllerChanged(~,~)
        % Changing the selection NEVER touches the gain table.
        highlightSelectedRow();
        setStatus(sprintf(['%s selected. Gains in the table are unchanged. ' ...
                           'Click "Run Selected Controller" to simulate.'], ddCtrl.Value),'info');
    end

    function onTableEdited(src,evt)
        % Validate the single edited cell; revert it if invalid.
        editRow = evt.Indices(1);
        editCol = evt.Indices(2);
        newVal  = evt.NewData;
        isGood  = isnumeric(newVal) && isscalar(newVal) && isreal(newVal) && ...
                  isfinite(newVal) && newVal >= 0;
        if ~isGood
            curTbl = src.Data;
            curTbl{editRow,editCol} = evt.PreviousData;   % revert only this cell
            src.Data = curTbl;
            colNames = src.Data.Properties.VariableNames;
            msgTxt = sprintf(['Invalid entry for %s of the %s controller. Gains must be ' ...
                              'finite, non-negative numbers. The previous value was restored.'], ...
                             colNames{editCol}, curTbl.Controller{editRow});
            setStatus(msgTxt,'error');
            uialert(fig,msgTxt,'Invalid Gain','Icon','warning');
        end
        drawnow;
    end

    function runSelected(prefixTxt)
        % Simulate the controller chosen in the dropdown and update the plots.
        if nargin < 1, prefixTxt = ''; end
        try
            setStatus('Simulating...','info');
            drawnow;
            mot  = readMotorAndReference();
            nm   = ddCtrl.Value;
            [kp,ki,kd] = readGains(nm);
            validateGains(nm,kp,ki,kd);
            res  = simulateController(nm,mot,kp,ki,kd,NPTS);
            plotSingle(nm,mot,res);
            gTxt = gainString(nm,kp,ki,kd);
            if res.stable
                setStatus(sprintf(['%s%s controller simulated (%s). Closed loop is stable ' ...
                    '(largest pole real part %.4g 1/s).'], prefixTxt, nm, gTxt, res.maxRe),'ok');
            else
                wTxt = sprintf(['%s controller (%s) gives an UNSTABLE closed loop ' ...
                    '(largest pole real part %.4g 1/s). The plotted response is diverging and is ' ...
                    'NOT a successful control result. Reduce the gains.'], nm, gTxt, res.maxRe);
                setStatus(['WARNING: ' wTxt],'warn');
                uialert(fig,wTxt,'Unstable Closed Loop','Icon','warning');
            end
        catch ME
            setStatus(['Error: ' ME.message],'error');
            uialert(fig,ME.message,'Simulation Error','Icon','error');
        end
        drawnow;
    end

    function runAll()
        % Overlay P, PI, PD and PID with identical motor/reference/duration.
        try
            setStatus('Simulating all controllers...','info');
            drawnow;
            mot = readMotorAndReference();
            nCtl = numel(DEF.names);
            results = cell(1,nCtl);
            for idx = 1:nCtl
                nm = DEF.names{idx};
                try
                    [kp,ki,kd] = readGains(nm);
                    validateGains(nm,kp,ki,kd);
                    results{idx} = simulateController(nm,mot,kp,ki,kd,NPTS);
                catch ME2
                    error('DCMotorGUI:SimFailed','%s controller: %s',nm,ME2.message);
                end
            end
            prepareAxes(axI, 'Armature Current i(t) - All Controllers', 'Current i(t) [A]',            mot.T,[0 0 0]);
            prepareAxes(axTh,'Angular Position \theta(t) - All Controllers','Position \theta(t) [rad]', mot.T,[0 0 0]);
            prepareAxes(axW, 'Angular Speed \omega(t) - All Controllers', 'Speed \omega(t) [rad/s]',   mot.T,[0 0 0]);
            unstableList = {};
            for idx = 1:nCtl
                nm = DEF.names{idx};
                r  = results{idx};
                if ~r.stable
                    unstableList{end+1} = nm; %#ok<AGROW>
                    continue;       % unstable responses are not drawn (they would hide the others)
                end
                cc = ctrlColor(nm);
                plot(axI, r.t,r.i, 'Color',cc,'LineWidth',1.8,'DisplayName',nm);
                plot(axTh,r.t,r.th,'Color',cc,'LineWidth',1.8,'DisplayName',nm);
                plot(axW, r.t,r.w, 'Color',cc,'LineWidth',1.8,'DisplayName',nm);
            end
            plot(axW,[0 mot.T],[mot.wref mot.wref],'--','Color',[0.15 0.15 0.15], ...
                 'LineWidth',1.4,'DisplayName','Reference speed');
            legend(axI, 'Location','best');
            legend(axTh,'Location','best');
            legend(axW, 'Location','best');
            if isempty(unstableList)
                setStatus('All four controllers simulated; all closed loops are stable.','ok');
            else
                wTxt = sprintf(['Unstable closed loop for: %s. These controllers are NOT plotted ' ...
                    'because their responses diverge; this is not a successful control result. ' ...
                    'Reduce their gains and run again.'], strjoin(unstableList,', '));
                setStatus(['WARNING: ' wTxt],'warn');
                uialert(fig,wTxt,'Unstable Closed Loop','Icon','warning');
            end
        catch ME
            setStatus(['Error: ' ME.message],'error');
            uialert(fig,ME.message,'Simulation Error','Icon','error');
        end
        drawnow;
    end

    function onReset(~,~)
        % Restore every default (motor, reference, duration, ALL gains, selection = P).
        edLa.Value   = DEF.La;
        edRa.Value   = DEF.Ra;
        edJ.Value    = DEF.J;
        edB.Value    = DEF.B;
        edKt.Value   = DEF.Kt;
        edKe.Value   = DEF.Ke;
        edWref.Value = DEF.wref;
        edTsim.Value = DEF.T;
        tblGains.Data = makeGainTable(DEF);
        ddCtrl.Value  = 'P';
        highlightSelectedRow();
        drawnow;
        runSelected('Defaults restored. ');
    end

    function mot = readMotorAndReference()
        % Always read the CURRENT values of the edit fields.
        mot.La   = edLa.Value;
        mot.Ra   = edRa.Value;
        mot.J    = edJ.Value;
        mot.B    = edB.Value;
        mot.Kt   = edKt.Value;
        mot.Ke   = edKe.Value;
        mot.wref = edWref.Value;
        mot.T    = edTsim.Value;
        validateInputs(mot);
    end

    function [kp,ki,kd] = readGains(nm)
        % Read the LATEST committed gains of controller 'nm' from the table.
        tbl = tblGains.Data;
        if ~istable(tbl)
            error('DCMotorGUI:BadTable','The gain table has an unexpected data type.');
        end
        row = find(strcmp(tbl.Controller,nm),1);
        if isempty(row)
            error('DCMotorGUI:BadTable','Controller "%s" was not found in the gain table.',nm);
        end
        kp = tbl.Kp(row);
        ki = tbl.Ki(row);
        kd = tbl.Kd(row);
    end

    function plotSingle(nm,mot,res)
        cc = ctrlColor(nm);
        if res.stable
            suffix = sprintf(' - %s Controller',nm);
            tc = [0 0 0];
        else
            suffix = sprintf(' - %s Controller (UNSTABLE)',nm);
            tc = COL.err;
        end
        prepareAxes(axI, ['Armature Current i(t)' suffix],  'Current i(t) [A]',            mot.T,tc);
        prepareAxes(axTh,['Angular Position \theta(t)' suffix],'Position \theta(t) [rad]', mot.T,tc);
        prepareAxes(axW, ['Angular Speed \omega(t)' suffix],'Speed \omega(t) [rad/s]',      mot.T,tc);
        plot(axI, res.t,res.i, 'Color',cc,'LineWidth',1.8,'DisplayName',nm);
        plot(axTh,res.t,res.th,'Color',cc,'LineWidth',1.8,'DisplayName',nm);
        plot(axW, res.t,res.w, 'Color',cc,'LineWidth',1.8,'DisplayName',[nm ' speed \omega(t)']);
        plot(axW,[0 mot.T],[mot.wref mot.wref],'--','Color',[0.15 0.15 0.15], ...
             'LineWidth',1.4,'DisplayName','Reference speed');
        legend(axW,'Location','best');
    end

    function highlightSelectedRow()
        % Visually mark the selected controller's row (cosmetic only).
        try
            removeStyle(tblGains);
            selRow = find(strcmp(DEF.names,ddCtrl.Value),1);
            addStyle(tblGains,uistyle('BackgroundColor',[0.80 0.89 1.00], ...
                                      'FontWeight','bold'),'row',selRow);
        catch
            % Styling is optional; ignore if unsupported.
        end
    end

    function setStatus(txt,kind)
        switch kind
            case 'ok',    statusLabel.FontColor = COL.ok;
            case 'warn',  statusLabel.FontColor = COL.warn;
            case 'error', statusLabel.FontColor = COL.err;
            otherwise,    statusLabel.FontColor = COL.info;
        end
        statusLabel.Text = txt;
        drawnow limitrate;
    end

end  % ======================= end of main function =======================


% ========================================================================
%                             LOCAL FUNCTIONS
% ========================================================================

function okFlag = hasControlToolbox()
% True if the Control System Toolbox functions we need are available.
okFlag = false;
try
    okFlag = license('test','Control_System_Toolbox') || license('test','Control_Toolbox');
    okFlag = okFlag && ~isempty(which('tf')) && ~isempty(which('lsim'));
catch
    okFlag = false;
end
end

function g = createSection(parent,row,titleText,rowHeights,colWidths,COL)
% Panel with a blue header bar; returns the inner grid (row 1 = header).
p = uipanel(parent,'BorderType','line','BackgroundColor',COL.panel);
p.Layout.Row = row;
nCols = numel(colWidths);
g = uigridlayout(p,[numel(rowHeights)+1, nCols]);
g.RowHeight       = [{26}, rowHeights];
g.ColumnWidth     = colWidths;
g.Padding         = [6 6 6 6];
g.RowSpacing      = 5;
g.ColumnSpacing   = 6;
g.BackgroundColor = COL.panel;
hdr = uilabel(g,'Text',['  ' titleText],'FontWeight','bold','FontSize',13, ...
              'FontColor',[1 1 1],'BackgroundColor',COL.blue, ...
              'HorizontalAlignment','left');
hdr.Layout.Row = 1;
% A one-column grid requires a scalar column index; [1 1] is invalid.
if nCols > 1
    hdr.Layout.Column = [1 nCols];
else
    hdr.Layout.Column = 1;
end
end

function h = addLabel(parent,txt,row,col)
h = uilabel(parent,'Text',txt,'FontSize',12,'HorizontalAlignment','left');
h.Layout.Row = row;
h.Layout.Column = col;
end

function h = addNumField(parent,val,row,col,lo,hi,loInclusive)
h = uieditfield(parent,'numeric','Value',val,'Limits',[lo hi], ...
                'LowerLimitInclusive',loInclusive, ...
                'ValueDisplayFormat','%.6g','HorizontalAlignment','right','FontSize',12);
h.Layout.Row = row;
h.Layout.Column = col;
end

function T = makeGainTable(DEF)
% Table with columns Controller | Kp | Ki | Kd (one independent row per controller).
T = table(DEF.names(:), DEF.gains(:,1), DEF.gains(:,2), DEF.gains(:,3), ...
          'VariableNames',{'Controller','Kp','Ki','Kd'});
end

function prepareAxes(ax,ttl,ylab,T,ttlColor)
% Clear an existing uiaxes and apply title / labels / grid (no new figures).
try, legend(ax,'off'); catch, end %#ok<NOCOM>
cla(ax);
hold(ax,'on');
grid(ax,'on');
box(ax,'on');
ax.FontSize = 12;
title(ax,ttl,'FontSize',13,'FontWeight','bold','Color',ttlColor);
xlabel(ax,'Time [s]','FontSize',12);
ylabel(ax,ylab,'FontSize',12);
xlim(ax,[0 T]);
ylim(ax,'auto');
end

function c = ctrlColor(nm)
switch nm
    case 'P',   c = [0.000 0.447 0.741];
    case 'PI',  c = [0.850 0.325 0.098];
    case 'PD',  c = [0.466 0.674 0.188];
    case 'PID', c = [0.494 0.184 0.556];
    otherwise,  c = [0 0 0];
end
end

function s = gainString(nm,kp,ki,kd)
switch nm
    case 'P',   s = sprintf('Kp=%.4g',kp);
    case 'PI',  s = sprintf('Kp=%.4g, Ki=%.4g',kp,ki);
    case 'PD',  s = sprintf('Kp=%.4g, Kd=%.4g',kp,kd);
    otherwise,  s = sprintf('Kp=%.4g, Ki=%.4g, Kd=%.4g',kp,ki,kd);
end
end

% ---------------------------- validation --------------------------------

function validateInputs(m)
posFields = {'La','Ra','J','Kt','Ke'};
for k = 1:numel(posFields)
    v = m.(posFields{k});
    if ~(isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && v > 0)
        error('DCMotorGUI:InvalidInput', ...
              'Motor parameter %s must be a finite, real, strictly positive number.',posFields{k});
    end
end
if ~(isnumeric(m.B) && isscalar(m.B) && isreal(m.B) && isfinite(m.B) && m.B >= 0)
    error('DCMotorGUI:InvalidInput', ...
          'Motor parameter B must be a finite, real, non-negative number.');
end
if ~(isnumeric(m.wref) && isscalar(m.wref) && isreal(m.wref) && isfinite(m.wref))
    error('DCMotorGUI:InvalidInput','Reference speed must be a finite real number.');
end
if ~(isnumeric(m.T) && isscalar(m.T) && isreal(m.T) && isfinite(m.T) && m.T > 0 && m.T <= 1000)
    error('DCMotorGUI:InvalidInput', ...
          'Simulation duration must be a finite number in the range (0, 1000] seconds.');
end
end

function validateGains(nm,kp,ki,kd)
gNames = {'Kp','Ki','Kd'};
vals   = {kp,ki,kd};
switch nm
    case 'P',   used = [true false false];
    case 'PI',  used = [true true  false];
    case 'PD',  used = [true false true];
    case 'PID', used = [true true  true];
    otherwise
        error('DCMotorGUI:InvalidInput','Unknown controller "%s".',nm);
end
for k = 1:3
    if used(k)
        v = vals{k};
        if ~(isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && v >= 0)
            error('DCMotorGUI:InvalidInput', ...
                  '%s gain %s must be a finite, non-negative number.',nm,gNames{k});
        end
    end
end
end

% ------------------------- polynomial helpers ----------------------------

function p = trimPoly(p)
% Remove leading zeros (keeps at least one coefficient).
p = p(:).';
k = find(p ~= 0,1,'first');
if isempty(k), p = 0; else, p = p(k:end); end
end

function c = polyAdd(a,b)
% Add polynomials of different degree (descending-power coefficient vectors).
a = a(:).';  b = b(:).';
n = max(numel(a),numel(b));
c = [zeros(1,n-numel(a)) a] + [zeros(1,n-numel(b)) b];
end

function [Nc,Dc] = controllerPolynomials(nm,kp,ki,kd)
% C(s) = Nc(s)/Dc(s) exactly as specified:
%   P  : Kp            PI : Kp + Ki/s = (Kp*s + Ki)/s
%   PD : Kp + Kd*s     PID: Kp + Ki/s + Kd*s = (Kd*s^2 + Kp*s + Ki)/s
% If Ki = 0 the integral term is exactly zero, so the 1/s factor is dropped
% (this is the same transfer function, without a cancelling pole/zero at s = 0).
useInt = ki > 0;
switch nm
    case 'P'
        Nc = kp;            Dc = 1;
    case 'PI'
        if useInt, Nc = [kp ki];     Dc = [1 0]; else, Nc = kp;        Dc = 1; end
    case 'PD'
        Nc = [kd kp];       Dc = 1;
    case 'PID'
        if useInt, Nc = [kd kp ki];  Dc = [1 0]; else, Nc = [kd kp];   Dc = 1; end
    otherwise
        error('DCMotorGUI:InvalidInput','Unknown controller "%s".',nm);
end
Nc = trimPoly(Nc);
end

% ----------------------------- simulation --------------------------------

function sim = simulateController(nm,m,kp,ki,kd,nPts)
% Closed-loop simulation of current, position and speed for one controller.

[Nc,Dc] = controllerPolynomials(nm,kp,ki,kd);

% D(s) = (La*s + Ra)(J*s + B) + Kt*Ke
Dp = conv([m.La m.Ra],[m.J m.B]);
Dp(end) = Dp(end) + m.Kt*m.Ke;

% Closed-loop characteristic polynomial: Dcl = D*Dc + Kt*Nc  (from 1 + P_w*C = 0)
Dcl = trimPoly(polyAdd(conv(Dp,Dc), m.Kt*Nc));

% Stability from closed-loop poles (all must have strictly negative real part).
p = roots(Dcl);
if isempty(p) || any(~isfinite(p))
    error('DCMotorGUI:Numerical','Could not compute closed-loop poles (non-finite values).');
end
tol    = 1e-9*max(1,max(abs(p)));
maxRe  = max(real(p));
stable = all(real(p) < -tol);

% Closed-loop transfer functions  X/Wref = P_X*C/(1 + P_w*C)  (D(s) cancelled exactly)
Ti  = tf(trimPoly(conv([m.J m.B],Nc)), Dcl);      % current  I/Wref
Tw  = tf(trimPoly(m.Kt*Nc),            Dcl);      % speed    W/Wref
Tth = tf(trimPoly(m.Kt*Nc),            [Dcl 0]);  % position Theta/Wref  (extra 1/s)

% Time grid and constant reference-speed input
t = linspace(0,m.T,nPts).';
u = m.wref*ones(size(t));

try
    yi  = lsim(Ti, u,t,'zoh');
    yw  = lsim(Tw, u,t,'zoh');
    yth = lsim(Tth,u,t,'zoh');
catch ME
    error('DCMotorGUI:SimFailed','lsim failed: %s',ME.message);
end

if ~(all(isfinite(yi)) && all(isfinite(yw)) && all(isfinite(yth)))
    error('DCMotorGUI:Numerical', ...
          ['The simulation produced non-finite values (overflow or numerical failure). ' ...
           'Check the parameters and reduce the controller gains.']);
end

sim.t = t;   sim.i = yi;   sim.w = yw;   sim.th = yth;
sim.poles = p;   sim.maxRe = maxRe;   sim.stable = stable;
end
