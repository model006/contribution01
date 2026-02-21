function choose_parameters()
%CHOOSE_PARAMETERS Interactive parameter selection for Coupled-Richards-Continuum-FEM
%   Creates a graphical user interface for selecting simulation parameters
%   and launching spatial/temporal convergence studies.
%
%   FIX (Error Table not showing):
%    (1) Do NOT rebuild folder name with sprintf('L=%.4f',L) -> it often doesn't match real folder.
%        We store the exact folder names found on disk (e.g., 'L=0.15') and reuse them.
%    (2) Your table title handle was created once, then deleted by cla(table_axes).
%        Now the title is recreated AFTER cla() inside draw_elegant_table().
%    (3) Robust field reading: accepts Erreur_L2 / ErreurL2 / error_L2 / etc. (same idea for h_values).
%
%   OUTPUT:
%       No direct output. Saves parameters to workspace and optionally runs main.m.
%
%   FEATURES:
%       - Interactive parameter selection with GUI
%       - Live progress monitoring
%       - CPU time visualization tab
%       - Error table visualization tab
%       - Automatic detection of completed simulations

    fprintf('\n============================================\n');
    fprintf('   INTERACTIVE PARAMETER SELECTION\n');
    fprintf('   Coupled-Richards-Continuum-FEM\n');
    fprintf('============================================\n\n');

    % ==================== CLEAN OLD RESULTS ====================
    try
        result_files = dir('*_results_*.mat');
        if ~isempty(result_files)
            fprintf('Cleaning %d old result files...\n', length(result_files));
            for i = 1:length(result_files)
                delete(result_files(i).name);
                fprintf('  Deleted: %s\n', result_files(i).name);
            end
            fprintf('Old results cleaned successfully.\n\n');
        else
            fprintf('No old result files found.\n\n');
        end
    catch ME
        fprintf('Warning: Could not clean old results: %s\n', ME.message);
    end

    % ========================= WINDOW =========================
    ss = get(0,'ScreenSize');
    fig = figure('Name', 'Coupled-Richards-Continuum-FEM - Quad Interface', ...
                 'NumberTitle', 'off', ...
                 'Units','pixels', ...
                 'Position', [0.1*ss(3) 0.05*ss(4) 0.8*ss(3) 0.9*ss(4)], ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'Resize', 'on', ...
                 'ResizeFcn', @on_resize, ...
                 'Color', [0.97 0.97 0.98]);

    % ========================= COLORS =========================
    BG   = [0.97 0.97 0.98];
    FG   = [0.10 0.10 0.12];
    MUT  = [0.45 0.45 0.48];
    LINE = [0.78 0.78 0.80];
    WHT  = [1 1 1];
    DIS  = [0.92 0.92 0.92];
    LIGHT_BLUE = [0.9 0.95 1];
    CPU_BLUE = [0.8 0.9 1];

    % ==================== MAIN TAB GROUP ====================
    main_tabgroup = uitabgroup('Parent', fig, ...
                               'Units', 'pixels', ...
                               'Position', [10, 10, 1280, 800], ...
                               'Tag', 'main_tabgroup');

    % ==================== TAB 1: PARAMETER SELECTION ====================
    tab1 = uitab('Parent', main_tabgroup, 'Title', 'Parameter Selection', ...
                 'BackgroundColor', BG);

    % Default values
    default_Nx_spatial  = '[5 9 17 33]';
    default_dt_spatial  = '0.025';
    default_Nx_temporal = '17';
    default_ell_values  = '1:3';
    default_L_vec       = '[0.15 0.25 0.65]';
    default_t_final     = '0.5';

    % ==================== TITLE ====================
    title_text = uicontrol('Parent', tab1, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [20, 760, 1240, 40], ...
              'String', 'Coupled-Richards-Continuum-FEM', ...
              'FontSize', 20, 'FontWeight', 'bold', ...
              'BackgroundColor', BG, ...
              'ForegroundColor', [0.2 0.2 0.8], ...
              'HorizontalAlignment', 'center');

    subtitle_text = uicontrol('Parent', tab1, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [20, 730, 1240, 25], ...
              'String', 'Select simulation parameters:', ...
              'FontSize', 14, 'FontWeight', 'normal', ...
              'BackgroundColor', BG, ...
              'ForegroundColor', FG, ...
              'HorizontalAlignment', 'center');

    % ==================== BLOCK 1: MODE ====================
    mode_panel = uipanel('Parent', tab1, 'Units', 'pixels', ...
                         'Position', [20, 640, 1240, 70], ...
                         'Title', ' SIMULATION MODE ', ...
                         'FontSize', 11, 'FontWeight', 'bold', ...
                         'BackgroundColor', BG, ...
                         'ForegroundColor', FG, ...
                         'BorderType', 'line', ...
                         'HighlightColor', LINE);

    uicontrol('Parent', mode_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [15, 25, 70, 22], ...
              'String', 'Mode:', ...
              'FontSize', 10, 'FontWeight', 'bold', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', BG, ...
              'ForegroundColor', FG);

    mode_popup = uicontrol('Parent', mode_panel, 'Style', 'popupmenu', 'Units', 'pixels', ...
                           'Position', [90, 25, 520, 22], ...
                           'String', {'Spatial study only (mesh refinement)', ...
                                      'Temporal study only (time step refinement)', ...
                                      'BOTH studies (spatial then temporal)'}, ...
                           'FontSize', 10, ...
                           'Value', 3, ...
                           'Callback', @mode_callback);

    % ==================== BLOCK 2: SPATIAL ====================
    spatial_panel = uipanel('Parent', tab1, 'Units', 'pixels', ...
                            'Position', [20, 450, 600, 180], ...
                            'Title', ' SPATIAL STUDY PARAMETERS ', ...
                            'FontSize', 11, 'FontWeight', 'bold', ...
                            'BackgroundColor', BG, ...
                            'ForegroundColor', FG, ...
                            'BorderType', 'line', ...
                            'HighlightColor', LINE);

    uicontrol('Parent', spatial_panel, 'Style', 'text', 'Units', 'pixels', ...
          'Position', [15, 135, 280, 20], ...   
          'String', 'Spatial discretization levels (Nx):', ...
          'FontSize', 10, 'FontWeight', 'bold', ...
          'HorizontalAlignment', 'left', ...
          'BackgroundColor', BG, ...
          'ForegroundColor', FG);


    nx_spatial_edit = uicontrol('Parent', spatial_panel, 'Style', 'edit', 'Units', 'pixels', ...
                                 'Position', [250, 133, 260, 22], ...
                                 'String', default_Nx_spatial, ...
                                 'FontSize', 10, ...
                                 'BackgroundColor', WHT, ...
                                 'TooltipString', 'Enter MATLAB vector like [17 33 65] or 17:16:65', ...
                                 'Callback', @update_h_spatial);

    uicontrol('Parent', spatial_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [15, 103, 70, 18], ...
              'String', 'h values:', ...
              'FontSize', 9, ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', BG, ...
              'ForegroundColor', MUT);

    h_spatial_text = uicontrol('Parent', spatial_panel, 'Style', 'edit', 'Units', 'pixels', ...
                                'Position', [250, 102, 260, 20], ...
                                'String', 'h = []', ...
                                'FontSize', 9, ...
                                'ForegroundColor', MUT, ...
                                'BackgroundColor', [1 1 0.9], ...
                                'HorizontalAlignment', 'left', ...
                                'Enable', 'inactive');

    uicontrol('Parent', spatial_panel, 'Style', 'text', 'Units', 'pixels', ...
          'Position', [15, 73, 140, 20], ...   % 70 -> 140
          'String', 'Time Step (dt):', ...
          'FontSize', 10, 'FontWeight', 'bold', ...
          'HorizontalAlignment', 'left', ...
          'BackgroundColor', BG, ...
          'ForegroundColor', FG);

    dt_spatial_edit = uicontrol('Parent', spatial_panel, 'Style', 'edit', 'Units', 'pixels', ...
                                 'Position', [250, 72, 100, 22], ...
                                 'String', default_dt_spatial, ...
                                 'FontSize', 10, ...
                                 'BackgroundColor', WHT, ...
                                 'TooltipString', 'Fixed time step for spatial study');

    spatial_progress_text = uicontrol('Parent', spatial_panel, 'Style', 'text', 'Units', 'pixels', ...
                                      'Position', [15, 30, 550, 35], ...
                                      'String', 'Spatial progress: Not started', ...
                                      'FontSize', 9, ...
                                      'ForegroundColor', MUT, ...
                                      'HorizontalAlignment', 'left', ...
                                      'BackgroundColor', BG);

    % ==================== BLOCK 3: TEMPORAL ====================
    temporal_panel = uipanel('Parent', tab1, 'Units', 'pixels', ...
                             'Position', [660, 450, 600, 180], ...
                             'Title', ' TEMPORAL STUDY PARAMETERS ', ...
                             'FontSize', 11, 'FontWeight', 'bold', ...
                             'BackgroundColor', BG, ...
                             'ForegroundColor', FG, ...
                             'BorderType', 'line', ...
                             'HighlightColor', LINE);

    uicontrol('Parent', temporal_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [15, 135, 70, 20], ...
              'String', 'Fixed Nx:', ...
              'FontSize', 10, 'FontWeight', 'bold', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', BG, ...
              'ForegroundColor', FG);

    nx_temporal_edit = uicontrol('Parent', temporal_panel, 'Style', 'edit', 'Units', 'pixels', ...
                                  'Position', [90, 133, 70, 22], ...
                                  'String', default_Nx_temporal, ...
                                  'FontSize', 10, ...
                                  'BackgroundColor', WHT, ...
                                  'TooltipString', 'Fixed mesh size for temporal convergence study', ...
                                  'Callback', @update_h_temporal);

    uicontrol('Parent', temporal_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [15, 103, 70, 18], ...
              'String', 'h value:', ...
              'FontSize', 9, ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', BG, ...
              'ForegroundColor', MUT);

    h_temporal_text = uicontrol('Parent', temporal_panel, 'Style', 'edit', 'Units', 'pixels', ...
                                 'Position', [90, 102, 170, 20], ...
                                 'String', 'h = []', ...
                                 'FontSize', 9, ...
                                 'ForegroundColor', MUT, ...
                                 'BackgroundColor', [1 1 0.9], ...
                                 'HorizontalAlignment', 'left', ...
                                 'Enable', 'inactive');

    uicontrol('Parent', temporal_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [15, 73, 70, 18], ...
              'String', 'ell values:', ...
              'FontSize', 9, 'FontWeight', 'bold', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', BG, ...
              'ForegroundColor', FG);

    ell_edit = uicontrol('Parent', temporal_panel, 'Style', 'edit', 'Units', 'pixels', ...
                         'Position', [90, 71, 100, 22], ...
                         'String', default_ell_values, ...
                         'FontSize', 10, ...
                         'BackgroundColor', WHT, ...
                         'TooltipString', 'Vector of ell values (dt = 0.1*2^(1-ell))', ...
                         'Callback', @update_dt_temporal);

    uicontrol('Parent', temporal_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [200, 71, 150, 22], ...
              'String', '(ell from 1 to n)', ...
              'FontSize', 9, ...
              'FontAngle', 'italic', ...
              'ForegroundColor', MUT, ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', BG);

    uicontrol('Parent', temporal_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [15, 43, 70, 18], ...
              'String', 'dt values:', ...
              'FontSize', 9, ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', BG, ...
              'ForegroundColor', MUT);

    dt_temporal_text = uicontrol('Parent', temporal_panel, 'Style', 'edit', 'Units', 'pixels', ...
                                  'Position', [90, 42, 320, 20], ...
                                  'String', 'dt = []', ...
                                  'FontSize', 9, ...
                                  'ForegroundColor', MUT, ...
                                  'BackgroundColor', [1 1 0.9], ...
                                  'HorizontalAlignment', 'left', ...
                                  'Enable', 'inactive');

    temporal_progress_text = uicontrol('Parent', temporal_panel, 'Style', 'text', 'Units', 'pixels', ...
                                       'Position', [15, 10, 550, 25], ...
                                       'String', 'Temporal progress: Not started', ...
                                       'FontSize', 9, ...
                                       'ForegroundColor', MUT, ...
                                       'HorizontalAlignment', 'left', ...
                                       'BackgroundColor', BG);

    % ==================== BLOCK 4: COMMON PARAMETERS ====================
    common_panel = uipanel('Parent', tab1, 'Units', 'pixels', ...
                           'Position', [20, 250, 1240, 190], ...
                           'Title', ' GLOBAL TIME AND STABILIZATION PARAMETERS ', ...
                           'FontSize', 11, 'FontWeight', 'bold', ...
                           'BackgroundColor', BG, ...
                           'ForegroundColor', FG, ...
                           'BorderType', 'line', ...
                           'HighlightColor', LINE);

    uicontrol('Parent', common_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [20, 145, 80, 20], ...
              'String', 'L values:', ...
              'FontSize', 10, 'FontWeight', 'bold', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', BG, ...
              'ForegroundColor', FG);

    L_edit = uicontrol('Parent', common_panel, 'Style', 'edit', 'Units', 'pixels', ...
                       'Position', [110, 143, 400, 22], ...
                       'String', default_L_vec, ...
                       'FontSize', 10, ...
                       'BackgroundColor', WHT, ...
                       'TooltipString', 'Vector of L values for L-scheme', ...
                       'Callback', @update_L_status);

    uicontrol('Parent', common_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [110, 120, 400, 16], ...
              'String', 'Example: [0.15 0.25 0.65 1]', ...
              'FontSize', 9, ...
              'ForegroundColor', MUT, ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', BG);

    L_status_text = uicontrol('Parent', common_panel, 'Style', 'text', 'Units', 'pixels', ...
                               'Position', [20, 70, 600, 45], ...
                               'String', 'L status: Not simulated yet', ...
                               'FontSize', 9, ...
                               'FontWeight', 'bold', ...
                               'ForegroundColor', [0.2 0.2 0.5], ...
                               'HorizontalAlignment', 'left', ...
                               'BackgroundColor', LIGHT_BLUE);

    L_details_text = uicontrol('Parent', common_panel, 'Style', 'text', 'Units', 'pixels', ...
                                'Position', [20, 30, 600, 30], ...
                                'String', 'Details: Waiting for simulation...', ...
                                'FontSize', 9, ...
                                'ForegroundColor', MUT, ...
                                'HorizontalAlignment', 'left', ...
                                'BackgroundColor', BG);

    uicontrol('Parent', common_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [650, 145, 120, 20], ...
              'String', 'Final time T:', ...
              'FontSize', 10, 'FontWeight', 'bold', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', BG, ...
              'ForegroundColor', FG);

    tfinal_edit = uicontrol('Parent', common_panel, 'Style', 'edit', 'Units', 'pixels', ...
                             'Position', [750, 143, 120, 22], ...
                             'String', default_t_final, ...
                             'FontSize', 10, ...
                             'BackgroundColor', WHT, ...
                             'TooltipString', 'Final simulation time', ...
                             'Callback', @update_tfinal);

    tfinal_display = uicontrol('Parent', common_panel, 'Style', 'text', 'Units', 'pixels', ...
                                'Position', [880, 143, 160, 20], ...
                                'String', sprintf('T = %s', default_t_final), ...
                                'FontSize', 9, ...
                                'ForegroundColor', MUT, ...
                                'HorizontalAlignment', 'left', ...
                                'BackgroundColor', BG);

    run_checkbox = uicontrol('Parent', tab1, 'Style', 'checkbox', 'Units', 'pixels', ...
                              'Position', [20, 215, 300, 22], ...
                              'String', 'Run main.m after saving parameters', ...
                              'FontSize', 10, ...
                              'Value', 1, ...
                              'BackgroundColor', BG, ...
                              'ForegroundColor', FG);

    % ==================== LIVE MONITOR ====================
    monitor_panel = uipanel('Parent', tab1, 'Units', 'pixels', ...
                            'Position', [20, 30, 920, 170], ...
                            'Title', ' LIVE MONITOR ', ...
                            'FontSize', 11, 'FontWeight', 'bold', ...
                            'BackgroundColor', BG, ...
                            'ForegroundColor', FG, ...
                            'BorderType', 'line', ...
                            'HighlightColor', LINE);

    log_box = uicontrol('Parent', monitor_panel, 'Style', 'listbox', 'Units', 'pixels', ...
                        'Position', [20, 50, 880, 90], ...
                        'BackgroundColor', WHT, ...
                        'FontName', 'Consolas', ...
                        'FontSize', 9, ...
                        'Max', 2, 'Min', 0, ...
                        'String', {'--- Live log ---'});

    progress_frame = uicontrol('Parent', monitor_panel, 'Style', 'text', 'Units', 'pixels', ...
              'Position', [20, 30, 880, 10], ...
              'BackgroundColor', [0.88 0.88 0.90], ...
              'HorizontalAlignment', 'left', ...
              'String', '');

    progress_fill = uicontrol('Parent', monitor_panel, 'Style', 'text', 'Units', 'pixels', ...
                              'Position', [20, 30, 10, 10], ...
                              'BackgroundColor', [0.35 0.35 0.38], ...
                              'HorizontalAlignment', 'left', ...
                              'String', '');

    status_text = uicontrol('Parent', monitor_panel, 'Style', 'text', 'Units', 'pixels', ...
                            'Position', [20, 5, 880, 15], ...
                            'String', 'Status: idle', ...
                            'BackgroundColor', BG, ...
                            'ForegroundColor', FG, ...
                            'HorizontalAlignment', 'left');

    btnY = 30; btnH = 42; btnW = 170;

    btn_save = uicontrol('Parent', tab1, 'Style', 'pushbutton', 'Units', 'pixels', ...
              'Position', [960, btnY, btnW, btnH], ...
              'String', 'Save & Run', ...
              'FontSize', 11, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.94 0.94 0.94], ...
              'ForegroundColor', FG, ...
              'Callback', @save_and_run_callback);

    btn_cancel = uicontrol('Parent', tab1, 'Style', 'pushbutton', 'Units', 'pixels', ...
              'Position', [1240-btnW, btnY, btnW, btnH], ...
              'String', 'Cancel', ...
              'FontSize', 11, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.94 0.94 0.94], ...
              'ForegroundColor', FG, ...
              'Callback', @(~,~)close(fig));

    % ==================== TAB 2: CPU TIME ====================
    tab2 = uitab('Parent', main_tabgroup, 'Title', 'CPU Time', ...
                 'BackgroundColor', BG);

    cpu_panel = uipanel('Parent', tab2, ...
                        'Units', 'pixels', ...
                        'Position', [20, 700, 1240, 70], ...
                        'Title', ' CPU Time Visualization ', ...
                        'FontSize', 12, 'FontWeight', 'bold', ...
                        'BackgroundColor', CPU_BLUE);

    uicontrol('Parent', cpu_panel, 'Style', 'text', ...
        'Position', [20, 25, 80, 20], ...
        'String', 'Study type:', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', CPU_BLUE);

    cpu_study_popup = uicontrol('Parent', cpu_panel, 'Style', 'popupmenu', ...
        'Position', [100, 25, 150, 25], ...
        'String', {'Spatial study', 'Temporal study'}, ...
        'Value', 1, ...
        'FontSize', 11, ...
        'Callback', @cpu_study_callback);

    uicontrol('Parent', cpu_panel, 'Style', 'text', ...
        'Position', [280, 25, 50, 20], ...
        'String', 'L value:', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', CPU_BLUE);

    cpu_L_popup = uicontrol('Parent', cpu_panel, 'Style', 'popupmenu', ...
        'Position', [340, 25, 150, 25], ...
        'String', {'No data available'}, ...
        'Value', 1, ...
        'FontSize', 11, ...
        'Callback', @cpu_L_callback);

    cpu_refresh_btn = uicontrol('Parent', cpu_panel, 'Style', 'pushbutton', ...
        'Position', [520, 20, 120, 30], ...
        'String', 'Refresh Data', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.8 0.9 1], ...
        'Callback', @cpu_refresh_callback);

    cpu_chk_logx = uicontrol('Parent', cpu_panel, 'Style', 'checkbox', ...
        'Position', [680, 25, 120, 25], ...
        'String', 'Log scale X', ...
        'Value', 1, ...
        'Callback', @(~,~)cpu_update_plot(guidata(fig)));

    cpu_chk_logy = uicontrol('Parent', cpu_panel, 'Style', 'checkbox', ...
        'Position', [820, 25, 120, 25], ...
        'String', 'Log scale Y', ...
        'Value', 1, ...
        'Callback', @(~,~)cpu_update_plot(guidata(fig)));

    cpu_path_text = uicontrol('Parent', cpu_panel, 'Style', 'text', ...
        'Position', [960, 25, 260, 25], ...
        'String', 'Results path: Not found', ...
        'FontSize', 9, ...
        'ForegroundColor', [0.5 0.5 0.5], ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', CPU_BLUE);

    cpu_ax = axes('Parent', tab2, 'Units', 'pixels', ...
        'Position', [80, 150, 1100, 520], ...
        'FontSize', 10);
    title(cpu_ax, 'CPU Time Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel(cpu_ax, '');
    ylabel(cpu_ax, 'CPU Time (s)');
    grid(cpu_ax, 'on'); box(cpu_ax, 'on'); hold(cpu_ax, 'on');

    cpu_status_text = uicontrol('Parent', tab2, 'Style', 'text', ...
        'Position', [20, 70, 1240, 25], ...
        'String', 'Ready. Click Refresh Data to load results.', ...
        'FontSize', 10, ...
        'BackgroundColor', BG, ...
        'ForegroundColor', [0.2 0.2 0.2], ...
        'HorizontalAlignment', 'left');

    % ==================== TAB 3: ERROR TABLE ====================
    tab3 = uitab('Parent', main_tabgroup, 'Title', 'Error Table', ...
                 'BackgroundColor', BG);

    table_control_panel = uipanel('Parent', tab3, ...
                                  'Units', 'pixels', ...
                                  'Position', [20, 700, 1240, 80], ...
                                  'Title', ' Error Table Controls ', ...
                                  'FontSize', 12, 'FontWeight', 'bold', ...
                                  'BackgroundColor', [0.9 0.95 1]);

    table_load_btn = uicontrol('Parent', table_control_panel, 'Style', 'pushbutton', ...
        'Position', [20, 25, 100, 30], ...
        'String', 'Load Data', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.7 0.8 1], ...
        'Callback', @error_table_load_data);

    uicontrol('Parent', table_control_panel, 'Style', 'text', ...
        'Position', [140, 30, 30, 20], ...
        'String', 'L:', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.9 0.95 1], ...
        'HorizontalAlignment', 'right');

    table_L_popup = uicontrol('Parent', table_control_panel, 'Style', 'popupmenu', ...
        'Position', [170, 30, 150, 25], ...
        'String', {'No data'}, ...
        'Value', 1, ...
        'FontSize', 10, ...
        'Callback', @error_table_refresh);

    uicontrol('Parent', table_control_panel, 'Style', 'text', ...
        'Position', [340, 30, 80, 20], ...
        'String', 'Study type:', ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.9 0.95 1], ...
        'HorizontalAlignment', 'right');

    table_study_popup = uicontrol('Parent', table_control_panel, 'Style', 'popupmenu', ...
        'Position', [420, 30, 120, 25], ...
        'String', {'Spatial study'}, ...
        'Value', 1, ...
        'FontSize', 10, ...
        'Callback', @error_table_refresh);

    table_refresh_btn = uicontrol('Parent', table_control_panel, 'Style', 'pushbutton', ...
        'Position', [560, 25, 100, 30], ...
        'String', 'Refresh', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.8 0.9 1], ...
        'Callback', @error_table_refresh);

    table_export_btn = uicontrol('Parent', table_control_panel, 'Style', 'pushbutton', ...
        'Position', [680, 25, 100, 30], ...
        'String', 'Export', ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'Callback', @error_table_export);

    table_status_text = uicontrol('Parent', table_control_panel, 'Style', 'text', ...
        'Position', [800, 30, 400, 20], ...
        'String', 'Ready - Click Load Data to view results', ...
        'FontSize', 10, ...
        'ForegroundColor', [0.2 0.2 0.2], ...
        'BackgroundColor', [0.9 0.95 1], ...
        'HorizontalAlignment', 'left', ...
        'FontWeight', 'bold');

    table_display_panel = uipanel('Parent', tab3, ...
                                  'Units', 'pixels', ...
                                  'Position', [20, 120, 1240, 570], ...
                                  'Title', ' Convergence Analysis ', ...
                                  'FontSize', 11, 'FontWeight', 'bold', ...
                                  'BackgroundColor', [1 1 1], ...
                                  'BorderType', 'line', ...
                                  'HighlightColor', [0.55 0.62 0.78]);

    table_axes = axes('Parent', table_display_panel, ...
                      'Units', 'pixels', ...
                      'Position', [10, 10, 1220, 530], ...
                      'Visible', 'off', ...
                      'XLim', [0 1], 'YLim', [0 1]);

    stats_panel = uipanel('Parent', tab3, ...
                          'Units', 'pixels', ...
                          'Position', [20, 30, 1240, 80], ...
                          'Title', ' Summary Statistics ', ...
                          'FontSize', 11, 'FontWeight', 'bold', ...
                          'BackgroundColor', [0.95 0.98 1], ...
                          'BorderType', 'line', ...
                          'HighlightColor', [0.55 0.62 0.78]);

    stats_axes = axes('Parent', stats_panel, ...
                      'Units', 'pixels', ...
                      'Position', [10, 10, 1220, 40], ...
                      'Visible', 'off', ...
                      'XLim', [0 1], 'YLim', [0 1]);

    stats_text_handle = text('Parent', stats_axes, ...
        'Position', [0.5, 0.5], ...
        'String', 'No data loaded', ...
        'FontSize', 12, ...
        'Color', [0.10 0.20 0.45], ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'latex');

    % ==================== HANDLES STRUCTURE ====================
    handles = struct();
    handles.fig = fig;
    handles.main_tabgroup = main_tabgroup;

    % Tab 1
    handles.title_text = title_text;
    handles.subtitle_text = subtitle_text;
    handles.mode_panel = mode_panel;
    handles.spatial_panel = spatial_panel;
    handles.temporal_panel = temporal_panel;
    handles.common_panel = common_panel;
    handles.monitor_panel = monitor_panel;
    handles.mode_popup = mode_popup;
    handles.nx_spatial_edit = nx_spatial_edit;
    handles.dt_spatial_edit = dt_spatial_edit;
    handles.spatial_progress_text = spatial_progress_text;
    handles.nx_temporal_edit = nx_temporal_edit;
    handles.ell_edit = ell_edit;
    handles.h_spatial_text = h_spatial_text;
    handles.h_temporal_text = h_temporal_text;
    handles.dt_temporal_text = dt_temporal_text;
    handles.temporal_progress_text = temporal_progress_text;
    handles.L_edit = L_edit;
    handles.L_status_text = L_status_text;
    handles.L_details_text = L_details_text;
    handles.tfinal_edit = tfinal_edit;
    handles.tfinal_display = tfinal_display;
    handles.run_checkbox = run_checkbox;
    handles.log_box = log_box;
    handles.progress_frame = progress_frame;
    handles.progress_fill = progress_fill;
    handles.status_text = status_text;
    handles.btn_save = btn_save;
    handles.btn_cancel = btn_cancel;

    % Tab 2
    handles.cpu_study_popup = cpu_study_popup;
    handles.cpu_L_popup = cpu_L_popup;
    handles.cpu_refresh_btn = cpu_refresh_btn;
    handles.cpu_chk_logx = cpu_chk_logx;
    handles.cpu_chk_logy = cpu_chk_logy;
    handles.cpu_path_text = cpu_path_text;
    handles.cpu_ax = cpu_ax;
    handles.cpu_status_text = cpu_status_text;

    % Tab 3
    handles.table_control_panel = table_control_panel;
    handles.table_load_btn = table_load_btn;
    handles.table_L_popup = table_L_popup;
    handles.table_study_popup = table_study_popup;
    handles.table_refresh_btn = table_refresh_btn;
    handles.table_export_btn = table_export_btn;
    handles.table_status_text = table_status_text;
    handles.table_display_panel = table_display_panel;
    handles.table_axes = table_axes;
    handles.stats_panel = stats_panel;
    handles.stats_axes = stats_axes;
    handles.stats_text_handle = stats_text_handle;

    % Data storage for CPU
    handles.cpu_spatial_data = {};
    handles.cpu_temporal_data = {};
    handles.cpu_available_L = [];
    handles.cpu_results_path = '';

    % Progress L_data
    L_data = struct();
    L_data.values = [];
    L_data.spatial_completed = [];
    L_data.temporal_completed = [];
    L_data.spatial_nx_done = {};
    L_data.temporal_dt_done = {};
    L_data.current_spatial_L = [];
    L_data.current_temporal_L = [];
    L_data.current_spatial_nx = [];
    L_data.current_temporal_dt = [];
    setappdata(fig, 'L_data', L_data);

    guidata(fig, handles);

    % Initial layout & updates
    do_layout(fig);
    mode_callback(mode_popup, []);
    update_h_spatial(nx_spatial_edit, []);
    update_h_temporal(nx_temporal_edit, []);
    update_dt_temporal(ell_edit, []);
    update_tfinal(tfinal_edit, []);
    update_L_status(L_edit, []);

    % Load available data
    cpu_load_available_data(guidata(fig));
    try
        error_table_load_data(handles.table_load_btn, []);
    catch
    end

% =========================================================================
% RESIZE / LAYOUT
% =========================================================================
    function on_resize(fig_, ~)
        do_layout(fig_);
    end

    function do_layout(fig_)
        if ~ishandle(fig_), return; end
        h = guidata(fig_);
        if isempty(h) || ~isfield(h, 'main_tabgroup'), return; end

        pos = get(fig_, 'Position');
        W2 = pos(3); H2 = pos(4);
        set(h.main_tabgroup, 'Position', [10, 10, W2-20, H2-20]);
        drawnow limitrate;

        % ----- Buttons layout (bottom-right, separated) -----
        margin = 70;
        gap    = 20;
        btnW   = 170;
        btnH   = 42;
        btnY   = 100;
        
        % rightmost = Cancel
        x_cancel = (W2 - margin - btnW);
        x_save   = (x_cancel - gap - btnW);
        
        set(h.btn_cancel, 'Position', [x_cancel, btnY, btnW, btnH]);
        set(h.btn_save,   'Position', [x_save,   btnY, btnW, btnH]);
        shift = 10;                 % pixels vers la droite
      

    end

% =========================================================================
% EXPORT
% =========================================================================
    function error_table_export(src, ~)
        h = guidata(ancestor(src,'figure'));

        errL2 = getappdata(h.fig, 'error_table_errL2');
        un_sur_h = getappdata(h.fig, 'error_table_un_sur_h');

        if isempty(errL2)
            errordlg('No data to export', 'Export Error');
            return;
        end

        L_idx = get(h.table_L_popup, 'Value');
        L_strings = get(h.table_L_popup, 'String');
        L_name = L_strings{L_idx};

        [file, path] = uiputfile({'*.txt', 'Text File'; '*.csv', 'CSV File'}, ...
            'Export Error Table', sprintf('spatial_analysis_%s.txt', strrep(L_name, ' ', '_')));

        if isequal(file, 0) || isequal(path, 0), return; end

        fullpath = fullfile(path, file);
        fid = fopen(fullpath, 'w');
        if fid == -1
            errordlg('Could not open file for writing', 'Export Error');
            return;
        end

        fprintf(fid, '# Spatial Error Analysis for %s\n', L_name);
        fprintf(fid, '# Generated: %s\n\n', datestr(now));
        fprintf(fid, 'h\tL2 Error\tH1 Error\tkappa_max\tCPU (s)\tIter\tOrder\n');

        for i = 1:length(un_sur_h)
            fprintf(fid, '1/%d\t%.4e\t', round(un_sur_h(i)), errL2(i));
            fprintf(fid, '-\t-\t-\t-\t');
            if i > 1
                ord = log10(errL2(i-1) / errL2(i)) / log10(2);
                fprintf(fid, '%.2f\n', ord);
            else
                fprintf(fid, '-\n');
            end
        end

        fclose(fid);
        set(h.table_status_text, 'String', sprintf('Exported to: %s', file));
    end

% =========================================================================
% CALLBACKS: small helpers
% =========================================================================
    function update_tfinal(src, ~)
        h = guidata(ancestor(src,'figure'));
        try
            t_str = get(h.tfinal_edit, 'String');
            t_val = eval(t_str);
            if isnumeric(t_val) && isscalar(t_val) && t_val > 0
                set(h.tfinal_display, 'String', sprintf('T = %.4g', t_val), 'ForegroundColor', MUT);
            else
                set(h.tfinal_display, 'String', 'T = (invalid)', 'ForegroundColor', [1 0 0]);
            end
        catch
            set(h.tfinal_display, 'String', 'T = (invalid)', 'ForegroundColor', [1 0 0]);
        end
    end

    function mode_callback(src, ~)
        h = guidata(ancestor(src,'figure'));
        mode = get(src, 'Value');
        switch mode
            case 1
                set(h.nx_spatial_edit, 'Enable', 'on',  'BackgroundColor', WHT);
                set(h.dt_spatial_edit, 'Enable', 'on',  'BackgroundColor', WHT);
                set(h.nx_temporal_edit, 'Enable', 'off', 'BackgroundColor', DIS);
                set(h.ell_edit,         'Enable', 'off', 'BackgroundColor', DIS);
            case 2
                set(h.nx_spatial_edit, 'Enable', 'off', 'BackgroundColor', DIS);
                set(h.dt_spatial_edit, 'Enable', 'off', 'BackgroundColor', DIS);
                set(h.nx_temporal_edit, 'Enable', 'on',  'BackgroundColor', WHT);
                set(h.ell_edit,         'Enable', 'on',  'BackgroundColor', WHT);
            case 3
                set(h.nx_spatial_edit, 'Enable', 'on',  'BackgroundColor', WHT);
                set(h.dt_spatial_edit, 'Enable', 'on',  'BackgroundColor', WHT);
                set(h.nx_temporal_edit, 'Enable', 'on',  'BackgroundColor', WHT);
                set(h.ell_edit,         'Enable', 'on',  'BackgroundColor', WHT);
        end
    end

    function update_h_spatial(src, ~)
        h = guidata(ancestor(src,'figure'));
        try
            nx_str = get(h.nx_spatial_edit, 'String');
            nx_values = eval(nx_str);
            if isnumeric(nx_values) && ~isempty(nx_values)
                h_str = 'h = [';
                for i = 1:length(nx_values)
                    denom = nx_values(i) - 1;
                    h_str = [h_str sprintf('1/%d', denom)];
                    if i < length(nx_values), h_str = [h_str '   ']; end
                end
                h_str = [h_str ']'];
                set(h.h_spatial_text, 'String', h_str, 'ForegroundColor', MUT, 'BackgroundColor', [0.95 0.95 0.9]);
            else
                set(h.h_spatial_text, 'String', 'h = []', 'ForegroundColor', [1 0 0], 'BackgroundColor', [0.95 0.95 0.9]);
            end
        catch
            set(h.h_spatial_text, 'String', 'h = []', 'ForegroundColor', [1 0 0], 'BackgroundColor', [0.95 0.95 0.9]);
        end
    end

    function update_h_temporal(src, ~)
        h = guidata(ancestor(src,'figure'));
        try
            nx_value = eval(get(h.nx_temporal_edit, 'String'));
            if isnumeric(nx_value) && isscalar(nx_value) && nx_value >= 2
                denom = nx_value - 1;
                set(h.h_temporal_text, 'String', sprintf('h = 1/%d = %.4f', denom, 1/denom), ...
                    'ForegroundColor', MUT, 'BackgroundColor', [0.95 0.95 0.9]);
            else
                set(h.h_temporal_text, 'String', 'h = []', 'ForegroundColor', [1 0 0], 'BackgroundColor', [0.95 0.95 0.9]);
            end
        catch
            set(h.h_temporal_text, 'String', 'h = []', 'ForegroundColor', [1 0 0], 'BackgroundColor', [0.95 0.95 0.9]);
        end
    end

    function update_dt_temporal(src, ~)
        h = guidata(ancestor(src,'figure'));
        try
            ell_values = eval(get(h.ell_edit, 'String'));
            if isnumeric(ell_values) && ~isempty(ell_values)
                dtv = 0.1 * 2.^(1 - ell_values(:));
                set(h.dt_temporal_text, 'String', sprintf('dt = %s', mat2str(dtv', 4)), ...
                    'ForegroundColor', MUT, 'BackgroundColor', [0.95 0.95 0.9]);
            else
                set(h.dt_temporal_text, 'String', 'dt = []', 'ForegroundColor', [1 0 0], 'BackgroundColor', [0.95 0.95 0.9]);
            end
        catch
            set(h.dt_temporal_text, 'String', 'dt = []', 'ForegroundColor', [1 0 0], 'BackgroundColor', [0.95 0.95 0.9]);
        end
    end

    function update_L_status(src, ~)
        h = guidata(ancestor(src,'figure'));
        try
            L_vec = eval(get(h.L_edit, 'String'));
            if isnumeric(L_vec) && ~isempty(L_vec)
                L_vec = L_vec(:)';

                L_data = getappdata(h.fig, 'L_data');
                status_msg = 'L status: ';
                details_msg = 'Details: ';

                for i = 1:length(L_vec)
                    L_val = L_vec(i);

                    spatial_completed = ~isempty(L_data.spatial_completed) && any(abs(L_data.spatial_completed - L_val) < 1e-10);
                    temporal_completed = ~isempty(L_data.temporal_completed) && any(abs(L_data.temporal_completed - L_val) < 1e-10);

                    if spatial_completed && temporal_completed
                        status_msg = [status_msg sprintf('L=%.2f[✓S✓T]  ', L_val)];
                    elseif spatial_completed
                        status_msg = [status_msg sprintf('L=%.2f[✓S□T]  ', L_val)];
                    elseif temporal_completed
                        status_msg = [status_msg sprintf('L=%.2f[□S✓T]  ', L_val)];
                    else
                        status_msg = [status_msg sprintf('L=%.2f[□S□T]  ', L_val)];
                    end

                    if spatial_completed
                        nx_done = '';
                        if i <= length(L_data.spatial_nx_done) && ~isempty(L_data.spatial_nx_done{i})
                            nx_done = sprintf('Nx=%s done', mat2str(L_data.spatial_nx_done{i}));
                        end
                        details_msg = [details_msg sprintf('L=%.2f: %s  ', L_val, nx_done)];
                    end

                    if mod(i, 2) == 0 && i < length(L_vec)
                        status_msg = [status_msg newline '           '];
                    end
                end

                set(h.L_status_text, 'String', status_msg, 'ForegroundColor', [0.2 0.2 0.5]);
                set(h.L_details_text, 'String', details_msg, 'ForegroundColor', MUT);
            end
        catch
            set(h.L_status_text, 'String', 'L status: Invalid L values', 'ForegroundColor', [1 0 0]);
        end
    end

% =========================================================================
% CPU PREVIEW FUNCTIONS
% =========================================================================
    function cpu_load_available_data(h)
        current_dir = fileparts(mfilename('fullpath'));
        results_path = fullfile(current_dir, 'results', 'numerical_validation', 'L-scheme');

        if ~exist(results_path, 'dir')
            set(h.cpu_path_text, 'String', 'Results path: Not found');
            set(h.cpu_status_text, 'String', 'Error: Results directory not found.');
            guidata(h.fig, h);
            return;
        end

        set(h.cpu_path_text, 'String', ['Results path: ' results_path]);

        L_dirs = dir(fullfile(results_path, 'L=*'));
        L_dirs = L_dirs([L_dirs.isdir]);

        L_values = [];
        spatial_data = {};
        temporal_data = {};
        folder_names = {};

        for i = 1:length(L_dirs)
            L_name = L_dirs(i).name;
            tok = regexp(L_name, 'L=([0-9.eE+-]+)', 'tokens', 'once');
            if ~isempty(tok)
                L_val = str2double(tok{1});
                L_values = [L_values; L_val];
                folder_names{end+1} = L_name;

                spatial_file = fullfile(results_path, L_name, 'spatial', 'resultats_complets', 'resultats_spatiaux.mat');
                if exist(spatial_file, 'file')
                    spatial_data{end+1} = load(spatial_file);
                else
                    spatial_data{end+1} = [];
                end

                temporal_file = fullfile(results_path, L_name, 'temporel', 'resultats_complets', 'resultats_temporels.mat');
                if exist(temporal_file, 'file')
                    temporal_data{end+1} = load(temporal_file);
                else
                    temporal_data{end+1} = [];
                end
            end
        end

        [L_values, idx] = sort(L_values);
        spatial_data = spatial_data(idx);
        temporal_data = temporal_data(idx);
        folder_names = folder_names(idx);

        L_strings = arrayfun(@(x) sprintf('L = %.4f', x), L_values, 'UniformOutput', false);
        if isempty(L_strings), L_strings = {'No data available'}; end
        set(h.cpu_L_popup, 'String', L_strings, 'Value', 1);

        h.cpu_available_L = L_values;
        h.cpu_spatial_data = spatial_data;
        h.cpu_temporal_data = temporal_data;
        h.cpu_results_path = results_path;
        guidata(h.fig, h);

        set(h.cpu_status_text, 'String', sprintf('', length(L_values)));
        cpu_update_plot(h);
    end

    function cpu_study_callback(src, ~)
        h = guidata(ancestor(src,'figure'));
        cpu_update_plot(h);
    end

    function cpu_L_callback(src, ~)
        h = guidata(ancestor(src,'figure'));
        cpu_update_plot(h);
    end

    function cpu_refresh_callback(src, ~)
        h = guidata(ancestor(src,'figure'));
        cpu_load_available_data(h);
        set(h.cpu_status_text, 'String', 'CPU data refreshed successfully.');
    end

    

    function cpu_update_plot(h)
    if nargin < 1
        h = guidata(gcbo);
        if isempty(h), return; end
    end

    study_type = get(h.cpu_study_popup, 'Value');
    
  % ===== LOG SCALE SUPPRESSION =====
    % Force both axes to linear scale
    % This overrides any previous log scale settings to ensure
    % consistent visualization of CPU time data.
    logx = 0;  % X axis: linear scale (0=linear, 1=log)
    logy = 0;  % Y axis: linear scale (0=linear, 1=log)
% ================================

    % Determine x-axis mode based on study type
    % study_type = 1: spatial study (mesh refinement)
    % study_type = 2: temporal study (time step refinement)
        if study_type == 1
            xmode = '1/h';  % Spatial study: use inverse mesh size
        else
            xmode = 'dt';   % Temporal study: use time step
        end
    
    % Check if data is available for plotting
        if isempty(h.cpu_available_L) || isempty(h.cpu_spatial_data)
            cla(h.cpu_ax);
            title(h.cpu_ax, 'No data available - Click Refresh Data');
            return;
        end
    
    % ---- Prepare data for ALL L values ----
    % This collects data from all available L values for simultaneous plotting
        donnees = {};
        noms_schemas = {};
        
    % Loop through all available L values
        for i = 1:length(h.cpu_available_L)
            % Select appropriate data based on study type
            if study_type == 1
                data = h.cpu_spatial_data{i};
            else
                data = h.cpu_temporal_data{i};
            end
            
            if ~isempty(data)
                % Verify that required fields exist in the data structure
                if study_type == 1
                    % Spatial study: need h_values and CPU_times
                    if isfield(data, 'h_values') && isfield(data, 'CPU_times')
                        donnees{end+1} = data;  
                        noms_schemas{end+1} = sprintf('L=%.4f', h.cpu_available_L(i));  
                    end
                else
                    % Temporal study: need dt_values and CPU_times
                    if isfield(data, 'dt_values') && isfield(data, 'CPU_times')
                        % Create compatible data structure for temporal study
                        temp_data = struct();
                        temp_data.CPU_times = data.CPU_times;
                        temp_data.dt_values = data.dt_values;  % For xmode='dt'
                        donnees{end+1} = temp_data;  
                        noms_schemas{end+1} = sprintf('L=%.4f', h.cpu_available_L(i));  
                    end
                end
            end
        end
    
    % % Déterminer le mode x en fonction du type d'étude
    % if study_type == 1
    %     xmode = '1/h';  % étude spatiale
    % else
    %     xmode = 'dt';   % étude temporelle
    % end
    % 
    % if isempty(h.cpu_available_L) || isempty(h.cpu_spatial_data)
    %     cla(h.cpu_ax);
    %     title(h.cpu_ax, 'No data available - Click Refresh Data');
    %     return;
    % end
    % 
    % % ---- Préparer les données pour TOUS les L ----
    % donnees = {};
    % noms_schemas = {};
    % 
    % % Parcourir TOUS les L disponibles
    % for i = 1:length(h.cpu_available_L)
    %     if study_type == 1
    %         data = h.cpu_spatial_data{i};
    %     else
    %         data = h.cpu_temporal_data{i};
    %     end
    % 
    %     if ~isempty(data)
    %         % Vérifier que les champs nécessaires existent
    %         if study_type == 1
    %             if isfield(data, 'h_values') && isfield(data, 'CPU_times')
    %                 donnees{end+1} = data;  
    %                 noms_schemas{end+1} = sprintf('L=%.4f', h.cpu_available_L(i));  
    %             end
    %         else
    %             % Pour étude temporelle, on peut utiliser dt_values
    %             if isfield(data, 'dt_values') && isfield(data, 'CPU_times')
    %                 % Créer une structure compatible avec ta fonction
    %                 temp_data = struct();
    %                 temp_data.CPU_times = data.CPU_times;
    %                 temp_data.dt_values = data.dt_values;  % pour xmode='dt'
    %                 donnees{end+1} = temp_data;  
    %                 noms_schemas{end+1} = sprintf('L=%.4f', h.cpu_available_L(i));  
    %             end
    %         end
    %     end
    % end
    
    % Vérifier qu'on a des données
    if isempty(donnees)
        cla(h.cpu_ax);
        title(h.cpu_ax, 'No valid data for selected study type');
        return;
    end
    
    % ---- Appeler ta fonction avec TOUS les L ----
    plot_cpu_comparaison_axes(h.cpu_ax, donnees, noms_schemas, logx, logy, xmode);
    
    % Ajouter un titre approprié
    if study_type == 1
        title(h.cpu_ax, 'CPU Time vs Mesh Size (All L values)', ...
            'FontSize', 14, 'FontWeight', 'bold');
    else
        title(h.cpu_ax, 'CPU Time vs Time Step (All L values)', ...
            'FontSize', 14, 'FontWeight', 'bold');
    end
end


% =========================================================================
% SAVE & RUN
% =========================================================================
    function save_and_run_callback(src, ~)
        h = guidata(ancestor(src,'figure'));
        try
            mode = get(h.mode_popup, 'Value');
            nx_spatial_str  = get(h.nx_spatial_edit,  'String');
            dt_spatial_str  = get(h.dt_spatial_edit,  'String');
            nx_temporal_str = get(h.nx_temporal_edit, 'String');
            ell_str         = get(h.ell_edit,         'String');
            L_str           = get(h.L_edit,           'String');
            tfinal_str      = get(h.tfinal_edit,      'String');
            run_main        = get(h.run_checkbox,     'Value');

            Nx_list    = eval(nx_spatial_str);
            dt_spatial = eval(dt_spatial_str);
            nx_fixed   = eval(nx_temporal_str);
            ell_values = eval(ell_str);
            L_vec      = eval(L_str);
            t_final    = eval(tfinal_str);

            if (mode == 1 || mode == 3)
                if ~isnumeric(Nx_list) || isempty(Nx_list), errordlg('Invalid Nx list for spatial study','Error'); return; end
                if ~isnumeric(dt_spatial) || dt_spatial <= 0, errordlg('Invalid dt for spatial study','Error'); return; end
            end
            if (mode == 2 || mode == 3)
                if ~isnumeric(nx_fixed) || nx_fixed < 2, errordlg('Invalid Nx for temporal study','Error'); return; end
                if ~isnumeric(ell_values) || isempty(ell_values), errordlg('Invalid ell values for temporal study','Error'); return; end
            end
            if ~isnumeric(L_vec) || isempty(L_vec), errordlg('Invalid L values','Error'); return; end
            if ~isnumeric(t_final) || t_final <= 0, errordlg('Invalid final time','Error'); return; end

            params = struct();
            params.mode          = mode;
            params.Nx_list       = Nx_list(:)';
            params.dt_spatial    = dt_spatial;
            params.nx_fixed      = nx_fixed;
            params.ell_values    = ell_values(:)';
            params.L_vec         = L_vec(:)';
            params.t_final       = t_final;

            L_data = getappdata(h.fig, 'L_data');
            L_data.values = params.L_vec;
            setappdata(h.fig, 'L_data', L_data);

            save('simulation_parameters.mat', 'params');

            if run_main
                assignin('base', 'mode', mode);
                assignin('base', 'Nx_list', params.Nx_list);
                assignin('base', 'dt_spatial', dt_spatial);
                assignin('base', 'nx_fixed', nx_fixed);
                assignin('base', 'ell_values', params.ell_values);
                assignin('base', 'L_vec', params.L_vec);
                assignin('base', 't_final', t_final);
                assignin('base', 'gui_handles', h);

                start_live_monitor(h);
                evalin('base', 'run(''main.m'')');
                stop_live_monitor(h);

                cpu_load_available_data(guidata(h.fig));
                try
                    error_table_load_data(h.table_load_btn, []);
                catch
                end
            end

        catch ME
            errordlg(sprintf('Error parsing parameters:\n%s', ME.message), 'Error');
        end
    end

% =========================================================================
% LIVE MONITOR
% =========================================================================
    function start_live_monitor(h)
        fig2 = h.fig;
        diaryFile = fullfile(tempdir, sprintf('live_main_log_%s.txt', char(java.util.UUID.randomUUID)));
        setappdata(fig2, 'LIVE_DIARY_FILE', diaryFile);

        try, set(h.log_box, 'String', {'--- Live log ---'}, 'Value', 1); catch, end
        try, diary('off'); diary(diaryFile); diary('on'); catch, end
        try, set(h.status_text, 'String', 'Status: running main.m ...'); catch, end

        setappdata(fig2, 'LIVE_BAR_POS', 0);
        setappdata(fig2, 'LIVE_BAR_DIR', 1);

        t = timer('ExecutionMode', 'fixedSpacing', ...
                  'Period', 0.25, ...
                  'BusyMode', 'drop', ...
                  'TimerFcn', @(~,~)live_tick(h), ...
                  'Tag', 'LIVE_MONITOR_TIMER');

        setappdata(fig2, 'LIVE_MONITOR_TIMER', t);
        start(t);
    end

    function stop_live_monitor(h)
        fig2 = h.fig;

        try
            t = getappdata(fig2, 'LIVE_MONITOR_TIMER');
            if ~isempty(t) && isvalid(t)
                stop(t); delete(t);
            end
        catch
        end

        try, diary('off'); catch, end
        try, set(h.status_text, 'String', 'Status: finished. You can view results in other tabs.'); catch, end

        try
            p = get(h.progress_fill, 'Position');
            barW = get(h.log_box, 'Position'); barW = barW(3);
            p(3) = barW;
            set(h.progress_fill, 'Position', p);
        catch
        end
    end

    function live_tick(h)
        fig2 = h.fig;

        try
            base = get(h.progress_fill, 'Position');
            baseX = base(1); baseY = base(2); baseH = base(4);

            barW = get(h.log_box, 'Position'); barW = barW(3);
            blockW = min(120, max(70, round(0.18*barW)));

            pos = getappdata(fig2, 'LIVE_BAR_POS');
            dir = getappdata(fig2, 'LIVE_BAR_DIR');

            pos = pos + dir*14;
            if pos <= 0, pos = 0; dir = 1;
            elseif pos >= (barW - blockW), pos = barW - blockW; dir = -1;
            end

            setappdata(fig2, 'LIVE_BAR_POS', pos);
            setappdata(fig2, 'LIVE_BAR_DIR', dir);
            set(h.progress_fill, 'Position', [baseX+pos, baseY, blockW, baseH]);
        catch
        end

        try
            diaryFile = getappdata(fig2, 'LIVE_DIARY_FILE');
            if isempty(diaryFile) || ~exist(diaryFile, 'file'), return; end

            txt = fileread(diaryFile);
            if isempty(txt), return; end

            lines = regexp(txt, '\r\n|\n|\r', 'split');
            if isempty(lines), return; end

            N = 140;
            if numel(lines) > N, lines = lines(end-N+1:end); end

            old = get(h.log_box, 'String');
            if ~isequal(old, lines)
                set(h.log_box, 'String', lines, 'Value', numel(lines));
                drawnow limitrate;
            end
        catch
        end
    end

% =========================================================================
% ERROR TABLE (FIXED)
% =========================================================================
    % =========================================================================
% ERROR TABLE (Spatial + Temporal)
% =========================================================================
function error_table_load_data(src, ~)
    h = guidata(ancestor(src,'figure'));

    current_dir = fileparts(mfilename('fullpath'));
    results_path = fullfile(current_dir, 'results', 'numerical_validation', 'L-scheme');

    if ~exist(results_path, 'dir')
        set(h.table_status_text, 'String', 'Error: Results directory not found.');
        set(h.table_L_popup, 'String', {'No data'}, 'Value', 1);
        return;
    end

    L_dirs = dir(fullfile(results_path, 'L=*'));
    L_dirs = L_dirs([L_dirs.isdir]);

    if isempty(L_dirs)
        set(h.table_status_text, 'String', 'No L-scheme results found.');
        set(h.table_L_popup, 'String', {'No data'}, 'Value', 1);
        return;
    end

    L_values = [];
    popup_names = {};
    folder_names = {};

    hasSpatialAny  = false;
    hasTemporalAny = false;

    for i = 1:length(L_dirs)
        fname = L_dirs(i).name;
        tok = regexp(fname, 'L=([0-9.eE+-]+)', 'tokens', 'once');
        if isempty(tok), continue; end

        spatial_file = fullfile(results_path, fname, 'spatial',  'resultats_complets', 'resultats_spatiaux.mat');
        temporal_file= fullfile(results_path, fname, 'temporel', 'resultats_complets', 'resultats_temporels.mat');

        hasS = exist(spatial_file, 'file') == 2;
        hasT = exist(temporal_file,'file') == 2;

        if ~(hasS || hasT)
            continue; % rien pour ce L
        end

        hasSpatialAny  = hasSpatialAny  || hasS;
        hasTemporalAny = hasTemporalAny || hasT;

        L_val = str2double(tok{1});
        if isnan(L_val), continue; end

        L_values(end+1,1) = L_val; 
        popup_names{end+1} = sprintf('L = %.4f', L_val); 
        folder_names{end+1} = fname; 
    end

    if isempty(L_values)
        set(h.table_status_text, 'String', 'No spatial/temporal data found.');
        set(h.table_L_popup, 'String', {'No data'}, 'Value', 1);
        return;
    end

    [L_values, id] = sort(L_values);
    popup_names  = popup_names(id);
    folder_names = folder_names(id);

    set(h.table_L_popup, 'String', popup_names, 'Value', 1);

    % Study type: show both if available
    studies = {};
    if hasSpatialAny,  studies{end+1} = 'Spatial study';  end
    if hasTemporalAny, studies{end+1} = 'Temporal study'; end
    if isempty(studies), studies = {'Spatial study'}; end
    set(h.table_study_popup, 'String', studies, 'Value', 1);

    set(h.table_status_text, 'String', sprintf('Loaded %d L values', length(L_values)));

    setappdata(h.fig, 'error_table_L_values',  L_values);
    setappdata(h.fig, 'error_table_L_folders', folder_names); % exact folder names
    setappdata(h.fig, 'error_table_results_path', results_path);

    error_table_refresh(h.table_refresh_btn, []);
end

function error_table_refresh(src, ~)
    h = guidata(ancestor(src,'figure'));

    L_strings = get(h.table_L_popup, 'String');
    if isempty(L_strings) || ischar(L_strings), return; end
    if strcmp(L_strings{1}, 'No data'), return; end

    L_idx    = get(h.table_L_popup, 'Value');
    L_values = getappdata(h.fig, 'error_table_L_values');
    folders  = getappdata(h.fig, 'error_table_L_folders');
    results_path = getappdata(h.fig, 'error_table_results_path');

    if isempty(L_values) || L_idx > length(L_values) || isempty(folders) || L_idx > length(folders)
        return;
    end

    L_val  = L_values(L_idx);
    folder = folders{L_idx};

    % Which study?
    study_list = get(h.table_study_popup, 'String');
    study_val  = get(h.table_study_popup, 'Value');
    study_name = study_list{study_val};
    isSpatial  = contains(lower(study_name), 'spatial');

    if isSpatial
        matfile = fullfile(results_path, folder, 'spatial', 'resultats_complets', 'resultats_spatiaux.mat');
        titleStr = sprintf('Spatial Error Analysis for $L = %.6g$', L_val);
    else
        matfile = fullfile(results_path, folder, 'temporel','resultats_complets', 'resultats_temporels.mat');
        titleStr = sprintf('Temporal Error Analysis for $L = %.6g$', L_val);
    end

    if ~exist(matfile, 'file')
        set(h.table_status_text, 'String', sprintf('No %s data for L = %.6g', study_name, L_val));
        return;
    end

    data = load(matfile);

    % Robust field picks (keep your helper pick_field)
    hvals = pick_field(data, {'h_values','h','H_values','hvals'});
    if ~isSpatial
        % temporal x-axis often is dt instead of h
        dtvals = pick_field(data, {'dt_values','dt','Dt_values','dtvals'});
        if ~isempty(dtvals), hvals = dtvals; end
    end
    errL2 = pick_field(data, {'Erreur_L2','ErreurL2','error_L2','errL2','L2_error','Erreur_L2_values'});

    if isempty(hvals) || isempty(errL2)
        set(h.table_status_text, 'String', 'Invalid data format: missing (h/dt) or L2 error');
        return;
    end

    % Normalize for drawing (reuse your draw_elegant_table)
    dataN = data;
    dataN.h_values  = hvals(:);     % NOTE: for temporal we store dt here (x-axis)
    dataN.Erreur_L2 = errL2(:);

    tmp = pick_field(data, {'Erreur_H1','ErreurH1','error_H1','errH1'}); if ~isempty(tmp), dataN.Erreur_H1 = tmp(:); end
    tmp = pick_field(data, {'Cond_max','kappa_max','Kappa_max','cond_max'}); if ~isempty(tmp), dataN.Cond_max = tmp(:); end
    tmp = pick_field(data, {'CPU_times','cpu_times','CPU','cpu'}); if ~isempty(tmp), dataN.CPU_times = tmp(:); end
    tmp = pick_field(data, {'Newton_last','Iter','iterations','iters'}); if ~isempty(tmp), dataN.Newton_last = tmp(:); end

    % Important: tell the drawer if x is dt (temporal)
    setappdata(h.fig, 'error_table_isTemporal', ~isSpatial);

    % Draw + stats
    draw_elegant_table(h, dataN, L_val);

    % Overwrite title (your draw currently builds a spatial title)
    ax = h.table_axes;
    % text(ax, 0.03, 0.93, titleStr, ...
    %     'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.10 0.20 0.45], ...
    %     'Interpreter', 'latex');

    update_table_statistics(h, dataN, L_val);

    set(h.table_status_text, 'String', sprintf('Displaying %s for L = %.6g', study_name, L_val));
end


    function draw_elegant_table(h, data, L_val)
        ax = h.table_axes;

        cla(ax); % ok now, we recreate title AFTER clearing
        hold(ax, 'on');
        axis(ax, [0 1 0 1]);

        % Title (RECREATED each refresh)
        text(ax, 0.03, 0.93, sprintf('Spatial Error Analysis for $L = %.6g$', L_val), ...
            'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.10 0.20 0.45], ...
            'Interpreter', 'latex');

        colBorder = [0.55 0.62 0.78];
        colGrid = [0.80 0.86 0.94];
        colHeader = [0.92 0.95 1.00];
        colRowA = [1.00 1.00 1.00];
        colRowB = [0.97 0.985 1.00];
        colHighlight = [0.85 0.95 0.85];

        headers = {'$h$', '$L_2$', '$H_1$', '$\kappa_{max}$', 'CPU (s)', 'Iter', 'Order'};

        un_sur_h = 1 ./ data.h_values(:);
        [un_sur_h, idx] = sort(un_sur_h, 'ascend');
        errL2 = data.Erreur_L2(idx);

        hasH1   = isfield(data, 'Erreur_H1')   && numel(data.Erreur_H1)==numel(data.h_values);
        hasCond = isfield(data, 'Cond_max')    && numel(data.Cond_max)==numel(data.h_values);
        hasCPU  = isfield(data, 'CPU_times')   && numel(data.CPU_times)==numel(data.h_values);
        hasIter = isfield(data, 'Newton_last') && numel(data.Newton_last)==numel(data.h_values);

        if hasH1,   errH1 = data.Erreur_H1(idx); end
        if hasCond, cond_max = data.Cond_max(idx); end
        if hasCPU,  cpu_times = data.CPU_times(idx); end
        if hasIter, iterations = data.Newton_last(idx); end

        left = 0.05; right = 0.95; top = 0.85; bottom = 0.15;
        W = right - left; H = top - bottom;

        nRows = numel(un_sur_h);
        rowH = H / (nRows + 1);
        nCols = 7;
        colW = W / nCols;
        xPos = left + (0:nCols-1) * colW;

        rectangle(ax, 'Position', [left, bottom, W, H], 'EdgeColor', colBorder, 'LineWidth', 2, 'FaceColor', 'none');
        rectangle(ax, 'Position', [left, top - rowH, W, rowH], 'FaceColor', colHeader, 'EdgeColor', 'none');

        for x = xPos(2:end)
            plot(ax, [x x], [bottom top], 'Color', colGrid, 'LineWidth', 1);
        end
        for r = 1:nRows
            y = top - rowH * (r + 0);
            plot(ax, [left right], [y y], 'Color', colGrid, 'LineWidth', 1);
        end

        for c = 1:nCols
            text(ax, xPos(c) + colW/2, top - rowH/2, headers{c}, ...
                'FontSize', 11, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'Interpreter', 'latex');
        end

        orders = [];
        min_err = min(errL2);
        min_err_idx = 1;

        for i = 1:nRows
            yRow = top - rowH * (i + 1);

            bgColor = colRowA;
            if mod(i,2)==0, bgColor = colRowB; end
            if abs(errL2(i) - min_err) < 1e-12
                bgColor = colHighlight;
                min_err_idx = i;
            end
            rectangle(ax, 'Position', [left, yRow, W, rowH], 'FaceColor', bgColor, 'EdgeColor', 'none');

            colIdx = 1;

            nx_val = round(un_sur_h(i));
            text(ax, xPos(colIdx)+colW/2, yRow+rowH/2, sprintf('$1/%d$', nx_val), ...
                'FontSize', 10, 'HorizontalAlignment','center','VerticalAlignment','middle','Interpreter','latex');
            colIdx=colIdx+1;

            [m2,e2]=format_scientific(errL2(i));
            text(ax, xPos(colIdx)+colW/2, yRow+rowH/2, sprintf('$%.2f\\times10^{%d}$', m2, e2), ...
                'FontSize',10,'HorizontalAlignment','center','VerticalAlignment','middle','Interpreter','latex');
            colIdx=colIdx+1;

            if hasH1
                [m1,e1]=format_scientific(errH1(i));
                s = sprintf('$%.2f\\times10^{%d}$', m1, e1);
            else
                s = '$-$';
            end
            text(ax, xPos(colIdx)+colW/2, yRow+rowH/2, s, 'FontSize',10,'HorizontalAlignment','center','VerticalAlignment','middle','Interpreter','latex');
            colIdx=colIdx+1;

            if hasCond
                v = cond_max(i);
                if v >= 1, s = sprintf('$%.1f$', v);
                else, [mc,ec]=format_scientific(v); s = sprintf('$%.2f\\times10^{%d}$', mc, ec);
                end
            else
                s='$-$';
            end
            text(ax, xPos(colIdx)+colW/2, yRow+rowH/2, s, 'FontSize',10,'HorizontalAlignment','center','VerticalAlignment','middle','Interpreter','latex');
            colIdx=colIdx+1;

            if hasCPU
                v = cpu_times(i);
                if v >= 1, s = sprintf('$%.2f$', v);
                else, [mc,ec]=format_scientific(v); s = sprintf('$%.2f\\times10^{%d}$', mc, ec);
                end
            else
                s='$-$';
            end
            text(ax, xPos(colIdx)+colW/2, yRow+rowH/2, s, 'FontSize',10,'HorizontalAlignment','center','VerticalAlignment','middle','Interpreter','latex');
            colIdx=colIdx+1;

            if hasIter
                v = iterations(i);
                if abs(v-round(v))<1e-10, s = sprintf('$%d$', round(v));
                else, s = sprintf('$%.1f$', v);
                end
            else
                s='$-$';
            end
            text(ax, xPos(colIdx)+colW/2, yRow+rowH/2, s, 'FontSize',10,'HorizontalAlignment','center','VerticalAlignment','middle','Interpreter','latex');
            colIdx=colIdx+1;

            if i>1
                ord = log10(errL2(i-1)/errL2(i))/log10(2);
                orders(end+1)=ord; 
                s = sprintf('$%.2f$', ord);
            else
                s='$-$';
            end
            text(ax, xPos(colIdx)+colW/2, yRow+rowH/2, s, 'FontSize',10,'HorizontalAlignment','center','VerticalAlignment','middle','Interpreter','latex');
        end

        setappdata(h.fig, 'error_table_orders', orders);
        setappdata(h.fig, 'error_table_errL2', errL2);
        setappdata(h.fig, 'error_table_un_sur_h', un_sur_h);
        setappdata(h.fig, 'error_table_min_idx', min_err_idx);

        setappdata(h.fig, 'error_table_hasCPU', hasCPU);
        setappdata(h.fig, 'error_table_hasCond', hasCond);
        setappdata(h.fig, 'error_table_hasIter', hasIter);
        if hasCPU,  setappdata(h.fig, 'error_table_cpu_times', cpu_times); end
        if hasCond, setappdata(h.fig, 'error_table_cond_max', cond_max); end
        if hasIter, setappdata(h.fig, 'error_table_iterations', iterations); end

        hold(ax,'off');
    end

    function update_table_statistics(h, ~, L_val)
        errL2    = getappdata(h.fig, 'error_table_errL2');
        orders   = getappdata(h.fig, 'error_table_orders');
        un_sur_h = getappdata(h.fig, 'error_table_un_sur_h');
        min_idx  = getappdata(h.fig, 'error_table_min_idx');

        if isempty(errL2), return; end

        hasCPU = getappdata(h.fig, 'error_table_hasCPU');
        hasCond = getappdata(h.fig, 'error_table_hasCond');
        hasIter = getappdata(h.fig, 'error_table_hasIter');

        [m_min,e_min] = format_scientific(min(errL2));
        if isempty(orders), avg_order = NaN; else, avg_order = mean(orders); end

        stats_text = sprintf('Best: $L_2$ min = $%.2f\\times10^{%d}$ at $1/%d$', ...
            m_min, e_min, round(un_sur_h(min_idx)));

        if hasCPU
            cpu_times = getappdata(h.fig, 'error_table_cpu_times');
            if ~isempty(cpu_times)
                v = min(cpu_times);
                if v >= 1, stats_text = [stats_text sprintf(', CPU min = $%.2f$ s', v)];
                else, [mc,ec]=format_scientific(v); stats_text = [stats_text sprintf(', CPU min = $%.2f\\times10^{%d}$ s', mc, ec)];
                end
            end
        end

        if hasCond
            cond_max = getappdata(h.fig, 'error_table_cond_max');
            if ~isempty(cond_max)
                v = min(cond_max);
                if v >= 1, stats_text = [stats_text sprintf(', $\\kappa_{max}$ min = $%.1f$', v)];
                else, [mc,ec]=format_scientific(v); stats_text = [stats_text sprintf(', $\\kappa_{max}$ min = $%.2f\\times10^{%d}$', mc, ec)];
                end
            end
        end

        if ~isnan(avg_order)
            stats_text = [stats_text sprintf(', Avg order = $%.2f$', avg_order)];
        else
            stats_text = [stats_text sprintf(', Avg order = $-$')];
        end

        if hasIter
            iterations = getappdata(h.fig, 'error_table_iterations');
            if ~isempty(iterations)
                stats_text = [stats_text sprintf(', Iter avg = $%.1f$', mean(iterations))];
            end
        end

        if ishandle(h.stats_text_handle)
            set(h.stats_text_handle, 'String', stats_text, 'Interpreter','latex');
        end
        if ishandle(h.table_status_text)
            set(h.table_status_text, 'String', sprintf('Displaying L = %.6g', L_val));
        end
    end

% =========================================================================
% small utilities
% =========================================================================
    function v = pick_field(S, names)
        v = [];
        for k = 1:numel(names)
            if isfield(S, names{k})
                v = S.(names{k});
                return;
            end
        end
    end

    function [m, e] = format_scientific(x)
        if x == 0
            m = 0; e = 0; return;
        end
        e = floor(log10(abs(x)));
        m = x / 10^e;
        m = round(m * 100) / 100;
    end

    function name = get_mode_name(val)
        switch val
            case 1, name = 'Spatial only';
            case 2, name = 'Temporal only';
            case 3, name = 'Both studies';
            otherwise, name = 'Unknown';
        end
    end


%     function plot_cpu_comparaison_axes(ax, donnees, noms_schemas, logx, logy, xmode)
% % PLOT_CPU_COMPARAISON_AXES
% % Version GUI (dessine dans un axes existant) de ta figure CPU style article.
% %
% % INPUTS
% %   ax          : handle axes (ex: h.cpu_ax)
% %   donnees     : cell array {data1, data2, ...}
% %                chaque data doit contenir:
% %                   - CPU_times (vecteur)
% %                   - h_values  (spatial)  OU dt_values (temporal)
% %   noms_schemas: cell array {name1, name2, ...} pour legend
% %   logx        : 0/1 (checkbox "Log scale X")
% %   logy        : 0/1 (checkbox "Log scale Y")
% %   xmode       : '1/h' (default) ou 'dt' ou '1/dt'
% 
%     if nargin < 4 || isempty(logx), logx = 0; end
%     if nargin < 5 || isempty(logy), logy = 0; end
%     if nargin < 6 || isempty(xmode), xmode = '1/h'; end
% 
%     if isempty(ax) || ~ishandle(ax)
%         return;
%     end
% 
%     cla(ax);
%     hold(ax,'on');
% 
%     % ------------------- Couleurs & styles -------------------
%     couleurs = {
%         [0, 0.4470, 0.7410],      % L-scheme (bleu)
%         [0.4660, 0.6740, 0.1880], % L-scheme (vert)
%         [0.2, 0.2, 0.2],          % Newton (gris/noir)
%         [0.4940, 0.1840, 0.5560], % backup
%         [0.8500, 0.3250, 0.0980]  % backup
%     };
%     styles = {'-o','-s','-^','-d','--s'};
% 
%     % ------------------- Style axes -------------------
%     ax.FontSize   = 16;
%     ax.LineWidth  = 1.3;
%     ax.FontWeight = 'bold';
%     ax.Box        = 'off';
%     ax.TickDir    = 'out';
%     grid(ax,'off');
% 
%     % Gestion des échelles
%     if logx
%         set(ax,'XScale','log');
%     else
%         set(ax,'XScale','linear');
%     end
% 
%     % FORCER Y en linéaire (pas de log)
%     set(ax,'YScale','linear');
%     % Ignorer logy même s'il est passé en paramètre
%     % logy est ignoré - on reste en linéaire
% 
%     % Stocker toutes les valeurs pour limites auto
%     allX = [];
%     allY = [];
% 
%     % ------------------- Tracés -------------------
%     for i = 1:length(donnees)
%         data = donnees{i};
%         if isempty(data) || ~isstruct(data), continue; end
%         if ~isfield(data,'CPU_times'), continue; end
% 
%         y = data.CPU_times(:);
%         if isempty(y), continue; end
% 
%         % Construire X selon xmode
%         x = [];
%         switch lower(strrep(xmode,' ',''))
%             case '1/h'
%                 if ~isfield(data,'h_values'), continue; end
%                 hv = data.h_values(:);
%                 x = 1 ./ hv;
%             case 'dt'
%                 if ~isfield(data,'dt_values')
%                     if isfield(data,'h_values')
%                         x = data.h_values(:);
%                     else
%                         continue;
%                     end
%                 else
%                     x = data.dt_values(:);
%                 end
%             case '1/dt'
%                 if ~isfield(data,'dt_values')
%                     if isfield(data,'h_values')
%                         x = 1 ./ data.h_values(:);
%                     else
%                         continue;
%                     end
%                 else
%                     x = 1 ./ data.dt_values(:);
%                 end
%             otherwise
%                 error('xmode must be ''1/h'', ''dt'' or ''1/dt''.');
%         end
% 
%         n = min(numel(x), numel(y));
%         x = x(1:n); y = y(1:n);
% 
%         % Nettoyage NaN/Inf
%         ok = isfinite(x) & isfinite(y);
%         x = x(ok); y = y(ok);
%         if isempty(x) || isempty(y), continue; end
% 
%         % Trier par X
%         [x, id] = sort(x);
%         y = y(id);
% 
%         couleur = couleurs{mod(i-1, numel(couleurs))+1};
%         style   = styles{mod(i-1, numel(styles))+1};
% 
%         % Nom du schéma
%         namei = sprintf('Scheme %d',i);
%         if i <= numel(noms_schemas) && ~isempty(noms_schemas{i})
%             namei = noms_schemas{i};
%         end
% 
%         if contains(namei,'Newton','IgnoreCase',true)
%             plot(ax, x, y, '--s', 'Color', couleur, ...
%                 'LineWidth', 2.8, 'MarkerSize', 7, 'MarkerFaceColor', couleur, ...
%                 'DisplayName', formatLegende(namei));
%         else
%             plot(ax, x, y, style, 'Color', couleur, ...
%                 'LineWidth', 2.8, 'MarkerSize', 7, 'MarkerFaceColor', couleur, ...
%                 'DisplayName', formatLegende(namei));
%         end
% 
%         % Labels des valeurs CPU (toujours en valeurs naturelles)
%         for j = 1:numel(x)
%             if y(j) >= 1000
%                 label_text = sprintf('(%.0f)', y(j));
%             else
%                 label_text = sprintf('(%.1f)', y(j));
%             end
% 
%             % Offset vertical fixe (pas de log)
%             yoff = y(j) + 0.03*(max(y)-min(y)+eps);
% 
%             text(ax, x(j), yoff, label_text, ...
%                 'FontSize', 12, 'FontWeight', 'bold', ...
%                 'HorizontalAlignment', 'center', ...
%                 'VerticalAlignment', 'bottom', ...
%                 'Color', couleur);
%         end
% 
%         allX = [allX; x(:)];
%         allY = [allY; y(:)];
%     end
% 
%     % ------------------- Labels axes -------------------
%     switch lower(strrep(xmode,' ',''))
%         case '1/h'
%             xlabel(ax,'1/h','FontSize',16,'FontWeight','bold');
%         case 'dt'
%             xlabel(ax,'dt','FontSize',16,'FontWeight','bold');
%         case '1/dt'
%             xlabel(ax,'1/dt','FontSize',16,'FontWeight','bold');
%     end
%     ylabel(ax,'CPU Time (s)','FontSize',16,'FontWeight','bold');
% 
%     % ------------------- Limites auto (DYNAMIQUES) -------------------
%     allX = allX(isfinite(allX));
%     allY = allY(isfinite(allY));
% 
%     if ~isempty(allX)
%         if logx
%             allX = allX(allX>0);
%             if ~isempty(allX)
%                 xmin = 10^(floor(log10(min(allX))) - 0);
%                 xmax = 10^(ceil(log10(max(allX))) + 0);
%                 xlim(ax,[xmin xmax]);
%             end
%         else
%             xmin = min(allX); 
%             xmax = max(allX);
%             pad = 0.06*(xmax-xmin+eps);
%             xlim(ax,[xmin-pad xmax+pad]);
% 
%             % Forcer les ticks aux valeurs exactes de 1/h
%             % Récupérer les valeurs uniques de 1/h depuis les données
%             xticks(ax, unique(round(allX)));
%         end
%     end
% 
%     if ~isempty(allY)
%         % Y toujours en linéaire
%         ymin = min(allY); 
%         ymax = max(allY);
%         pad = 0.08*(ymax-ymin+eps);
%         ylim(ax, [max(0, ymin-pad) ymax+pad]);
% 
%         % Y ticks naturels (entiers si possible)
%         if all(floor(allY) == allY)  % Si toutes les valeurs sont entières
%             yticks(ax, unique(round(allY)));
%         end
%     end
% 
%     % ------------------- Légende -------------------
%     legend(ax,'Location','northwest','FontSize',14,'Box','on','Interpreter','latex');
%     hold(ax,'off');
% 
%     % ===================== Sous-fonction: légende LaTeX =====================
%     function legende_formatee = formatLegende(nom)
%         % Détection L-scheme
%         if contains(nom, 'L=', 'IgnoreCase', true)
%             % Extraire la valeur de L
%             tokens = regexp(nom, 'L=([0-9.]+)', 'tokens');
%             if ~isempty(tokens)
%                 L_val = str2double(tokens{1}{1});
%                 % Valeurs qui doivent avoir "L-scheme"
%                 L_scheme_values = [0.15, 0.25];
% 
%                 if any(abs(L_val - L_scheme_values) < 1e-10)
%                     % C'est un L-scheme (0.15 ou 0.25)
%                     legende_formatee = sprintf('$\\mathbf{L\\!-\\!scheme\\,(L = %.2f)}$', L_val);
%                 else
%                     % Autre valeur : afficher juste "L = X"
%                     legende_formatee = sprintf('$\\mathbf{L = %.4f}$', L_val);
%                 end
%                 return;
%             end
%         end
% 
%         % Newton
%         if contains(nom, 'Newton', 'IgnoreCase', true)
%             legende_formatee = '$\mathbf{Newton}$';
%             return;
%         end
% 
%         % Fallback
%         legende_formatee = ['$\mathbf{' strrep(nom,'_','\_') '}$'];
%     end
% end
function plot_cpu_comparaison_axes(ax, donnees, noms_schemas, logx, logy, xmode)
%PLOT_CPU_COMPARAISON_AXES Publication-quality CPU time comparison plot
%   Plots CPU time data for multiple L-scheme values in a given axes handle.
%   Designed for GUI integration with interactive controls.
%
%   INPUTS:
%       ax : axes handle, target axes for plotting (e.g., h.cpu_ax)
%       donnees : cell array, each element is a data structure containing:
%           - CPU_times : vector, CPU time measurements
%           - h_values  : vector, mesh sizes (for spatial studies)
%           - dt_values : vector, time step sizes (for temporal studies)
%       noms_schemas : cell array, legend names for each dataset
%       logx : logical, 1 for log scale X axis, 0 for linear
%       logy : logical, 1 for log scale Y axis, 0 for linear (NOTE: Y is forced linear)
%       xmode : string, x-axis quantity: '1/h' (default), 'dt', or '1/dt'
%
%   BEHAVIOR:
%       - Y-axis is forced to linear scale regardless of logy input
%       - Automatically adjusts axis limits with padding
%       - Adds value labels above data points
%       - Uses LaTeX formatting for legend entries
%       - Detects L-scheme vs Newton schemes for special formatting

    if nargin < 4 || isempty(logx), logx = 0; end
    if nargin < 5 || isempty(logy), logy = 0; end
    if nargin < 6 || isempty(xmode), xmode = '1/h'; end

    if isempty(ax) || ~ishandle(ax)
        return;
    end

    cla(ax);
    hold(ax,'on');

    % ------------------- Colors & line styles -------------------
    couleurs = {
        [0, 0.4470, 0.7410],      % L-scheme (blue)
        [0.4660, 0.6740, 0.1880], % L-scheme (green)
        [0.2, 0.2, 0.2],          % Newton (gray/black)
        [0.4940, 0.1840, 0.5560], % backup
        [0.8500, 0.3250, 0.0980]  % backup
    };
    styles = {'-o','-s','-^','-d','--s'};

    % ------------------- Axes styling -------------------
    ax.FontSize   = 16;
    ax.LineWidth  = 1.3;
    ax.FontWeight = 'bold';
    ax.Box        = 'off';
    ax.TickDir    = 'out';
    grid(ax,'off');

    % Handle axis scales
    if logx
        set(ax,'XScale','log');
    else
        set(ax,'XScale','linear');
    end
    
    % FORCE Y to linear scale (override logy input)
    set(ax,'YScale','linear');
    % logy is ignored - always use linear scale for Y

    % Store all values for automatic axis limits
    allX = [];
    allY = [];

    % ------------------- Plot data -------------------
    for i = 1:length(donnees)
        data = donnees{i};
        if isempty(data) || ~isstruct(data), continue; end
        if ~isfield(data,'CPU_times'), continue; end

        y = data.CPU_times(:);
        if isempty(y), continue; end

        % Construct X based on xmode
        x = [];
        switch lower(strrep(xmode,' ',''))
            case '1/h'
                if ~isfield(data,'h_values'), continue; end
                hv = data.h_values(:);
                x = 1 ./ hv;
            case 'dt'
                if ~isfield(data,'dt_values')
                    if isfield(data,'h_values')
                        x = data.h_values(:);
                    else
                        continue;
                    end
                else
                    x = data.dt_values(:);
                end
            case '1/dt'
                if ~isfield(data,'dt_values')
                    if isfield(data,'h_values')
                        x = 1 ./ data.h_values(:);
                    else
                        continue;
                    end
                else
                    x = 1 ./ data.dt_values(:);
                end
            otherwise
                error('xmode must be ''1/h'', ''dt'' or ''1/dt''.');
        end

        n = min(numel(x), numel(y));
        x = x(1:n); y = y(1:n);

        % Remove NaN/Inf values
        ok = isfinite(x) & isfinite(y);
        x = x(ok); y = y(ok);
        if isempty(x) || isempty(y), continue; end

        % Sort by X
        [x, id] = sort(x);
        y = y(id);

        couleur = couleurs{mod(i-1, numel(couleurs))+1};
        style   = styles{mod(i-1, numel(styles))+1};

        % Scheme name
        namei = sprintf('Scheme %d',i);
        if i <= numel(noms_schemas) && ~isempty(noms_schemas{i})
            namei = noms_schemas{i};
        end

        if contains(namei,'Newton','IgnoreCase',true)
            plot(ax, x, y, '--s', 'Color', couleur, ...
                'LineWidth', 2.8, 'MarkerSize', 7, 'MarkerFaceColor', couleur, ...
                'DisplayName', formatLegende(namei));
        else
            plot(ax, x, y, style, 'Color', couleur, ...
                'LineWidth', 2.8, 'MarkerSize', 7, 'MarkerFaceColor', couleur, ...
                'DisplayName', formatLegende(namei));
        end

        % Add value labels (always in natural numbers)
        for j = 1:numel(x)
            if y(j) >= 1000
                label_text = sprintf('(%.0f)', y(j));
            else
                label_text = sprintf('(%.1f)', y(j));
            end

            % Fixed vertical offset (no log scaling)
            yoff = y(j) + 0.03*(max(y)-min(y)+eps);

            text(ax, x(j), yoff, label_text, ...
                'FontSize', 12, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'Color', couleur);
        end

        allX = [allX; x(:)];
        allY = [allY; y(:)];
    end

    % ------------------- Axis labels -------------------
    switch lower(strrep(xmode,' ',''))
        case '1/h'
            xlabel(ax,'1/h','FontSize',16,'FontWeight','bold');
        case 'dt'
            xlabel(ax,'dt','FontSize',16,'FontWeight','bold');
        case '1/dt'
            xlabel(ax,'1/dt','FontSize',16,'FontWeight','bold');
    end
    ylabel(ax,'CPU Time (s)','FontSize',16,'FontWeight','bold');

    % ------------------- Dynamic axis limits -------------------
    allX = allX(isfinite(allX));
    allY = allY(isfinite(allY));

    if ~isempty(allX)
        if logx
            allX = allX(allX>0);
            if ~isempty(allX)
                xmin = 10^(floor(log10(min(allX))) - 0);
                xmax = 10^(ceil(log10(max(allX))) + 0);
                xlim(ax,[xmin xmax]);
            end
        else
            xmin = min(allX); 
            xmax = max(allX);
            pad = 0.06*(xmax-xmin+eps);
            xlim(ax,[xmin-pad xmax+pad]);
            
            % Force ticks to exact 1/h values
            % Get unique 1/h values from data
            xticks(ax, unique(round(allX)));
        end
    end

    if ~isempty(allY)
        % Y always linear
        ymin = min(allY); 
        ymax = max(allY);
        pad = 0.08*(ymax-ymin+eps);
        ylim(ax, [max(0, ymin-pad) ymax+pad]);
        
        % Natural Y ticks (integers if possible)
        if all(floor(allY) == allY)  % If all values are integers
            yticks(ax, unique(round(allY)));
        end
    end

    % ------------------- Legend -------------------
    legend(ax,'Location','northwest','FontSize',14,'Box','on','Interpreter','latex');
    hold(ax,'off');

    % ===================== Nested function: LaTeX legend formatting =====================
    function legende_formatee = formatLegende(nom)
    %FORMATLEGENDE Format legend entries with LaTeX for publication quality
    %   Detects L-scheme and Newton schemes and applies appropriate formatting.
    %
    %   INPUT:
    %       nom : string, raw legend name
    %
    %   OUTPUT:
    %       legende_formatee : string, LaTeX-formatted legend entry

        % Detect L-scheme
        if contains(nom, 'L=', 'IgnoreCase', true)
            % Extract L value
            tokens = regexp(nom, 'L=([0-9.]+)', 'tokens');
            if ~isempty(tokens)
                L_val = str2double(tokens{1}{1});
                % Values that should be labeled as "L-scheme"
                L_scheme_values = [0.15, 0.25];
                
                if any(abs(L_val - L_scheme_values) < 1e-10)
                    % This is an L-scheme (0.15 or 0.25)
                    legende_formatee = sprintf('$\\mathbf{L\\!-\\!scheme\\,(L = %.2f)}$', L_val);
                else
                    % Other values: just show "L = X"
                    legende_formatee = sprintf('$\\mathbf{L = %.4f}$', L_val);
                end
                return;
            end
        end
        
        % Newton scheme
        if contains(nom, 'Newton', 'IgnoreCase', true)
            legende_formatee = '$\mathbf{Newton}$';
            return;
        end
        
        % Fallback
        legende_formatee = ['$\mathbf{' strrep(nom,'_','\_') '}$'];
    end
end




% ==================== DATA PREPARATION FUNCTION ====================
function preparer_et_afficher_cpu(ax, results_struct, xmode, logx, logy)
%PREPARER_ET_AFFICHER_CPU Prepare and display CPU time comparison plot
%   Organizes data from results structure and calls the plotting function.
%   This is a wrapper that formats data for plot_cpu_comparaison_axes().
%
%   INPUTS:
%       ax : axes handle, target axes for plotting
%       results_struct : structure containing results for each L and Newton
%           Expected format:
%               results_struct.L_values = [0.15, 0.25, 0.5, 1];
%               results_struct.L_0.15.CPU_times = [cpu1 cpu2 cpu3 cpu4];
%               results_struct.L_0.15.h_values = [h1 h2 h3 h4];  % or dt_values
%               results_struct.L_0.25.CPU_times = [...];
%               ... etc ...
%               results_struct.Newton.CPU_times = [...];
%               results_struct.Newton.h_values = [...];
%       xmode : string, x-axis quantity: '1/h', 'dt', or '1/dt'
%       logx : logical, 1 for log scale X axis, 0 for linear
%       logy : logical, 1 for log scale Y axis, 0 for linear
%
%   BEHAVIOR:
%       - Automatically collects all L-scheme data from results structure
%       - Adds Newton data if present
%       - Formats data into cell arrays expected by plot_cpu_comparaison_axes()
%       - Calls the plotting function with formatted data

    % Initialize cell arrays for the plotting function
    donnees = {};
    noms_schemas = {};
    
    % 1. ADD ALL L-SCHEMES
    if isfield(results_struct, 'L_values')
        L_values = results_struct.L_values;
        
        for i = 1:length(L_values)
            L = L_values(i);
            
            % Find the field corresponding to this L
            % (adapt based on how your data is stored)
            field_name = sprintf('L_%g', L);
            
            if isfield(results_struct, field_name)
                % Add data
                donnees{end+1} = results_struct.(field_name);  
                
                % Add name with L value
                if L == 1
                    noms_schemas{end+1} = 'L=1';  
                elseif abs(L - 0.15) < 1e-10
                    noms_schemas{end+1} = 'L=0.15';  
                elseif abs(L - 0.25) < 1e-10
                    noms_schemas{end+1} = 'L=0.25';  
                elseif abs(L - 0.5) < 1e-10
                    noms_schemas{end+1} = 'L=0.5';  
                else
                    noms_schemas{end+1} = sprintf('L=%g', L);  
                end
            end
        end
    end
    
    % 2. ADD NEWTON (if present)
    if isfield(results_struct, 'Newton')
        donnees{end+1} = results_struct.Newton;
        noms_schemas{end+1} = 'Newton';
    end
    
    % 3. CALL EXISTING PLOTTING FUNCTION (unchanged!)
    plot_cpu_comparaison_axes(ax, donnees, noms_schemas, logx, logy, xmode);
end




end % Final end of main function




% % ==================== CODE POUR PRÉPARER LES DONNÉES ====================
% function preparer_et_afficher_cpu(ax, results_struct, xmode, logx, logy)
% % results_struct : structure contenant les résultats pour chaque L et Newton
% %
% % Format attendu de results_struct :
% %   results_struct.L_values = [0.15, 0.25, 0.5, 1];
% %   results_struct.L_0.15.CPU_times = [cpu1 cpu2 cpu3 cpu4];
% %   results_struct.L_0.15.h_values = [h1 h2 h3 h4];  % ou dt_values
% %   results_struct.L_0.25.CPU_times = [...];
% %   ... etc ...
% %   results_struct.Newton.CPU_times = [...];
% %   results_struct.Newton.h_values = [...];
% 
%     % Initialiser les cell arrays pour ta fonction
%     donnees = {};
%     noms_schemas = {};
% 
%     % 1. AJOUTER TOUS LES L-SCHEMES
%     if isfield(results_struct, 'L_values')
%         L_values = results_struct.L_values;
% 
%         for i = 1:length(L_values)
%             L = L_values(i);
% 
%             % Chercher le champ correspondant à ce L
%             % (adapté selon comment tu stockes tes données)
%             field_name = sprintf('L_%g', L);
% 
%             if isfield(results_struct, field_name)
%                 % Ajouter les données
%                 donnees{end+1} = results_struct.(field_name);  
% 
%                 % Ajouter le nom avec la valeur de L
%                 if L == 1
%                     noms_schemas{end+1} = 'L=1';  
%                 elseif abs(L - 0.15) < 1e-10
%                     noms_schemas{end+1} = 'L=0.15';  
%                 elseif abs(L - 0.25) < 1e-10
%                     noms_schemas{end+1} = 'L=0.25';  
%                 elseif abs(L - 0.5) < 1e-10
%                     noms_schemas{end+1} = 'L=0.5';  
%                 else
%                     noms_schemas{end+1} = sprintf('L=%g', L);  
%                 end
%             end
%         end
%     end
% 
%     % 2. AJOUTER NEWTON (si présent)
%     if isfield(results_struct, 'Newton')
%         donnees{end+1} = results_struct.Newton;
%         noms_schemas{end+1} = 'Newton';
%     end
% 
%     % 3. APPELER TA FONCTION EXISTANTE (inchangée !)
%     plot_cpu_comparaison_axes(ax, donnees, noms_schemas, logx, logy, xmode);
% end
% 
% 
% 
% 
% end % dernier end de la fonction principal