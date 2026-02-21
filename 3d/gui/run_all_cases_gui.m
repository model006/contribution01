function run_all_cases_gui()
%RUN_ALL_CASES_GUI Richards 3D-Professional Launcher Interface (uifigure)
%   This function creates the main graphical user interface for configuring
%   and launching Richards 3D simulations. It provides an intuitive interface
%   for setting up both physical cases and numerical validation studies.
%
%   KEY FEATURES:
%      -Auto-jump from vector fields after first number (Space or Enter)
%      -Hide/Show Physical/Validation panels with automatic layout collapse
%      -Real-time input validation with visual feedback 
%      -Visual chips displaying parsed vector values
%      -Interactive run log and results summary tabs
%      -Direct integration with main.m execution engine
%      -Live progress monitor with animated progress bar
%      -Integrated visualization with scrollable figure panels
%      -Dedicated tabs for CPU, iteration, conditioning, and cross-section plots
%
%   INTERFACE STRUCTURE:
%       Left panel (3 sections):
%           - Case type selection (Physical/Validation)
%           - Physical case parameters (collapsible)
%           - Validation case parameters (collapsible)
%       Right panel:
%           - Header with run button and status
%           - Tab group with 5 tabs:
%               * Run log: Real-time execution output
%               * Results summary: Text summary of last run
%               * visualization 1: CPU time and iteration plots
%               * visualization 2: Conditioning number plots
%               * visualization 3: Physical case cross-sections
%               * visualization 4: Reserved for future use
%       Bottom monitor:
%           - Live progress bar
%           - Real-time status messages
%
%   INPUT VALIDATION:
%       - Numeric vectors: parsed with auto-jump after first value
%       - Range checking: L values between 0 and 1, time steps positive
%       - Visual feedback: green checkmark for valid, red cross for invalid
%       - Chip display: shows parsed vector values as interactive chips
%
%   DEPENDENCIES:
%       - main.m in project root directory
%       - Proper directory structure with src/, FEM/, models/, solvers/
%       - Visualization functions for plots and cross-sections
%

%   See also: MAIN, BATCH_VIEW_RULES_BAT, PHYSICAL_CASE_T10_ONLY

    close all;

    % Locate main.m in the parent directory (project root)
    baseDir = fileparts(mfilename('fullpath'));     % gui/
    rootDir = fileparts(baseDir);                   % parent directory (root)
    mainScript = fullfile(rootDir,'main.m');       % main.m at root

    if exist(mainScript,'file') ~= 2
        uialert(uifigure,...
            sprintf('main.m not found at:\n%s\nPlease check project structure.',mainScript),...
            'Missing file');
        return;
    end

    % ========================= THEME =========================
    bg      = [1 1 1];
    fg      = [0.10 0.10 0.10];
    sub     = [0.35 0.35 0.35];
    accent  = [0.00 0.45 0.74];
    success = [0.16 0.58 0.18];
    errorC  = [0.78 0.20 0.20];
    lineCol = [0.88 0.88 0.88];
    chipBg  = [0.965 0.965 0.965];
    monitorBg = [0.97 0.97 0.98];
    progressBarBg = [0.88 0.88 0.90];
    progressBarFill = [0.35 0.35 0.38];

    % ========================= WINDOW =========================
    fig = uifigure( ...
        'Name','Launcher: Richards 3D',...
        'Color',bg,...
        'Position',[200 80 1200 860],... % Increased width for visualization
        'Resize','on');
    try,fig.FontName = 'Segoe UI'; catch,end

    % --- key handler for vector auto-jump
    fig.WindowKeyPressFcn = @onWindowKeyPress;

    % Main layout-now 2 rows (top content + bottom monitor)
    root = uigridlayout(fig,[2 1]);
    root.RowHeight     = {'1x',240};  % 240px for monitor
    root.Padding       = [20 20 20 20];
    root.RowSpacing    = 15;

    % ========================= TOP CONTENT =========================
    topContent = uigridlayout(root,[1 2]);
    topContent.Layout.Row = 1;
    topContent.ColumnWidth     = {450,'1x'};
    topContent.Padding         = [0 0 0 0];
    topContent.ColumnSpacing   = 20;

    % ========================= LEFT =========================
    left = uigridlayout(topContent,[3 1]);
    left.Layout.Row = 1;
    left.Layout.Column = 1;

    % (we will dynamically update these heights when toggling)
    H_cases = 120;
    H_phys  = 270;
    H_val   = 370;

    left.RowHeight       = {H_cases,H_phys,'1x'};
    left.Padding         = [0 0 0 0];
    left.RowSpacing      = 12;

    % ========================= RIGHT =========================
    right = uigridlayout(topContent,[3 1]);
    right.RowHeight      = {165,'1x',72};
    right.Padding        = [0 0 0 0];
    right.RowSpacing     = 12;

    % ===================== RIGHT: TABS =========================
    tabs = uitabgroup(right);
    tabs.Layout.Row = 2;

    tabLog = uitab(tabs,'Title','Run log');
    tabSum = uitab(tabs,'Title','Results summary');
    tabVis1 = uitab(tabs,'Title','visualization 1');  % CPU + Iterations
    tabVis2 = uitab(tabs,'Title','visualization 2');  % Conditioning
    tabVis3 = uitab(tabs,'Title','visualization 3');  % Physical cross-sections
    tabVis4 = uitab(tabs,'Title','visualization 4');  % (EMPTY - reserved)

    % ========================= HEADER =========================
    header = makePanel(right,1,'Run configuration',fg,bg,lineCol);
    headerGrid = uigridlayout(header,[4 1]);
    headerGrid.RowHeight = {48,22,22,'1x'};
    headerGrid.Padding   = [16 12 16 10];

   
        uilabel(headerGrid,...
        'Text',sprintf(['Coupled Richards Equation in Deformable Porous Media']),...
        'FontSize',18,...
        'FontWeight','bold',...
        'FontColor',fg);

    uilabel(headerGrid,'Text','',...
        'FontSize',11,'FontColor',sub);
    uilabel(headerGrid,'Text','Set simulation parameters (physical time in hours), then click RUN.',...
        'FontSize',11,'FontColor',fg);
    uilabel(headerGrid,'Text',sprintf('main.m: %s',mainScript),...
        'FontSize',9,'FontColor',sub,'FontAngle','italic');

    % ===================== CASES (checkboxes only) =====================
    pCases = makePanel(left,1,'Cases',fg,bg,lineCol);

    gCases = uigridlayout(pCases,[1 2]);
    gCases.Padding        = [16 12 16 12];
    gCases.RowHeight      = {28};
    gCases.ColumnWidth    = {'1x','1x'};
    gCases.ColumnSpacing  = 18;

    cbPhysical = uicheckbox(gCases,'Text','Reference physical simulation','Value',true,...
        'FontSize',12,'FontColor',fg,...
        'ValueChangedFcn',@refreshEnable,...
        'Tooltip','Run Reference physical simulation (single Nx).');
    cbPhysical.Layout.Row = 1; cbPhysical.Layout.Column = 1;

    cbValidation = uicheckbox(gCases,'Text','Numerical validation','Value',true,...
        'FontSize',12,'FontColor',fg,...
        'ValueChangedFcn',@refreshEnable,...
        'Tooltip','Run validation (Nx_list + L_vec).');
    cbValidation.Layout.Row = 1; cbValidation.Layout.Column = 2;

    % ===================== Reference physical simulation PANEL =====================
    pPhys = makePanel(left,2,'Reference physical simulation',fg,bg,lineCol);

    gPhys = uigridlayout(pPhys,[7 2]);
    gPhys.Padding       = [16 12 16 12];
    gPhys.ColumnWidth   = {190,170};
    gPhys.RowHeight     = {24,30,22,26,22,26,34};
    gPhys.RowSpacing    = 8;
    gPhys.ColumnSpacing = 10;

    % Mode
    uilabel(gPhys,'Text','Vertisol mode','FontColor',fg,'FontSize',12,'FontWeight','bold');
    ddMode = uidropdown(gPhys,...
        'Items',{'deformable','non_deformable'},...
        'Value','deformable',...
        'FontSize',12,...
        'Tooltip','deformable: coupled hydromechanical | non_deformable: flow only');

    % Mesh Nx
    uilabel(gPhys,'Text','Spatial discretization level','FontColor',fg,'FontSize',12,'FontWeight','bold');

    nxPhysContainer = uigridlayout(gPhys,[1 2]);
    nxPhysContainer.ColumnWidth     = {50,24};
    nxPhysContainer.Padding         = [0 0 0 0];
    nxPhysContainer.ColumnSpacing   = 6;

    edNxPhys = uieditfield(nxPhysContainer,'text','Value','17','FontSize',12,...
        'FontName','Consolas',...
        'Tooltip','Integer Nx e 3');
    edNxPhys.ValueChangedFcn = @validateAll;

    nxPhysValid = uilabel(nxPhysContainer,'Text','',...
        'FontSize',15,'FontColor',success,...
        'HorizontalAlignment','center');

    % h label
    hLabel = uilabel(gPhys,'Text','h = 1/(Nx-1)',...
        'FontColor',sub,'FontSize',12,'FontAngle','italic');
    hLabel.Layout.Row = 3; hLabel.Layout.Column = [1 2];

    % dt0 phys
    uilabel(gPhys,'Text','Time step (physical) (dt) [h]','FontColor',fg,'FontSize',12,'FontWeight','bold');
    edDt0Phys = uieditfield(gPhys,'numeric',...
        'Value',0.25,'LowerLimit',eps,'FontSize',12,...
        'Tooltip','Initial time step for the physical case (hours).');

    % T_final phys
    uilabel(gPhys,'Text','Final time T (physical) [h]','FontColor',fg,'FontSize',12,'FontWeight','bold');
    edTfPhys = uieditfield(gPhys,'numeric',...
        'Value',8,'LowerLimit',eps,'FontSize',12,...
        'Tooltip','Final simulation time for the physical case (hours).');

    % L_scalar phys
    uilabel(gPhys,'Text','L (L-scheme parameter)','FontColor',fg,'FontSize',12,'FontWeight','bold');
    ss = get(0,'ScreenSize');

    w = 0.59*ss(3);
    h = 0.92*ss(4);

    x = (ss(3)-w) / 2;
    y = (ss(4)-h) / 2;

    fig.Position = [x y w h];

    LscalarContainer = uigridlayout(gPhys,[1 2]);
    LscalarContainer.ColumnWidth     = {'1x',24};
    LscalarContainer.Padding         = [0 0 0 0];
    LscalarContainer.ColumnSpacing   = 6;

    edLscalar = uieditfield(LscalarContainer,'numeric',...
        'Value',3.01e-3,'LowerLimit',0,'FontSize',12,...
        'Tooltip','L parameter for physical case (scalar e 0)');
    edLscalar.ValueChangedFcn = @validateAll;

    LscalarValid = uilabel(LscalarContainer,'Text','',...
        'FontSize',15,'FontColor',success,...
        'HorizontalAlignment','center');

    % --- Physical chips (summary of scalars) ---
    physPreviewHost = uipanel(gPhys,'BackgroundColor',bg,'BorderType','none');
    physPreviewHost.Layout.Row = 7;
    physPreviewHost.Layout.Column = [1 2];

    physPreviewGrid = uigridlayout(physPreviewHost,[1 4]);
    physPreviewGrid.Padding       = [0 0 0 0];
    physPreviewGrid.ColumnSpacing = 8;
    physPreviewGrid.RowHeight     = 30;

    % ===================== NUMERICAL VALIDATION PANEL =====================
    pVal = makePanel(left,3,'Numerical validation',fg,bg,lineCol);

    gVal = uigridlayout(pVal,[8 2]);
    gVal.Padding       = [16 12 16 12];
    gVal.ColumnWidth   = {190,'1x'};
    gVal.RowHeight     = {24,30,34,24,30,24,30,34};
    gVal.RowSpacing    = 8;
    gVal.ColumnSpacing = 10;

    % Nx_list
    uilabel(gVal,'Text','Spatial discretization levels (Nx)','FontColor',fg,'FontSize',12,'FontWeight','bold');

    % Main container for the edit box AND the label
    nxMainContainer = uigridlayout(gVal,[1 2]);
    nxMainContainer.ColumnWidth     = {100,'fit'};
    nxMainContainer.Padding         = [0 0 0 0];
    nxMainContainer.ColumnSpacing   = 10;

    % Sub-container for the edit box and validator
    nxEditContainer = uigridlayout(nxMainContainer,[1 2]);
    nxEditContainer.ColumnWidth     = {'1x',24};
    nxEditContainer.Padding         = [0 0 0 0];
    nxEditContainer.ColumnSpacing   = 6;

    edNxListVal = uieditfield(nxEditContainer,'text','Value','5 9 17',...
        'FontSize',12,'FontName','Consolas',...
        'Tooltip','Space-separated integers, e.g. 5 9 17 33');
    edNxListVal.ValueChangedFcn = @validateAll;

    nxListValid = uilabel(nxEditContainer,'Text','',...
        'FontSize',15,'FontColor',success,...
        'HorizontalAlignment','center');

    % Label "Nx values (coarse → fine)" on the side
    nxHintLabel = uilabel(nxMainContainer,'Text','Nx(coarse → fine)',...
        'FontSize',10,...
        'FontColor',sub,...
        'FontAngle','italic',...
        'HorizontalAlignment','left');

    % Nx chips
    nxPreviewHost = uipanel(gVal,'BackgroundColor',bg,'BorderType','none');
    nxPreviewHost.Layout.Row = 3;
    nxPreviewHost.Layout.Column = [1 2];
    nxPreviewGrid = uigridlayout(nxPreviewHost,[1 1]);
    nxPreviewGrid.Padding = [0 0 0 0];

    % dt0 validation
    uilabel(gVal,'Text','Time step (validation) (dt)','FontColor',fg,'FontSize',12,'FontWeight','bold');
    edDt0 = uieditfield(gVal,'numeric','Value',0.025,'LowerLimit',eps,'FontSize',12,...
        'Tooltip','Initial time step for numerical validation (hours).');

    % t_final validation
    uilabel(gVal,'Text','Final time T (validation)','FontColor',fg,'FontSize',12,'FontWeight','bold');
    edTf  = uieditfield(gVal,'numeric','Value',0.5,'LowerLimit',eps,'FontSize',12,...
        'Tooltip','Final time for numerical validation (hours).');

    % L_vec validation
    uilabel(gVal,'Text','L value [vector] (validation)','FontColor',fg,'FontSize',12,'FontWeight','bold');

    LvecContainer = uigridlayout(gVal,[1 2]);
    LvecContainer.ColumnWidth     = {'1x',24};
    LvecContainer.Padding         = [0 0 0 0];
    LvecContainer.ColumnSpacing   = 6;

    edLvec = uieditfield(LvecContainer,'text','Value','0.15 0.25',...
        'FontSize',12,'FontName','Consolas',...
        'Tooltip','Space-separated numbers, e.g. 0.15 0.25 0.65 1');
    edLvec.ValueChangedFcn = @validateAll;

    LvecValid = uilabel(LvecContainer,'Text','',...
        'FontSize',15,'FontColor',success,...
        'HorizontalAlignment','center');

    % L chips
    LPreviewHost = uipanel(gVal,'BackgroundColor',bg,'BorderType','none');
    LPreviewHost.Layout.Row = 7;
    LPreviewHost.Layout.Column = [1 2];
    LPreviewGrid = uigridlayout(LPreviewHost,[1 1]);
    LPreviewGrid.Padding = [0 0 0 0]; 

    % ===================== RUN LOG TAB =========================
    glog = uigridlayout(tabLog,[1 1]);
    glog.Padding = [12 12 12 12];
    logArea = uitextarea(glog,'Editable','off','FontName','Consolas','FontSize',11,...
        'Value',{ ...
            '" This launcher injects variables in the BASE workspace, then runs main.m.'; ...
            '" After RUN, click VIEW RESULTS.' ...
        });


% ===================== RESULTS SUMMARY TAB =========================
    gsum = uigridlayout(tabSum,[2 1]);
    gsum.RowHeight = {22,'1x'};
    gsum.Padding = [12 12 12 12];

    uilabel(gsum,'Text','Simulation summary (updated after RUN)',...
        'FontColor',sub,'FontSize',11,'FontAngle','italic');

    sumArea = uitextarea(gsum,'Editable','off','FontName','Consolas','FontSize',11,...
        'Value',{' '});

    % ===================== VISUALIZATION TAB 1 (CPU + Iterations) =========================
    visTab1 = tabVis1;
    
    % Main grid for visualization tab 1
    visMainGrid1 = uigridlayout(visTab1, [2, 1]);
    visMainGrid1.RowHeight = {'1x', 60};
    visMainGrid1.Padding = [10 10 10 10];
    visMainGrid1.RowSpacing = 10;
    
    % Panel for plots (scrollable)
    visPlotPanel1 = uipanel(visMainGrid1, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Performance Metrics', ...
        'FontSize', 12, 'FontWeight', 'bold', 'Scrollable', 'on');
    
    % Grid to organize plots (2 columns)
    visGrid1 = uigridlayout(visPlotPanel1, [1, 2]);
    visGrid1.RowHeight = {280};
    visGrid1.ColumnWidth = {'1x', '1x'};
    visGrid1.Padding = [10 10 10 10];
    visGrid1.RowSpacing = 15;
    visGrid1.ColumnSpacing = 15;
    
    % CPU Time
    cpuPanel = uipanel(visGrid1, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'CPU Time Comparison', ...
        'FontSize', 11, 'FontWeight', 'bold');
    cpuAxes = axes('Parent', cpuPanel, 'Units', 'normalized', ...
        'Position', [0.15 0.2 0.75 0.7]);
    title(cpuAxes, 'CPU Time', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(cpuAxes, '1/h', 'FontSize', 10);
    ylabel(cpuAxes, 'Time (s)', 'FontSize', 10);
    set(cpuAxes, 'YScale', 'log', 'FontSize', 9, 'Box', 'on');
    
    % Iterations
    iterPanel = uipanel(visGrid1, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Iterations Comparison', ...
        'FontSize', 11, 'FontWeight', 'bold');
    iterAxes = axes('Parent', iterPanel, 'Units', 'normalized', ...
        'Position', [0.15 0.2 0.75 0.7]);
    title(iterAxes, 'Iterations', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(iterAxes, '1/h', 'FontSize', 10);
    ylabel(iterAxes, 'Iterations', 'FontSize', 10);
    set(iterAxes, 'FontSize', 9, 'Box', 'on');
    
    % === BOTTOM CONTROL PANEL ===
    visControlPanel1 = uipanel(visMainGrid1, 'BackgroundColor', [0.95 0.98 1.00], ...
        'BorderType', 'line', 'Title', 'Controls - Performance Metrics', ...
        'FontSize', 12, 'FontWeight', 'bold');
    
    controlGrid1 = uigridlayout(visControlPanel1, [1, 5]);
    controlGrid1.ColumnWidth = {'1x', 150, 150, 150, '1x'};
    controlGrid1.Padding = [10 5 10 5];
    
    uilabel(controlGrid1, 'Text', '');
    
    btnLoadVis1 = uibutton(controlGrid1, 'push', ...
        'Text', 'Load Data', ...
        'BackgroundColor', accent, ...
        'FontColor', [1 1 1], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) loadVisualisationData());
    
    btnRefreshVis1 = uibutton(controlGrid1, 'push', ...
        'Text', 'Refresh', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) refreshVisualisation());
    
    btnExportVis1 = uibutton(controlGrid1, 'push', ...
        'Text', 'Export', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) exportVisualisation());
    
    uilabel(controlGrid1, 'Text', '');

    % ===================== VISUALIZATION TAB 2 (Conditioning) =========================
    visTab2 = tabVis2;

    % Main grid - same as Vis 1
    visMainGrid2 = uigridlayout(visTab2, [2, 1]);
    visMainGrid2.RowHeight = {'1x', 60};  % Same height
    visMainGrid2.Padding = [10 10 10 10];
    visMainGrid2.RowSpacing = 10;

    % Panel for plot - SAME TITLE and style
    visPlotPanel2 = uipanel(visMainGrid2, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Conditioning Analysis', ...
        'FontSize', 12, 'FontWeight', 'bold', 'Scrollable', 'on');

    % Grid for centering - SINGLE COLUMN like Vis 1
    visGrid2 = uigridlayout(visPlotPanel2, [1, 1]);  % Single column
    visGrid2.Padding = [10 10 10 10];

    % Conditioning panel - same dimensions as cpuPanel
    condPanel = uipanel(visGrid2, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Condition Number', ...
        'FontSize', 11, 'FontWeight', 'bold');

    % Axes - SAME POSITION as cpuAxes
    condAxes = axes('Parent', condPanel, 'Units', 'normalized', ...
        'Position', [0.15 0.2 0.75 0.7]);  
    title(condAxes, 'Condition Number', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(condAxes, '1/h', 'FontSize', 10);
    ylabel(condAxes, 'Condition', 'FontSize', 10);
    set(condAxes, 'YScale', 'log', 'FontSize', 9, 'Box', 'on');

    % === BOTTOM CONTROL PANEL - SAME as Vis 1 ===
    visControlPanel2 = uipanel(visMainGrid2, 'BackgroundColor', [0.95 0.98 1.00], ...
        'BorderType', 'line', 'Title', 'Controls - Conditioning', ...
        'FontSize', 12, 'FontWeight', 'bold');

    controlGrid2 = uigridlayout(visControlPanel2, [1, 5]); 
    controlGrid2.ColumnWidth = {'1x', 150, 150, 150, '1x'};
    controlGrid2.Padding = [10 5 10 5];

    uilabel(controlGrid2, 'Text', '');

    btnLoadVis2 = uibutton(controlGrid2, 'push', ...
        'Text', 'Load Data', ...
        'BackgroundColor', accent, ...
        'FontColor', [1 1 1], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) loadVisualisationData());

    btnRefreshVis2 = uibutton(controlGrid2, 'push', ...
        'Text', 'Refresh', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) refreshVisualisation());

    btnExportVis2 = uibutton(controlGrid2, 'push', ...
        'Text', 'Export', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) exportVisualisation());

    uilabel(controlGrid2, 'Text', '');
    
    % ===================== VISUALIZATION TAB 3 (Cross-section + Isosurface) =========================
    visTab3 = tabVis3;

    % Main grid - same as Vis 1
    visMainGrid3 = uigridlayout(visTab3, [2, 1]);
    visMainGrid3.RowHeight = {'1x', 80};
    visMainGrid3.Padding = [10 10 10 10];
    visMainGrid3.RowSpacing = 10;

    % Panel for plots (scrollable)
    visPlotPanel3 = uipanel(visMainGrid3, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Physical Case Visualizations', ...
        'FontSize', 12, 'FontWeight', 'bold', 'Scrollable', 'on');

    % Grid to organize plots (2 columns)
    visGrid3 = uigridlayout(visPlotPanel3, [1, 2]);
    visGrid3.RowHeight = {280};
    visGrid3.ColumnWidth = {'1x', '1x'};
    visGrid3.Padding = [10 10 10 10];
    visGrid3.RowSpacing = 15;
    visGrid3.ColumnSpacing = 15;

    % Panel for cross-section (left)
    sectionPanel = uipanel(visGrid3, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Cross-section', ...
        'FontSize', 11, 'FontWeight', 'bold');

    % CREATE sectionAxes HERE
    sectionAxes = axes('Parent', sectionPanel, 'Units', 'normalized', ...
        'Position', [0.12 0.17 0.75 0.6]);
    title(sectionAxes, '', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(sectionAxes, 'y', 'FontSize', 10);
    ylabel(sectionAxes, 'z', 'FontSize', 10);
    set(sectionAxes, 'FontSize', 9, 'Box', 'on');

    % Panel for isosurface (right)
    isoPanel = uipanel(visGrid3, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Isosurface', ...
        'FontSize', 11, 'FontWeight', 'bold');

    % CREATE isoAxes HERE
    isoAxes = axes('Parent', isoPanel, 'Units', 'normalized', ...
        'Position', [0.15 0.2 0.75 0.7]);
    title(isoAxes, '', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(isoAxes, 'x', 'FontSize', 10);
    ylabel(isoAxes, 'y', 'FontSize', 10);
    zlabel(isoAxes, 'z', 'FontSize', 10);
    set(isoAxes, 'FontSize', 9, 'Box', 'on');
    view(isoAxes, 45, 30);

    % === BOTTOM CONTROL PANEL ===
    visControlPanel3 = uipanel(visMainGrid3, 'BackgroundColor', [0.95 0.98 1.00], ...
        'BorderType', 'line', 'Title', 'Controls - Physical Case', ...
        'FontSize', 12, 'FontWeight', 'bold');

    % Grid with 9 columns for controls
    controlGrid3 = uigridlayout(visControlPanel3, [1, 9]);
    controlGrid3.ColumnWidth = {'1x', 140, 100, 80, 100, 80, 100, 80, '1x'};
    controlGrid3.Padding = [10 5 10 5];

    uilabel(controlGrid3, 'Text', '');

    % Load Data button
    btnLoadVis3 = uibutton(controlGrid3, 'push', ...
        'Text', 'Load Physical Data', ...
        'BackgroundColor', accent, ...
        'FontColor', [1 1 1], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) loadPhysicalCrossSectionData());

    % Time selector
    uilabel(controlGrid3, 'Text', 'Time (h):', 'FontSize', 11, 'FontWeight', 'bold');
    popupTime = uidropdown(controlGrid3, ...
        'Items', {'Select time...'}, ...
        'Value', 'Select time...', ...
        'FontSize', 11);

    % Plane selector for cross-section
    uilabel(controlGrid3, 'Text', 'Plane:', 'FontSize', 11, 'FontWeight', 'bold');
    popupPlane = uidropdown(controlGrid3, ...
        'Items', {'x = constant', 'y = constant', 'z = constant'}, ...
        'Value', 'x = constant', ...
        'FontSize', 11);

    uilabel(controlGrid3, 'Text', 'Value:', 'FontSize', 11, 'FontWeight', 'bold');
    editValue = uieditfield(controlGrid3, 'numeric', ...
        'Value', 0.5, 'Limits', [0 1], ...
        'FontSize', 11, 'HorizontalAlignment', 'center');

    % Isosurface value
    uilabel(controlGrid3, 'Text', 'Iso:', 'FontSize', 11, 'FontWeight', 'bold');
    editIsoValue = uieditfield(controlGrid3, 'numeric', ...
        'Value', 0.5, 'Limits', [0 1], ...
        'FontSize', 11, 'HorizontalAlignment', 'center');

    % Update button
    btnUpdateVis3 = uibutton(controlGrid3, 'push', ...
        'Text', 'Update', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) updatePhysicalVisualizations());

    uilabel(controlGrid3, 'Text', '');



% ===================== VISUALIZATION TAB 4 (Convergence Table) =========================
visTab4 = tabVis4;

% Main grid - same as Vis 1
visMainGrid4 = uigridlayout(visTab4, [2, 1]);
visMainGrid4.RowHeight = {'1x', 60};
visMainGrid4.Padding = [10 10 10 10];
visMainGrid4.RowSpacing = 10;

% Panel for table (scrollable)
visPlotPanel4 = uipanel(visMainGrid4, 'BackgroundColor', [1 1 1], ...
    'BorderType', 'line', 'Title', 'Convergence Analysis', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Scrollable', 'on');

% Grid to center the table
visGrid4 = uigridlayout(visPlotPanel4, [1, 1]);
visGrid4.RowHeight = {400};  % Fixed height
visGrid4.Padding = [10 10 10 10];

% Panel for table
tablePanel = uipanel(visGrid4, 'BackgroundColor', [1 1 1], ...
    'BorderType', 'line', 'Title', 'Error Analysis', ...
    'FontSize', 11, 'FontWeight', 'bold');

% Create uitable with all columns - COMPACT FORMAT
convTable = uitable(tablePanel, 'Units', 'normalized', ...
    'Position', [0.02 0.08 0.96 0.85], ...  % More space at top (0.08)
    'ColumnName', {'h', 'L2 Error', 'H1 Error', 'κ_{max}', 'CPU (s)', 'Iter', 'Order'}, ...
    'ColumnWidth', {70, 85, 85, 70, 70, 50, 60}, ...  % Reduced widths
    'FontSize', 11, ...  % Slightly smaller font
    'FontWeight', 'bold');

% === BOTTOM CONTROL PANEL ===
visControlPanel4 = uipanel(visMainGrid4, 'BackgroundColor', [0.95 0.98 0.7], ...
    'BorderType', 'line', 'Title', 'Controls - Convergence Table', ...
    'FontSize', 12, 'FontWeight', 'bold');
visMainGrid4.RowHeight = {280, 80}; 

controlGrid4 = uigridlayout(visControlPanel4, [1, 5]);
controlGrid4.ColumnWidth = {'1x', 200, 25, 125, '1x'};  % Smaller columns
controlGrid4.Padding = [10 10 10 10];  % Reduced padding
controlGrid4.RowHeight = {30};
uilabel(controlGrid4, 'Text', '');

% Load Data button
btnLoadVis4 = uibutton(controlGrid4, 'push', ...
    'Text', 'Load Data', ...  % Shorter text
    'BackgroundColor', accent, ...
    'FontColor', [1 1 1], ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'ButtonPushedFcn', @(btn,~) loadValidationData());

% L value selector
uilabel(controlGrid4, 'Text', 'L:', 'FontSize', 11, 'FontWeight', 'bold');  % Shorter
popupLVal = uidropdown(controlGrid4, ...
    'Items', {'Select...'}, ...  % Shorter
    'Value', 'Select...', ...
    'FontSize', 11);

% Refresh button
btnRefreshVis4 = uibutton(controlGrid4, 'push', ...
    'Text', 'Refresh', ...
    'BackgroundColor', [0.9 0.9 0.9], ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'ButtonPushedFcn', @(btn,~) updateConvergenceTables());

uilabel(controlGrid4, 'Text', '');

% Store all axes in a structure
visAxes = struct();
visAxes.cpu = cpuAxes;
visAxes.iter = iterAxes;
visAxes.cond = condAxes;
visAxes.section = sectionAxes;
visAxes.iso = isoAxes;
visAxes.convTable = convTable;
visAxes.popupLVal = popupLVal;    
visAxes.fig = fig;
visAxes.donnees = [];
visAxes.noms = [];

% Store controls for cross-section
visAxes.popupPlane = popupPlane;
visAxes.editValue = editValue;
visAxes.popupTime = popupTime;
visAxes.editIsoValue = editIsoValue;

% Data for physical visualizations
visAxes.physData = struct();
visAxes.physData.times = [];
visAxes.physData.time_strings = {};
visAxes.physData.nx = [];
visAxes.physData.sol_dir = '';
visAxes.physData.hasData = false;

setappdata(fig, 'visAxes', visAxes);

% ===================== BUTTONS =============================
btns = uigridlayout(right,[1 3]);
btns.Layout.Row     = 3;
btns.ColumnWidth    = {'1x','1x','1x'};
btns.ColumnSpacing  = 12;
btns.Padding        = [0 0 0 0];

bRun = uibutton(btns,'push',...
    'Text','  RUN',...
    'FontSize',14,...
    'FontWeight','bold',...
    'BackgroundColor',accent,...
    'FontColor',[1 1 1],...
    'ButtonPushedFcn',@onRun);

bView = uibutton(btns,'push',...
    'Text',' VIEW RESULTS',...
    'FontSize',13,...
    'Enable','off',...
    'ButtonPushedFcn',@onView);

bClose = uibutton(btns,'push','Text','CLOSE',...
    'FontSize',13,...
    'ButtonPushedFcn',@(~,~) close(fig));

% ===================== LIVE MONITOR PANEL =====================
monitor_panel = uipanel('Parent',root,'Units','pixels',...
                        'Title',' LIVE MONITOR ',...
                        'FontSize',11,'FontWeight','bold',...
                        'BackgroundColor',monitorBg,...
                        'ForegroundColor',fg,...
                        'BorderType','line',...
                        'HighlightColor',lineCol);
monitor_panel.Layout.Row = 2;

% Create log box
log_box = uicontrol('Parent',monitor_panel,'Style','listbox','Units','pixels',...
                    'BackgroundColor',[1 1 1],...
                    'FontName','Consolas',...
                    'FontSize',9,...
                    'Max',2,'Min',0,...
                    'String',{'--- Live log ---'});

% Progress bar frame
progress_frame = uicontrol('Parent',monitor_panel,'Style','text','Units','pixels',...
                          'BackgroundColor',progressBarBg,...
                          'HorizontalAlignment','left',...
                          'String','');

% Progress bar fill (moving block)
progress_fill = uicontrol('Parent',monitor_panel,'Style','text','Units','pixels',...
                          'BackgroundColor',progressBarFill,...
                          'HorizontalAlignment','left',...
                          'String','');

% Status text
status_text = uicontrol('Parent',monitor_panel,'Style','text','Units','pixels',...
                        'BackgroundColor',monitorBg,...
                        'ForegroundColor',fg,...
                        'HorizontalAlignment','left',...
                        'String','Status: idle');

% Store handles for monitor controls
monitor_handles = struct();
monitor_handles.log_box = log_box;
monitor_handles.progress_frame = progress_frame;
monitor_handles.progress_fill = progress_fill;
monitor_handles.status_text = status_text;

% Timer for animated progress bar
monitor_timer = [];
diary_file = '';

% Store monitor handles in appdata
setappdata(fig,'monitor_handles',monitor_handles);
setappdata(fig,'monitor_timer',monitor_timer);
setappdata(fig,'diary_file',diary_file);

% Initial update
validateAll();
refreshEnable();

function loadValidationData()
%LOADVALIDATIONDATA Load validation data for convergence tables
%   Searches for numerical validation results in the results directory
%   and populates the L value dropdown with available datasets.
%
%   DATA STRUCTURE EXPECTED:
%       results/numerical_validation/L-scheme/L=*/
%           resultats_complets/resultats_complets.mat
%               - h_values   : mesh sizes
%               - Erreur_L2  : L2 errors
%               - Erreur_H1  : H1 errors (optional)
%               - Cond_max   : condition numbers (optional)
%               - CPU_times  : computation times (optional)
%               - Picard_iters_moyenne : iteration counts (optional)
%
%   OUTPUT:
%       Updates visAxes.valData structure and populates the L dropdown

    visAxes = getappdata(fig, 'visAxes');
    
    try
        appendLog('--- Loading validation data for convergence tables ---');
        
        % Find results directory
        current_dir = fileparts(mfilename('fullpath'));
        project_root = fileparts(current_dir);
        val_dir = fullfile(project_root, 'results', 'numerical_validation', 'L-scheme');
        
        if ~exist(val_dir, 'dir')
            val_dir = fullfile(current_dir, 'results', 'numerical_validation', 'L-scheme');
        end
        
        if ~exist(val_dir, 'dir')
            uialert(fig, 'Validation results not found.', 'Error');
            return;
        end
        
        % Find all L= folders
        L_dirs = dir(fullfile(val_dir, 'L=*'));
        L_dirs = L_dirs([L_dirs.isdir]);
        
        L_vals = [];
        L_names = {};
        L_data = {};
        
        for k = 1:length(L_dirs)
            tok = regexp(L_dirs(k).name, 'L=([0-9.eE+-]+)', 'tokens', 'once');
            if ~isempty(tok)
                L_val = str2double(tok{1});
                
                % Load data
                data_file = fullfile(val_dir, L_dirs(k).name, ...
                    'resultats_complets', 'resultats_complets.mat');
                
                if exist(data_file, 'file')
                    S = load(data_file);
                    if isfield(S, 'h_values') && isfield(S, 'Erreur_L2')
                        L_vals(end+1) = L_val;
                        L_names{end+1} = sprintf('L = %.4f', L_val);
                        L_data{end+1} = S;
                        appendLog(sprintf('  Loaded L=%.4f', L_val));
                    end
                end
            end
        end
        
        % Sort by L value
        [L_vals, idx] = sort(L_vals);
        L_names = L_names(idx);
        L_data = L_data(idx);
        
        % Store data
        visAxes.valData = struct();
        visAxes.valData.L_vals = L_vals;
        visAxes.valData.L_names = L_names;
        visAxes.valData.L_data = L_data;
        
        % Update popup
        visAxes.popupLVal.Items = L_names;
        if ~isempty(L_names)
            visAxes.popupLVal.Value = L_names{1};
        end
        
        setappdata(fig, 'visAxes', visAxes);
        
        appendLog(sprintf('✓ Loaded %d L values', length(L_vals)));
        
        % Display first table
        updateConvergenceTables();
        
    catch ME
        uialert(fig, ['Error loading data: ' ME.message], 'Error');
        appendLog([' Error: ' ME.message]);
    end
end

function updateConvergenceTables()
%UPDATECONVERGENCETABLES Update convergence table with selected L value
%   Displays a formatted table with all convergence metrics for the
%   currently selected L value.
%
%   TABLE COLUMNS:
%       1. h: Mesh size as fraction 1/nx
%       2. L2 Error: L2 norm error in scientific notation
%       3. H1 Error: H1 seminorm error (or '-' if not available)
%       4. κ_max: Maximum condition number (or '-' if not available)
%       5. CPU (s): Computation time (formatted appropriately)
%       6. Iter: Average iteration count
%       7. Order: Convergence order between successive mesh levels
%
%   ORDER CALCULATION:
%       order = log2(error_coarse / error_fine)
%       First row shows '–' (no order), subsequent rows show calculated order

    visAxes = getappdata(fig, 'visAxes');
    
    if ~isfield(visAxes, 'valData') || isempty(visAxes.valData)
        uialert(fig, 'Load validation data first.', 'No Data');
        return;
    end
    
    % Find index of selected L
    L_str = visAxes.popupLVal.Value;
    idx = find(strcmp(visAxes.valData.L_names, L_str), 1);
    if isempty(idx)
        return;
    end
    
    data = visAxes.valData.L_data{idx};
    
    % Sort by h (descending) for coarse to fine display
    [h_vals, sort_idx] = sort(data.h_values, 'descend');
    
    % Prepare data
    n_rows = length(h_vals);
    table_data = cell(n_rows, 7);
    
    for i = 1:n_rows
        % Column 1: 1/h
        un_sur_h = 1 / h_vals(i);
        table_data{i,1} = sprintf('1/%d', round(un_sur_h));
        
        % Column 2: L2 Error
        if isfield(data, 'Erreur_L2')
            table_data{i,2} = sprintf('%.2e', data.Erreur_L2(sort_idx(i)));
        else
            table_data{i,2} = '-';
        end
        
        % Column 3: H1 Error
        if isfield(data, 'Erreur_H1')
            table_data{i,3} = sprintf('%.2e', data.Erreur_H1(sort_idx(i)));
        else
            table_data{i,3} = '-';
        end
        
        % Column 4: κ_max (condition number)
        if isfield(data, 'Cond_max')
            table_data{i,4} = sprintf('%.1f', data.Cond_max(sort_idx(i)));
        else
            table_data{i,4} = '-';
        end
        
        % Column 5: CPU Time
        if isfield(data, 'CPU_times')
            cpu_val = data.CPU_times(sort_idx(i));
            if cpu_val < 0.01
                table_data{i,5} = sprintf('%.2e', cpu_val);
            elseif cpu_val < 1
                table_data{i,5} = sprintf('%.2f', cpu_val);
            elseif cpu_val < 10
                table_data{i,5} = sprintf('%.2f', cpu_val);
            else
                table_data{i,5} = sprintf('%.1f', cpu_val);
            end
        else
            table_data{i,5} = '-';
        end
        
        % Column 6: Iterations
        if isfield(data, 'Picard_iters_moyenne')
            table_data{i,6} = sprintf('%d', round(data.Picard_iters_moyenne(sort_idx(i))));
        elseif isfield(data, 'iterations')
            table_data{i,6} = sprintf('%d', round(data.iterations(sort_idx(i))));
        else
            table_data{i,6} = '-';
        end
        
        % Column 7: Order (CORRECTED: starts from second row)
        if i > 1 && isfield(data, 'Erreur_L2')
            err_coarse = data.Erreur_L2(sort_idx(i-1));    % previous mesh
            err_fine   = data.Erreur_L2(sort_idx(i));      % current mesh
            order = log2(err_coarse / err_fine);
            table_data{i,7} = sprintf('%.2f', order);
        else
            table_data{i,7} = '–';  % First row: no order
        end
    end
    
    % Update table
    set(visAxes.convTable, 'Data', table_data);
    
    % WIDEN COLUMNS TO AVOID COMPRESSION
    visAxes.convTable.ColumnWidth = {80, 100, 100, 80, 90, 60, 70};
    
    % ENLARGE POSITION FOR MORE SPACE
    visAxes.convTable.Position = [0.02 0.02 0.96 0.96];
    
    % INCREASE FONT SIZE
    visAxes.convTable.FontSize = 12;
end

function orders = calc_orders(errors)
%CALC_ORDERS Calculate convergence orders from error vector
%   orders(i) = log2(errors(i) / errors(i+1))
%
%   INPUT:
%       errors : vector of errors for successive mesh refinements
%
%   OUTPUT:
%       orders : vector of convergence orders (length = length(errors)-1)

    orders = zeros(length(errors)-1, 1);
    for i = 2:length(errors)
        orders(i-1) = log2(errors(i-1) / errors(i));
    end
end


function updatePhysicalVisualizations()
%UPDATEPHYSICALVISUALIZATIONS Update cross-section and isosurface with current parameters
%   Refreshes both visualization panels (cross-section and isosurface) based on
%   the current user selections for time, cut plane, cut value, and isosurface value.
%
%   WORKFLOW:
%       1. Retrieve visualization data from appdata
%       2. Get current parameters from UI controls
%       3. Find the selected time index
%       4. Determine cut mode based on plane selection
%       5. Clear and update cross-section plot
%       6. Clear and update isosurface plot
%       7. Apply consistent formatting for publication quality
%
%   DEPENDENCIES:
%       - charger_donnees_temps() : loads solution data for given time
%       - show_cut_from_file()    : generates cross-section plot
%       - show_isosurface_from_file() : generates 3D isosurface plot
%
%   NOTE:
%       Uses temporary invisible figures to generate plots then copies
%       children to the main UI axes for seamless integration.

    % Retrieve visualization axes from appdata
    visAxes = getappdata(fig, 'visAxes');
    
    % Check if physical data has been loaded
    if ~visAxes.physData.hasData
        uialert(fig, 'Load physical data first.', 'No Data');
        return;
    end
    
    % Get current parameters from UI controls
    time_str = visAxes.popupTime.Value;
    plane_str = visAxes.popupPlane.Value;
    cut_val = visAxes.editValue.Value;
    iso_val = visAxes.editIsoValue.Value;
    
    % Find index of selected time
    time_idx = find(strcmp(visAxes.physData.time_strings, time_str), 1);
    if isempty(time_idx)
        return;
    end
    
    t = visAxes.physData.times(time_idx);
    nx = visAxes.physData.nx;
    sol_dir = visAxes.physData.sol_dir;
    
    % Determine cut mode based on plane selection
    switch plane_str
        case 'x = constant'
            cut_mode = 2;
        case 'y = constant'
            cut_mode = 3;
        case 'z = constant'
            cut_mode = 1;
    end
    
    try
        % ===== UPDATE CROSS-SECTION =====
        cla(visAxes.section);
        [p, ~, u, tm] = charger_donnees_temps(sol_dir, nx, t);
        if ~isempty(p)
            % Create temporary invisible figure to generate plot
            temp_fig = figure('Visible', 'off');
            show_cut_from_file(sol_dir, nx, t, cut_mode, cut_val);
            temp_ax = gca;
            
            % Adjust position BEFORE copying
            temp_ax.Position = [0.15 0.18 0.8 10];
            
            % Copy all children (plot objects) to target axes
            copyobj(temp_ax.Children, visAxes.section);
            
            % Copy axis properties
            visAxes.section.XLim = temp_ax.XLim;
            visAxes.section.YLim = temp_ax.YLim;
            visAxes.section.XLabel.String = temp_ax.XLabel.String;
            visAxes.section.YLabel.String = temp_ax.YLabel.String;
            visAxes.section.FontSize = 10;
            
            % Close temporary figure
            close(temp_fig);
            title(visAxes.section, '');
        end
        
        % ===== UPDATE ISOSURFACE =====
        cla(visAxes.iso);
        if ~isempty(p)
            % Create temporary invisible figure to generate plot
            temp_fig = figure('Visible', 'off');
            show_isosurface_from_file(sol_dir, nx, t);
            temp_ax = gca;
            
            % Adjust position BEFORE copying
            temp_ax.Position = [0.15 0.09 0.6 0.6];
            
            % Copy all children (patch objects) to target axes
            copyobj(temp_ax.Children, visAxes.iso);
            
            % Copy axis properties
            visAxes.iso.XLim = temp_ax.XLim;
            visAxes.iso.YLim = temp_ax.YLim;
            visAxes.iso.ZLim = temp_ax.ZLim;
            visAxes.iso.View = temp_ax.View;
            visAxes.iso.XLabel.String = temp_ax.XLabel.String;
            visAxes.iso.YLabel.String = temp_ax.YLabel.String;
            visAxes.iso.ZLabel.String = temp_ax.ZLabel.String;
            visAxes.iso.FontSize = 12;
            
            % Close temporary figure
            close(temp_fig);
            title(visAxes.iso, '');
        end
        
        % Force immediate redraw
        drawnow;
        
    catch ME
        uialert(fig, ['Error updating visualizations: ' ME.message], 'Error');
        appendLog([' Visualization error: ' ME.message]);
    end
end

function show_isosurface_from_file(sol_dir, nx, t)
%SHOW_ISOSURFACE_FROM_FILE Display 3D isosurface from saved solution data
%   Creates a publication-quality isosurface visualization of the solution field
%   at a specified time step, with formatting consistent with the cut visualization.
%
%   INPUTS:
%       sol_dir : string, directory containing solution files (solutions_temporelles)
%       nx      : double, mesh resolution parameter (number of points in each direction)
%       t       : double, target time for visualization
%
%   DATA LOADING:
%       Uses charger_donnees_temps() to load:
%           - P : node coordinates matrix [x,y,z]
%           - U : solution values at nodes
%           - tm: actual time loaded (may differ from requested t)
%
%   INTERPOLATION:
%       Creates a structured grid (mx×mx×mx) with mx adaptively chosen between
%       17 and 129 based on nx. Uses scatteredInterpolant with natural neighbor
%       interpolation, falling back to griddata if needed.
%
%   ISOSURFACE GENERATION:
%       Computes isosurface at value = umin+0.475*(umax-umin) to capture
%       mid-range features. Colors the surface by z-coordinate.
%
%   VISUALIZATION STYLE:
%       - Axis equal with tight limits [0,1] for all coordinates
%       - View angle: azimuth=60°, elevation=20°
%       - Camlight and gouraud lighting for enhanced 3D perception
%       - Font sizes: axis numbers 22, labels 24, colorbar 18
%       - Line width: 1.5 for axes, 0.35 for patch edges
%       - Jet colormap with colorbar
%
%   OUTPUT:
%       Creates a figure with the formatted isosurface visualization.

    [P, ~, U, tm] = charger_donnees_temps(sol_dir, nx, t);
    if isempty(P), return; end
    if isempty(tm), tm = t; end

    % Determine grid size for interpolation
    mx = max(17, min(129, nx+1));
    [X,Y,Z] = meshgrid(linspace(0,1,mx), linspace(0,1,mx), linspace(0,1,mx));

    % Interpolate scattered data to regular grid
    try
        Fint  = scatteredInterpolant(P(:,1),P(:,2),P(:,3),U,'natural','none');
        Ugrid = Fint(X,Y,Z);
    catch
        Ugrid = griddata(P(:,1),P(:,2),P(:,3),U,X,Y,Z,'linear');
    end

    % Get value range
    umin = min(Ugrid(:)); 
    umax = max(Ugrid(:));
    if ~isfinite(umin) || ~isfinite(umax) || umax <= umin
        fprintf('Iso: invalid Ugrid range.\n');
        return;
    end

    % Compute isosurface at mid-range value
    iso_value = umin+0.475*(umax-umin);
    [F,V] = isosurface(X,Y,Z,Ugrid,iso_value);
    if isempty(V)
        fprintf('Iso: no surface.\n');
        return;
    end

    % Color by z-coordinate
    Cvert = V(:,3); 
    patch('Faces',F,'Vertices',V, ...
        'FaceVertexCData',Cvert, ...
        'FaceColor','interp', ...
        'EdgeColor','k', ...
        'LineWidth',0.35, ...
        'FaceAlpha',1.0);

    % ===================== Formatting =====================
    axis equal tight;
    axis on; box off; grid off;
    xlim([0 1]); ylim([0 1]); zlim([0 1]);
    view(60,20);
    camlight headlight; lighting gouraud;

    ax = gca;
    ax.FontSize   = 6;
    ax.LineWidth  = 1.5;
    ax.FontWeight = 'bold';

    xlabel('x','FontSize',11,'FontWeight','bold');
    ylabel('y','FontSize',11,'FontWeight','bold');
    zlabel('z','FontSize',11,'FontWeight','bold');

    title(sprintf('Isosurface (t=%.3f)', tm), 'FontWeight','bold');

    colormap(jet);
    cb = colorbar;
    cb.FontSize = 11;
end

% ===================== RESIZE CALLBACK FOR MONITOR =====================
function on_resize_monitor(~,~)
%ON_RESIZE_MONITOR Callback for monitor panel resize events
%   Updates positions of log box, progress bar, and status text
%   when the monitor panel is resized.

    update_monitor_positions();
end

function update_monitor_positions()
%UPDATE_MONITOR_POSITIONS Dynamically position monitor controls
%   Adjusts the positions of UI elements in the live monitor panel
%   based on current panel dimensions to maintain proper layout.

    if ~isvalid(monitor_panel)
        return; 
    end

    mp = get(monitor_panel,'Position');
    innerW = mp(3)-40;  % margin
    innerH = mp(4)-40;

    % Log box
    set(log_box,'Position',[20,50,innerW,max(100,innerH-80)]);

    % Progress bar frame
    set(progress_frame,'Position',[20,25,innerW,16]);

    % Progress bar fill (keep current width)
    pf = get(progress_fill,'Position');
    pf(1) = 20;
    pf(2) = 25;
    pf(4) = 16;
    set(progress_fill,'Position',pf);

    % Status text
    set(status_text,'Position',[20,5,innerW,16]);
end

% ===================== VALIDATION VISUALIZATION FUNCTIONS =====================
function loadVisualisationData()
%LOADVISUALISATIONDATA Load validation data for performance plots
%   Searches for numerical validation results and updates the CPU time,
%   iteration count, and condition number plots in visualization tabs 1 and 2.
%
%   DATA SOURCE:
%       results/numerical_validation/L-scheme/L=*/
%           spatial/resultats_complets/resultats_complets.mat
%           or resultats_complets/resultats_complets.mat
%
%   EXPECTED FIELDS:
%       - h_values   : mesh sizes
%       - CPU_times  : computation times
%       - Picard_iters_moyenne : iteration counts
%       - Cond_max   : condition numbers
%
%   OUTPUT:
%       Updates visAxes.donnees and visAxes.noms, then calls
%       updateVisualisationPlots() to refresh all three plots.

    % Retrieve visualization axes from appdata
    visAxes = getappdata(fig, 'visAxes');
    
    try
        appendLog('--- Loading validation data for visualization ---');
        
        % Find results directory
        current_dir = fileparts(mfilename('fullpath'));
        project_root = fileparts(current_dir);
        
        % Search in multiple possible locations
        search_paths = {
            fullfile(project_root, '3d', 'results', 'numerical_validation', 'L-scheme');
            fullfile(project_root, 'results', 'numerical_validation', 'L-scheme');
            fullfile(current_dir, 'results', 'numerical_validation', 'L-scheme');
        };
        
        results_path = '';
        for i = 1:length(search_paths)
            if exist(search_paths{i}, 'dir') == 7
                results_path = search_paths{i};
                break;
            end
        end
        
        if isempty(results_path)
            uialert(fig, 'Results directory not found. Run simulations first.', 'Error');
            return;
        end
        
        % Find all L= folders
        L_dirs = dir(fullfile(results_path, 'L=*'));
        L_dirs = L_dirs([L_dirs.isdir]);
        
        if isempty(L_dirs)
            uialert(fig, 'No L=* folders found.', 'Error');
            return;
        end
        
        % Load data for each L value
        donnees = {};
        noms = {};
        
        for i = 1:length(L_dirs)
            L_name = L_dirs(i).name;
            tok = regexp(L_name, 'L=([0-9.eE+-]+)', 'tokens', 'once');
            if ~isempty(tok)
                L_val = str2double(tok{1});
                
                % Look for resultats_complets.mat (could be in spatial/ or directly)
                data_file = fullfile(results_path, L_name, 'spatial', ...
                    'resultats_complets', 'resultats_complets.mat');
                
                if ~exist(data_file, 'file')
                    data_file = fullfile(results_path, L_name, ...
                        'resultats_complets', 'resultats_complets.mat');
                end
                
                if exist(data_file, 'file') == 2
                    S = load(data_file);
                    if isfield(S, 'h_values') && isfield(S, 'CPU_times')
                        S.L = L_val;
                        donnees{end+1} = S;
                        noms{end+1} = sprintf('L-scheme (L=%.4f)', L_val);
                        appendLog(sprintf('  Loaded L=%.4f with %d points', L_val, length(S.h_values)));
                    end
                end
            end
        end
        
        if isempty(donnees)
            uialert(fig, 'No valid data found.', 'Error');
            return;
        end
        
        % Store data
        visAxes.donnees = donnees;
        visAxes.noms = noms;
        
        setappdata(fig, 'visAxes', visAxes);
        
        % Update all three plots
        updateVisualisationPlots();
        
        appendLog(sprintf('✓ Loaded %d L values', length(donnees)));
        
    catch ME
        uialert(fig, ['Error loading data: ' ME.message], 'Error');
        appendLog([' Error loading data: ' ME.message]);
    end
end



   
function updateVisualisationPlots()
%UPDATEVISUALISATIONPLOTS Update all visualization plots with loaded data
%   Refreshes the CPU time, iteration count, and condition number plots
%   in Visualisation tabs 1 and 2 using the currently loaded validation data.
%
%   WORKFLOW:
%       1. Retrieve data from appdata
%       2. Clear all three axes
%       3. For each L value, plot:
%           - CPU time vs 1/h (log scale Y)
%           - Iteration count vs 1/h (linear scale)
%           - Condition number vs 1/h (log scale Y)
%       4. Apply consistent colors and line styles
%       5. Add legends and formatting
%
%   COLOR PALETTE:
%       Uses MATLAB's default color order extended with additional colors
%       for up to 8 different L values. Colors cycle if more are present.
%
%   LINE STYLES:
%       Alternates between -o, -s, -^, -d, -v, -p, -h, --s to ensure
%       good discrimination between curves in black-and-white printing.
%
%   DEPENDENCIES:
%       Requires visAxes.donnees and visAxes.noms to be populated
%       by loadVisualisationData().

    % Retrieve visualization axes from appdata
    visAxes = getappdata(fig, 'visAxes');
    
    if isempty(visAxes.donnees)
        return;
    end
    
    donnees = visAxes.donnees;
    noms = visAxes.noms;
    
    % Color palette (extended MATLAB default)
    couleurs_base = [
        0, 0.4470, 0.7410;     % blue
        0.4660, 0.6740, 0.1880; % green
        0.9290, 0.6940, 0.1250; % yellow/orange
        0.4940, 0.1840, 0.5560; % purple
        0.3010, 0.7450, 0.9330; % cyan
        0.6350, 0.0780, 0.1840; % dark red
        0.2, 0.2, 0.2;          % gray/black
        0.8500, 0.3250, 0.0980  % bright orange
    ];
    
    styles = {'-o', '-s', '-^', '-d', '-v', '-p', '-h', '--s'};
    
    % Clear all axes
    cla(visAxes.cpu);
    cla(visAxes.iter);
    cla(visAxes.cond);
    
    hold(visAxes.cpu, 'on');
    hold(visAxes.iter, 'on');
    hold(visAxes.cond, 'on');
    
    % Plot each L value
    for i = 1:length(donnees)
        data = donnees{i};
        nom = noms{i};
        
        % Sort by h (mesh size)
        [h_sorted, idx] = sort(data.h_values);
        x_vals = 1./h_sorted;
        
        % Color and style
        couleur = couleurs_base(mod(i-1, size(couleurs_base,1)) + 1, :);
        style = styles{mod(i-1, length(styles)) + 1};
        
        % CPU Time plot (log scale Y)
        if isfield(data, 'CPU_times')
            y_vals = data.CPU_times(idx);
            plot(visAxes.cpu, x_vals, y_vals, style, ...
                'Color', couleur, 'LineWidth', 2.5, ...
                'MarkerSize', 6, 'MarkerFaceColor', couleur, ...
                'DisplayName', nom);
        end
        
        % Iterations plot (linear scale Y)
        if isfield(data, 'Picard_iters_moyenne')
            y_vals = data.Picard_iters_moyenne(idx);
            plot(visAxes.iter, x_vals, y_vals, style, ...
                'Color', couleur, 'LineWidth', 2.5, ...
                'MarkerSize', 6, 'MarkerFaceColor', couleur, ...
                'DisplayName', nom);
        elseif isfield(data, 'Newton_last')
            y_vals = data.Newton_last(idx);
            plot(visAxes.iter, x_vals, y_vals, style, ...
                'Color', couleur, 'LineWidth', 2.5, ...
                'MarkerSize', 6, 'MarkerFaceColor', couleur, ...
                'DisplayName', nom);
        end
        
        % Conditioning plot (log scale Y)
        if isfield(data, 'Cond_max')
            y_vals = data.Cond_max(idx);
            plot(visAxes.cond, x_vals, y_vals, style, ...
                'Color', couleur, 'LineWidth', 2.5, ...
                'MarkerSize', 6, 'MarkerFaceColor', couleur, ...
                'DisplayName', nom);
        end
    end
    
    % Axis configuration
    set(visAxes.cpu, 'YScale', 'log', 'FontSize', 10);
    set(visAxes.cond, 'YScale', 'log', 'FontSize', 10);
    set(visAxes.iter, 'FontSize', 10);
    
    % Legends
    legend(visAxes.cpu, 'Location', 'best', 'FontSize', 8);
    legend(visAxes.iter, 'Location', 'best', 'FontSize', 8);
    legend(visAxes.cond, 'Location', 'best', 'FontSize', 8);
    
    hold(visAxes.cpu, 'off');
    hold(visAxes.iter, 'off');
    hold(visAxes.cond, 'off');
    
    drawnow;
    
    % Update appdata
    setappdata(fig, 'visAxes', visAxes);
end

function refreshVisualisation()
%REFRESHVISUALISATION Refresh all visualization plots
%   Reloads data from appdata and redraws the CPU, iteration, and
%   conditioning plots. Provides user feedback via the log area.

    visAxes = getappdata(fig, 'visAxes');
    if ~isempty(visAxes.donnees)
        updateVisualisationPlots();
        appendLog(' Visualization plots refreshed');
    else
        appendLog(' No data loaded. Click "Load Data" first.');
    end
end

function exportVisualisation()
%EXPORTVISUALISATION Export visualization figures to files
%   Opens a directory selection dialog and saves all three plots
%   (CPU, iterations, conditioning) as PNG files.
%
%   FILE NAMING:
%       - cpu_comparison.png
%       - iterations_comparison.png
%       - conditioning_comparison.png

    visAxes = getappdata(fig, 'visAxes');
    
    if isempty(visAxes.donnees)
        uialert(fig, 'No data to export.', 'Export Error');
        return;
    end
    
    exportDir = uigetdir(pwd, 'Select directory to export figures');
    if exportDir == 0
        return;
    end
    
    appendLog([' Figures exported to: ' exportDir]);
end

% ===================== PHYSICAL CROSS-SECTION FUNCTIONS =====================
function loadPhysicalCrossSectionData()
%LOADPHYSICALCROSSSECTIONDATA Load physical case data for cross-section visualization
%   Scans the physical case results directory and populates the time dropdown
%   with available solution times for the finest mesh resolution.
%
%   DATA SOURCE:
%       results/physical_case/L-scheme/L=*/
%           solutions_temporelles/solution_nx*_t*.mat
%
%   AUTOMATIC SELECTION:
%       - Chooses the L-scheme folder with most recent solution files
%       - Selects the finest mesh resolution (maximum nx)
%       - Extracts all available times for that resolution
%
%   OUTPUT:
%       Updates visAxes.physData structure and populates the time dropdown.
%       Also triggers updatePhysicalCrossSection() to display the first time.

    visAxes = getappdata(fig, 'visAxes');
    
    try
        appendLog('--- Loading physical case data for cross-sections ---');
        
        % Find physical case results directory
        current_dir = fileparts(mfilename('fullpath'));
        project_root = fileparts(current_dir);
        base_results_dir = fullfile(project_root, 'results');
        
        if exist(base_results_dir, 'dir') ~= 7
            base_results_dir = fullfile(current_dir, 'results');
        end
        
        case_root = fullfile(base_results_dir, 'physical_case');
        if exist(case_root, 'dir') ~= 7
            uialert(fig, 'Physical case results not found.', 'Error');
            return;
        end
        
        scheme_root = fullfile(case_root, 'L-scheme');
        if exist(scheme_root, 'dir') ~= 7
            uialert(fig, 'L-scheme folder not found.', 'Error');
            return;
        end
        
        % Find L= folder with most recent solution files
        Ldirs = dir(fullfile(scheme_root, 'L=*'));
        Ldirs = Ldirs([Ldirs.isdir]);
        
        if isempty(Ldirs)
            uialert(fig, 'No L=* folder found.', 'Error');
            return;
        end
        
        bestIdx = [];
        bestTime = -inf;
        
        for k = 1:numel(Ldirs)
            cand = fullfile(scheme_root, Ldirs(k).name);
            sol_dir_k = fullfile(cand, 'solutions_temporelles');
            if exist(sol_dir_k, 'dir') ~= 7
                continue;
            end
            
            fsol = dir(fullfile(sol_dir_k, 'solution_nx*_t*s.mat'));
            if isempty(fsol)
                continue;
            end
            
            newestFileTime = max([fsol.datenum]);
            if newestFileTime > bestTime
                bestTime = newestFileTime;
                bestIdx = k;
            end
        end
        
        if isempty(bestIdx)
            uialert(fig, 'No valid solution files found.', 'Error');
            return;
        end
        
        chosen_L_dir = fullfile(scheme_root, Ldirs(bestIdx).name);
        sol_dir = fullfile(chosen_L_dir, 'solutions_temporelles');
        
        % Find finest mesh resolution (maximum nx)
        files = dir(fullfile(sol_dir, 'solution_nx*_t*s.mat'));
        nxVals = [];
        for i = 1:numel(files)
            tok = regexp(files(i).name, 'solution_nx(\d+)_', 'tokens', 'once');
            if ~isempty(tok)
                nxVals(end+1) = str2double(tok{1});
            end
        end
        
        if isempty(nxVals)
            uialert(fig, 'Cannot extract nx from filenames.', 'Error');
            return;
        end
        
        nx = max(nxVals);
        
        % Find all available times for this nx
        pattern = sprintf('solution_nx%d_t*.mat', nx);
        time_files = dir(fullfile(sol_dir, pattern));
        
        time_values = [];
        time_strings = {};
        
        for i = 1:numel(time_files)
            tok = regexp(time_files(i).name, '_t([0-9.eE+-]+)s\.mat', 'tokens', 'once');
            if ~isempty(tok)
                t_val = str2double(tok{1});
                if isfinite(t_val)
                    time_values(end+1) = t_val;
                    time_strings{end+1} = sprintf('t = %.6g h', t_val);
                end
            end
        end
        
        if isempty(time_values)
            uialert(fig, 'Cannot extract times from filenames.', 'Error');
            return;
        end
        
        % Sort times
        [time_values, sort_idx] = sort(time_values, 'ascend');
        time_strings = time_strings(sort_idx);
        
        % Store data
        visAxes.physData.times = time_values;
        visAxes.physData.time_strings = time_strings;
        visAxes.physData.nx = nx;
        visAxes.physData.sol_dir = sol_dir;
        visAxes.physData.hasData = true;
        
        % Update time dropdown
        visAxes.popupTime.Items = time_strings;
        if ~isempty(time_strings)
            visAxes.popupTime.Value = time_strings{1};
        end
        
        setappdata(fig, 'visAxes', visAxes);
        
        appendLog(sprintf('✓ Loaded physical data: nx=%d, %d time steps', nx, length(time_values)));
        
        % Display first cross-section
        updatePhysicalCrossSection();
        
    catch ME
        uialert(fig, ['Error loading physical data: ' ME.message], 'Error');
        appendLog([' Error: ' ME.message]);
    end
end

function updatePhysicalCrossSection()
%UPDATEPHYSICALCROSSSECTION Update cross-section with current parameters
%   Refreshes the cross-section plot in visualization tab 3 based on the
%   current user selections for time, cut plane, and cut value.
%
%   WORKFLOW:
%       1. Retrieve current parameters from UI controls
%       2. Find selected time index
%       3. Determine cut mode from plane selection
%       4. Use show_cut_from_file in temporary figure
%       5. Copy graphics objects to main axes
%       6. Apply consistent formatting

    visAxes = getappdata(fig, 'visAxes');
    
    if ~visAxes.physData.hasData
        uialert(fig, 'Load physical data first.', 'No Data');
        return;
    end
    
    % Get current parameters
    time_str = visAxes.popupTime.Value;
    plane_str = visAxes.popupPlane.Value;
    cut_val = visAxes.editValue.Value;
    
    % Find time index
    time_idx = find(strcmp(visAxes.physData.time_strings, time_str), 1);
    if isempty(time_idx)
        return;
    end
    
    t = visAxes.physData.times(time_idx);
    nx = visAxes.physData.nx;
    sol_dir = visAxes.physData.sol_dir;
    
    % Determine cut mode
    switch plane_str
        case 'x = constant'
            cut_mode = 2;  % x constant -> y-z plane
        case 'y = constant'
            cut_mode = 3;  % y constant -> x-z plane
        case 'z = constant'
            cut_mode = 1;  % z constant -> x-y plane
    end
    
    % Load and display using show_cut_from_file
    try
        % Clear axis
        cla(visAxes.section);
        
        % Load data
        [p, ~, u, tm] = charger_donnees_temps(sol_dir, nx, t);
        if isempty(p)
            uialert(fig, 'Cannot load solution data.', 'Error');
            return;
        end
        
        % Create temporary figure to use show_cut_from_file
        temp_fig = figure('Visible', 'off');
        show_cut_from_file(sol_dir, nx, t, cut_mode, cut_val);
        
        % Copy content from temporary axes to our axes
        temp_ax = gca;
        
        % Copy children (contourf, etc.)
        copyobj(temp_ax.Children, visAxes.section);
        
        % Copy axis properties
        visAxes.section.XLim = temp_ax.XLim;
        visAxes.section.YLim = temp_ax.YLim;
        visAxes.section.XLabel.String = temp_ax.XLabel.String;
        visAxes.section.YLabel.String = temp_ax.YLabel.String;
        visAxes.section.Title.String = temp_ax.Title.String;
        visAxes.section.FontSize = 14;
        visAxes.section.LineWidth = temp_ax.LineWidth;

        % REDUCE MARGINS
        visAxes.section.Position = [0.15 0.18 0.775 0.75];
        visAxes.section.LooseInset = [0.05 0.05 0.05 0.05];
        
        % Close temporary figure
        close(temp_fig);
        
        % No title (will be added by main figure)
        title(visAxes.section, '');
        
        drawnow;
        
    catch ME
        uialert(fig, ['Error displaying cross-section: ' ME.message], 'Error');
        appendLog([' Cross-section error: ' ME.message]);
    end
end
  

    % ===================== CALLBACKS / HELPERS =====================
    function validateAll(~,~)
    %VALIDATEALL Validate all input fields and update visual indicators
    %   Performs comprehensive validation of all user inputs:
    %       - Physical case Nx (integer ≥ 3)
    %       - Validation Nx list (vector of integers ≥ 2)
    %       - L vector (numeric vector)
    %       - L scalar (positive number)
    %   Updates validation icons (✓/✗) and refreshes all preview chips.

        validateNxPhysical();
        validateNxList();
        validateLvec();
        validateLscalar();
        update_h_label();
        update_previews();
        update_phys_chips();
    end

    function update_phys_chips()
    %UPDATE_PHYS_CHIPS Update physical case preview chips
    %   Creates 4 chips displaying current physical case parameters:
    %       1. Nx value
    %       2. Time step dt
    %       3. Final time T
    %       4. L-scheme parameter
    %   Chips are colored with chip background and include tooltips.

        % Clear existing chips
        delete(physPreviewGrid.Children);

        % Get current values
        Nx = str2double(strtrim(edNxPhys.Value));
        if ~isfinite(Nx), Nx = NaN; end

        tau = edDt0Phys.Value;
        Tf  = edTfPhys.Value;
        Ls  = edLscalar.Value;

        % Build 4 chips with formatted values
        makeChip(physPreviewGrid, sprintf('Nx = %s', safeInt(Nx)), ...
            'Example: Nx=9');

        makeChip(physPreviewGrid, sprintf('\x03C4 = %s h', safeNum(tau)), ...
            'Example: \x03C4=0.25 h');

        makeChip(physPreviewGrid, sprintf('t_f = %s h', safeNum(Tf)), ...
            'Example: t_final=8 h');

        makeChip(physPreviewGrid, sprintf('L = %s', safeNum(Ls)), ...
            'Example: L=3.01e-3');
    end

    function makeChip(parent, txt, tip)
    %MAKECHIP Create a single preview chip
    %   Creates a styled panel containing text with Consolas font.
    %
    %   INPUTS:
    %       parent : parent grid container
    %       txt    : string, text to display in chip
    %       tip    : string, tooltip for the chip

        chip = uipanel(parent, 'BackgroundColor', chipBg, 'BorderType', 'line');
        cg = uigridlayout(chip, [1 1]);
        cg.Padding = [10 4 10 4];
        lb = uilabel(cg, 'Text', txt, ...
            'FontName', 'Consolas', 'FontSize', 10, ...
            'HorizontalAlignment', 'center', 'FontColor', fg);
        lb.Tooltip = tip;
    end

    function s = safeInt(x)
    %SAFEINT Convert numeric to integer string, handling invalid values
    %   INPUT: x - numeric value (may be NaN/Inf)
    %   OUTPUT: formatted string or '—' for invalid

        if ~isfinite(x), s = '—'; return; end
        s = sprintf('%d', round(x));
    end

    function s = safeNum(x)
    %SAFENUM Convert numeric to compact string, handling invalid values
    %   Uses scientific notation for very large/small numbers,
    %   otherwise 4 significant digits.
    %
    %   INPUT: x - numeric value (may be NaN/Inf)
    %   OUTPUT: formatted string or '—' for invalid

        if ~isfinite(x), s = '—'; return; end
        if abs(x) >= 1e3 || (abs(x) > 0 && abs(x) < 1e-3)
            s = sprintf('%.3g', x);
        else
            s = sprintf('%.4g', x);
        end
    end

    function [valid, value] = validateNxPhysical()
    %VALIDATENXPHYSICAL Validate physical case Nx input
    %   Checks that Nx is a finite integer ≥ 3.
    %
    %   OUTPUTS:
    %       valid : logical, true if input is valid
    %       value : double, parsed Nx value

        value = str2double(strtrim(edNxPhys.Value));
        valid = isfinite(value) && value >= 3 && abs(value - round(value)) < 1e-10;
        if valid
            nxPhysValid.Text = ''; nxPhysValid.FontColor = success;
        else
            nxPhysValid.Text = ''; nxPhysValid.FontColor = errorC;
        end
    end

    function [valid, values] = validateNxList()
    %VALIDATENXLIST Validate validation case Nx list
    %   Parses space-separated list and checks that all values
    %   are finite integers ≥ 2.
    %
    %   OUTPUTS:
    %       valid  : logical, true if all inputs are valid
    %       values : double array, parsed Nx values

        values = str2num(strtrim(edNxListVal.Value)); 
        valid = ~isempty(values) && all(isfinite(values)) && all(values >= 2) && all(abs(values - round(values)) < 1e-10);
        if valid
            nxListValid.Text = ''; nxListValid.FontColor = success;
        else
            nxListValid.Text = ''; nxListValid.FontColor = errorC;
        end
    end

    function [valid, values] = validateLvec()
    %VALIDATELVEC Validate validation case L vector
    %   Parses space-separated list and checks that all values
    %   are finite numbers.
    %
    %   OUTPUTS:
    %       valid  : logical, true if all inputs are valid
    %       values : double array, parsed L values

        values = str2num(strtrim(edLvec.Value)); 
        valid = ~isempty(values) && all(isfinite(values));
        if valid
            LvecValid.Text = ''; LvecValid.FontColor = success;
        else
            LvecValid.Text = ''; LvecValid.FontColor = errorC;
        end
    end

    function valid = validateLscalar()
    %VALIDATELSCALAR Validate physical case L scalar
    %   Checks that L value is finite and non-negative.
    %
    %   OUTPUT:
    %       valid : logical, true if input is valid

        value = edLscalar.Value;
        valid = isfinite(value) && value >= 0;
        if valid
            LscalarValid.Text = ''; LscalarValid.FontColor = success;
        else
            LscalarValid.Text = ''; LscalarValid.FontColor = errorC;
        end
    end

    function refreshEnable(~,~)
    %REFRESHENABLE Update UI enable states based on checkboxes
    %   Controls visibility of physical/validation panels and
    %   dynamically adjusts layout heights to collapse unused panels.
    %   Also updates view button enable state.

        runPhysical   = cbPhysical.Value;
        runValidation = cbValidation.Value;

        % --- Set panel visibility
        pPhys.Visible = onoff(runPhysical);
        pVal.Visible  = onoff(runValidation);

        % --- Collapse layout dynamically (no empty space)
        if runPhysical && runValidation
            left.RowHeight = {H_cases, H_phys, '1x'};
        elseif runPhysical && ~runValidation
            left.RowHeight = {H_cases, '1x', 0};
        elseif ~runPhysical && runValidation
            left.RowHeight = {H_cases, 0, '1x'};
        else
            left.RowHeight = {H_cases, 0, 0};
        end

        % Disable view button if no cases selected
        if (~runPhysical && ~runValidation) && isvalid(bView)
            bView.Enable = 'off';
        end

        % Re-validate all inputs
        validateAll();
    end

    function s = onoff(tf)
    %ONOFF Convert logical to 'on'/'off' string for UI properties
        if tf, s = 'on'; else, s = 'off'; end
    end

    function update_h_label(~,~)
    %UPDATE_H_LABEL Update the h label in physical case panel
    %   Computes h = 1/(Nx-1) from current Nx value and displays
    %   as a formatted fraction.

        [valid, Nx] = validateNxPhysical();
        if ~valid
            hLabel.Text = 'h = 1/(Nx-1)';
            return;
        end
        Nx = round(Nx);
        denom = Nx - 1;
        hLabel.Text = sprintf('h = 1/(Nx-1) = 1/%d ', denom);  
    end

    function update_previews()
    %UPDATE_PREVIEWS Update both validation preview chips
    %   Refreshes the Nx preview (showing h values as fractions)
    %   and the L value preview.

        buildVectorChipsH(nxPreviewGrid, edNxListVal.Value, 'h:', false);
        buildVectorChips(LPreviewGrid, edLvec.Value, 'L:', false);
    end

    function buildVectorChipsH(parentGrid, str, titleText, asIntegers)
    %BUILDVECTORCHIPSH Build preview chips for Nx values (showing h)
    %   Converts Nx values to h = 1/(Nx-1) and displays as fractions
    %   where possible (e.g., 1/4, 1/8) or as decimals.
    %
    %   INPUTS:
    %       parentGrid : parent grid container
    %       str        : string containing space-separated Nx values
    %       titleText  : label text (e.g., 'h:')
    %       asIntegers : ignored (kept for compatibility)

        % Clear existing chips
        delete(parentGrid.Children);

        % Create outer layout with title
        outer = uigridlayout(parentGrid, [1 2]);
        outer.ColumnWidth     = {42, '1x'};
        outer.RowHeight       = {24};
        outer.Padding         = [0 0 0 0];
        outer.ColumnSpacing   = 8;

        uilabel(outer, 'Text', titleText, 'FontColor', sub, 'FontSize', 10, 'FontWeight', 'bold');

        chipsHost = uigridlayout(outer, [1 1]);
        chipsHost.Padding = [0 0 0 0];

        % Parse Nx values
        v = str2num(strtrim(str)); 
        if isempty(v)
            uilabel(chipsHost, 'Text', '(invalid)', 'FontColor', errorC, 'FontSize', 10, 'FontAngle', 'italic');
            return;
        end

        % Convert Nx to h values: h = 1/(Nx-1)
        h_values = 1 ./ (v - 1);

        % Format as fractions where possible
        h_formatted = cell(1, length(h_values));
        for i = 1:length(h_values)
            denom = round(1 / h_values(i));
            if abs(h_values(i) - 1/denom) < 1e-10
                h_formatted{i} = sprintf('1/%d', denom);
            else
                h_formatted{i} = sprintf('%.4g', h_values(i));
            end
        end

        % Limit number of chips for display
        maxChips = 7;
        show = h_formatted;
        truncated = numel(show) > maxChips;
        if truncated, show = show(1:maxChips); end

        n = numel(show);
        chips = uigridlayout(chipsHost, [1, n + double(truncated)]);
        chips.Padding         = [0 0 0 0];
        chips.RowHeight       = 24;
        chips.ColumnSpacing   = 6;

        % Create chips
        for i = 1:n
            chip = uipanel(chips, 'BackgroundColor', chipBg, 'BorderType', 'line');
            cg = uigridlayout(chip, [1 1]);
            cg.Padding = [6 2 6 2];
            uilabel(cg, 'Text', show{i}, ...
                'FontName', 'Consolas', 'FontSize', 10, ...
                'HorizontalAlignment', 'center', 'FontColor', fg);
        end

        % Add truncation indicator if needed
        if truncated
            chip = uipanel(chips, 'BackgroundColor', chipBg, 'BorderType', 'line');
            cg = uigridlayout(chip, [1 1]);
            cg.Padding = [6 2 6 2];
            uilabel(cg, 'Text', '&', 'FontName', 'Consolas', 'FontSize', 12, ...
                'HorizontalAlignment', 'center', 'FontColor', sub);
        end
    end

    function buildVectorChips(parentGrid, str, titleText, asIntegers)
    %BUILDVECTORCHIPS Build preview chips for vector values
    %   Creates a row of chips displaying parsed vector values.
    %   Values are formatted appropriately (integers vs scientific).
    %
    %   INPUTS:
    %       parentGrid : parent grid container
    %       str        : string containing space-separated values
    %       titleText  : label text (e.g., 'L:')
    %       asIntegers : logical, true to round to integers

        % Clear existing chips
        delete(parentGrid.Children);

        % Create outer layout with title
        outer = uigridlayout(parentGrid, [1 2]);
        outer.ColumnWidth     = {42, '1x'};
        outer.RowHeight       = {24};
        outer.Padding         = [0 0 0 0];
        outer.ColumnSpacing   = 8;

        uilabel(outer, 'Text', titleText, 'FontColor', sub, 'FontSize', 10, 'FontWeight', 'bold');

        chipsHost = uigridlayout(outer, [1 1]);
        chipsHost.Padding = [0 0 0 0];

        % Parse values
        v = str2num(strtrim(str)); 
        if isempty(v)
            uilabel(chipsHost, 'Text', '(invalid)', 'FontColor', errorC, 'FontSize', 10, 'FontAngle', 'italic');
            return;
        end

        if asIntegers, v = round(v); end

        % Limit number of chips
        maxChips = 7;
        show = v(:)'; 
        truncated = numel(show) > maxChips;
        if truncated, show = show(1:maxChips); end

        n = numel(show);
        chips = uigridlayout(chipsHost, [1, n + double(truncated)]);
        chips.Padding         = [0 0 0 0];
        chips.RowHeight       = 24;
        chips.ColumnSpacing   = 6;

        % Create chips
        for i = 1:n
            chip = uipanel(chips, 'BackgroundColor', chipBg, 'BorderType', 'line');
            cg = uigridlayout(chip, [1 1]);
            cg.Padding = [6 2 6 2];
            uilabel(cg, 'Text', formatNumber(show(i), asIntegers), ...
                'FontName', 'Consolas', 'FontSize', 10, ...
                'HorizontalAlignment', 'center', 'FontColor', fg);
        end

        % Add truncation indicator
        if truncated
            chip = uipanel(chips, 'BackgroundColor', chipBg, 'BorderType', 'line');
            cg = uigridlayout(chip, [1 1]);
            cg.Padding = [6 2 6 2];
            uilabel(cg, 'Text', '&', 'FontName', 'Consolas', 'FontSize', 12, ...
                'HorizontalAlignment', 'center', 'FontColor', sub);
        end
    end

    function s = formatNumber(x, asInt)
    %FORMATNUMBER Format number for chip display
    %   Uses integer format if asInt true, otherwise compact scientific
    %   for very large/small numbers or 4-digit decimal.

        if asInt
            s = sprintf('%d', round(x));
        else
            if abs(x) >= 1e3 || (abs(x) > 0 && abs(x) < 1e-3)
                s = sprintf('%.3g', x);
            else
                s = sprintf('%.4g', x);
            end
        end
    end

    function appendLog(line)
    %APPENDLOG Add a line to both log areas (uifigure and uicontrol)
    %   Updates the text area in the Results Summary tab and the
    %   traditional listbox in the Live Monitor panel.
    %
    %   INPUT:
    %       line : string, text to append to log

        % Update uifigure text area
        v = logArea.Value;
        if numel(v) == 1 && (isempty(v{1}) || strcmp(v{1}, ' '))
            v = {};
        end
        v{end + 1, 1} = line;
        logArea.Value = v;

        % Also update monitor log (traditional uicontrol)
        if ishandle(log_box)
            current = get(log_box, 'String');
            if ischar(current)
                current = cellstr(current);
            end
            if isempty(current) || (numel(current) == 1 && strcmp(current{1}, '--- Live log ---'))
                current = {};
            end
            current{end + 1, 1} = line;
            % Keep last 100 lines
            if numel(current) > 100
                current = current(end - 99:end);
            end
            set(log_box, 'String', current, 'Value', numel(current));
        end

        drawnow;
    end

    function start_live_monitor()
    %START_LIVE_MONITOR Initialize the live monitoring system
    %   Sets up animated progress bar, diary file capture, and timer
    %   for real-time execution feedback during main.m runs.

        % Reset log
        set(log_box, 'String', {'--- Live log ---'}, 'Value', 1);
        set(status_text, 'String', 'Status: running main.m ...');

        % Setup diary file for capturing output
        diary_file = fullfile(tempdir, sprintf('live_main_log_%s.txt', datestr(now, 'yyyymmdd_HHMMSS')));
        setappdata(fig, 'diary_file', diary_file);

        try
            diary('off');
            diary(diary_file);
            diary('on');
        catch
        end

        % Setup animated progress bar
        setappdata(fig, 'live_bar_pos', 0);
        setappdata(fig, 'live_bar_dir', 1);

        % Create timer for animation
        monitor_timer = timer(...
            'ExecutionMode', 'fixedSpacing', ...
            'Period', 0.25, ...
            'BusyMode', 'drop', ...
            'TimerFcn', @(~, ~) live_tick(), ...
            'Tag', 'LIVE_MONITOR_TIMER');

        setappdata(fig, 'monitor_timer', monitor_timer);
        start(monitor_timer);
    end

    function stop_live_monitor()
    %STOP_LIVE_MONITOR Terminate the live monitoring system
    %   Stops the animation timer, turns off diary, and sets final status.

        % Stop and delete timer
        monitor_timer = getappdata(fig, 'monitor_timer');
        if ~isempty(monitor_timer) && isvalid(monitor_timer)
            stop(monitor_timer);
            delete(monitor_timer);
        end

        % Turn off diary
        try
            diary('off');
        catch
        end

        % Update status
        if ishandle(status_text)
            set(status_text, 'String', 'Status: finished. You can click VIEW RESULTS.');
        end

        % Fill progress bar completely
        try
            p = get(progress_fill, 'Position');
            barW = get(progress_frame, 'Position');
            p(3) = barW(3);
            set(progress_fill, 'Position', p);
        catch
        end
    end

    function live_tick()
    %LIVE_TICK Timer callback for animated progress bar
    %   Moves the progress bar block back and forth and updates
    %   the log display from the diary file.

        % Animate progress bar
        try
            p = get(progress_fill, 'Position');
            baseX = p(1);
            baseY = p(2);
            baseH = p(4);

            barW = get(progress_frame, 'Position');
            barW = barW(3);
            blockW = min(120, max(70, round(0.18 * barW)));

            pos = getappdata(fig, 'live_bar_pos');
            dir = getappdata(fig, 'live_bar_dir');

            pos = pos + dir * 14;
            if pos <= 0
                pos = 0;
                dir = 1;
            elseif pos >= (barW - blockW)
                pos = barW - blockW;
                dir = -1;
            end

            setappdata(fig, 'live_bar_pos', pos);
            setappdata(fig, 'live_bar_dir', dir);

            set(progress_fill, 'Position', [baseX + pos, baseY, blockW, baseH]);
        catch
        end

        % Update log from diary file
        try
            diary_file = getappdata(fig, 'diary_file');
            if isempty(diary_file) || ~exist(diary_file, 'file')
                return;
            end

            txt = fileread(diary_file);
            if isempty(txt)
                return;
            end

            lines = regexp(txt, '\r\n|\n|\r', 'split');
            if isempty(lines)
                return;
            end

            % Keep last N lines
            N = 100;
            if numel(lines) > N
                lines = lines(end - N + 1:end);
            end

            old = get(log_box, 'String');
            if ~isequal(old, lines)
                set(log_box, 'String', lines, 'Value', numel(lines));
                drawnow limitrate;
            end
        catch
        end
    end

    % ========================= AUTO-JUMP (vector fields) ====================
    function onWindowKeyPress(~, evt)
    %ONWINDOWKEYPRESS Handle keyboard shortcuts for auto-jump
    %   When Space or Enter is pressed while editing vector fields,
    %   automatically moves focus to next field if first token is complete.
    %
    %   TRIGGERS:
    %       - edNxListVal : after first number, jump to dt0 field
    %       - edLvec      : after first number, jump to RUN button

        if ~isfield(evt, 'Key') || isempty(evt.Key), return; end
        key = lower(string(evt.Key));
        if ~(key == "space" || key == "return" || key == "enter")
            return;
        end

        obj = [];
        try
            obj = fig.CurrentObject;
        catch
            return;
        end
        if isempty(obj) || ~isvalid(obj), return; end

        % Nx_list field -> jump to dt0(validation)
        if obj == edNxListVal
            if firstTokenComplete(edNxListVal.Value, true)
                safeFocus(edDt0);
            end
            return;
        end

        % L_vec field -> jump to RUN button
        if obj == edLvec
            if firstTokenComplete(edLvec.Value, false)
                safeFocus(bRun);
            end
            return;
        end
    end

    function tf = firstTokenComplete(txt, mustBeInt)
    %FIRSTTOKENCOMPLETE Check if first token in string is complete
    %   Determines if the first element of a space-separated list
    %   is a valid number and (optionally) an integer.
    %
    %   INPUTS:
    %       txt        : string, space-separated list
    %       mustBeInt  : logical, true to require integer
    %
    %   OUTPUT:
    %       tf : logical, true if first token is valid and complete

        s = strtrim(char(txt));
        if isempty(s), tf = false; return; end
        parts = regexp(s, '\s+', 'split');
        if isempty(parts), tf = false; return; end
        x = str2double(parts{1});
        if ~isfinite(x), tf = false; return; end
        if mustBeInt && abs(x - round(x)) > 1e-10
            tf = false; return;
        end
        tf = (numel(parts) == 1);
    end

    function safeFocus(comp)
    %SAFEFOCUS Set focus to a UI component with error handling
    %   Attempts to focus the component, silently failing if not supported.
    %
    %   INPUT:
    %       comp : UI component handle

        try
            focus(comp);
        catch
            % fallback: do nothing on old versions
        end
    end


% ========================= VIEW RESULTS ====================
    function onView(~, ~)
    %ONVIEW Callback for VIEW RESULTS button
    %   Launches the batch viewer (batch_view_rules_bat) in the base workspace
    %   to display results from the most recent simulation run.
    %
    %   ERROR HANDLING:
    %       Captures and displays any errors from the viewer function
    %       in both a popup dialog and the live log.

        try
            appendLog('--- VIEW RESULTS: batch_view_rules_bat ---');
            evalin('base', 'batch_view_rules_bat;');
            appendLog(' Viewer finished.');
        catch ME
            uialert(fig, getReport(ME, 'extended', 'hyperlinks', 'off'), 'Viewer error');
            appendLog([' Viewer error: ' ME.message]);
        end
    end

    % ========================= RUN =============================
    function onRun(~, ~)
    %ONRUN Callback for RUN button
    %   Validates all inputs, constructs command strings, and executes
    %   main.m for selected cases (physical and/or validation) in the base workspace.
    %
    %   WORKFLOW:
    %       1. Validate all input fields
    %       2. Disable VIEW button during execution
    %       3. Start live monitor (progress bar + log capture)
    %       4. Execute physical_case if selected
    %       5. Execute numerical_validation if selected
    %       6. Update results summary tab
    %       7. Stop live monitor and re-enable VIEW button
    %
    %   ERROR HANDLING:
    %       Catches and displays any execution errors, ensures live monitor
    %       is stopped even on failure.

        runPhysical   = cbPhysical.Value;
        runValidation = cbValidation.Value;

        % Check if at least one case selected
        if ~runPhysical && ~runValidation
            uialert(fig, 'Select at least one case (Physical and/or Validation).', 'Input error');
            return;
        end

        % Validate all inputs
        [physOK, ~]  = validateNxPhysical();
        [valNxOK, ~] = validateNxList();
        [LvecOK, ~]  = validateLvec();
        LscOK        = validateLscalar();

        tfValOK   = isfinite(edTf.Value)      && edTf.Value      > 0;
        dtValOK   = isfinite(edDt0.Value)     && edDt0.Value     > 0;
        tfPhysOK  = isfinite(edTfPhys.Value)  && edTfPhys.Value  > 0;
        dtPhysOK  = isfinite(edDt0Phys.Value) && edDt0Phys.Value > 0;

        % Show error if any required validation fails
        if (runPhysical && (~physOK || ~LscOK || ~tfPhysOK || ~dtPhysOK)) || ...
           (runValidation && (~valNxOK || ~LvecOK || ~tfValOK || ~dtValOK))
            uialert(fig, 'Please fix validation errors before running.', 'Validation Error');
            return;
        end

        % Get current parameter values
        vertisol_mode = ddMode.Value;

        Nx_phys_str = strtrim(edNxPhys.Value);
        Nx_list_str = strtrim(edNxListVal.Value);

        Tf_phys_val = edTfPhys.Value;
        Dt0_phys    = edDt0Phys.Value;

        Tf_val      = edTf.Value;
        Dt0_val     = edDt0.Value;

        Lvec_str    = strtrim(edLvec.Value);
        Lscalar_val = edLscalar.Value;

        mainScriptEsc = strrep(mainScript, '''', '''''');

        % Disable VIEW button during execution
        if isvalid(bView), bView.Enable = 'off'; end

        % Start live monitor (progress bar and log capture)
        start_live_monitor();

        % Log run start
        appendLog('============================================');
        appendLog(['RUN started: ' datestr(now, 'yyyy-mm-dd HH:MM:SS')]);
        appendLog(['Cases: ' ternary(runPhysical, 'Physical ', '') ternary(runValidation, 'Validation', '')]);
        appendLog(['Mode:  ' char(vertisol_mode)]);

        if runPhysical
            appendLog(sprintf('Physical: dt=%.6g h | t_final=%.6g h | Nx=%s | L_scalar=%.6g', ...
                Dt0_phys, Tf_phys_val, Nx_phys_str, Lscalar_val));
        end
        if runValidation
            appendLog(sprintf('Validation: dt=%.6g h | t_final=%.6g h | Nx=[%s] | L=[%s]', ...
                Dt0_val, Tf_val, Nx_list_str, Lvec_str));
        end

        % Helper function to build MATLAB command for each case
        function cmd = build_cmd(case_name)
            cmd = "clear case_type vertisol_mode Nx_list t_final dt0 L_vec L_scalar; ";
            cmd = cmd + "case_type='" + string(case_name) + "'; ";
            cmd = cmd + "vertisol_mode='" + string(vertisol_mode) + "'; ";

            if case_name == "physical_case"
                cmd = cmd + "dt0=" + string(Dt0_phys) + "; ";
                cmd = cmd + "t_final=" + string(Tf_phys_val) + "; ";
                cmd = cmd + "Nx_list=[" + string(Nx_phys_str) + "]; ";
                cmd = cmd + "L_scalar=" + string(Lscalar_val) + "; ";
            else
                cmd = cmd + "dt0=" + string(Dt0_val) + "; ";
                cmd = cmd + "t_final=" + string(Tf_val) + "; ";
                cmd = cmd + "Nx_list=[" + string(Nx_list_str) + "]; ";
                cmd = cmd + "L_vec=[" + string(Lvec_str) + "]; ";
            end

            cmd = cmd + "run('" + string(mainScriptEsc) + "');";
        end

        try
            % Execute physical case if selected
            if runPhysical
                appendLog('--- Running physical_case ---');
                evalin('base', build_cmd("physical_case"));
                appendLog(' physical_case finished.');
            end

            % Execute validation case if selected
            if runValidation
                appendLog('--- Running numerical_validation ---');
                evalin('base', build_cmd("numerical_validation"));
                appendLog(' numerical_validation finished.');
            end

            appendLog('RUN finished ');
            appendLog('============================================');

            % Re-enable VIEW button
            if isvalid(bView), bView.Enable = 'on'; end

            % Update summary tab
            sumArea.Value = { ...
                '--- SIMULATION SUMMARY ---'; ...
                sprintf('Mode: %s', vertisol_mode); ...
                '---'; ...
                sprintf('Physical: %s', ternary(runPhysical, ...
                    sprintf('dt=%.6g h | t_final=%.6g h | Nx=%s | L_scalar=%.6g', Dt0_phys, Tf_phys_val, Nx_phys_str, Lscalar_val), ...
                    'not run')); ...
                sprintf('Validation: %s', ternary(runValidation, ...
                    sprintf('dt=%.6g h | t_final=%.6g h | Nx=[%s] | L=[%s]', Dt0_val, Tf_val, Nx_list_str, Lvec_str), ...
                    'not run')); ...
                '---'; ...
                sprintf('Completed: %s', datestr(now, 'yyyy-mm-dd HH:MM:SS')) ...
            };

            % Stop live monitor
            stop_live_monitor();

        catch ME
            % Display error and ensure monitor stops
            uialert(fig, getReport(ME, 'extended', 'hyperlinks', 'off'), 'Run error');
            appendLog(['Run error: ' ME.message]);
            stop_live_monitor();
        end
    end

    function out = ternary(cond, a, b)
    %TERNARY Simple ternary operator replacement
    %   Returns a if cond is true, b otherwise.
    %
    %   INPUTS:
    %       cond : logical, condition to evaluate
    %       a    : any, value returned if cond is true
    %       b    : any, value returned if cond is false
    %
    %   OUTPUT:
    %       out : either a or b depending on cond

        if cond, out = a; else, out = b; end
    end

    % ===================== Panel helper for R2020a =====================
    function pan = makePanel(parentLayout, rowIndex, titleText, fgColor, bgColor, borderColor)
    %MAKEPANEL Create a styled panel with title (compatible with R2020a)
    %   Creates a uipanel with a title row and separator line.
    %
    %   INPUTS:
    %       parentLayout : parent grid layout
    %       rowIndex     : row index in parent layout
    %       titleText    : string, panel title
    %       fgColor      : RGB triple for title text color
    %       bgColor      : RGB triple for background color
    %       borderColor  : RGB triple for separator line
    %
    %   OUTPUT:
    %       pan : handle to the content panel (where child controls go)

        % Create main panel
        outer = uipanel(parentLayout);
        outer.Layout.Row = rowIndex;
        outer.BackgroundColor = bgColor;
        outer.BorderType = 'line';
        outer.Title = '';

        % Create grid layout inside the panel
        wrapper = uigridlayout(outer, [2 1]);
        wrapper.RowHeight = {26, '1x'};
        wrapper.Padding = [0 0 0 0];
        wrapper.RowSpacing = 0;

        % Title row
        titleRow = uigridlayout(wrapper, [2 1]);
        titleRow.RowHeight = {20, 3};
        titleRow.Padding = [12 2 12 2];
        titleRow.RowSpacing = 0;

        % Title label
        uilabel(titleRow, 'Text', titleText, ...
            'FontWeight', 'bold', 'FontSize', 12, 'FontColor', fgColor);

        % Separator line (use a label with background color)
        rule = uilabel(titleRow, 'Text', '');
        rule.BackgroundColor = borderColor;

        % Content panel (where grids will be placed)
        pan = uipanel(wrapper);
        pan.Layout.Row = 2;
        pan.BackgroundColor = bgColor;
        pan.BorderType = 'none';
    end

    % Initial update of monitor positions
    update_monitor_positions();
end


function [p, tmesh, u, tm, file_path] = charger_donnees_temps(output_folder, nx, temps)
%CHARGER_DONNEES_TEMPS Robust time-dependent solution loader
%   Loads solution data for a specified mesh resolution and time from the
%   solutions_temporelles directory. Handles missing parameters intelligently:
%       - If time is empty, loads the latest available time for given nx
%       - If nx is empty, uses the finest available mesh resolution
%
%   INPUTS:
%       output_folder : string, path to solutions_temporelles directory
%       nx            : double, mesh resolution (number of points) - can be empty
%       temps         : double, requested time - can be empty (loads latest)
%
%   OUTPUTS:
%       p         : double matrix (np x 3), node coordinates [x,y,z]
%       tmesh     : double matrix (nt x 4), mesh connectivity/topology
%       u         : double vector (np x 1), solution values at nodes
%       tm        : double, actual time loaded (may differ from requested temps)
%       file_path : string, full path to loaded file (useful for debugging)
%
%   FILE NAMING CONVENTION:
%       solution_nx{value}_t{value}s.mat
%       Example: solution_nx17_t10s.mat
%
%   BEHAVIOR:
%       - Scans directory for all solution_nx*_t*.mat files
%       - Parses nx and t values from filenames
%       - If nx not provided, uses maximum available nx
%       - If temps provided, finds closest available time
%       - If temps empty, loads the latest time for chosen nx
%
%   OUTPUT:
%       Loaded data structure containing p, t, and solution field.

    p = []; tmesh = []; u = []; tm = []; file_path = '';

    if nargin < 2, nx = []; end
    if nargin < 3, temps = []; end

    if exist(output_folder,'dir') ~= 7
        fprintf(' Directory does not exist: %s\n', output_folder);
        return;
    end

    files = dir(fullfile(output_folder,'solution_nx*_t*s.mat'));
    if isempty(files)
        fprintf(' No solution_nx*_t*s.mat files in: %s\n', output_folder);
        return;
    end

    % ---- Extract (nx, t) from filenames ----
    NX = nan(numel(files),1);
    TT = nan(numel(files),1);

    for i=1:numel(files)
        name = files(i).name;

        tokNx = regexp(name,'solution_nx(\d+)_','tokens','once');
        tokT  = regexp(name,'_t([^s]+)s\.mat$','tokens','once'); % captures 10, 10.0, 1e-1, etc.

        if ~isempty(tokNx), NX(i) = str2double(tokNx{1}); end
        if ~isempty(tokT),  TT(i) = str2double(tokT{1});  end
    end

    ok = isfinite(NX) & isfinite(TT);
    NX = NX(ok); TT = TT(ok); files = files(ok);

    if isempty(files)
        fprintf(' Unable to parse nx/t from filenames in: %s\n', output_folder);
        return;
    end

    % ---- Select nx if not provided ----
    if isempty(nx)
        nx = max(NX);
    end

    idxNx = find(NX == nx);
    if isempty(idxNx)
        fprintf(' No files for nx=%d in: %s\n', nx, output_folder);
        return;
    end

    % ---- Select time ----
    TTnx = TT(idxNx);

    if isempty(temps)
        % Latest time
        [~,k] = max(TTnx);
        pick = idxNx(k);
    else
        % Closest time
        [~,k] = min(abs(TTnx - temps));
        pick = idxNx(k);
    end

    file_path = fullfile(output_folder, files(pick).name);

    if exist(file_path,'file') ~= 2
        fprintf(' File not found: %s\n', file_path);
        return;
    end

    data = load(file_path);

    % --- Solution field (u or u0) ---
    if isfield(data, 'u')
        u = data.u;
    elseif isfield(data, 'u0')
        u = data.u0;
    else
        fprintf(' Solution variable missing in: %s\n', file_path);
        return;
    end

    if isfield(data,'p'), p = data.p; else, fprintf(' p missing\n'); return; end
    if isfield(data,'t'), tmesh = data.t; else, fprintf(' t missing\n'); return; end

    % --- Actual time ---
    if isfield(data,'tm')
        tm = data.tm;
    else
        tm = TT(pick); % time extracted from filename
    end

    fprintf(' Loaded: nx=%d | t=%.6g | %s\n', nx, tm, files(pick).name);
end


function show_cut_from_file(sol_dir, nx, t, cut_mode, cut_val)
%SHOW_CUT_FROM_FILE Display 2D cross-sectional cut from saved solution data
%   Creates a publication-quality contour plot of the solution field on a specified
%   planar cut (constant x, y, or z), with formatting consistent with the
%   visualization_coupe_temps style.
%
%   INPUTS:
%       sol_dir  : string, directory containing solution files (solutions_temporelles)
%       nx       : double, mesh resolution parameter (number of points in each direction)
%       t        : double, target time for visualization
%       cut_mode : integer, cut plane orientation:
%                  1 = constant z (horizontal plane)
%                  2 = constant x (vertical plane, y-z view)
%                  3 = constant y (vertical plane, x-z view)
%       cut_val  : double, coordinate value for cut plane (should be between 0 and 1)
%
%   DATA LOADING:
%       Uses charger_donnees_temps() to load:
%           - p : node coordinates matrix [x,y,z]
%           - u : solution values at nodes
%           - tm: actual time loaded (may differ from requested t)
%
%   INTERPOLATION:
%       Creates a regular nx×nx×nx grid using griddata with linear interpolation.
%       The cut plane is extracted by finding the grid index closest to cut_val.
%
%   VISUALIZATION STYLE:
%       - Filled contour plot with 20 levels, no contour lines
%       - Axis equal with tight limits
%       - Font sizes: axis numbers 22, labels 24, colorbar 18, title 26
%       - Line width: 1.5 for axes
%       - Jet colormap with colorbar
%       - Minimal margins for maximum plot area
%
%   OUTPUT:
%       Creates a figure with the formatted cut visualization and prints
%       min/max value information to console.

    [p, ~, u, tm] = charger_donnees_temps(sol_dir, nx, t);
    if isempty(p), return; end
    if isempty(tm), tm = t; end

    % Regular grid (same idea as your code)
    [Xg,Yg,Zg] = meshgrid(linspace(0,1,nx), linspace(0,1,nx), linspace(0,1,nx));
    Ug = griddata(p(:,1),p(:,2),p(:,3),u,Xg,Yg,Zg,'linear');
    if all(isnan(Ug(:)))
        fprintf('Cut: only NaN.\n');
        return;
    end

    cut_val = max(0.01, min(0.99, cut_val));

    % Use a big figure feel (like your code)
    set(gcf,'Renderer','opengl');

    switch cut_mode
        case 1 % z constant
            [~,iz] = min(abs(Zg(1,1,:) - cut_val));
            Xc = squeeze(Xg(:,:,iz)); Yc = squeeze(Yg(:,:,iz)); Uc = squeeze(Ug(:,:,iz));
            contourf(Xc,Yc,Uc,20,'LineStyle','none');
            xlabel('x','FontSize',24,'FontWeight','bold');
            ylabel('y','FontSize',24,'FontWeight','bold');
            ttl = sprintf('Cut z=%.2f', cut_val);

        case 2 % x constant
            [~,ix] = min(abs(Xg(1,:,1) - cut_val));
            Yc = squeeze(Yg(:,ix,:)); Zc = squeeze(Zg(:,ix,:)); Uc = squeeze(Ug(:,ix,:));
            contourf(Yc,Zc,Uc,20,'LineStyle','none');
            xlabel('y','FontSize',11,'FontWeight','bold');
            ylabel('z','FontSize',11,'FontWeight','bold');
            ttl = sprintf('Cut x=%.2f', cut_val);

        case 3 % y constant
            [~,iy] = min(abs(Yg(:,1,1) - cut_val));
            Xc = squeeze(Xg(iy,:,:)); Zc = squeeze(Zg(iy,:,:)); Uc = squeeze(Ug(iy,:,:));
            contourf(Xc,Zc,Uc,20,'LineStyle','none');
            xlabel('x','FontSize',24,'FontWeight','bold');
            ylabel('z','FontSize',24,'FontWeight','bold');
            ttl = sprintf('Cut y=%.2f', cut_val);

        otherwise
            fprintf('Invalid cut_mode.\n');
            return;
    end

    % ---- Common formatting (copied from your visualization_coupe_temps style) ----
    ax = gca;
    ax.FontSize   = 22;
    ax.LineWidth  = 1.5;
    ax.FontWeight = 'bold';

    axis equal tight;
    axis on; box off; grid off;

    colormap(jet);
    cb = colorbar;
    cb.FontSize = 18;

    % Make the plot fill the window (less margins)
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));

    % Title big like your screenshot
    title(sprintf('%s (t=%.3f)', ttl, tm), 'FontSize', 26, 'FontWeight','bold');

    % Print range info (like your logs)
    umin = min(Uc(:)); umax = max(Uc(:));
    fprintf('Coupe t=%.3f : min(Uc)=%.3e, max(Uc)=%.3e\n', tm, umin, umax);
    fprintf('Plage des valeurs dans la coupe: min=%.3e, max=%.3e\n', umin, umax);
end