%==========================================================================
% RUN_RICHARDS_LSCHEME_BATCH - Batch driver for Richards 3D L-scheme simulations
% in deformable porous media (Vertisol)
%
% This script serves as the main driver for running Richards 3D simulations
% in deformable porous media using the L-scheme nonlinear solver. It handles
% both numerical validation and physical case scenarios with automatic
% directory management.
%
% PHYSICAL CONTEXT:
%   This code simulates water flow in deformable Vertisol soils where
%   hydraulic properties depend on both pressure head and soil deformation
%   (swelling/shrinking). The L-scheme provides robust linearization for
%   these strongly nonlinear problems.
%
% KEY FEATURES:
%   - Automatic looping over L values for numerical validation
%   - Automatic creation of results directory structure:
%       results/<case_type>/L-scheme/L=<val>/resultats_complets
%       results/<case_type>/L-scheme/L=<val>/solutions_temporelles
%   - Dynamic path management for different simulation modes
%   - Comprehensive diagnostics and error computation
%   - Automatic saving of solution snapshots and convergence data
%
% MODES:
%   - numerical_validation : Multiple L values, error computation,
%                            convergence analysis with manufactured solutions
%   - physical_case        : Single L value, no error computation,
%                            full physical simulation of real Vertisol behavior
%
% DEPENDENCIES:
%   Requires proper directory structure with FEM/, models/, solvers/, utils/
%   and the Vertisol model files for deformable/non-deformable cases.
%
% OUTPUTS:
%   - Complete result files with error metrics, iterations, CPU times
%   - Solution snapshots at specified time intervals
%   - Conditioning history for linear systems
%   - Text summaries with convergence tables
%
% AUTHOR: Alhadiri MOELEVOU
% ORGANIZATION: Université Clermont Auvergne - LIMOS
% DATE:   20/02/2026
% VERSION: 1.0
% See also: SOLVENONLINEARLSCHEME, KPD

clc; close all;


% ===================== Project paths setup ==============================
% Locate the project root directory by climbing up from this file's location
% until finding main.m or the src folder

baseDir = fileparts(mfilename('fullpath'));
root    = baseDir;

maxUp = 10;
for k = 1:maxUp
    if exist(fullfile(root,'main.m'),'file') || ...
       isfolder(fullfile(root,'src'))
        break;
    end
    parent = fileparts(root);
    if strcmp(parent, root)
        error('Project root not found when climbing up from: %s', baseDir);
    end
    root = parent;
end

% ===================== Core folders ======================================

srcDir      = fullfile(root,'src');
FEMDir      = fullfile(srcDir,'FEM');
modelsDir   = fullfile(srcDir,'models');
utilsDir    = fullfile(srcDir,'utils');
solversDir  = fullfile(srcDir,'solvers');

examplesDir = fullfile(root,'examples');
guiDir      = fullfile(root,'gui');

% Assertions
assert(isfolder(srcDir),      'Missing folder: %s', srcDir);
assert(isfolder(FEMDir),      'Missing folder: %s', FEMDir);
assert(isfolder(modelsDir),   'Missing folder: %s', modelsDir);
assert(isfolder(utilsDir),    'Missing folder: %s', utilsDir);
assert(isfolder(solversDir),  'Missing folder: %s', solversDir);
assert(isfolder(examplesDir), 'Missing folder: %s', examplesDir);
assert(isfolder(guiDir),      'Missing folder: %s', guiDir);

% Add paths
addpath(genpath(srcDir));
addpath(genpath(guiDir));
addpath(genpath(examplesDir));


% ===================== MODE SELECTION ===================================
% If a driver has already defined these variables, preserve them.
if ~exist('case_type','var') || isempty(case_type)
    case_type = 'physical_case';            % 'numerical_validation' or 'physical_case'
end
if ~exist('vertisol_mode','var') || isempty(vertisol_mode)
    vertisol_mode = 'deformable';           % 'deformable' or 'non_deformable'
end

% ===================== Models folders ===================================
vertisolBaseDir = fullfile(modelsDir,'vertisol');
vanBaseDir      = fullfile(modelsDir,'van');
coeffDir        = fullfile(modelsDir,'coefficients_matrix');

% ---- Case selection ----
switch case_type
    case 'numerical_validation'
        caseFolder = 'numerical_validation';
    case 'physical_case'
        caseFolder = 'physical_case';
    otherwise
        error('Invalid case_type. Choose "numerical_validation" or "physical_case".');
end

vertisolCaseDir = fullfile(vertisolBaseDir, caseFolder);
vanCaseDir      = fullfile(vanBaseDir, caseFolder);

% ---- Vertisol mode selection ----
switch vertisol_mode
    case 'deformable'
        activeVertisolDir = fullfile(vertisolCaseDir,'deformable');
    case 'non_deformable'
        activeVertisolDir = fullfile(vertisolCaseDir,'non_deformable');
    otherwise
        error('Invalid vertisol_mode. Choose "deformable" or "non_deformable".');
end

% ---- Safety checks (NO automatic creation) ----
assert(isfolder(vertisolCaseDir),    'Missing folder: %s', vertisolCaseDir);
assert(isfolder(activeVertisolDir),  'Missing folder: %s', activeVertisolDir);
assert(isfolder(vanCaseDir),         'Missing folder: %s', vanCaseDir);
assert(isfolder(coeffDir),           'Missing folder: %s', coeffDir);

% ===================== Add stable paths =================================
addpath(FEMDir, '-begin');
addpath(coeffDir, '-begin');

% ===================== SOLVERS: ALWAYS case-dependent ====================
solversValDir  = fullfile(solversDir,'numerical_validation');
solversPhysDir = fullfile(solversDir,'physical_case');

assert(isfolder(solversValDir),  'Missing folder: %s', solversValDir);
assert(isfolder(solversPhysDir), 'Missing folder: %s', solversPhysDir);

% Remove both solver subfolders, then add only the selected one
warning('off','MATLAB:rmpath:DirNotFound');
rmpath(solversValDir);
rmpath(solversPhysDir);
warning('on','MATLAB:rmpath:DirNotFound');

switch case_type
    case 'numerical_validation'
        addpath(solversValDir, '-begin');
        activeSolversDir = solversValDir;
    case 'physical_case'
        addpath(solversPhysDir, '-begin');
        activeSolversDir = solversPhysDir;
end

addpath(examplesDir, '-begin');
addpath(genpath(utilsDir), '-begin');   % utils + subfolders

% ===================== CLEAN ALL model paths =============================
% Remove all possible Vertisol and Van Genuchten paths to avoid conflicts
allVertisolDirs = {
    fullfile(vertisolBaseDir,'numerical_validation','deformable')
    fullfile(vertisolBaseDir,'numerical_validation','non_deformable')
    fullfile(vertisolBaseDir,'physical_case','deformable')
    fullfile(vertisolBaseDir,'physical_case','non_deformable')
};

allVanDirs = {
    fullfile(vanBaseDir,'numerical_validation')
    fullfile(vanBaseDir,'physical_case')
};

warning('off','MATLAB:rmpath:DirNotFound');
for ii = 1:numel(allVertisolDirs), rmpath(allVertisolDirs{ii}); end
for ii = 1:numel(allVanDirs),      rmpath(allVanDirs{ii});      end
warning('on','MATLAB:rmpath:DirNotFound');

% ===================== Add ONLY selected folders =========================
addpath(vanCaseDir, '-begin');
addpath(activeVertisolDir, '-begin');

rehash path;

% ===================== Diagnostics ======================================
fprintf('\n================ ACTIVE CONFIGURATION ================\n');
fprintf('Case type         : %s\n', case_type);
fprintf('Vertisol mode     : %s\n', vertisol_mode);
fprintf('Vertisol folder   : %s\n', activeVertisolDir);
fprintf('Van folder        : %s\n', vanCaseDir);
fprintf('Solvers folder    : %s\n', activeSolversDir);
fprintf('------------------------------------------------------\n');

fprintf('Function locations:\n');
fprintf('e        -> %s\n', which('e'));
fprintf('theta_vg -> %s\n', which('theta_vg'));
fprintf('kh       -> %s\n', which('kh'));
fprintf('a0       -> %s\n', which('a0'));
fprintf('======================================================\n\n');

% ===================== MODE-DEPENDENT PARAMETERS =========================
ell  = 3;
ell0 = NaN; % used only in numerical_validation

switch case_type
    case 'physical_case'
       % t_final = 20;
       if ~exist('t_final','var') || isempty(t_final)
           t_final = 20;
       end
       % L_scalar = 3.01e-3;
       if ~exist('L_scalar','var') || isempty(L_scalar)
           L_scalar = 3.01e-3;
       end

       % dt0 = 0.25;
       if ~exist('dt0','var') || isempty(dt0)
           dt0 = 0.25;
       end

        test_id   = 3;
        test_cond = 3;
        % Nx_list   = [40];
        if ~exist('Nx_list','var') || isempty(Nx_list)
            Nx_list = [5 9];
        end

        save_interval = 1;

    case 'numerical_validation'
        t_final = 0.5;
        % L_vec   = [0.15 0.25 0.65 1]; 
        if ~exist('L_vec','var') || isempty(L_vec)
            L_vec = [0.15 0.25 0.65 1];
        end

        
       % dt0     = 0.1 * 2^(1 - ell0);
       if ~exist('ell0','var') || isempty(ell0)
           ell0    = 3;
       end

        test_id   = 1;
        test_cond = 1;
        % Nx_list   = [5 9 17 33];
        if ~exist('Nx_list','var') || isempty(Nx_list)
            Nx_list = [5 9 17 33];
        end

        save_interval = 0.10;

    otherwise
        error('Invalid case_type.');
end

eps1 = 1e-5; % nonlinear tolerance

% ===================== LOOP SUR L ========================================
if strcmp(case_type,'numerical_validation')
    L_list = L_vec(:)';           % row
else
    L_list = L_scalar;            % scalar
end

scheme_name = 'L-scheme';
results_base = 'results';

for iL = 1:numel(L_list)

    L = L_list(iL);

    fprintf('\n=====================================================\n');
    fprintf('RUN %s | case=%s | L=%.6g (%d/%d)\n', scheme_name, case_type, L, iL, numel(L_list));
    fprintf('=====================================================\n');

    % ======================================================================
    % OUTPUT DIRECTORIES (case / scheme / L)
    % ======================================================================
    results_root  = fullfile(results_base, case_type, scheme_name, sprintf('L=%.6g', L));
    results_dir   = fullfile(results_root, 'resultats_complets');
    solutions_dir = fullfile(results_root, 'solutions_temporelles');

    if ~exist(results_dir,'dir'),   mkdir(results_dir);   end
    if ~exist(solutions_dir,'dir'), mkdir(solutions_dir); end

    fprintf('Folders:\n');
    fprintf('  - %s\n', results_root);
    fprintf('  - %s\n', results_dir);
    fprintf('  - %s\n', solutions_dir);

    % ======================================================================
    % RESULTS ARRAYS (reinitialize for each L)
    % ======================================================================
    compute_errors = strcmp(case_type, 'numerical_validation');

    if compute_errors
        Erreur_L1   = zeros(length(Nx_list),1);
        Erreur_L2   = zeros(length(Nx_list),1);
        Erreur_Linf = zeros(length(Nx_list),1);
        Erreur_H1   = zeros(length(Nx_list),1);
    else
        Erreur_L1 = []; Erreur_L2 = []; Erreur_Linf = []; Erreur_H1 = [];
    end

    Picard_iters_last    = zeros(length(Nx_list),1);
    Picard_iters_moyenne = zeros(length(Nx_list),1);
    CPU_times            = zeros(length(Nx_list),1);

    Cond_max            = zeros(length(Nx_list),1);
    Cond_moyen          = zeros(length(Nx_list),1);
    Iter_problematiques = zeros(length(Nx_list),1);

    dt_used = zeros(length(Nx_list),1);
    visualization_data = struct();

    % ======================================================================
    % LOOP OVER MESHES
    % ======================================================================
    for i = 1:length(Nx_list)
        tic;

        nx = Nx_list(i);
        h  = 1/(nx - 1);

        dt = dt0;
        N  = ceil(t_final / dt);
        dt = t_final / N;

        dt_used(i) = dt;

        fprintf('\n=== Simulation %d/%d: nx=%d, dt=%.6f, h=1/%d=%.6f ===\n', ...
            i, length(Nx_list), nx, dt, nx-1, h);
        fprintf('Ratio dt/h = %.6f\n', dt/h);

        % -------------------------------------------------------------
        % 3D MESH + BOUNDARY NODES (CASE-DEPENDENT)
        % -------------------------------------------------------------
        [p, tmesh, pbx, pby, pbz] = kpde3dumsh(0,1,0,1,0,1,nx,nx,nx);
        x = p(:,1); y = p(:,2); z = p(:,3);
        np = size(p,1);

        switch case_type
            case 'numerical_validation'
                pbx  = union(pbx(:,1), pbx(:,2));
                pby  = union(pby(:,1), pby(:,2));
                pbz  = union(pbz(:,1), pbz(:,2));
                ibcd = union(pbx, union(pby, pbz));
            case 'physical_case'
                pbz0 = pbz(:,1);   % face z = 0 only
                ibcd = pbz0;
        end

        fprintf('Number of nodes: %5d and number of tetrahedra: %5d \n', ...
                size(p,1), size(tmesh,1));
        fprintf('Theoretical number of time steps: %d\n', N);

        nodes  = (1:np)';
        inodes = setdiff(nodes, ibcd);

        % -------------------------------------------------------------
        % Initialization at time t=0
        % -------------------------------------------------------------
        t  = 0;
        k  = 0;
        ht = dt;

        [u0, ~, ~, ~] = uex(x, y, z, t, test_cond);
        up = u0;

        iter_total = 0;
        nsteps     = 0;

        % Conditioning history for this simulation
        kappa_history_sim = [];

        % ------------------------------------------------------------------
        % SNAPSHOTS: save at t=0 and then at multiples of save_interval
        % ------------------------------------------------------------------
        it_save         = 1;
        ut_partial      = u0;
        t_saved_partial = 0;

        solution_file = sprintf('solution_nx%d_t%.3fs.mat', nx, 0);
        save(fullfile(solutions_dir, solution_file), ...
             'p', 'tmesh', 'u0', 't', 'nx', 'test_id', 'test_cond');

        next_save_time = save_interval;

        % =========================================================
        % TIME LOOP
        % =========================================================
        it = 0;
        while (t < t_final)

            k = k + 1;
            t = k * ht;
            it = k;

            if t > t_final 
                t = t_final;
            end

            % =========================================================
            % NONLINEAR SOLVER (L-scheme) + linear GMRES solver
            % =========================================================
            [u, n_iter, kappa_hist_step, cond_diag_step] = solveNonLinearLscheme( ...
                L, p, tmesh, dt, ibcd, inodes, eps1, t, up, test_id, test_cond); 

            % Snapshots
            if t >= next_save_time 
                it_save = it_save + 1;
                ut_partial(:, it_save)      = u;
                t_saved_partial(it_save, 1) = t;

                solution_file = sprintf('solution_nx%d_t%.3fs.mat', nx, t);
                save(fullfile(solutions_dir, solution_file), ...
                     'p', 'tmesh', 'u', 't', 'nx', 'test_id', 'test_cond');

                next_save_time = next_save_time + save_interval;
            end

            % Conditioning history
            if ~isempty(kappa_hist_step)
                kappa_history_sim = [kappa_history_sim; kappa_hist_step]; 
            end

            up         = u;
            iter_total = iter_total + n_iter;
            nsteps     = nsteps + 1;

            if mod(it, max(1,floor(N/10))) == 0
                fprintf('  Time step %d/%d, t=%.3f\n', it, N, t);
            end

            if it >= N
                break;
            end
        end

        % =========================================================
        % CONDITIONING DIAGNOSTICS
        % =========================================================
        if ~isempty(kappa_history_sim)
            Cond_max(i)   = max(kappa_history_sim);
            Cond_moyen(i) = mean(kappa_history_sim);
            Iter_problematiques(i) = sum(kappa_history_sim > 1e10);
        else
            Cond_max(i) = NaN;
            Cond_moyen(i) = NaN;
            Iter_problematiques(i) = 0;
        end

        % =========================================================
        % ERRORS AT FINAL TIME (ONLY for numerical_validation)
        % =========================================================
        if compute_errors
            [eL2, eH1, eL1, eLinf] = kpde3derr_all(p, tmesh, u, t, test_cond);
            Erreur_L1(i)   = eL1;
            Erreur_L2(i)   = eL2;
            Erreur_Linf(i) = eLinf;
            Erreur_H1(i)   = eH1;
        else
            eL1 = NaN; eL2 = NaN; eLinf = NaN; eH1 = NaN; 
        end

        Picard_iters_last(i)    = n_iter;
        Picard_iters_moyenne(i) = iter_total / max(1, nsteps);

        CPU_times(i) = toc;

        if compute_errors
            fprintf(['Result: h=1/%-2d, dt=%.4f | L1=%.3e | L2=%.3e | Linf=%.3e | ' ...
                     'H1=%.3e | It(last)= %d | CPU=%.2fs | Reached time=%.2f\n'], ...
                    nx-1, dt, Erreur_L1(i), Erreur_L2(i), Erreur_Linf(i), Erreur_H1(i), ...
                    n_iter, CPU_times(i), t);
        else
            fprintf(('Result: h=1/%-2d, dt=%.4f | It(last)= %d | CPU=%.2fs | Reached time=%.2f\n'), nx-1, dt, n_iter, CPU_times(i), t);
        end

        fprintf('Conditioning: max=%.3e, mean=%.3e, problematic iterations=%d\n', ...
                Cond_max(i), Cond_moyen(i), Iter_problematiques(i));

        % =========================================================
        % STORE 3D VIZ DATA
        % =========================================================
        visualization_data(i).p        = p;
        visualization_data(i).t        = tmesh;
        visualization_data(i).u        = u;
        visualization_data(i).nx       = nx;
        visualization_data(i).t_final  = t;

        visualization_data(i).X   = reshape(p(:,1), nx, nx, nx);
        visualization_data(i).Y   = reshape(p(:,2), nx, nx, nx);
        visualization_data(i).Z   = reshape(p(:,3), nx, nx, nx);
        visualization_data(i).U   = reshape(u,      nx, nx, nx);

        visualization_data(i).ut_partial       = ut_partial;
        visualization_data(i).t_saved_partial  = t_saved_partial;
    end

    % ======================================================================
    % SAVES
    % ======================================================================
    h_values = 1 ./ (Nx_list - 1);
    data_file = fullfile(results_dir, 'resultats_complets.mat');

    if compute_errors
        save(data_file, 'Erreur_L1', 'Erreur_L2', 'Erreur_Linf', 'Erreur_H1', ...
             'Picard_iters_last', 'Picard_iters_moyenne', 'CPU_times', 'Cond_max', ...
             'Cond_moyen', 'Iter_problematiques', 'dt_used', 'Nx_list', 'test_id', ...
             'test_cond', 't_final', 'visualization_data', 'h_values', ...
             'ell', 'L', 'ell0', 'dt0', 'case_type', 'vertisol_mode');
    else
        save(data_file, 'Picard_iters_last', 'Picard_iters_moyenne', 'CPU_times', 'Cond_max', ...
             'Cond_moyen', 'Iter_problematiques', 'dt_used', 'Nx_list', 'test_id', ...
             'test_cond', 't_final', 'visualization_data', 'h_values', ...
             'ell', 'L', 'ell0', 'dt0', 'case_type', 'vertisol_mode');
    end
    fprintf('\nData saved: %s\n', data_file);

    % ======================================================================
    % TEXT SUMMARY
    % ======================================================================
    summary_file = fullfile(results_dir, 'resume_resultats.txt');
    fid = fopen(summary_file, 'w');

    fprintf(fid, 'RESULTS SUMMARY - %s | case=%s | L=%.6g | Test %d, Condition %d\n', ...
            scheme_name, case_type, L, test_id, test_cond);
    fprintf(fid, 'Date: %s\n', datestr(now));
    fprintf(fid, 'Final time: %.6f\n', t_final);

    if strcmp(case_type, 'numerical_validation')
        fprintf(fid, 'dt0 (before adjustment) = %.10f with ell0=%g : dt = 0.1*2^(1-ell0)\n\n', dt0, ell0);
    else
        fprintf(fid, 'dt0 (before adjustment) = %.10f\n\n', dt0);
    end

    fprintf(fid, ['====================================================================================================\n' ...
                  'FINAL SUMMARY (iterations + CPU + conditioning)\n' ...
                  '====================================================================================================\n']);

    if compute_errors
        fprintf(fid, ['h       dt        L1          L2          Linf        H1          ' ...
                      'It. last   It. mean   CPU (s)   Cond_max     Cond_mean\n']);
        fprintf(fid, '----------------------------------------------------------------------------------------------------\n');

        for i = 1:length(Nx_list)
            fprintf(fid, ['1/%-2d   %-9.6f %-12.3e %-12.3e %-12.3e %-12.3e %-9d %-10.2f ' ...
                          '%-8.2f %-12.3e %-12.3e\n'], ...
                Nx_list(i)-1, dt_used(i), Erreur_L1(i), Erreur_L2(i), Erreur_Linf(i), Erreur_H1(i), ...
                Picard_iters_last(i), Picard_iters_moyenne(i), CPU_times(i), Cond_max(i), Cond_moyen(i));
        end

        fprintf(fid, '====================================================================================================\n\n');

        if length(Nx_list) >= 2
            ordre_L1   = diff(log(Erreur_L1))   ./ diff(log(h_values));
            ordre_L2   = diff(log(Erreur_L2))   ./ diff(log(h_values));
            ordre_Linf = diff(log(Erreur_Linf)) ./ diff(log(h_values));
            ordre_H1   = diff(log(Erreur_H1))   ./ diff(log(h_values));

            fprintf(fid, '\n=== ESTIMATED CONVERGENCE ORDERS ===\n');
            for i = 1:length(ordre_L1)
                fprintf(fid, '%d → %d : L1=%.4f | L2=%.4f | Linf=%.4f | H1=%.4f\n', ...
                    Nx_list(i), Nx_list(i+1), ordre_L1(i), ordre_L2(i), ordre_Linf(i), ordre_H1(i));
            end
        else
            fprintf(fid, '\n=== ESTIMATED CONVERGENCE ORDERS ===\n');
            fprintf(fid, 'Not computed (need at least 2 mesh levels).\n');
        end
    else
        fprintf(fid, ('h       dt        It. last   It. mean   CPU (s)   Cond_max     Cond_mean\n'));
        fprintf(fid, '----------------------------------------------------------------------------------------------------\n');

        for i = 1:length(Nx_list)
            fprintf(fid, ('1/%-2d   %-9.6f %-9d %-10.2f %-8.2f %-12.3e %-12.3e\n'), ...
                Nx_list(i)-1, dt_used(i), Picard_iters_last(i), Picard_iters_moyenne(i), ...
                CPU_times(i), Cond_max(i), Cond_moyen(i));
        end

        fprintf(fid, '----------------------------------------------------------------------------------------------------\n');
        fprintf(fid, '\nNote: Error norms and convergence orders are intentionally omitted for the physical case.\n');
    end

    fclose(fid);
    fprintf('Summary saved: %s\n', summary_file);

    fprintf('\n=== RUN COMPLETED for L=%.6g ===\n', L);
    fprintf('Saved under:\n');
    fprintf('  - %s\n', solutions_dir);
    fprintf('  - %s\n', results_dir);

end % for iL

fprintf('\n=== ALL COMPUTATIONS COMPLETED ===\n');
fprintf('Base outputs under: %s\n', fullfile(results_base, case_type, scheme_name));