function batch_view_rules_bat()
%BATCH_VIEW_RULES_BAT Automated post-processing viewer for Richards 3D
%   One-click viewer that executes a fixed sequence of visualization routines
%   without requiring user interaction during the main execution.
%
%   AUTO-RUN SEQUENCE:
%       1) Checks if results exist (main.m has been run)
%       2) Displays publication-quality error tables for L-scheme analysis
%
%   FEATURES:
%      -Interactive selection of L values and study types (spatial/temporal)
%      -Beautiful LaTeX-rendered tables with error metrics
%      -Automatic detection of available result files
%      -Safety check to warn if main.m hasn't been compiled yet
%
%   DEPENDENCIES:
%      -Requires results in: results/numerical_validation/L-scheme/L=*/
%      -Uses visualiser_tableau_erreur_L() for table generation
%
%   OUTPUT:
%       Generates publication-quality figures with error tables.

    fprintf('\n============================================\n');
    fprintf(' BATCH VIEWER (AUTO-RUN) - NO INPUTS\n');
    fprintf('============================================\n');

    % --------- CHECK IF MAIN.M HAS BEEN COMPILED ----------
    if ~check_main_compiled()
        fprintf('\nWARNING: main.m has not been compiled yet!\n');
        fprintf('   Please run main.m first to generate the results.\n');
        fprintf('   Without results, the viewer has nothing to display.\n\n');
        
        answer = questdlg('main.m has not been compiled. Do you want to continue anyway?',...
                         'Compilation Check',...
                         'Continue','Cancel','Cancel');
        if strcmp(answer,'Cancel')
            fprintf(' Batch viewer cancelled.\n');
            return;
        end
        fprintf(' Continuing without results may show empty tables.\n\n');
    end

    % --------- Error tables visualization ----------
    visualiser_tableau_erreur_L();

    fprintf('\n AUTO-RUN DONE.\n');
end

function compiled = check_main_compiled()
%CHECK_MAIN_COMPILED Verify that simulation results exist
%   Returns true if at least one results file exists in the expected location.
%   Checks for resultats_spatiaux.mat or resultats_temporels.mat files
%   in the L-scheme subdirectories.
%
%   OUTPUT:
%       compiled : logical, true if at least one result file exists

    thisFileDir = fileparts(mfilename('fullpath'));
    base_results_dir = fullfile(thisFileDir,'results');
    validation_dir = fullfile(base_results_dir,'numerical_validation');
    
    if exist(validation_dir,'dir') ~= 7
        compiled = false;
        return;
    end
    
    L_root = fullfile(validation_dir,'L-scheme');
    if exist(L_root,'dir') ~= 7
        compiled = false;
        return;
    end
    
    L_dirs = dir(fullfile(L_root,'L=*'));
    L_dirs = L_dirs([L_dirs.isdir]);
    
    for k = 1:length(L_dirs)
        spatial_file = fullfile(L_root,L_dirs(k).name,'spatial','resultats_complets','resultats_spatiaux.mat');
        temporel_file = fullfile(L_root,L_dirs(k).name,'temporel','resultats_complets','resultats_temporels.mat');
        
        if exist(spatial_file,'file') == 2 || exist(temporel_file,'file') == 2
            compiled = true;
            return;
        end
    end
    
    compiled = false;
end

%==========================================================================
% MAIN FUNCTION FOR ERROR TABLES WITH ELEGANT FIGURES
%==========================================================================

function visualiser_tableau_erreur_L()
%VISUALISER_TABLEAU_ERREUR_L Interactive error table visualization
%   Provides an interface to choose between spatial and temporal studies
%   and display publication-quality tables for different L values.
%
%   This is the main entry point for the visualization workflow.
%   It handles study type selection and dispatches to appropriate
%   visualization routines.

    fprintf('\n--- Error Tables Visualization (elegant version) ---\n');

    thisFileDir = fileparts(mfilename('fullpath'));
    base_results_dir = fullfile(thisFileDir,'results');
    validation_dir = fullfile(base_results_dir,'numerical_validation');
    
    if exist(validation_dir,'dir') ~= 7
        fprintf(' Folder not found: %s\n',validation_dir);
        fprintf('   Please run main.m first to generate results.\n');
        return;
    end

    L_root = fullfile(validation_dir,'L-scheme');
    if exist(L_root,'dir') ~= 7
        fprintf(' Folder not found: %s\n',L_root);
        fprintf('   Please run main.m first to generate results.\n');
        return;
    end

    % First ask for study type
    study_types = {'Spatial study (mesh refinement)',...
                   'Temporal study (time step refinement)'};
    
    [study_idx,ok] = listdlg(...
        'PromptString','Choose the type of study to visualize:',...
        'SelectionMode','single',...
        'ListString',study_types,...
        'Name','Study Type',...
        'ListSize',[400,150],...
        'OKString','Select',...
        'CancelString','Cancel');
    
    if ~ok || isempty(study_idx)
        fprintf(' Visualization cancelled.\n');
        return;
    end

    current_study_type = study_idx;
    
    switch study_idx
        case 1
            visualiser_etude_spatiale(L_root,current_study_type);
        case 2
            visualiser_etude_temporelle(L_root,current_study_type);
    end
end

function visualiser_etude_spatiale(L_root,study_type)
%VISUALISER_ETUDE_SPATIALE Display tables for spatial convergence study
%   Lists available L values with spatial data and lets user choose
%   which ones to visualize.
%
%   INPUTS:
%       L_root : string, path to the L-scheme root directory
%       study_type : integer, type of study (spatial=1, temporal=2)

    L_dirs = dir(fullfile(L_root,'L=*'));
    L_dirs = L_dirs([L_dirs.isdir]);
    
    if isempty(L_dirs)
        fprintf(' No L=* folders found\n');
        return;
    end

    L_values = [];
    L_names = {};
    valid_dirs = {};
    valid_L = [];
    
    for k = 1:length(L_dirs)
        L_name = L_dirs(k).name;
        tok = regexp(L_name,'L=([0-9.eE+-]+)','tokens','once');
        if ~isempty(tok)
            L_val = str2double(tok{1});
            
            spatial_dir = fullfile(L_root,L_name,'spatial','resultats_complets');
            mat_file = fullfile(spatial_dir,'resultats_spatiaux.mat');
            
            if exist(mat_file,'file') == 2
                L_values = [L_values; L_val];
                L_names{end+1} = sprintf('L = %.4f (spatial)',L_val);
                valid_dirs{end+1} = fullfile(L_root,L_name);
                valid_L(end+1) = L_val;
            end
        end
    end
    
    if isempty(L_values)
        fprintf(' No spatial data found\n');
        return;
    end
    
    [L_values_sorted,sort_idx] = sort(L_values);
    L_names_sorted = L_names(sort_idx);
    valid_dirs_sorted = valid_dirs(sort_idx);
    valid_L_sorted = valid_L(sort_idx);
    
    L_names_sorted{end+1} = 'VIEW ALL TABLES';
    
    [selection_idx,ok] = listdlg(...
        'PromptString','Choose L value to visualize (spatial study):',...
        'SelectionMode','single',...
        'ListString',L_names_sorted,...
        'Name','L Selection - Spatial',...
        'ListSize',[350,400],...
        'OKString','Visualize',...
        'CancelString','Cancel');
    
    if ~ok || isempty(selection_idx)
        fprintf(' Visualization cancelled.\n');
        return;
    end
    
    if selection_idx == length(L_names_sorted)
        for i = 1:length(valid_dirs_sorted)
            L_dir = valid_dirs_sorted{i};
            mat_file = fullfile(L_dir,'spatial','resultats_complets','resultats_spatiaux.mat');
            afficher_tableau_spatial_ameliore(mat_file,valid_L_sorted(i),L_dir,study_type);
            if i < length(valid_dirs_sorted)
                waitfor(msgbox(sprintf('L = %.4f - Click OK to continue',valid_L_sorted(i)),...
                               'Continue','modal'));
            end
        end
    else
        L_dir = valid_dirs_sorted{selection_idx};
        mat_file = fullfile(L_dir,'spatial','resultats_complets','resultats_spatiaux.mat');
        afficher_tableau_spatial_ameliore(mat_file,valid_L_sorted(selection_idx),L_dir,study_type);
    end
end

function visualiser_etude_temporelle(L_root,study_type)
%VISUALISER_ETUDE_TEMPORELLE Display tables for temporal convergence study
%   Lists available L values with temporal data and lets user choose
%   which ones to visualize.
%
%   INPUTS:
%       L_root : string, path to the L-scheme root directory
%       study_type : integer, type of study (spatial=1, temporal=2)

    L_dirs = dir(fullfile(L_root,'L=*'));
    L_dirs = L_dirs([L_dirs.isdir]);
    
    L_values = [];
    L_names = {};
    valid_dirs = {};
    valid_L = [];
    
    for k = 1:length(L_dirs)
        L_name = L_dirs(k).name;
        tok = regexp(L_name,'L=([0-9.eE+-]+)','tokens','once');
        if ~isempty(tok)
            L_val = str2double(tok{1});
            
            temporel_dir = fullfile(L_root,L_name,'temporel','resultats_complets');
            mat_file = fullfile(temporel_dir,'resultats_temporels.mat');
            
            if exist(mat_file,'file') == 2
                L_values = [L_values; L_val];
                L_names{end+1} = sprintf('L = %.4f (temporal)',L_val);
                valid_dirs{end+1} = fullfile(L_root,L_name);
                valid_L(end+1) = L_val;
            end
        end
    end
    
    if isempty(L_values)
        fprintf(' No temporal data found\n');
        return;
    end
    
    [L_values_sorted,sort_idx] = sort(L_values);
    L_names_sorted = L_names(sort_idx);
    valid_dirs_sorted = valid_dirs(sort_idx);
    valid_L_sorted = valid_L(sort_idx);
    
    L_names_sorted{end+1} = 'VIEW ALL TABLES';
    
    [selection_idx,ok] = listdlg(...
        'PromptString','Choose L value to visualize (temporal study):',...
        'SelectionMode','single',...
        'ListString',L_names_sorted,...
        'Name','L Selection - Temporal',...
        'ListSize',[350,400],...
        'OKString','Visualize',...
        'CancelString','Cancel');
    
    if ~ok || isempty(selection_idx)
        fprintf(' Visualization cancelled.\n');
        return;
    end
    
    if selection_idx == length(L_names_sorted)
        for i = 1:length(valid_dirs_sorted)
            L_dir = valid_dirs_sorted{i};
            mat_file = fullfile(L_dir,'temporel','resultats_complets','resultats_temporels.mat');
            afficher_tableau_temporel_ameliore(mat_file,valid_L_sorted(i),L_dir,study_type);
            if i < length(valid_dirs_sorted)
                waitfor(msgbox(sprintf('L = %.4f - Click OK to continue',valid_L_sorted(i)),...
                               'Continue','modal'));
            end
        end
    else
        L_dir = valid_dirs_sorted{selection_idx};
        mat_file = fullfile(L_dir,'temporel','resultats_complets','resultats_temporels.mat');
        afficher_tableau_temporel_ameliore(mat_file,valid_L_sorted(selection_idx),L_dir,study_type);
    end
end

function afficher_tableau_spatial_ameliore(mat_file, L_val, L_dir, study_type)
%AFFICHER_TABLEAU_SPATIAL_AMELIORE Publication-quality spatial error table
%   Creates a beautifully formatted figure displaying convergence data
%   from a spatial refinement study for a given L value.
%
%   INPUTS:
%       mat_file : string, path to the .mat file containing spatial results
%       L_val : double, L parameter value
%       L_dir : string, path to the L-scheme directory
%       study_type : integer, type of study (for navigation callbacks)
%
%   DATA FIELDS EXPECTED:
%       h_values : array, mesh sizes
%       Erreur_L2 : array, L2 norm errors
%       Erreur_H1 : array, H1 seminorm errors (optional)
%       Cond_max : array, condition numbers (optional)
%       CPU_times : array, computation times (optional)
%       Newton_last : array, iteration counts (optional)

    data = load(mat_file);

    if ~isfield(data, 'h_values') || ~isfield(data, 'Erreur_L2')
        fprintf(' Missing fields (h_values / Erreur_L2) for L = %.4f\n', L_val);
        return;
    end

    has_iterations = isfield(data, 'Newton_last');
    if has_iterations
        iterations = data.Newton_last;
    else
        iterations = [];
        has_iterations = false;
    end

    % Check for MAXIMAL conditioning (Cond_max)
    has_cond = isfield(data, 'Cond_max');
    if has_cond
        cond_number = data.Cond_max;  % MAXIMAL condition number
    else
        cond_number = [];
        has_cond = false;
    end

    has_cpu = isfield(data, 'CPU_times');
    if has_cpu
        cpu_time = data.CPU_times;
    else
        cpu_time = [];
        has_cpu = false;
    end

    hasH1 = isfield(data, 'Erreur_H1');

    fig = figure('Position', [150, 150, 1450, 750], ...
        'Name', sprintf('Spatial Analysis - L = %.4f', L_val), ...
        'NumberTitle', 'off', ...
        'Color', [1 1 1]);

    uicontrol('Parent', fig, ...
        'Style', 'pushbutton', ...
        'String', 'Change L', ...
        'Units', 'normalized', ...
        'Position', [0.72, 0.92, 0.10, 0.055], ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Callback', @(~,~) switch_L_spatial(fig, L_dir, L_val, study_type));

    uicontrol('Parent', fig, ...
        'Style', 'pushbutton', ...
        'String', 'Change Study', ...
        'Units', 'normalized', ...
        'Position', [0.83, 0.92, 0.12, 0.055], ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Callback', @(~,~) change_study_type(fig));

    uicontrol('Parent', fig, ...
        'Style', 'pushbutton', ...
        'String', 'Export', ...
        'Units', 'normalized', ...
        'Position', [0.61, 0.92, 0.10, 0.055], ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Callback', @(~,~) export_table_to_file(fig, data, L_val, 'spatial'));

    fontNameBody = 'Times New Roman';
    fontSizeTitle = 22;
    fontSizeHead = 13;
    fontSizeBody = 11;

    colTitle = [0.10 0.20 0.45];
    colBorder = [0.55 0.62 0.78];
    colGrid = [0.80 0.86 0.94];
    colHeader = [0.92 0.95 1.00];
    colRowA = [1.00 1.00 1.00];
    colRowB = [0.97 0.985 1.00];
    colStatsBG = [0.95 0.98 1.00];
    colHighlight = [0.85 0.95 0.85];

    % Left-aligned title
    annotation('textbox', [0.06, 0.91, 0.5, 0.06], ...
        'String', sprintf('Spatial Error Analysis for $L = %.4f$', L_val), ...
        'FontSize', fontSizeTitle, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'EdgeColor', 'none', ...
        'Interpreter', 'latex', ...
        'Color', colTitle);

    un_sur_h = 1 ./ data.h_values(:);
    [un_sur_h, idx] = sort(un_sur_h, 'ascend');
    errL2 = data.Erreur_L2(:);
    errL2 = errL2(idx);

    if has_iterations
        iterations = iterations(idx);
    end

    if has_cond
        cond_number = cond_number(idx);
    end

    if has_cpu
        cpu_time = cpu_time(idx);
    end

    if hasH1
        errH1 = data.Erreur_H1(:);
        errH1 = errH1(idx);
    end

    % Fixed number of columns: 7
    nCols = 7;
    headers = {'$h$', '$L_2$', '$H_1$', '$\kappa_{max}$', 'CPU (s)', 'Iter', 'Order'};

    left = 0.05;
    right = 0.95;
    top = 0.78;
    bottom = 0.25;

    W = right - left;
    H = top - bottom;

    nRows = numel(un_sur_h);
    rowH = H / (nRows + 1);
    colW = W / nCols;

    xPos = left + (0:nCols-1) * colW;

    % Table background
    annotation('rectangle', [left, bottom, W, H], ...
        'EdgeColor', colBorder, 'LineWidth', 2, 'FaceColor', 'none');

    % Header
    annotation('rectangle', [left, top - rowH, W, rowH], ...
        'FaceColor', colHeader, 'EdgeColor', 'none');

    % Vertical grid lines
    for x = xPos(2:end)
        annotation('line', [x, x], [bottom, top], 'Color', colGrid, 'LineWidth', 1);
    end

    % Horizontal grid lines
    for r = 1:nRows
        y = top - rowH * (r + 0);
        annotation('line', [left, right], [y, y], 'Color', colGrid, 'LineWidth', 1);
    end

    % Column headers
    for c = 1:nCols
        annotation('textbox', [xPos(c), top - rowH, colW, rowH], ...
            'String', headers{c}, 'FontSize', fontSizeHead, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'EdgeColor', 'none', 'Interpreter', 'latex', 'Color', [0 0 0]);
    end

    orders = [];
    min_idx = 1;

    for i = 1:nRows
        yRow = top - rowH * (i + 1);
        bg = colRowA;
        if mod(i, 2) == 0
            bg = colRowB;
        end

        % Highlight best performance (minimum L2 error)
        if errL2(i) == min(errL2)
            bg = colHighlight;
            min_idx = i;
        end

        annotation('rectangle', [left, yRow, W, rowH], 'FaceColor', bg, 'EdgeColor', 'none');

        % Cell contents
        rowCells = cell(1, nCols);
        colIdx = 1;

        % h
        nx_val = round(un_sur_h(i));
        rowCells{colIdx} = sprintf('$1/%d$', nx_val);
        colIdx = colIdx + 1;

        % L2 Error
        [m2, e2] = format_scientific(errL2(i));
        rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', m2, e2);
        colIdx = colIdx + 1;

        % H1 Error
        if hasH1
            [m1, e1] = format_scientific(errH1(i));
            rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', m1, e1);
        else
            rowCells{colIdx} = '$-$';
        end
        colIdx = colIdx + 1;

        % MAXIMAL conditioning
        if has_cond && i <= length(cond_number)
            if cond_number(i) > 1e3
                [mc, ec] = format_scientific(cond_number(i));
                rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', mc, ec);
            elseif cond_number(i) >= 1
                rowCells{colIdx} = sprintf('$%.1f$', cond_number(i));
            else
                [mc, ec] = format_scientific(cond_number(i));
                rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', mc, ec);
            end
        else
            rowCells{colIdx} = '$-$';
        end
        colIdx = colIdx + 1;

        % CPU time
        if has_cpu && i <= length(cpu_time)
            if cpu_time(i) >= 1000
                [m_cpu, e_cpu] = format_scientific(cpu_time(i));
                rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', m_cpu, e_cpu);
            elseif cpu_time(i) >= 1
                rowCells{colIdx} = sprintf('$%.2f$', cpu_time(i));
            else
                [m_cpu, e_cpu] = format_scientific(cpu_time(i));
                rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', m_cpu, e_cpu);
            end
        else
            rowCells{colIdx} = '$-$';
        end
        colIdx = colIdx + 1;

        % Iterations
        if has_iterations && i <= length(iterations)
            if abs(iterations(i) - round(iterations(i))) < 1e-10
                rowCells{colIdx} = sprintf('$%d$', round(iterations(i)));
            else
                rowCells{colIdx} = sprintf('$%.1f$', iterations(i));
            end
        else
            rowCells{colIdx} = '$-$';
        end
        colIdx = colIdx + 1;

        % Order
        if i > 1
            ord = log10(errL2(i-1) / errL2(i)) / log10(2);
            orders(end + 1) = ord;
            rowCells{colIdx} = sprintf('$%.2f$', ord);
        else
            rowCells{colIdx} = '$-$';
        end

        % Place all cells
        for c = 1:nCols
            annotation('textbox', [xPos(c), yRow, colW, rowH], ...
                'String', rowCells{c}, 'FontName', fontNameBody, 'FontSize', fontSizeBody, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'EdgeColor', 'none', 'Interpreter', 'latex', 'Color', [0 0 0]);
        end
    end

    % Statistics calculation
    [min_err, min_idx_abs] = min(errL2);
    [m_min, e_min] = format_scientific(min_err);
    avg_order = mean(orders);

    % Build statistics text
    stats_text = sprintf('Best: $L_2$ min $=%.2f\\times10^{%d}$ (1/%d)', ...
        m_min, e_min, round(un_sur_h(min_idx_abs)));

    if has_cpu && ~isempty(cpu_time)
        min_cpu = min(cpu_time);
        if min_cpu >= 1
            stats_text = [stats_text sprintf(', CPU min $=%.2f$ s', min_cpu)];
        else
            [m_cpu_min, e_cpu_min] = format_scientific(min_cpu);
            stats_text = [stats_text sprintf(', CPU min $=%.2f\\times10^{%d}$ s', m_cpu_min, e_cpu_min)];
        end
    end

    if has_cond && ~isempty(cond_number)
        min_cond = min(cond_number);
        if min_cond >= 1
            stats_text = [stats_text sprintf(', $\\kappa_{max}$ min $=%.1f$', min_cond)];
        else
            [m_cond_min, e_cond_min] = format_scientific(min_cond);
            stats_text = [stats_text sprintf(', $\\kappa_{max}$ min $=%.2f\\times10^{%d}$', m_cond_min, e_cond_min)];
        end
        
        avg_cond = mean(cond_number);
        if avg_cond >= 1
            stats_text = [stats_text sprintf(', $\\kappa_{max}$ avg $=%.1f$', avg_cond)];
        else
            [m_cond_avg, e_cond_avg] = format_scientific(avg_cond);
            stats_text = [stats_text sprintf(', $\\kappa_{max}$ avg $=%.2f\\times10^{%d}$', m_cond_avg, e_cond_avg)];
        end
    end

    stats_text = [stats_text sprintf(' / Avg order $=%.2f$', avg_order)];

    if has_iterations && ~isempty(iterations)
        avg_iters = mean(iterations);
        stats_text = [stats_text sprintf(', Iter avg $=%.1f$', avg_iters)];
    end

    annotation('textbox', [0.08, 0.06, 0.84, 0.08], ...
        'String', stats_text, 'FontName', fontNameBody, 'FontSize', 13, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'EdgeColor', colBorder, 'LineWidth', 2, 'BackgroundColor', colStatsBG, ...
        'Interpreter', 'latex', 'Color', colTitle);

    fprintf(' Elegant spatial table displayed for L = %.4f\n', L_val);
    fprintf('   - h values: %s\n', mat2str(round(un_sur_h)));
    fprintf('   - Condition number (max): %s\n', ternary(has_cond, 'yes', 'no'));
    fprintf('   - CPU time: %s\n', ternary(has_cpu, 'yes', 'no'));
end

%Partie A tradui%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 






function afficher_tableau_temporel_ameliore(mat_file, L_val, L_dir, study_type)
%AFFICHER_TABLEAU_TEMPOREL_AMELIORE Publication-quality temporal error table
%   Creates a beautifully formatted figure displaying convergence data
%   from a time step refinement study for a given L value.
%
%   INPUTS:
%       mat_file : string, path to the .mat file containing temporal results
%       L_val : double, L parameter value
%       L_dir : string, path to the L-scheme directory
%       study_type : integer, type of study (for navigation callbacks)
%
%   DATA FIELDS EXPECTED:
%       dt_values : array, time step sizes
%       Erreur_L2 : array, L2 norm errors
%       Erreur_H1 : array, H1 seminorm errors (optional)
%       Cond_max : array, condition numbers (optional)
%       CPU_times : array, computation times (optional)
%       Newton_last : array, iteration counts (optional)

    data = load(mat_file);

    if isfield(data, 'dt_values')
        dt_vals = data.dt_values(:);
    else
        fprintf(' No time step data\n');
        return;
    end

    if ~isfield(data, 'Erreur_L2')
        fprintf(' Missing Erreur_L2 data\n');
        return;
    end

    errL2 = data.Erreur_L2(:);
    [dt_vals, idx] = sort(dt_vals, 'ascend');
    errL2 = errL2(idx);

    has_iterations = isfield(data, 'Newton_last');
    if has_iterations
        iterations = data.Newton_last;
        iterations = iterations(idx);
    else
        iterations = [];
    end

    % Check for MAXIMAL conditioning (Cond_max)
    has_cond = isfield(data, 'Cond_max');
    if has_cond
        cond_number = data.Cond_max;
        cond_number = cond_number(idx);
    else
        cond_number = [];
    end

    has_cpu = isfield(data, 'CPU_times');
    if has_cpu
        cpu_time = data.CPU_times;
        cpu_time = cpu_time(idx);
    else
        cpu_time = [];
    end

    hasH1 = isfield(data, 'Erreur_H1');
    if hasH1
        errH1 = data.Erreur_H1(:);
        errH1 = errH1(idx);
    end

    fig = figure('Position', [150, 150, 1450, 750], ...
        'Name', sprintf('Temporal Analysis - L = %.4f', L_val), ...
        'NumberTitle', 'off', ...
        'Color', [1 1 1]);

    uicontrol('Parent', fig, 'Style', 'pushbutton', 'String', 'Change L', ...
        'Units', 'normalized', 'Position', [0.72, 0.92, 0.10, 0.055], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'Callback', @(~,~) switch_L_temporel(fig, L_dir, L_val, study_type));

    uicontrol('Parent', fig, 'Style', 'pushbutton', 'String', 'Change Study', ...
        'Units', 'normalized', 'Position', [0.83, 0.92, 0.12, 0.055], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'Callback', @(~,~) change_study_type(fig));

    uicontrol('Parent', fig, ...
        'Style', 'pushbutton', ...
        'String', 'Export', ...
        'Units', 'normalized', ...
        'Position', [0.61, 0.92, 0.10, 0.055], ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Callback', @(~,~) export_table_to_file(fig, data, L_val, 'temporal'));

    fontNameBody = 'Times New Roman';
    fontSizeTitle = 22;
    fontSizeHead = 13;
    fontSizeBody = 11;

    colTitle = [0.10 0.20 0.45];
    colBorder = [0.55 0.62 0.78];
    colGrid = [0.80 0.86 0.94];
    colHeader = [0.92 0.95 1.00];
    colRowA = [1.00 1.00 1.00];
    colRowB = [0.97 0.985 1.00];
    colStatsBG = [0.95 0.98 1.00];
    colHighlight = [0.85 0.95 0.85];

    % Left-aligned title
    annotation('textbox', [0.06, 0.91, 0.5, 0.06], ...
        'String', sprintf('Temporal Error Analysis for $L = %.4f$', L_val), ...
        'FontSize', fontSizeTitle, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'EdgeColor', 'none', 'Interpreter', 'latex', 'Color', colTitle);

    % Fixed number of columns: 7
    nCols = 7;
    headers = {'$\Delta t$', '$L_2$', '$H_1$', '$\kappa_{max}$', 'CPU (s)', 'Iter', 'Order'};

    left = 0.05;
    right = 0.95;
    top = 0.78;
    bottom = 0.25;

    W = right - left;
    H = top - bottom;

    nRows = numel(dt_vals);
    rowH = H / (nRows + 1);
    colW = W / nCols;

    xPos = left + (0:nCols-1) * colW;

    annotation('rectangle', [left, bottom, W, H], ...
        'EdgeColor', colBorder, 'LineWidth', 2, 'FaceColor', 'none');
    annotation('rectangle', [left, top - rowH, W, rowH], ...
        'FaceColor', colHeader, 'EdgeColor', 'none');

    for x = xPos(2:end)
        annotation('line', [x, x], [bottom, top], 'Color', colGrid, 'LineWidth', 1);
    end
    for r = 1:nRows
        y = top - rowH * (r + 0);
        annotation('line', [left, right], [y, y], 'Color', colGrid, 'LineWidth', 1);
    end

    for c = 1:nCols
        annotation('textbox', [xPos(c), top - rowH, colW, rowH], ...
            'String', headers{c}, 'FontSize', fontSizeHead, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'EdgeColor', 'none', 'Interpreter', 'latex', 'Color', [0 0 0]);
    end

    orders = [];
    min_idx = 1;

    for i = 1:nRows
        yRow = top - rowH * (i + 1);
        bg = colRowA;
        if mod(i, 2) == 0
            bg = colRowB;
        end

        if errL2(i) == min(errL2)
            bg = colHighlight;
            min_idx = i;
        end

        annotation('rectangle', [left, yRow, W, rowH], 'FaceColor', bg, 'EdgeColor', 'none');

        % Cell contents
        rowCells = cell(1, nCols);
        colIdx = 1;

        % dt
        [m_dt, e_dt] = format_scientific(dt_vals(i));
        rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', m_dt, e_dt);
        colIdx = colIdx + 1;

        % L2 Error
        [m2, e2] = format_scientific(errL2(i));
        rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', m2, e2);
        colIdx = colIdx + 1;

        % H1 Error
        if hasH1
            [m1, e1] = format_scientific(errH1(i));
            rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', m1, e1);
        else
            rowCells{colIdx} = '$-$';
        end
        colIdx = colIdx + 1;

        % MAXIMAL conditioning
        if has_cond && i <= length(cond_number)
            if cond_number(i) > 1e3
                [mc, ec] = format_scientific(cond_number(i));
                rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', mc, ec);
            elseif cond_number(i) >= 1
                rowCells{colIdx} = sprintf('$%.1f$', cond_number(i));
            else
                [mc, ec] = format_scientific(cond_number(i));
                rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', mc, ec);
            end
        else
            rowCells{colIdx} = '$-$';
        end
        colIdx = colIdx + 1;

        % CPU time
        if has_cpu && i <= length(cpu_time)
            if cpu_time(i) >= 1000
                [m_cpu, e_cpu] = format_scientific(cpu_time(i));
                rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', m_cpu, e_cpu);
            elseif cpu_time(i) >= 1
                rowCells{colIdx} = sprintf('$%.2f$', cpu_time(i));
            else
                [m_cpu, e_cpu] = format_scientific(cpu_time(i));
                rowCells{colIdx} = sprintf('$%.2f\\times10^{%d}$', m_cpu, e_cpu);
            end
        else
            rowCells{colIdx} = '$-$';
        end
        colIdx = colIdx + 1;

        % Iterations
        if has_iterations && i <= length(iterations)
            if abs(iterations(i) - round(iterations(i))) < 1e-10
                rowCells{colIdx} = sprintf('$%d$', round(iterations(i)));
            else
                rowCells{colIdx} = sprintf('$%.1f$', iterations(i));
            end
        else
            rowCells{colIdx} = '$-$';
        end
        colIdx = colIdx + 1;

        % Order
        if i > 1
            ord = log10(errL2(i-1) / errL2(i)) / log10(2);
            orders(end + 1) = ord;
            rowCells{colIdx} = sprintf('$%.2f$', ord);
        else
            rowCells{colIdx} = '$-$';
        end

        for c = 1:nCols
            annotation('textbox', [xPos(c), yRow, colW, rowH], ...
                'String', rowCells{c}, 'FontName', fontNameBody, 'FontSize', fontSizeBody, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'EdgeColor', 'none', 'Interpreter', 'latex', 'Color', [0 0 0]);
        end
    end

    % Statistics calculation
    [min_err, min_idx_abs] = min(errL2);
    [m_min, e_min] = format_scientific(min_err);
    avg_order = mean(orders);

    stats_text = sprintf('Best: $L_2$ min $=%.2f\\times10^{%d}$ ($\\Delta t=%.2e$)', ...
        m_min, e_min, dt_vals(min_idx_abs));

    if has_cpu && ~isempty(cpu_time)
        min_cpu = min(cpu_time);
        if min_cpu >= 1
            stats_text = [stats_text sprintf(', CPU min $=%.2f$ s', min_cpu)];
        else
            [m_cpu_min, e_cpu_min] = format_scientific(min_cpu);
            stats_text = [stats_text sprintf(', CPU min $=%.2f\\times10^{%d}$ s', m_cpu_min, e_cpu_min)];
        end
    end

    if has_cond && ~isempty(cond_number)
        min_cond = min(cond_number);
        if min_cond >= 1
            stats_text = [stats_text sprintf(', $\\kappa_{max}$ min $=%.1f$', min_cond)];
        else
            [m_cond_min, e_cond_min] = format_scientific(min_cond);
            stats_text = [stats_text sprintf(', $\\kappa_{max}$ min $=%.2f\\times10^{%d}$', m_cond_min, e_cond_min)];
        end
        
        avg_cond = mean(cond_number);
        if avg_cond >= 1
            stats_text = [stats_text sprintf(', $\\kappa_{max}$ avg $=%.1f$', avg_cond)];
        else
            [m_cond_avg, e_cond_avg] = format_scientific(avg_cond);
            stats_text = [stats_text sprintf(', $\\kappa_{max}$ avg $=%.2f\\times10^{%d}$', m_cond_avg, e_cond_avg)];
        end
    end

    stats_text = [stats_text sprintf(' / Avg order $=%.2f$', avg_order)];

    if has_iterations && ~isempty(iterations)
        avg_iters = mean(iterations);
        stats_text = [stats_text sprintf(', Iter avg $=%.1f$', avg_iters)];
    end

    annotation('textbox', [0.08, 0.06, 0.84, 0.08], ...
        'String', stats_text, 'FontName', fontNameBody, 'FontSize', 13, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'EdgeColor', colBorder, 'LineWidth', 2, 'BackgroundColor', colStatsBG, ...
        'Interpreter', 'latex', 'Color', colTitle);

    fprintf(' Elegant temporal table displayed for L = %.4f\n', L_val);
    fprintf('   - dt values: from %.2e to %.2e\n', min(dt_vals), max(dt_vals));
    fprintf('   - Condition number (max): %s\n', ternary(has_cond, 'yes', 'no'));
    fprintf('   - CPU time: %s\n', ternary(has_cpu, 'yes', 'no'));
end

function [m, e] = format_scientific(x)
%FORMAT_SCIENTIFIC Convert scalar to mantissa-exponent (base 10) with 2 decimals
%   Returns mantissa m in [1,10) and integer exponent e such that x = m * 10^e.
%   Used for consistent scientific notation formatting in tables.
%
%   INPUT:
%       x : double, value to format
%
%   OUTPUT:
%       m : double, mantissa rounded to 2 decimals
%       e : integer, exponent

    if x == 0
        m = 0;
        e = 0;
        return;
    end
    e = floor(log10(abs(x)));
    m = x / 10^e;
    m = round(m * 100) / 100;
end

%%%%%

function export_table_to_file(fig, data, L_val, study_type)
%EXPORT_TABLE_TO_FILE Export the table to a text file
%   Saves the current error table to a user-selected file in various formats.
%   Provides interactive file dialog for choosing save location and format.
%
%   INPUTS:
%       fig : figure handle, current figure (unused but kept for callback compatibility)
%       data : struct, data structure containing error metrics
%       L_val : double, L parameter value
%       study_type : string, 'spatial' or 'temporal'

    [file, path] = uiputfile({'*.txt'; '*.csv'; '*.tex'}, ...
        sprintf('Export %s Table for L=%.4f', study_type, L_val), ...
        sprintf('%s_table_L%.4f.txt', study_type, L_val));
    
    if isequal(file, 0) || isequal(path, 0)
        return;
    end
    
    fullpath = fullfile(path, file);
    fid = fopen(fullpath, 'w');
    
    if fid == -1
        errordlg('Could not open file for writing', 'Export Error');
        return;
    end
    
    fprintf(fid, '# %s Error Analysis for L = %.4f\n', study_type, L_val);
    fprintf(fid, '# Generated: %s\n\n', datestr(now));
    
    if strcmp(study_type, 'spatial')
        fprintf(fid, 'h\tL2 Error\t');
        if isfield(data, 'Erreur_H1')
            fprintf(fid, 'H1 Error\t');
        end
        if isfield(data, 'cond_last')
            fprintf(fid, 'Condition\t');
        end
        if isfield(data, 'cpu_time')
            fprintf(fid, 'CPU (s)\t');
        end
        if isfield(data, 'Newton_last')
            fprintf(fid, 'Iterations\t');
        end
        fprintf(fid, 'Order\n');
        
        un_sur_h = 1 ./ data.h_values(:);
        [un_sur_h, idx] = sort(un_sur_h, 'ascend');
        errL2 = data.Erreur_L2(idx);
        
        for i = 1:length(un_sur_h)
            fprintf(fid, '1/%d\t%.4e\t', round(un_sur_h(i)), errL2(i));
            if isfield(data, 'Erreur_H1')
                fprintf(fid, '%.4e\t', data.Erreur_H1(idx(i)));
            end
            if isfield(data, 'cond_last')
                fprintf(fid, '%.2f\t', data.cond_last(idx(i)));
            end
            if isfield(data, 'cpu_time')
                fprintf(fid, '%.2f\t', data.cpu_time(idx(i)));
            end
            if isfield(data, 'Newton_last')
                fprintf(fid, '%d\t', round(data.Newton_last(idx(i))));
            end
            if i > 1
                ord = log10(errL2(i-1) / errL2(i)) / log10(2);
                fprintf(fid, '%.2f\n', ord);
            else
                fprintf(fid, '-\n');
            end
        end
    else
        if isfield(data, 'dt_values')
            dt_vals = data.dt_values(:);
        else
            dt_vals = data.dt_used(:);
        end
        [dt_vals, idx] = sort(dt_vals, 'ascend');
        errL2 = data.Erreur_L2(idx);
        
        fprintf(fid, 'dt\tL2 Error\t');
        if isfield(data, 'Erreur_H1')
            fprintf(fid, 'H1 Error\t');
        end
        if isfield(data, 'cond_last')
            fprintf(fid, 'Condition\t');
        end
        if isfield(data, 'cpu_time')
            fprintf(fid, 'CPU (s)\t');
        end
        if isfield(data, 'Newton_last')
            fprintf(fid, 'Iterations\t');
        end
        fprintf(fid, 'Order\n');
        
        for i = 1:length(dt_vals)
            fprintf(fid, '%.4e\t%.4e\t', dt_vals(i), errL2(i));
            if isfield(data, 'Erreur_H1')
                fprintf(fid, '%.4e\t', data.Erreur_H1(idx(i)));
            end
            if isfield(data, 'cond_last')
                fprintf(fid, '%.2f\t', data.cond_last(idx(i)));
            end
            if isfield(data, 'cpu_time')
                fprintf(fid, '%.2f\t', data.cpu_time(idx(i)));
            end
            if isfield(data, 'Newton_last')
                fprintf(fid, '%d\t', round(data.Newton_last(idx(i))));
            end
            if i > 1
                ord = log10(errL2(i-1) / errL2(i)) / log10(2);
                fprintf(fid, '%.2f\n', ord);
            else
                fprintf(fid, '-\n');
            end
        end
    end
    
    fclose(fid);
    fprintf('Table exported to: %s\n', fullpath);
end

function out = ternary(cond, a, b)
%TERNARY Simple ternary operator replacement
%   Returns a if cond is true, b otherwise.
%   Provides inline conditional logic similar to C's ternary operator.
%
%   INPUTS:
%       cond : logical, condition to evaluate
%       a : any, value returned if cond is true
%       b : any, value returned if cond is false
%
%   OUTPUT:
%       out : any, either a or b depending on cond

    if cond
        out = a;
    else
        out = b;
    end
end

function switch_L_spatial(figHandle,current_L_dir,current_L_val,study_type)
%SWITCH_L_SPATIAL Interactive L-value selector for spatial tables
%   Allows user to switch between different L values and refresh
%   the spatial error table with the newly selected data.
%
%   INPUTS:
%       figHandle : figure handle, current figure to close
%       current_L_dir : string, path to current L directory
%       current_L_val : double, current L value
%       study_type : integer, type of study (for callback)

    L_root = fileparts(current_L_dir);
    L_dirs = dir(fullfile(L_root,'L=*'));
    L_dirs = L_dirs([L_dirs.isdir]);

    L_values = [];
    valid_dirs = {};
    for k = 1:numel(L_dirs)
        tok = regexp(L_dirs(k).name,'L=([0-9.eE+\-]+)','tokens','once');
        if ~isempty(tok)
            L_val = str2double(tok{1});
            mat_file = fullfile(L_root,L_dirs(k).name,'spatial','resultats_complets','resultats_spatiaux.mat');
            if exist(mat_file,'file') == 2
                L_values = [L_values; L_val];
                valid_dirs{end+1} = fullfile(L_root,L_dirs(k).name);
            end
        end
    end

    if isempty(L_values)
        errordlg('No other spatial data found.','Error');
        return;
    end

    [L_values,idx] = sort(L_values);
    valid_dirs = valid_dirs(idx);

    items = cell(numel(L_values),1);
    for k = 1:numel(L_values)
        items{k} = sprintf('L = %.6g',L_values(k));
    end

    preSel = find(abs(L_values-current_L_val) < 1e-12,1);
    if isempty(preSel),preSel = 1; end

    [sel,okDlg] = listdlg('PromptString','Choose L:',...
        'SelectionMode','single','ListString',items,...
        'InitialValue',preSel,'ListSize',[300,300],'Name','Choose L');

    if ~okDlg || isempty(sel),return; end

    newL = L_values(sel);
    newLdir = valid_dirs{sel};
    mat_file = fullfile(newLdir,'spatial','resultats_complets','resultats_spatiaux.mat');

    if isvalid(figHandle),close(figHandle); end
    afficher_tableau_spatial_ameliore(mat_file,newL,newLdir,study_type);
end

function switch_L_temporel(figHandle,current_L_dir,current_L_val,study_type)
%SWITCH_L_TEMPOREL Interactive L-value selector for temporal tables
%   Allows user to switch between different L values and refresh
%   the temporal error table with the newly selected data.
%
%   INPUTS:
%       figHandle : figure handle, current figure to close
%       current_L_dir : string, path to current L directory
%       current_L_val : double, current L value
%       study_type : integer, type of study (for callback)

    L_root = fileparts(current_L_dir);
    L_dirs = dir(fullfile(L_root,'L=*'));
    L_dirs = L_dirs([L_dirs.isdir]);

    L_values = [];
    valid_dirs = {};
    for k = 1:numel(L_dirs)
        tok = regexp(L_dirs(k).name,'L=([0-9.eE+\-]+)','tokens','once');
        if ~isempty(tok)
            L_val = str2double(tok{1});
            mat_file = fullfile(L_root,L_dirs(k).name,'temporel','resultats_complets','resultats_temporels.mat');
            if exist(mat_file,'file') == 2
                L_values = [L_values; L_val];
                valid_dirs{end+1} = fullfile(L_root,L_dirs(k).name);
            end
        end
    end

    if isempty(L_values)
        errordlg('No other temporal data found.','Error');
        return;
    end

    [L_values,idx] = sort(L_values);
    valid_dirs = valid_dirs(idx);

    items = cell(numel(L_values),1);
    for k = 1:numel(L_values)
        items{k} = sprintf('L = %.6g',L_values(k));
    end

    preSel = find(abs(L_values-current_L_val) < 1e-12,1);
    if isempty(preSel),preSel = 1; end

    [sel,okDlg] = listdlg('PromptString','Choose L:',...
        'SelectionMode','single','ListString',items,...
        'InitialValue',preSel,'ListSize',[300,300],'Name','Choose L');

    if ~okDlg || isempty(sel),return; end

    newL = L_values(sel);
    newLdir = valid_dirs{sel};
    mat_file = fullfile(newLdir,'temporel','resultats_complets','resultats_temporels.mat');

    if isvalid(figHandle),close(figHandle); end
    afficher_tableau_temporel_ameliore(mat_file,newL,newLdir,study_type);
end

function change_study_type(figHandle)
%CHANGE_STUDY_TYPE Restart study type selection
%   Closes current figure and returns to the study type selection dialog.
%
%   INPUT:
%       figHandle : figure handle, current figure to close

    if isvalid(figHandle)
        close(figHandle);
    end
    visualiser_tableau_erreur_L();
end
