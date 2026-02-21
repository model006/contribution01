clear; clc;
%==========================================================================
% MAIN_2D_NUMERICAL_VALIDATION Main driver for 2D Richards L-scheme
%                                 numerical validation studies
%
% This script performs systematic numerical validation of the L-scheme
% for Richards equation in 2D. It handles both spatial (mesh refinement)
% and temporal (time step refinement) convergence studies.
%
% KEY FEATURES:
%  -Automatic path management for src2D directory structure
%  -Support for both deformable and non-deformable Vertisol models
%  -Interactive parameter loading from GUI (choose_parameters.m)
%  -Automatic fallback to default parameters if GUI not used
%  -Comprehensive error computation (L1,L2,Linf,H1 norms)
%  -Automatic convergence order calculation
%  -Organized output structure:
%       results/numerical_validation/L-scheme/L=<val>/spatial|temporel/
%           resultats_complets/     -MAT files with all results
%           solutions_temporelles/  -Solution snapshots over time
%           convergence_data/       -Iteration/CPU/conditioning data
%  -Detailed text summaries with convergence tables
%  -Real-time progress monitoring in console
%
% STUDY MODES:
%   Mode 1: Spatial only  -Mesh refinement with fixed time step
%   Mode 2: Temporal only -Time step refinement with fixed mesh
%   Mode 3: Both studies  -Runs both spatial and temporal studies
%
% PARAMETER SOURCES (priority order):
%   1. Base workspace (from choose_parameters GUI)
%   2. simulation_parameters.mat file
%   3. Default values (for standalone execution)
%
% DEPENDENCIES:
%   Requires proper directory structure:
%   src2D/
%       FEM2D/         -Finite element core functions
%       models2D/      -Physical models (vertisol,van Genuchten)
%           vertisol/  -Vertisol model variants
%           van/       -Van Genuchten model
%           coefficients_matrix/-Material coefficients
%       utils2D/       -Utility functions
%       solvers2D/     -Nonlinear solvers
%           numerical_validation/-L-scheme solver for validation
%   examples2D/        -Example files (uex.m,etc.)
%
% OUTPUTS:
%   -MAT files with error metrics, iteration counts, CPU times
%   -Text summaries with convergence tables
%   -Solution snapshots at specified intervals
%   -Convergence data for iterative solvers
%
% USAGE:
%   1. Run choose_parameters.m first for interactive parameter selection
%   2. Execute this script directly or via GUI "Save & Run" button
%   3. View results using batch_view_rules_bat.m or CPU/Error tabs
%
% NOTES:
%   -The script automatically cleans old result files at startup
%   -Convergence data is saved incrementally (allows partial results)
%   -Conditioning information is stored when available

baseDir = fileparts(mfilename('fullpath'));
root    = baseDir;

maxUp = 10;
for k = 1:maxUp
    if exist(fullfile(root,'main.m'),'file') || ...
       isfolder(fullfile(root,'src2D'))      || ...
       isfolder(fullfile(root,'models2D'))    % Kept for backward compatibility
        break;
    end
    parent = fileparts(root);
    if strcmp(parent,root)
        error('Project root not found when climbing up from: %s',baseDir);
    end
    root = parent;
end

% ===================== Core folders in src2D ============================
src2DDir = fullfile(root,'src2D');
assert(isfolder(src2DDir),'Missing folder: %s',src2DDir);

% All core directories are now inside src2D
FEM2DDir      = fullfile(src2DDir,'FEM2D');
models2DDir   = fullfile(src2DDir,'models2D');
utils2DDir    = fullfile(src2DDir,'utils2D');
solvers2DDir  = fullfile(src2DDir,'solvers2D');
examples2DDir = fullfile(root,'examples2D');  % examples2D remains at root

assert(isfolder(FEM2DDir),'Missing folder: %s',FEM2DDir);
assert(isfolder(models2DDir),'Missing folder: %s',models2DDir);
assert(isfolder(utils2DDir),'Missing folder: %s',utils2DDir);
assert(isfolder(solvers2DDir),'Missing folder: %s',solvers2DDir);
assert(isfolder(examples2DDir),'Missing folder: %s',examples2DDir);

% ===================== Mode ===================================
case_type     = 'numerical_validation';  % Only numerical validation
vertisol_mode = 'deformable';            % 'deformable' or 'non_deformable'

% ===================== models2D folders ===================================
vertisolBaseDir = fullfile(models2DDir,'vertisol');
vanBaseDir      = fullfile(models2DDir,'van');
coeffDir        = fullfile(models2DDir,'coefficients_matrix');

% ---- Paths for numerical_validation ----
vertisolCaseDir = fullfile(vertisolBaseDir,'numerical_validation');
vanCaseDir      = fullfile(vanBaseDir,'numerical_validation');

% ---- Vertisol mode selection ----
switch vertisol_mode
    case 'deformable'
        activeVertisolDir = fullfile(vertisolCaseDir,'deformable');
    case 'non_deformable'
        activeVertisolDir = fullfile(vertisolCaseDir,'non_deformable');
    otherwise
        error('Invalid vertisol_mode. Choose "deformable" or "non_deformable".');
end

% ---- Safety checks ----
assert(isfolder(vertisolCaseDir),'Missing folder: %s',vertisolCaseDir);
assert(isfolder(activeVertisolDir),'Missing folder: %s',activeVertisolDir);
assert(isfolder(vanCaseDir),'Missing folder: %s',vanCaseDir);
assert(isfolder(coeffDir),'Missing folder: %s',coeffDir);

% ===================== Add stable paths =================================
addpath(FEM2DDir,'-begin');
addpath(coeffDir,'-begin');

% ===================== solvers2D: numerical_validation ====================
solvers2DValDir = fullfile(solvers2DDir,'numerical_validation');
assert(isfolder(solvers2DValDir),'Missing folder: %s',solvers2DValDir);

% Remove all solver subfolders,then add only numerical_validation
warning('off','MATLAB:rmpath:DirNotFound');
rmpath(fullfile(solvers2DDir,'physical_case'));
warning('on','MATLAB:rmpath:DirNotFound');

addpath(solvers2DValDir,'-begin');
activesolvers2DDir = solvers2DValDir;

addpath(examples2DDir,'-begin');
addpath(genpath(utils2DDir),'-begin');  % utils2D+subfolders

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
for ii = 1:numel(allVertisolDirs),rmpath(allVertisolDirs{ii}); end
for ii = 1:numel(allVanDirs),rmpath(allVanDirs{ii}); end
warning('on','MATLAB:rmpath:DirNotFound');

% ===================== Add ONLY selected folders =========================
addpath(vanCaseDir,'-begin');
addpath(activeVertisolDir,'-begin');

rehash path;

% ===================== Diagnostics ======================================
fprintf('\n================ ACTIVE CONFIGURATION ================\n');
fprintf('Case type         : %s\n',case_type);
fprintf('Vertisol mode     : %s\n',vertisol_mode);
fprintf('Vertisol folder   : %s\n',activeVertisolDir);
fprintf('Van folder        : %s\n',vanCaseDir);
fprintf('solvers2D folder  : %s\n',activesolvers2DDir);
fprintf('src2D folder      : %s\n',src2DDir);
fprintf('======================================================\n\n');

% ===================== LOAD INTERACTIVE PARAMETERS =====================
% Priority:
%   (A) If GUI already put variables in BASE (mode,Nx_list,nx_fixed,...),use them.
%   (B) Else,load simulation_parameters.mat (absolute search).
%   (C) Else,defaults.

% ---- Detect if launched from choose_parameters (base workspace vars) ----
baseHasMode = false;
try
    baseHasMode = evalin('base','exist(''mode'',''var'')==1');
catch
    baseHasMode = false;
end

if baseHasMode
    % --- Use BASE variables (GUI priority) ---
    mode = evalin('base','mode');

    if evalin('base','exist(''Nx_list'',''var'')==1'),Nx_list  = evalin('base','Nx_list');  else,Nx_list  = []; end
    if evalin('base','exist(''nx_fixed'',''var'')==1'), nx_fixed = evalin('base','nx_fixed'); else,nx_fixed = []; end
    if evalin('base','exist(''L_vec'',''var'')==1'),L_vec    = evalin('base','L_vec');    else,L_vec    = []; end
    if evalin('base','exist(''t_final'',''var'')==1'),t_final  = evalin('base','t_final');  else,t_final  = []; end
    if evalin('base','exist(''dt_spatial'',''var'')==1'),dt_spatial = evalin('base','dt_spatial'); else,dt_spatial = []; end

    % If some fields missing in base,we will try file,else defaults later
    fprintf('\n Using parameters from BASE workspace (GUI priority)\n');
    fprintf('Mode: %s\n',get_mode_name(mode));

else
    % --- Try load file (absolute search) ---
    paramCandidates = {
        fullfile('results','simulation_parameters.mat')  % Search in results/ first
        fullfile(root,'results','simulation_parameters.mat')
        fullfile(root,'simulation_parameters.mat')
        fullfile(baseDir,'simulation_parameters.mat')
        'simulation_parameters.mat'
    };

    paramFile = '';
    for kk = 1:numel(paramCandidates)
        if exist(paramCandidates{kk},'file') == 2
            paramFile = paramCandidates{kk};
            break;
        end
    end

    if ~isempty(paramFile)
        load(paramFile,'params');
        fprintf('\n Loaded interactive parameters from: %s\n',paramFile);
        fprintf('Mode: %s\n',get_mode_name(params.mode));

        mode     = params.mode;
        Nx_list  = params.Nx_list;
        nx_fixed = params.nx_fixed;
        L_vec    = params.L_vec;
        t_final  = params.t_final;
        dt_spatial = params.dt_spatial;

    else
        fprintf('\n No interactive parameters found. Using defaults.\n');
        fprintf('Run choose_parameters.m first for interactive selection.\n');

        mode     = 3;
        Nx_list  = [17 33 65 129];  % Increased to see more values
        nx_fixed = 17;
        L_vec    = [0.15 0.25 0.65 1];
        t_final  = 0.5;
        dt_spatial = 0.025;
    end
end

% ---- Fill missing values if GUI provided partial vars ----
if ~exist('mode','var') || isempty(mode),mode = 3; end

if (mode == 1 || mode == 3) && (~exist('Nx_list','var') || isempty(Nx_list))
    Nx_list = [17 33 65 129];
end
if (mode == 2 || mode == 3) && (~exist('nx_fixed','var') || isempty(nx_fixed))
    nx_fixed = 17;
end
if ~exist('L_vec','var') || isempty(L_vec)
    L_vec = [0.15 0.25 0.65 1];
end
if ~exist('t_final','var') || isempty(t_final)
    t_final = 0.5;
end
if ~exist('dt_spatial','var') || isempty(dt_spatial)
    dt_spatial = 0.025;
end

% Force L_vec to be a row vector for proper display
L_vec = L_vec(:)';

% Print final resolved parameters
fprintf('\n================ SELECTED PARAMETERS ================\n');
fprintf('Mode              : %s\n',get_mode_name(mode));
if mode == 1 || mode == 3,
    fprintf('Nx list (spatial)  : %s\n',mat2str(Nx_list)); 
    fprintf('Number of Nx values: %d\n',length(Nx_list));
    fprintf('dt_spatial         : %.6f\n',dt_spatial);
end
if mode == 2 || mode == 3,
    fprintf('Nx (temporal)      : %d\n',nx_fixed); 
end
fprintf('L values           : %s\n',mat2str(L_vec));
fprintf('Number of L values : %d\n',length(L_vec));
fprintf('t_final            : %.6g\n',t_final);
fprintf('=====================================================\n\n');

% ===================== GLOBAL PARAMETERS =================================
eps1    = 1e-8;
s       = 5;            % number of dt levels
ellList = 1:s;          % list of ell for variable dt
ell0    = 3;            % parameter for solver

% --- Snapshot saving ---
save_interval = 0.2;

% ===================== BASE OUTPUT DIRECTORIES ===========================
scheme_name   = 'L-scheme';
results_base  = 'results';

% =======================================================================
% PART 1 : SPATIAL STUDY (loop over L and mesh sizes)
% =======================================================================
if mode == 1 || mode == 3
    fprintf('\n');
    fprintf('====================================================================\n');
    fprintf('PART 1 : SPATIAL STUDY (mesh refinement)\n');
    fprintf('====================================================================\n');
    fprintf('Number of L values to process: %d\n',length(L_vec));
    fprintf('Number of Nx values to process: %d\n',length(Nx_list));

    for iL = 1:numel(L_vec)

        L = L_vec(iL);

        fprintf('\n=====================================================\n');
        fprintf('SPATIAL STUDY | L=%.6g (%d/%d)\n',L,iL,numel(L_vec));
        fprintf('=====================================================\n');

        % OUTPUT DIRECTORIES for spatial study
        study_type   = 'spatial';
        results_root = fullfile(results_base,case_type,scheme_name,...
                                sprintf('L=%.6g',L),study_type);
        results_dir   = fullfile(results_root,'resultats_complets');
        solutions_dir = fullfile(results_root,'solutions_temporelles');

        if ~exist(results_dir,'dir');     mkdir(results_dir);     end
        if ~exist(solutions_dir,'dir');   mkdir(solutions_dir);   end

        fprintf('Folders:\n');
        fprintf(' -%s\n',results_root);

        % RESULT ARRAYS for this L value
        nH = length(Nx_list);

        Erreur_L1   = zeros(nH,1);
        Erreur_L2   = zeros(nH,1);
        Erreur_Linf = zeros(nH,1);
        Erreur_H1   = zeros(nH,1);

        Newton_last = zeros(nH,1);
        Newton_avg  = zeros(nH,1);
        CPU_times   = zeros(nH,1);

        Cond_max            = NaN(nH,1);
        Cond_moyen          = NaN(nH,1);
        Iter_problematiques = zeros(nH,1);

        dt_used  = zeros(nH,1);
        h_values = zeros(nH,1);

        visualization_data = struct();

        % Fixed time step for spatial study-use interface value
        fprintf('\n--- Temporal parameter for spatial study ---\n');
        if exist('dt_spatial','var') && ~isempty(dt_spatial)
            dt_fixed = dt_spatial;
            fprintf('    Using dt_spatial from interface: %.6f\n',dt_fixed);
        else
            % Fallback if interface did not provide value
            dt_fixed = 0.025;  % default value
            fprintf('   Using default dt_fixed: %.6f\n',dt_fixed);
        end

        % LOOP OVER MESH SIZES
        for i = 1:nH
            tic;

            nx = Nx_list(i);
            h  = 1/(nx-1);
            h_values(i) = h;

            % Adjust time step
            dt = dt_fixed;
            N  = ceil(t_final/dt);
            dt_used(i) = dt;

            fprintf('\n--- Simulation %d/%d: nx=%d,h=%.6f,dt=%.6f ---\n',...
                    i,nH,nx,h,dt);

            % 2D MESH GENERATION
            [ibcd,p,t,np] = kpde2dumsh(0,1,0,1,nx,nx);
            x = p(:,1); z = p(:,2);

            nodes  = (1:np)';
            inodes = setdiff(nodes,ibcd);

            % INITIALIZATION
            tm = 0;
            k  = 0;
            ht = dt;

            u0 = uex(x,z,0);
            up = u0;

            iter_total = 0;
            nsteps     = 0;

            kappa_history_sim = [];

            % SNAPSHOTS
            it_save          = 1;
            ut_partial       = u0;
            t_saved_partial  = 0;

            solution_file = sprintf('solution_nx%d_t%.3fs.mat',nx,0);
            save(fullfile(solutions_dir,solution_file),...
                 'p','t','u0','tm','nx','L','dt','t_final');

            next_save_time = save_interval;

            % TIME LOOP
            while (tm < t_final)
                k  = k+1;
                tm = k*ht;

                if tm > t_final
                    tm = t_final;
                end

                % Solver call-uses ell0 for L-scheme solver
                try
                    [u,n_iter,kappa_hist_step] = solveNonLinearLscheme( ...
                        ell0,L,p,t,dt,ibcd,inodes,eps1,tm,up);
                    if ~isempty(kappa_hist_step)
                        kappa_history_sim = [kappa_history_sim; kappa_hist_step]; 
                    end
                catch
                    [u,n_iter] = solveNonLinearLscheme( ...
                        ell0,L,p,t,dt,ibcd,inodes,eps1,tm,up);
                end

                up = u;
                iter_total = iter_total+n_iter;
                nsteps     = nsteps+1;

                % Snapshots
                if tm >= next_save_time
                    it_save = it_save+1;
                    ut_partial(:,it_save) = u;
                    t_saved_partial(it_save,1) = tm;

                    solution_file = sprintf('solution_nx%d_t%.3fs.mat',nx,tm);
                    save(fullfile(solutions_dir,solution_file),...
                         'p','t','u','tm','nx','L','dt','t_final');

                    next_save_time = next_save_time+save_interval;
                end

                if k >= N
                    break;
                end
            end

            % DIAGNOSTICS
            if ~isempty(kappa_history_sim)
                Cond_max(i)   = max(kappa_history_sim);
                Cond_moyen(i) = mean(kappa_history_sim);
                Iter_problematiques(i) = sum(kappa_history_sim > 1e10);
            end

            % ERROR COMPUTATION
            [eL2,eH1] = kpde2derr(p,t,u,t_final);
            [eL1,eLinf] = kpde2derrL1Linfty(p,t,u,tm);

            Erreur_L1(i)   = eL1;
            Erreur_L2(i)   = eL2;
            Erreur_Linf(i) = eLinf;
            Erreur_H1(i)   = eH1;

            Newton_last(i) = n_iter;
            Newton_avg(i)  = iter_total/max(1,nsteps);

            CPU_times(i) = toc;

            % DISPLAY
            fprintf('  L1=%.3e | L2=%.3e | Linf=%.3e | H1=%.3e | It(last)=%d | CPU=%.2fs\n',...
                    eL1,eL2,eLinf,eH1,n_iter,CPU_times(i));

            % STORE VIZ DATA
            visualization_data(i).p               = p;
            visualization_data(i).t               = t;
            visualization_data(i).u               = u;
            visualization_data(i).nx              = nx;
            visualization_data(i).h               = h;
            visualization_data(i).dt              = dt;
            visualization_data(i).t_final         = tm;
            visualization_data(i).ut_partial      = ut_partial;
            visualization_data(i).t_saved_partial = t_saved_partial;

            % COLLECT DATA FOR GRAPHS (SPATIAL)
            try
                % Create subfolder for convergence data
                conv_data_dir = fullfile(results_root,'convergence_data');
                if ~exist(conv_data_dir,'dir')
                    mkdir(conv_data_dir);
                end

                % Save in subfolder
                conv_file = fullfile(conv_data_dir,'convergence_data_spatial.mat');

                if exist(conv_file,'file')
                    load(conv_file,'conv_data');
                else
                    conv_data = struct('Nx',[],'iterations',[],'cpu_time',[],'conditioning',[]);
                end

                conv_data.Nx(end+1) = nx;
                conv_data.iterations(end+1) = iter_total;
                conv_data.cpu_time(end+1) = CPU_times(i);
                if ~isempty(kappa_history_sim)
                    conv_data.conditioning(end+1) = max(kappa_history_sim);
                else
                    conv_data.conditioning(end+1) = NaN;
                end

                save(conv_file,'conv_data');
                fprintf('   Convergence data saved (%d points)\n',length(conv_data.Nx));

            catch ME
                fprintf('  Error collecting spatial data: %s\n',ME.message);
            end
        end

        % SPATIAL CONVERGENCE ORDERS
        if nH >= 2
            ordre_L1   = diff(log(Erreur_L1))./diff(log(h_values));
            ordre_L2   = diff(log(Erreur_L2))./diff(log(h_values));
            ordre_Linf = diff(log(Erreur_Linf))./diff(log(h_values));
            ordre_H1   = diff(log(Erreur_H1))./diff(log(h_values));
        else
            ordre_L1 = []; ordre_L2 = []; ordre_Linf = []; ordre_H1 = [];
        end

        % .MAT SAVE
        data_file = fullfile(results_dir,'resultats_spatiaux.mat');
        save(data_file,...
            'Erreur_L1','Erreur_L2','Erreur_Linf','Erreur_H1',...
            'Newton_last','Newton_avg','CPU_times',...
            'Cond_max','Cond_moyen','Iter_problematiques',...
            'dt_used','dt_fixed','Nx_list','h_values',...
            't_final','L','eps1','save_interval',...
            'ordre_L1','ordre_L2','ordre_Linf','ordre_H1',...
            'visualization_data');

        fprintf('\n Spatial data saved: %s\n',data_file);

        % TEXT SUMMARY
        summary_file = fullfile(results_dir,'resume_spatial.txt');
        fid = fopen(summary_file,'w');

        fprintf(fid,'SPATIAL STUDY SUMMARY-L=%.6g\n',L);
        fprintf(fid,'Date: %s\n',datestr(now));
        fprintf(fid,'dt_fixed=%.6e | t_final=%.6f | eps1=%.1e\n\n',...
            dt_fixed,t_final,eps1);

        fprintf(fid,['========================================================================\n' ...
                      'h       nx    dt        L1          L2          Linf        H1          \n' ...
                      '========================================================================\n']);

        for i = 1:nH
            fprintf(fid,'%.3e  %-4d  %.6f  %-12.3e %-12.3e %-12.3e %-12.3e\n',...
                h_values(i),Nx_list(i),dt_used(i),...
                Erreur_L1(i),Erreur_L2(i),Erreur_Linf(i),Erreur_H1(i));
        end

        if ~isempty(ordre_L1)
            fprintf(fid,'\n=== ESTIMATED CONVERGENCE ORDERS (in h) ===\n');
            for i = 1:length(ordre_L1)
                fprintf(fid,'%d → %d : L1=%.4f | L2=%.4f | Linf=%.4f | H1=%.4f\n',...
                    Nx_list(i),Nx_list(i+1),ordre_L1(i),ordre_L2(i),ordre_Linf(i),ordre_H1(i));
            end
        end

        fclose(fid);
        fprintf(' Summary saved: %s\n',summary_file);

    end % end loop over L for spatial study
end

% =======================================================================
% PART 2 : TEMPORAL STUDY (time step refinement)
% =======================================================================
if mode == 2 || mode == 3
    fprintf('\n');
    fprintf('====================================================================\n');
    fprintf('PART 2 : TEMPORAL STUDY (time step refinement)\n');
    fprintf('====================================================================\n');
    fprintf('Number of L values to process: %d\n',length(L_vec));

    for iL = 1:numel(L_vec)
        L  = L_vec(iL);
        nT = length(ellList);

        fprintf('\n=====================================================\n');
        fprintf('TEMPORAL STUDY | L=%.6g (%d/%d) | nx=%d\n',L,iL,numel(L_vec),nx_fixed);
        fprintf('=====================================================\n');

        % OUTPUT DIRECTORIES for temporal study
        study_type   = 'temporel';
        results_root = fullfile(results_base,case_type,scheme_name,...
                                sprintf('L=%.6g',L),study_type);
        results_dir   = fullfile(results_root,'resultats_complets');
        solutions_dir = fullfile(results_root,'solutions_temporelles');

        if ~exist(results_dir,'dir');     mkdir(results_dir);     end
        if ~exist(solutions_dir,'dir');   mkdir(solutions_dir);   end

        fprintf('Folders:\n');
        fprintf(' -%s\n',results_root);

        % RESULT ARRAYS for temporal study
        Erreur_L1   = zeros(nT,1);
        Erreur_L2   = zeros(nT,1);
        Erreur_Linf = zeros(nT,1);
        Erreur_H1   = zeros(nT,1);
        CPU_times   = zeros(nT,1);
        Newton_last = zeros(nT,1);
        Newton_avg  = zeros(nT,1);
        dt_values   = zeros(nT,1);

        Cond_max            = NaN(nT,1);
        Cond_moyen          = NaN(nT,1);
        Iter_problematiques = zeros(nT,1);

        visualization_data = struct();

        % FIXED MESH
        [ibcd,p,t,np] = kpde2dumsh(0,1,0,1,nx_fixed,nx_fixed);
        x = p(:,1); z = p(:,2);

        nodes  = (1:np)';
        inodes = setdiff(nodes,ibcd);

        fprintf('np=%d | interior unknowns=%d\n',np,length(inodes));

        % LOOP OVER TIME STEPS
        for kdt = 1:nT
            ell = ellList(kdt);
            dt  = 0.1*2^(1-ell);
            dt_values(kdt) = dt;

            fprintf('\n--- Simulation %d/%d: ell=%d,dt=%.3e ---\n',kdt,nT,ell,dt);

            % INITIALIZATION
            tm = 0;
            k  = 0;
            ht = dt;

            u0 = uex(x,z,0);
            up = u0;

            N  = ceil(t_final/dt);
            dt = t_final/N;       % adjustment
            dt_values(kdt) = dt;

            iter_total = 0;
            nsteps     = 0;

            kappa_history_sim = [];

            % SNAPSHOTS
            it_save         = 1;
            ut_partial      = u0;
            t_saved_partial = 0;

            solution_file = sprintf('solution_ell%d_t%.3fs.mat',ell,0);
            save(fullfile(solutions_dir,solution_file),...
                 'p','t','u0','tm','nx_fixed','ell','L','dt','t_final');

            next_save_time = save_interval;

            tic;

            % TIME LOOP
            while (tm < t_final)
                k  = k+1;
                tm = k*ht;

                if tm > t_final
                    tm = t_final;
                end

                % Solver call
                try
                    [u,n_iter,kappa_hist_step] = solveNonLinearLscheme( ...
                        ell0,L,p,t,dt,ibcd,inodes,eps1,tm,up);
                    if ~isempty(kappa_hist_step)
                        kappa_history_sim = [kappa_history_sim; kappa_hist_step]; 
                    end
                catch
                    [u,n_iter] = solveNonLinearLscheme( ...
                        ell0,L,p,t,dt,ibcd,inodes,eps1,tm,up);
                end

                up = u;
                iter_total = iter_total+n_iter;
                nsteps     = nsteps+1;

                % Snapshots
                if tm >= next_save_time
                    it_save = it_save+1;
                    ut_partial(:,it_save) = u;
                    t_saved_partial(it_save,1) = tm;

                    solution_file = sprintf('solution_ell%d_t%.3fs.mat',ell,tm);
                    save(fullfile(solutions_dir,solution_file),...
                         'p','t','u','tm','nx_fixed','ell','L','dt','t_final');

                    next_save_time = next_save_time+save_interval;
                end

                if k >= N
                    break;
                end
            end

            CPU_times(kdt) = toc;

            % DIAGNOSTICS
            if ~isempty(kappa_history_sim)
                Cond_max(kdt)   = max(kappa_history_sim);
                Cond_moyen(kdt) = mean(kappa_history_sim);
                Iter_problematiques(kdt) = sum(kappa_history_sim > 1e10);
            end

            % ERROR COMPUTATION
            [eL2,eH1] = kpde2derr(p,t,u,t_final);
            [eL1,eLinf] = kpde2derrL1Linfty(p,t,u,tm);

            Erreur_L1(kdt)   = eL1;
            Erreur_L2(kdt)   = eL2;
            Erreur_Linf(kdt) = eLinf;
            Erreur_H1(kdt)   = eH1;

            Newton_last(kdt) = n_iter;
            Newton_avg(kdt)  = iter_total/max(1,nsteps);

            % DISPLAY
            fprintf('  dt=%.2e | L1=%.3e | L2=%.3e | Linf=%.3e | H1=%.3e | It(last)=%d | CPU=%.2fs\n',...
                    dt,eL1,eL2,eLinf,eH1,n_iter,CPU_times(kdt));

            % STORE VIZ DATA
            visualization_data(kdt).p               = p;
            visualization_data(kdt).t               = t;
            visualization_data(kdt).u               = u;
            visualization_data(kdt).nx              = nx_fixed;
            visualization_data(kdt).t_final         = tm;
            visualization_data(kdt).ell             = ell;
            visualization_data(kdt).dt              = dt;
            visualization_data(kdt).ut_partial      = ut_partial;
            visualization_data(kdt).t_saved_partial = t_saved_partial;

            % COLLECT DATA FOR GRAPHS (TEMPORAL)
            try
                % Create subfolder for convergence data
                conv_data_dir = fullfile(results_root,'convergence_data');
                if ~exist(conv_data_dir,'dir')
                    mkdir(conv_data_dir);
                end

                % Save in subfolder
                conv_file = fullfile(conv_data_dir,'convergence_data_temporal.mat');

                if exist(conv_file,'file')
                    load(conv_file,'conv_data');
                else
                    conv_data = struct('dt',[],'iterations',[],'cpu_time',[],'conditioning',[]);
                end

                conv_data.dt(end+1) = dt;
                conv_data.iterations(end+1) = iter_total;
                conv_data.cpu_time(end+1) = CPU_times(kdt);
                if ~isempty(kappa_history_sim)
                    conv_data.conditioning(end+1) = max(kappa_history_sim);
                else
                    conv_data.conditioning(end+1) = NaN;
                end

                save(conv_file,'conv_data');
                fprintf('   Temporal convergence data saved (%d points)\n',length(conv_data.dt));

            catch ME
                fprintf('  Error collecting temporal data: %s\n',ME.message);
            end
        end

        % TEMPORAL CONVERGENCE ORDERS
        if nT >= 2
            Ordre_L1   = [NaN; diff(log(Erreur_L1))./diff(log(dt_values))];
            Ordre_L2   = [NaN; diff(log(Erreur_L2))./diff(log(dt_values))];
            Ordre_Linf = [NaN; diff(log(Erreur_Linf))./diff(log(dt_values))];
            Ordre_H1   = [NaN; diff(log(Erreur_H1))./diff(log(dt_values))];
        else
            Ordre_L1 = NaN(nT,1); Ordre_L2 = NaN(nT,1); 
            Ordre_Linf = NaN(nT,1); Ordre_H1 = NaN(nT,1);
        end

        % .MAT SAVE for temporal study
        data_file = fullfile(results_dir,'resultats_temporels.mat');
        save(data_file,...
            'Erreur_L1','Erreur_L2','Erreur_Linf','Erreur_H1',...
            'CPU_times','Newton_last','Newton_avg','dt_values',...
            'Ordre_L1','Ordre_L2','Ordre_Linf','Ordre_H1',...
            'Cond_max','Cond_moyen','Iter_problematiques',...
            'nx_fixed','ellList','L','eps1','t_final','save_interval',...
            'visualization_data');

        fprintf('\n Temporal data saved: %s\n',data_file);

        % TEXT SUMMARY for temporal study
        summary_file = fullfile(results_dir,'resume_temporel.txt');
        fid = fopen(summary_file,'w');

        fprintf(fid,'TEMPORAL STUDY SUMMARY-L=%.6g | nx=%d\n',L,nx_fixed);
        fprintf(fid,'Date: %s\n',datestr(now));
        fprintf(fid,'t_final=%.6f | eps1=%.1e | save_interval=%.3f\n\n',...
            t_final,eps1,save_interval);

        fprintf(fid,['=====================================================================================\n' ...
                      'dt        L1          Ord      L2          Ord      Linf        Ord      H1          Ord\n' ...
                      '=====================================================================================\n']);

        for i = 1:nT
            fprintf(fid,'%.2e  %.3e  %s  %.3e  %s  %.3e  %s  %.3e  %s\n',...
                dt_values(i),...
                Erreur_L1(i),dispOrd(Ordre_L1(i)),...
                Erreur_L2(i),dispOrd(Ordre_L2(i)),...
                Erreur_Linf(i),dispOrd(Ordre_Linf(i)),...
                Erreur_H1(i),dispOrd(Ordre_H1(i)));
        end

        fprintf(fid,'\nConditioning (if available):\n');
        fprintf(fid,'dt        Cond_max     Cond_moy    Iter_prob(>1e10)\n');
        for i = 1:nT
            fprintf(fid,'%.2e  %.3e  %.3e  %d\n',dt_values(i),Cond_max(i),Cond_moyen(i),Iter_problematiques(i));
        end

        fclose(fid);
        fprintf(' Summary saved: %s\n',summary_file);
    end
end

fprintf('\n');
fprintf('====================================================================\n');
fprintf('COMPLETE STUDY FINISHED\n');
fprintf('====================================================================\n');
fprintf('Results available in:\n');
fprintf(' -%s\n',fullfile(results_base,case_type,scheme_name));

% =======================================================================
% FUNCTIONS FOR REFRESHING PLOTS
% =======================================================================
function refresh_plots_spatial(handles)
%REFRESH_PLOTS_SPATIAL Update spatial convergence plots with latest data
%   Searches for convergence_data_spatial.mat files and updates
%   the provided axes handles with iteration,CPU time,and conditioning plots.
%
%   INPUT:
%       handles : structure containing axes handles (ax1,ax2,ax3)

    try
        if ~isstruct(handles) || ~isfield(handles,'ax1') || ~isfield(handles,'ax2') || ~isfield(handles,'ax3')
            return;
        end

        ax1 = handles.ax1; ax2 = handles.ax2; ax3 = handles.ax3;

        % Search for files in all results folders
        found = false;
        conv_data = [];

        % Recursive search in results/
        files = dir('results/**/convergence_data_spatial.mat');
        if ~isempty(files)
            % Take the most recent
            [~,idx] = max([files.datenum]);
            load(fullfile(files(idx).folder,files(idx).name),'conv_data');
            found = true;
        end

        if ~ishandle(ax1) || ~ishandle(ax2) || ~ishandle(ax3),return; end

        cla(ax1); cla(ax2); cla(ax3);

        title(ax1,'Iterations vs Mesh (Spatial)');
        title(ax2,'CPU Time vs Mesh (Spatial)');
        title(ax3,'Conditioning vs Mesh (Spatial)');

        if found && ~isempty(conv_data) && isfield(conv_data,'Nx') && ~isempty(conv_data.Nx)

            [Nx_sorted,idx] = sort(conv_data.Nx);

            if isfield(conv_data,'iterations') && ~isempty(conv_data.iterations)
                plot(ax1,Nx_sorted,conv_data.iterations(idx),'b-o','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','b');
                xlabel(ax1,'Nx (mesh points)'); ylabel(ax1,'Number of iterations'); grid(ax1,'on');
            end

            if isfield(conv_data,'cpu_time') && ~isempty(conv_data.cpu_time)
                plot(ax2,Nx_sorted,conv_data.cpu_time(idx),'r-s','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','r');
                xlabel(ax2,'Nx (mesh points)'); ylabel(ax2,'CPU Time (s)'); grid(ax2,'on');
            end

            if isfield(conv_data,'conditioning') && ~isempty(conv_data.conditioning)
                plot(ax3,Nx_sorted,conv_data.conditioning(idx),'g-d','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','g');
                xlabel(ax3,'Nx (mesh points)'); ylabel(ax3,'Conditioning'); grid(ax3,'on');
            end

            drawnow;
        else
            text(ax1,0.5,0.5,'No spatial data available','HorizontalAlignment','center','FontSize',12,'Parent',ax1);
            text(ax2,0.5,0.5,'No spatial data available','HorizontalAlignment','center','FontSize',12,'Parent',ax2);
            text(ax3,0.5,0.5,'No spatial data available','HorizontalAlignment','center','FontSize',12,'Parent',ax3);
        end
    catch ME
        fprintf('Error in refresh_plots_spatial: %s\n',ME.message);
    end
end

function refresh_plots_temporal(handles)
%REFRESH_PLOTS_TEMPORAL Update temporal convergence plots with latest data
%   Searches for convergence_data_temporal.mat files and updates
%   the provided axes handles with iteration,CPU time,and conditioning plots.
%
%   INPUT:
%       handles : structure containing axes handles (ax1,ax2,ax3)

    try
        if ~isstruct(handles) || ~isfield(handles,'ax1') || ~isfield(handles,'ax2') || ~isfield(handles,'ax3')
            return;
        end

        ax1 = handles.ax1; ax2 = handles.ax2; ax3 = handles.ax3;

        % Search for files in all results folders
        found = false;
        conv_data = [];

        % Recursive search in results/
        files = dir('results/**/convergence_data_temporal.mat');
        if ~isempty(files)
            % Take the most recent
            [~,idx] = max([files.datenum]);
            load(fullfile(files(idx).folder,files(idx).name),'conv_data');
            found = true;
        end

        if ~ishandle(ax1) || ~ishandle(ax2) || ~ishandle(ax3),return; end

        cla(ax1); cla(ax2); cla(ax3);

        title(ax1,'Iterations vs dt (Temporal)');
        title(ax2,'CPU Time vs dt (Temporal)');
        title(ax3,'Conditioning vs dt (Temporal)');

        if found && ~isempty(conv_data) && isfield(conv_data,'dt') && ~isempty(conv_data.dt)

            [dt_sorted,idx] = sort(conv_data.dt);

            if isfield(conv_data,'iterations') && ~isempty(conv_data.iterations)
                plot(ax1,dt_sorted,conv_data.iterations(idx),'b-o','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','b');
                xlabel(ax1,'dt (time step)'); ylabel(ax1,'Number of iterations');
                set(ax1,'XScale','log'); grid(ax1,'on');
            end

            if isfield(conv_data,'cpu_time') && ~isempty(conv_data.cpu_time)
                plot(ax2,dt_sorted,conv_data.cpu_time(idx),'r-s','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','r');
                xlabel(ax2,'dt (time step)'); ylabel(ax2,'CPU Time (s)');
                set(ax2,'XScale','log'); grid(ax2,'on');
            end

            if isfield(conv_data,'conditioning') && ~isempty(conv_data.conditioning)
                plot(ax3,dt_sorted,conv_data.conditioning(idx),'g-d','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','g');
                xlabel(ax3,'dt (time step)'); ylabel(ax3,'Conditioning');
                set(ax3,'XScale','log'); grid(ax3,'on');
            end

            drawnow;
        else
            text(ax1,0.5,0.5,'No temporal data available','HorizontalAlignment','center','FontSize',12,'Parent',ax1);
            text(ax2,0.5,0.5,'No temporal data available','HorizontalAlignment','center','FontSize',12,'Parent',ax2);
            text(ax3,0.5,0.5,'No temporal data available','HorizontalAlignment','center','FontSize',12,'Parent',ax3);
        end
    catch ME
        fprintf('Error in refresh_plots_temporal: %s\n',ME.message);
    end
end

% =======================================================================
% UTILITY FUNCTIONS
% =======================================================================
function s = dispOrd(val)
%DISPORD Format convergence order for display
%   Returns '-' for NaN,otherwise formatted number with 2 decimals.
%
%   INPUT:
%       val : double, convergence order value (may be NaN)
%
%   OUTPUT:
%       s : string, formatted order or '-'

    if isnan(val),s = '-'; else,s = sprintf('%.2f',val); end
end

function name = get_mode_name(val)
%GET_MODE_NAME Convert mode number to descriptive string
%
%   INPUT:
%       val : integer, mode number (1,2,3)
%
%   OUTPUT:
%       name : string, description of the mode

    switch val
        case 1,name = 'Spatial only';
        case 2,name = 'Temporal only';
        case 3,name = 'Both studies';
        otherwise,name = 'Unknown';
    end
end









% % clear; clc;
% % %==========================================================================
% % % MAIN_2D_NUMERICAL_VALIDATION-Main driver for 2D Richards L-scheme
% % %                                 numerical validation studies
% % %
% % % This script performs systematic numerical validation of the L-scheme
% % % for Richards equation in 2D. It handles both spatial (mesh refinement)
% % % and temporal (time step refinement) convergence studies.
% % %
% % % KEY FEATURES:
% % %  -Automatic path management for src2D directory structure
% % %  -Support for both deformable and non-deformable Vertisol models
% % %  -Interactive parameter loading from GUI (choose_parameters.m)
% % %  -Automatic fallback to default parameters if GUI not used
% % %  -Comprehensive error computation (L1,L2,Linf,H1 norms)
% % %  -Automatic convergence order calculation
% % %  -Organized output structure:
% % %       results/numerical_validation/L-scheme/L=<val>/spatial|temporel/
% % %           resultats_complets/     -MAT files with all results
% % %           solutions_temporelles/  -Solution snapshots over time
% % %           convergence_data/       -Iteration/CPU/conditioning data
% % %  -Detailed text summaries with convergence tables
% % %  -Real-time progress monitoring in console
% % %
% % % STUDY MODES:
% % %   Mode 1: Spatial only  -Mesh refinement with fixed time step
% % %   Mode 2: Temporal only -Time step refinement with fixed mesh
% % %   Mode 3: Both studies  -Runs both spatial and temporal studies
% % %
% % % PARAMETER SOURCES (priority order):
% % %   1. Base workspace (from choose_parameters GUI)
% % %   2. simulation_parameters.mat file
% % %   3. Default values (for standalone execution)
% % %
% % % DEPENDENCIES:
% % %   Requires proper directory structure:
% % %   src2D/
% % %       FEM2D/         -Finite element core functions
% % %       models2D/      -Physical models (vertisol,van Genuchten)
% % %           vertisol/  -Vertisol model variants
% % %           van/       -Van Genuchten model
% % %           coefficients_matrix/-Material coefficients
% % %       utils2D/       -Utility functions
% % %       solvers2D/     -Nonlinear solvers
% % %           numerical_validation/-L-scheme solver for validation
% % %   examples2D/        -Example files (uex.m,etc.)
% % %
% % % AUTHOR: [Your Name]
% % % DATE:   [Current Date]
% % %==========================================================================
% % 
% % % ===================== Project paths setup ==============================
% % % Locate the project root directory by climbing up from this file's location
% % % until finding main.m or the src2D directory
% % baseDir = fileparts(mfilename('fullpath'));
% % root    = baseDir;
% % 
% % maxUp = 10;
% % for k = 1:maxUp
% %     if exist(fullfile(root,'main.m'),'file') || ...
% %        isfolder(fullfile(root,'src2D'))      || ...
% %        isfolder(fullfile(root,'models2D'))    % Kept for backward compatibility
% %         break;
% %     end
% %     parent = fileparts(root);
% %     if strcmp(parent,root)
% %         error('Project root not found when climbing up from: %s',baseDir);
% %     end
% %     root = parent;
% % end
% % 
% % % ===================== Core folders in src2D ============================
% % src2DDir = fullfile(root,'src2D');
% % assert(isfolder(src2DDir),'Missing folder: %s',src2DDir);
% % 
% % % All core directories are now inside src2D
% % FEM2DDir      = fullfile(src2DDir,'FEM2D');
% % models2DDir   = fullfile(src2DDir,'models2D');
% % utils2DDir    = fullfile(src2DDir,'utils2D');
% % solvers2DDir  = fullfile(src2DDir,'solvers2D');
% % examples2DDir = fullfile(root,'examples2D');  % examples2D remains at root
% % 
% % assert(isfolder(FEM2DDir),'Missing folder: %s',FEM2DDir);
% % assert(isfolder(models2DDir),'Missing folder: %s',models2DDir);
% % assert(isfolder(utils2DDir),'Missing folder: %s',utils2DDir);
% % assert(isfolder(solvers2DDir),'Missing folder: %s',solvers2DDir);
% % assert(isfolder(examples2DDir),'Missing folder: %s',examples2DDir);
% % 
% % % ===================== Mode ===================================
% % case_type     = 'numerical_validation';  % Only numerical validation
% % vertisol_mode = 'deformable';            % 'deformable' or 'non_deformable'
% % 
% % % ===================== models2D folders ===================================
% % vertisolBaseDir = fullfile(models2DDir,'vertisol');
% % vanBaseDir      = fullfile(models2DDir,'van');
% % coeffDir        = fullfile(models2DDir,'coefficients_matrix');
% % 
% % % ---- Paths for numerical_validation ----
% % vertisolCaseDir = fullfile(vertisolBaseDir,'numerical_validation');
% % vanCaseDir      = fullfile(vanBaseDir,'numerical_validation');
% % 
% % % ---- Vertisol mode selection ----
% % switch vertisol_mode
% %     case 'deformable'
% %         activeVertisolDir = fullfile(vertisolCaseDir,'deformable');
% %     case 'non_deformable'
% %         activeVertisolDir = fullfile(vertisolCaseDir,'non_deformable');
% %     otherwise
% %         error('Invalid vertisol_mode. Choose "deformable" or "non_deformable".');
% % end
% % 
% % % ---- Safety checks ----
% % assert(isfolder(vertisolCaseDir),'Missing folder: %s',vertisolCaseDir);
% % assert(isfolder(activeVertisolDir),'Missing folder: %s',activeVertisolDir);
% % assert(isfolder(vanCaseDir),'Missing folder: %s',vanCaseDir);
% % assert(isfolder(coeffDir),'Missing folder: %s',coeffDir);
% % 
% % % ===================== Add stable paths =================================
% % addpath(FEM2DDir,'-begin');
% % addpath(coeffDir,'-begin');
% % 
% % % ===================== solvers2D: numerical_validation ====================
% % solvers2DValDir = fullfile(solvers2DDir,'numerical_validation');
% % assert(isfolder(solvers2DValDir),'Missing folder: %s',solvers2DValDir);
% % 
% % % Remove all solver subfolders,then add only numerical_validation
% % warning('off','MATLAB:rmpath:DirNotFound');
% % rmpath(fullfile(solvers2DDir,'physical_case'));
% % warning('on','MATLAB:rmpath:DirNotFound');
% % 
% % addpath(solvers2DValDir,'-begin');
% % activesolvers2DDir = solvers2DValDir;
% % 
% % addpath(examples2DDir,'-begin');
% % addpath(genpath(utils2DDir),'-begin');  % utils2D+subfolders
% % 
% % % ===================== CLEAN ALL model paths =============================
% % % Remove all possible Vertisol and Van Genuchten paths to avoid conflicts
% % allVertisolDirs = {
% %     fullfile(vertisolBaseDir,'numerical_validation','deformable')
% %     fullfile(vertisolBaseDir,'numerical_validation','non_deformable')
% %     fullfile(vertisolBaseDir,'physical_case','deformable')
% %     fullfile(vertisolBaseDir,'physical_case','non_deformable')
% % };
% % 
% % allVanDirs = {
% %     fullfile(vanBaseDir,'numerical_validation')
% %     fullfile(vanBaseDir,'physical_case')
% % };
% % 
% % warning('off','MATLAB:rmpath:DirNotFound');
% % for ii = 1:numel(allVertisolDirs),rmpath(allVertisolDirs{ii}); end
% % for ii = 1:numel(allVanDirs),rmpath(allVanDirs{ii}); end
% % warning('on','MATLAB:rmpath:DirNotFound');
% % 
% % % ===================== Add ONLY selected folders =========================
% % addpath(vanCaseDir,'-begin');
% % addpath(activeVertisolDir,'-begin');
% % 
% % rehash path;
% % 
% % % ===================== Diagnostics ======================================
% % fprintf('\n================ ACTIVE CONFIGURATION ================\n');
% % fprintf('Case type         : %s\n',case_type);
% % fprintf('Vertisol mode     : %s\n',vertisol_mode);
% % fprintf('Vertisol folder   : %s\n',activeVertisolDir);
% % fprintf('Van folder        : %s\n',vanCaseDir);
% % fprintf('solvers2D folder  : %s\n',activesolvers2DDir);
% % fprintf('src2D folder      : %s\n',src2DDir);
% % fprintf('======================================================\n\n');
% % 
% % % ===================== LOAD INTERACTIVE PARAMETERS =====================
% % % Priority:
% % %   (A) If GUI already put variables in BASE (mode,Nx_list,nx_fixed,...),use them.
% % %   (B) Else,load simulation_parameters.mat (absolute search).
% % %   (C) Else,defaults.
% % 
% % % ---- Detect if launched from choose_parameters (base workspace vars) ----
% % baseHasMode = false;
% % try
% %     baseHasMode = evalin('base','exist(''mode'',''var'')==1');
% % catch
% %     baseHasMode = false;
% % end
% % 
% % if baseHasMode
% %     % --- Use BASE variables (GUI priority) ---
% %     mode = evalin('base','mode');
% % 
% %     if evalin('base','exist(''Nx_list'',''var'')==1'),Nx_list  = evalin('base','Nx_list');  else,Nx_list  = []; end
% %     if evalin('base','exist(''nx_fixed'',''var'')==1'), nx_fixed = evalin('base','nx_fixed'); else,nx_fixed = []; end
% %     if evalin('base','exist(''L_vec'',''var'')==1'),L_vec    = evalin('base','L_vec');    else,L_vec    = []; end
% %     if evalin('base','exist(''t_final'',''var'')==1'),t_final  = evalin('base','t_final');  else,t_final  = []; end
% %     if evalin('base','exist(''dt_spatial'',''var'')==1'),dt_spatial = evalin('base','dt_spatial'); else,dt_spatial = []; end
% % 
% %     % If some fields missing in base,we will try file,else defaults later
% %     fprintf('\n Using parameters from BASE workspace (GUI priority)\n');
% %     fprintf('Mode: %s\n',get_mode_name(mode));
% % 
% % else
% %     % --- Try load file (absolute search) ---
% %     paramCandidates = {
% %         fullfile('results','simulation_parameters.mat')  % Search in results/ first
% %         fullfile(root,'results','simulation_parameters.mat')
% %         fullfile(root,'simulation_parameters.mat')
% %         fullfile(baseDir,'simulation_parameters.mat')
% %         'simulation_parameters.mat'
% %     };
% % 
% %     paramFile = '';
% %     for kk = 1:numel(paramCandidates)
% %         if exist(paramCandidates{kk},'file') == 2
% %             paramFile = paramCandidates{kk};
% %             break;
% %         end
% %     end
% % 
% %     if ~isempty(paramFile)
% %         load(paramFile,'params');
% %         fprintf('\n Loaded interactive parameters from: %s\n',paramFile);
% %         fprintf('Mode: %s\n',get_mode_name(params.mode));
% % 
% %         mode     = params.mode;
% %         Nx_list  = params.Nx_list;
% %         nx_fixed = params.nx_fixed;
% %         L_vec    = params.L_vec;
% %         t_final  = params.t_final;
% %         dt_spatial = params.dt_spatial;
% % 
% %     else
% %         fprintf('\n No interactive parameters found. Using defaults.\n');
% %         fprintf('Run choose_parameters.m first for interactive selection.\n');
% % 
% %         mode     = 3;
% %         Nx_list  = [17 33 65 129];  % Increased to see more values
% %         nx_fixed = 17;
% %         L_vec    = [0.15 0.25 0.65 1];
% %         t_final  = 0.5;
% %         dt_spatial = 0.025;
% %     end
% % end
% % 
% % % ---- Fill missing values if GUI provided partial vars ----
% % if ~exist('mode','var') || isempty(mode),mode = 3; end
% % 
% % if (mode == 1 || mode == 3) && (~exist('Nx_list','var') || isempty(Nx_list))
% %     Nx_list = [17 33 65 129];
% % end
% % if (mode == 2 || mode == 3) && (~exist('nx_fixed','var') || isempty(nx_fixed))
% %     nx_fixed = 17;
% % end
% % if ~exist('L_vec','var') || isempty(L_vec)
% %     L_vec = [0.15 0.25 0.65 1];
% % end
% % if ~exist('t_final','var') || isempty(t_final)
% %     t_final = 0.5;
% % end
% % if ~exist('dt_spatial','var') || isempty(dt_spatial)
% %     dt_spatial = 0.025;
% % end
% % 
% % % Force L_vec to be a row vector for proper display
% % L_vec = L_vec(:)';
% % 
% % % Print final resolved parameters
% % fprintf('\n================ SELECTED PARAMETERS ================\n');
% % fprintf('Mode              : %s\n',get_mode_name(mode));
% % if mode == 1 || mode == 3,
% %     fprintf('Nx list (spatial)  : %s\n',mat2str(Nx_list)); 
% %     fprintf('Number of Nx values: %d\n',length(Nx_list));
% %     fprintf('dt_spatial         : %.6f\n',dt_spatial);
% % end
% % if mode == 2 || mode == 3,
% %     fprintf('Nx (temporal)      : %d\n',nx_fixed); 
% % end
% % fprintf('L values           : %s\n',mat2str(L_vec));
% % fprintf('Number of L values : %d\n',length(L_vec));
% % fprintf('t_final            : %.6g\n',t_final);
% % fprintf('=====================================================\n\n');
% % 
% % % ===================== GLOBAL PARAMETERS =================================
% % eps1    = 1e-8;
% % s       = 5;            % number of dt levels
% % ellList = 1:s;          % list of ell for variable dt
% % ell0    = 3;            % parameter for solver
% % 
% % % --- Snapshot saving ---
% % save_interval = 0.2;
% % 
% % % ===================== BASE OUTPUT DIRECTORIES ===========================
% % scheme_name   = 'L-scheme';
% % results_base  = 'results';
% % 
% % % =======================================================================
% % % PART 1 : SPATIAL STUDY (loop over L and mesh sizes)
% % % =======================================================================
% % if mode == 1 || mode == 3
% %     fprintf('\n');
% %     fprintf('====================================================================\n');
% %     fprintf('PART 1 : SPATIAL STUDY (mesh refinement)\n');
% %     fprintf('====================================================================\n');
% %     fprintf('Number of L values to process: %d\n',length(L_vec));
% %     fprintf('Number of Nx values to process: %d\n',length(Nx_list));
% % 
% %     for iL = 1:numel(L_vec)
% % 
% %         L = L_vec(iL);
% % 
% %         fprintf('\n=====================================================\n');
% %         fprintf('SPATIAL STUDY | L=%.6g (%d/%d)\n',L,iL,numel(L_vec));
% %         fprintf('=====================================================\n');
% % 
% %         % OUTPUT DIRECTORIES for spatial study
% %         study_type   = 'spatial';
% %         results_root = fullfile(results_base,case_type,scheme_name,...
% %                                 sprintf('L=%.6g',L),study_type);
% %         results_dir   = fullfile(results_root,'resultats_complets');
% %         solutions_dir = fullfile(results_root,'solutions_temporelles');
% % 
% %         if ~exist(results_dir,'dir');     mkdir(results_dir);     end
% %         if ~exist(solutions_dir,'dir');   mkdir(solutions_dir);   end
% % 
% %         fprintf('Folders:\n');
% %         fprintf(' -%s\n',results_root);
% % 
% %         % RESULT ARRAYS for this L value
% %         nH = length(Nx_list);
% % 
% %         Erreur_L1   = zeros(nH,1);
% %         Erreur_L2   = zeros(nH,1);
% %         Erreur_Linf = zeros(nH,1);
% %         Erreur_H1   = zeros(nH,1);
% % 
% %         Newton_last = zeros(nH,1);
% %         Newton_avg  = zeros(nH,1);
% %         CPU_times   = zeros(nH,1);
% % 
% %         Cond_max            = NaN(nH,1);
% %         Cond_moyen          = NaN(nH,1);
% %         Iter_problematiques = zeros(nH,1);
% % 
% %         dt_used  = zeros(nH,1);
% %         h_values = zeros(nH,1);
% % 
% %         visualization_data = struct();
% % 
% %         % Fixed time step for spatial study-use interface value
% %         fprintf('\n--- Temporal parameter for spatial study ---\n');
% %         if exist('dt_spatial','var') && ~isempty(dt_spatial)
% %             dt_fixed = dt_spatial;
% %             fprintf('    Using dt_spatial from interface: %.6f\n',dt_fixed);
% %         else
% %             % Fallback if interface did not provide value
% %             dt_fixed = 0.025;  % default value
% %             fprintf('   Using default dt_fixed: %.6f\n',dt_fixed);
% %         end
% % 
% %         % LOOP OVER MESH SIZES
% %         for i = 1:nH
% %             tic;
% % 
% %             nx = Nx_list(i);
% %             h  = 1/(nx-1);
% %             h_values(i) = h;
% % 
% %             % Adjust time step
% %             dt = dt_fixed;
% %             N  = ceil(t_final/dt);
% %             dt_used(i) = dt;
% % 
% %             fprintf('\n--- Simulation %d/%d: nx=%d,h=%.6f,dt=%.6f ---\n',...
% %                     i,nH,nx,h,dt);
% % 
% %             % 2D MESH GENERATION
% %             [ibcd,p,t,np] = kpde2dumsh(0,1,0,1,nx,nx);
% %             x = p(:,1); z = p(:,2);
% % 
% %             nodes  = (1:np)';
% %             inodes = setdiff(nodes,ibcd);
% % 
% %             % INITIALIZATION
% %             tm = 0;
% %             k  = 0;
% %             ht = dt;
% % 
% %             u0 = uex(x,z,0);
% %             up = u0;
% % 
% %             iter_total = 0;
% %             nsteps     = 0;
% % 
% %             kappa_history_sim = [];
% % 
% %             % SNAPSHOTS
% %             it_save          = 1;
% %             ut_partial       = u0;
% %             t_saved_partial  = 0;
% % 
% %             solution_file = sprintf('solution_nx%d_t%.3fs.mat',nx,0);
% %             save(fullfile(solutions_dir,solution_file),...
% %                  'p','t','u0','tm','nx','L','dt','t_final');
% % 
% %             next_save_time = save_interval;
% % 
% %             % TIME LOOP
% %             while (tm < t_final)
% %                 k  = k+1;
% %                 tm = k*ht;
% % 
% %                 if tm > t_final
% %                     tm = t_final;
% %                 end
% % 
% %                 % Solver call-uses ell0 for L-scheme solver
% %                 try
% %                     [u,n_iter,kappa_hist_step] = solveNonLinearLscheme( ...
% %                         ell0,L,p,t,dt,ibcd,inodes,eps1,tm,up);
% %                     if ~isempty(kappa_hist_step)
% %                         kappa_history_sim = [kappa_history_sim; kappa_hist_step]; 
% %                     end
% %                 catch
% %                     [u,n_iter] = solveNonLinearLscheme( ...
% %                         ell0,L,p,t,dt,ibcd,inodes,eps1,tm,up);
% %                 end
% % 
% %                 up = u;
% %                 iter_total = iter_total+n_iter;
% %                 nsteps     = nsteps+1;
% % 
% %                 % Snapshots
% %                 if tm >= next_save_time
% %                     it_save = it_save+1;
% %                     ut_partial(:,it_save) = u;
% %                     t_saved_partial(it_save,1) = tm;
% % 
% %                     solution_file = sprintf('solution_nx%d_t%.3fs.mat',nx,tm);
% %                     save(fullfile(solutions_dir,solution_file),...
% %                          'p','t','u','tm','nx','L','dt','t_final');
% % 
% %                     next_save_time = next_save_time+save_interval;
% %                 end
% % 
% %                 if k >= N
% %                     break;
% %                 end
% %             end
% % 
% %             % DIAGNOSTICS
% %             if ~isempty(kappa_history_sim)
% %                 Cond_max(i)   = max(kappa_history_sim);
% %                 Cond_moyen(i) = mean(kappa_history_sim);
% %                 Iter_problematiques(i) = sum(kappa_history_sim > 1e10);
% %             end
% % 
% %             % ERROR COMPUTATION
% %             [eL2,eH1] = kpde2derr(p,t,u,t_final);
% %             [eL1,eLinf] = kpde2derrL1Linfty(p,t,u,tm);
% % 
% %             Erreur_L1(i)   = eL1;
% %             Erreur_L2(i)   = eL2;
% %             Erreur_Linf(i) = eLinf;
% %             Erreur_H1(i)   = eH1;
% % 
% %             Newton_last(i) = n_iter;
% %             Newton_avg(i)  = iter_total/max(1,nsteps);
% % 
% %             CPU_times(i) = toc;
% % 
% %             % DISPLAY
% %             fprintf('  L1=%.3e | L2=%.3e | Linf=%.3e | H1=%.3e | It(last)=%d | CPU=%.2fs\n',...
% %                     eL1,eL2,eLinf,eH1,n_iter,CPU_times(i));
% % 
% %             % STORE VIZ DATA
% %             visualization_data(i).p               = p;
% %             visualization_data(i).t               = t;
% %             visualization_data(i).u               = u;
% %             visualization_data(i).nx              = nx;
% %             visualization_data(i).h               = h;
% %             visualization_data(i).dt              = dt;
% %             visualization_data(i).t_final         = tm;
% %             visualization_data(i).ut_partial      = ut_partial;
% %             visualization_data(i).t_saved_partial = t_saved_partial;
% % 
% %             % COLLECT DATA FOR GRAPHS (SPATIAL)
% %             try
% %                 % Create subfolder for convergence data
% %                 conv_data_dir = fullfile(results_root,'convergence_data');
% %                 if ~exist(conv_data_dir,'dir')
% %                     mkdir(conv_data_dir);
% %                 end
% % 
% %                 % Save in subfolder
% %                 conv_file = fullfile(conv_data_dir,'convergence_data_spatial.mat');
% % 
% %                 if exist(conv_file,'file')
% %                     load(conv_file,'conv_data');
% %                 else
% %                     conv_data = struct('Nx',[],'iterations',[],'cpu_time',[],'conditioning',[]);
% %                 end
% % 
% %                 conv_data.Nx(end+1) = nx;
% %                 conv_data.iterations(end+1) = iter_total;
% %                 conv_data.cpu_time(end+1) = CPU_times(i);
% %                 if ~isempty(kappa_history_sim)
% %                     conv_data.conditioning(end+1) = max(kappa_history_sim);
% %                 else
% %                     conv_data.conditioning(end+1) = NaN;
% %                 end
% % 
% %                 save(conv_file,'conv_data');
% %                 fprintf('   Convergence data saved (%d points)\n',length(conv_data.Nx));
% % 
% %             catch ME
% %                 fprintf('  Error collecting spatial data: %s\n',ME.message);
% %             end
% %         end
% % 
% %         % SPATIAL CONVERGENCE ORDERS
% %         if nH >= 2
% %             ordre_L1   = diff(log(Erreur_L1))./diff(log(h_values));
% %             ordre_L2   = diff(log(Erreur_L2))./diff(log(h_values));
% %             ordre_Linf = diff(log(Erreur_Linf))./diff(log(h_values));
% %             ordre_H1   = diff(log(Erreur_H1))./diff(log(h_values));
% %         else
% %             ordre_L1 = []; ordre_L2 = []; ordre_Linf = []; ordre_H1 = [];
% %         end
% % 
% %         % .MAT SAVE
% %         data_file = fullfile(results_dir,'resultats_spatiaux.mat');
% %         save(data_file,...
% %             'Erreur_L1','Erreur_L2','Erreur_Linf','Erreur_H1',...
% %             'Newton_last','Newton_avg','CPU_times',...
% %             'Cond_max','Cond_moyen','Iter_problematiques',...
% %             'dt_used','dt_fixed','Nx_list','h_values',...
% %             't_final','L','eps1','save_interval',...
% %             'ordre_L1','ordre_L2','ordre_Linf','ordre_H1',...
% %             'visualization_data');
% % 
% %         fprintf('\n Spatial data saved: %s\n',data_file);
% % 
% %         % TEXT SUMMARY
% %         summary_file = fullfile(results_dir,'resume_spatial.txt');
% %         fid = fopen(summary_file,'w');
% % 
% %         fprintf(fid,'SPATIAL STUDY SUMMARY-L=%.6g\n',L);
% %         fprintf(fid,'Date: %s\n',datestr(now));
% %         fprintf(fid,'dt_fixed=%.6e | t_final=%.6f | eps1=%.1e\n\n',...
% %             dt_fixed,t_final,eps1);
% % 
% %         fprintf(fid,['========================================================================\n' ...
% %                       'h       nx    dt        L1          L2          Linf        H1          \n' ...
% %                       '========================================================================\n']);
% % 
% %         for i = 1:nH
% %             fprintf(fid,'%.3e  %-4d  %.6f  %-12.3e %-12.3e %-12.3e %-12.3e\n',...
% %                 h_values(i),Nx_list(i),dt_used(i),...
% %                 Erreur_L1(i),Erreur_L2(i),Erreur_Linf(i),Erreur_H1(i));
% %         end
% % 
% %         if ~isempty(ordre_L1)
% %             fprintf(fid,'\n=== ESTIMATED CONVERGENCE ORDERS (in h) ===\n');
% %             for i = 1:length(ordre_L1)
% %                 fprintf(fid,'%d → %d : L1=%.4f | L2=%.4f | Linf=%.4f | H1=%.4f\n',...
% %                     Nx_list(i),Nx_list(i+1),ordre_L1(i),ordre_L2(i),ordre_Linf(i),ordre_H1(i));
% %             end
% %         end
% % 
% %         fclose(fid);
% %         fprintf(' Summary saved: %s\n',summary_file);
% % 
% %     end % end loop over L for spatial study
% % end
% % 
% % % =======================================================================
% % % PART 2 : TEMPORAL STUDY (time step refinement)
% % % =======================================================================
% % if mode == 2 || mode == 3
% %     fprintf('\n');
% %     fprintf('====================================================================\n');
% %     fprintf('PART 2 : TEMPORAL STUDY (time step refinement)\n');
% %     fprintf('====================================================================\n');
% %     fprintf('Number of L values to process: %d\n',length(L_vec));
% % 
% %     for iL = 1:numel(L_vec)
% %         L  = L_vec(iL);
% %         nT = length(ellList);
% % 
% %         fprintf('\n=====================================================\n');
% %         fprintf('TEMPORAL STUDY | L=%.6g (%d/%d) | nx=%d\n',L,iL,numel(L_vec),nx_fixed);
% %         fprintf('=====================================================\n');
% % 
% %         % OUTPUT DIRECTORIES for temporal study
% %         study_type   = 'temporel';
% %         results_root = fullfile(results_base,case_type,scheme_name,...
% %                                 sprintf('L=%.6g',L),study_type);
% %         results_dir   = fullfile(results_root,'resultats_complets');
% %         solutions_dir = fullfile(results_root,'solutions_temporelles');
% % 
% %         if ~exist(results_dir,'dir');     mkdir(results_dir);     end
% %         if ~exist(solutions_dir,'dir');   mkdir(solutions_dir);   end
% % 
% %         fprintf('Folders:\n');
% %         fprintf(' -%s\n',results_root);
% % 
% %         % RESULT ARRAYS for temporal study
% %         Erreur_L1   = zeros(nT,1);
% %         Erreur_L2   = zeros(nT,1);
% %         Erreur_Linf = zeros(nT,1);
% %         Erreur_H1   = zeros(nT,1);
% %         CPU_times   = zeros(nT,1);
% %         Newton_last = zeros(nT,1);
% %         Newton_avg  = zeros(nT,1);
% %         dt_values   = zeros(nT,1);
% % 
% %         Cond_max            = NaN(nT,1);
% %         Cond_moyen          = NaN(nT,1);
% %         Iter_problematiques = zeros(nT,1);
% % 
% %         visualization_data = struct();
% % 
% %         % FIXED MESH
% %         [ibcd,p,t,np] = kpde2dumsh(0,1,0,1,nx_fixed,nx_fixed);
% %         x = p(:,1); z = p(:,2);
% % 
% %         nodes  = (1:np)';
% %         inodes = setdiff(nodes,ibcd);
% % 
% %         fprintf('np=%d | interior unknowns=%d\n',np,length(inodes));
% % 
% %         % LOOP OVER TIME STEPS
% %         for kdt = 1:nT
% %             ell = ellList(kdt);
% %             dt  = 0.1*2^(1-ell);
% %             dt_values(kdt) = dt;
% % 
% %             fprintf('\n--- Simulation %d/%d: ell=%d,dt=%.3e ---\n',kdt,nT,ell,dt);
% % 
% %             % INITIALIZATION
% %             tm = 0;
% %             k  = 0;
% %             ht = dt;
% % 
% %             u0 = uex(x,z,0);
% %             up = u0;
% % 
% %             N  = ceil(t_final/dt);
% %             dt = t_final/N;       % adjustment
% %             dt_values(kdt) = dt;
% % 
% %             iter_total = 0;
% %             nsteps     = 0;
% % 
% %             kappa_history_sim = [];
% % 
% %             % SNAPSHOTS
% %             it_save         = 1;
% %             ut_partial      = u0;
% %             t_saved_partial = 0;
% % 
% %             solution_file = sprintf('solution_ell%d_t%.3fs.mat',ell,0);
% %             save(fullfile(solutions_dir,solution_file),...
% %                  'p','t','u0','tm','nx_fixed','ell','L','dt','t_final');
% % 
% %             next_save_time = save_interval;
% % 
% %             tic;
% % 
% %             % TIME LOOP
% %             while (tm < t_final)
% %                 k  = k+1;
% %                 tm = k*ht;
% % 
% %                 if tm > t_final
% %                     tm = t_final;
% %                 end
% % 
% %                 % Solver call
% %                 try
% %                     [u,n_iter,kappa_hist_step] = solveNonLinearLscheme( ...
% %                         ell0,L,p,t,dt,ibcd,inodes,eps1,tm,up);
% %                     if ~isempty(kappa_hist_step)
% %                         kappa_history_sim = [kappa_history_sim; kappa_hist_step]; 
% %                     end
% %                 catch
% %                     [u,n_iter] = solveNonLinearLscheme( ...
% %                         ell0,L,p,t,dt,ibcd,inodes,eps1,tm,up);
% %                 end
% % 
% %                 up = u;
% %                 iter_total = iter_total+n_iter;
% %                 nsteps     = nsteps+1;
% % 
% %                 % Snapshots
% %                 if tm >= next_save_time
% %                     it_save = it_save+1;
% %                     ut_partial(:,it_save) = u;
% %                     t_saved_partial(it_save,1) = tm;
% % 
% %                     solution_file = sprintf('solution_ell%d_t%.3fs.mat',ell,tm);
% %                     save(fullfile(solutions_dir,solution_file),...
% %                          'p','t','u','tm','nx_fixed','ell','L','dt','t_final');
% % 
% %                     next_save_time = next_save_time+save_interval;
% %                 end
% % 
% %                 if k >= N
% %                     break;
% %                 end
% %             end
% % 
% %             CPU_times(kdt) = toc;
% % 
% %             % DIAGNOSTICS
% %             if ~isempty(kappa_history_sim)
% %                 Cond_max(kdt)   = max(kappa_history_sim);
% %                 Cond_moyen(kdt) = mean(kappa_history_sim);
% %                 Iter_problematiques(kdt) = sum(kappa_history_sim > 1e10);
% %             end
% % 
% %             % ERROR COMPUTATION
% %             [eL2,eH1] = kpde2derr(p,t,u,t_final);
% %             [eL1,eLinf] = kpde2derrL1Linfty(p,t,u,tm);
% % 
% %             Erreur_L1(kdt)   = eL1;
% %             Erreur_L2(kdt)   = eL2;
% %             Erreur_Linf(kdt) = eLinf;
% %             Erreur_H1(kdt)   = eH1;
% % 
% %             Newton_last(kdt) = n_iter;
% %             Newton_avg(kdt)  = iter_total/max(1,nsteps);
% % 
% %             % DISPLAY
% %             fprintf('  dt=%.2e | L1=%.3e | L2=%.3e | Linf=%.3e | H1=%.3e | It(last)=%d | CPU=%.2fs\n',...
% %                     dt,eL1,eL2,eLinf,eH1,n_iter,CPU_times(kdt));
% % 
% %             % STORE VIZ DATA
% %             visualization_data(kdt).p               = p;
% %             visualization_data(kdt).t               = t;
% %             visualization_data(kdt).u               = u;
% %             visualization_data(kdt).nx              = nx_fixed;
% %             visualization_data(kdt).t_final         = tm;
% %             visualization_data(kdt).ell             = ell;
% %             visualization_data(kdt).dt              = dt;
% %             visualization_data(kdt).ut_partial      = ut_partial;
% %             visualization_data(kdt).t_saved_partial = t_saved_partial;
% % 
% %             % COLLECT DATA FOR GRAPHS (TEMPORAL)
% %             try
% %                 % Create subfolder for convergence data
% %                 conv_data_dir = fullfile(results_root,'convergence_data');
% %                 if ~exist(conv_data_dir,'dir')
% %                     mkdir(conv_data_dir);
% %                 end
% % 
% %                 % Save in subfolder
% %                 conv_file = fullfile(conv_data_dir,'convergence_data_temporal.mat');
% % 
% %                 if exist(conv_file,'file')
% %                     load(conv_file,'conv_data');
% %                 else
% %                     conv_data = struct('dt',[],'iterations',[],'cpu_time',[],'conditioning',[]);
% %                 end
% % 
% %                 conv_data.dt(end+1) = dt;
% %                 conv_data.iterations(end+1) = iter_total;
% %                 conv_data.cpu_time(end+1) = CPU_times(kdt);
% %                 if ~isempty(kappa_history_sim)
% %                     conv_data.conditioning(end+1) = max(kappa_history_sim);
% %                 else
% %                     conv_data.conditioning(end+1) = NaN;
% %                 end
% % 
% %                 save(conv_file,'conv_data');
% %                 fprintf('   Temporal convergence data saved (%d points)\n',length(conv_data.dt));
% % 
% %             catch ME
% %                 fprintf('  Error collecting temporal data: %s\n',ME.message);
% %             end
% %         end
% % 
% %         % TEMPORAL CONVERGENCE ORDERS
% %         if nT >= 2
% %             Ordre_L1   = [NaN; diff(log(Erreur_L1))./diff(log(dt_values))];
% %             Ordre_L2   = [NaN; diff(log(Erreur_L2))./diff(log(dt_values))];
% %             Ordre_Linf = [NaN; diff(log(Erreur_Linf))./diff(log(dt_values))];
% %             Ordre_H1   = [NaN; diff(log(Erreur_H1))./diff(log(dt_values))];
% %         else
% %             Ordre_L1 = NaN(nT,1); Ordre_L2 = NaN(nT,1); 
% %             Ordre_Linf = NaN(nT,1); Ordre_H1 = NaN(nT,1);
% %         end
% % 
% %         % .MAT SAVE for temporal study
% %         data_file = fullfile(results_dir,'resultats_temporels.mat');
% %         save(data_file,...
% %             'Erreur_L1','Erreur_L2','Erreur_Linf','Erreur_H1',...
% %             'CPU_times','Newton_last','Newton_avg','dt_values',...
% %             'Ordre_L1','Ordre_L2','Ordre_Linf','Ordre_H1',...
% %             'Cond_max','Cond_moyen','Iter_problematiques',...
% %             'nx_fixed','ellList','L','eps1','t_final','save_interval',...
% %             'visualization_data');
% % 
% %         fprintf('\n Temporal data saved: %s\n',data_file);
% % 
% %         % TEXT SUMMARY for temporal study
% %         summary_file = fullfile(results_dir,'resume_temporel.txt');
% %         fid = fopen(summary_file,'w');
% % 
% %         fprintf(fid,'TEMPORAL STUDY SUMMARY-L=%.6g | nx=%d\n',L,nx_fixed);
% %         fprintf(fid,'Date: %s\n',datestr(now));
% %         fprintf(fid,'t_final=%.6f | eps1=%.1e | save_interval=%.3f\n\n',...
% %             t_final,eps1,save_interval);
% % 
% %         fprintf(fid,['=====================================================================================\n' ...
% %                       'dt        L1          Ord      L2          Ord      Linf        Ord      H1          Ord\n' ...
% %                       '=====================================================================================\n']);
% % 
% %         for i = 1:nT
% %             fprintf(fid,'%.2e  %.3e  %s  %.3e  %s  %.3e  %s  %.3e  %s\n',...
% %                 dt_values(i),...
% %                 Erreur_L1(i),dispOrd(Ordre_L1(i)),...
% %                 Erreur_L2(i),dispOrd(Ordre_L2(i)),...
% %                 Erreur_Linf(i),dispOrd(Ordre_Linf(i)),...
% %                 Erreur_H1(i),dispOrd(Ordre_H1(i)));
% %         end
% % 
% %         fprintf(fid,'\nConditioning (if available):\n');
% %         fprintf(fid,'dt        Cond_max     Cond_moy    Iter_prob(>1e10)\n');
% %         for i = 1:nT
% %             fprintf(fid,'%.2e  %.3e  %.3e  %d\n',dt_values(i),Cond_max(i),Cond_moyen(i),Iter_problematiques(i));
% %         end
% % 
% %         fclose(fid);
% %         fprintf(' Summary saved: %s\n',summary_file);
% %     end
% % end
% % 
% % fprintf('\n');
% % fprintf('====================================================================\n');
% % fprintf('COMPLETE STUDY FINISHED\n');
% % fprintf('====================================================================\n');
% % fprintf('Results available in:\n');
% % fprintf(' -%s\n',fullfile(results_base,case_type,scheme_name));
% % 
% % % =======================================================================
% % % FUNCTIONS FOR REFRESHING PLOTS
% % % =======================================================================
% % function refresh_plots_spatial(handles)
% % %REFRESH_PLOTS_SPATIAL Update spatial convergence plots with latest data
% % %   Searches for convergence_data_spatial.mat files and updates
% % %   the provided axes handles with iteration,CPU time,and conditioning plots.
% % 
% %     try
% %         if ~isstruct(handles) || ~isfield(handles,'ax1') || ~isfield(handles,'ax2') || ~isfield(handles,'ax3')
% %             return;
% %         end
% % 
% %         ax1 = handles.ax1; ax2 = handles.ax2; ax3 = handles.ax3;
% % 
% %         % Search for files in all results folders
% %         found = false;
% %         conv_data = [];
% % 
% %         % Recursive search in results/
% %         files = dir('results/**/convergence_data_spatial.mat');
% %         if ~isempty(files)
% %             % Take the most recent
% %             [~,idx] = max([files.datenum]);
% %             load(fullfile(files(idx).folder,files(idx).name),'conv_data');
% %             found = true;
% %         end
% % 
% %         if ~ishandle(ax1) || ~ishandle(ax2) || ~ishandle(ax3),return; end
% % 
% %         cla(ax1); cla(ax2); cla(ax3);
% % 
% %         title(ax1,'Iterations vs Mesh (Spatial)');
% %         title(ax2,'CPU Time vs Mesh (Spatial)');
% %         title(ax3,'Conditioning vs Mesh (Spatial)');
% % 
% %         if found && ~isempty(conv_data) && isfield(conv_data,'Nx') && ~isempty(conv_data.Nx)
% % 
% %             [Nx_sorted,idx] = sort(conv_data.Nx);
% % 
% %             if isfield(conv_data,'iterations') && ~isempty(conv_data.iterations)
% %                 plot(ax1,Nx_sorted,conv_data.iterations(idx),'b-o','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','b');
% %                 xlabel(ax1,'Nx (mesh points)'); ylabel(ax1,'Number of iterations'); grid(ax1,'on');
% %             end
% % 
% %             if isfield(conv_data,'cpu_time') && ~isempty(conv_data.cpu_time)
% %                 plot(ax2,Nx_sorted,conv_data.cpu_time(idx),'r-s','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','r');
% %                 xlabel(ax2,'Nx (mesh points)'); ylabel(ax2,'CPU Time (s)'); grid(ax2,'on');
% %             end
% % 
% %             if isfield(conv_data,'conditioning') && ~isempty(conv_data.conditioning)
% %                 plot(ax3,Nx_sorted,conv_data.conditioning(idx),'g-d','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','g');
% %                 xlabel(ax3,'Nx (mesh points)'); ylabel(ax3,'Conditioning'); grid(ax3,'on');
% %             end
% % 
% %             drawnow;
% %         else
% %             text(ax1,0.5,0.5,'No spatial data available','HorizontalAlignment','center','FontSize',12,'Parent',ax1);
% %             text(ax2,0.5,0.5,'No spatial data available','HorizontalAlignment','center','FontSize',12,'Parent',ax2);
% %             text(ax3,0.5,0.5,'No spatial data available','HorizontalAlignment','center','FontSize',12,'Parent',ax3);
% %         end
% %     catch ME
% %         fprintf('Error in refresh_plots_spatial: %s\n',ME.message);
% %     end
% % end
% % 
% % function refresh_plots_temporal(handles)
% % %REFRESH_PLOTS_TEMPORAL Update temporal convergence plots with latest data
% % %   Searches for convergence_data_temporal.mat files and updates
% % %   the provided axes handles with iteration,CPU time,and conditioning plots.
% % 
% %     try
% %         if ~isstruct(handles) || ~isfield(handles,'ax1') || ~isfield(handles,'ax2') || ~isfield(handles,'ax3')
% %             return;
% %         end
% % 
% %         ax1 = handles.ax1; ax2 = handles.ax2; ax3 = handles.ax3;
% % 
% %         % Search for files in all results folders
% %         found = false;
% %         conv_data = [];
% % 
% %         % Recursive search in results/
% %         files = dir('results/**/convergence_data_temporal.mat');
% %         if ~isempty(files)
% %             % Take the most recent
% %             [~,idx] = max([files.datenum]);
% %             load(fullfile(files(idx).folder,files(idx).name),'conv_data');
% %             found = true;
% %         end
% % 
% %         if ~ishandle(ax1) || ~ishandle(ax2) || ~ishandle(ax3),return; end
% % 
% %         cla(ax1); cla(ax2); cla(ax3);
% % 
% %         title(ax1,'Iterations vs dt (Temporal)');
% %         title(ax2,'CPU Time vs dt (Temporal)');
% %         title(ax3,'Conditioning vs dt (Temporal)');
% % 
% %         if found && ~isempty(conv_data) && isfield(conv_data,'dt') && ~isempty(conv_data.dt)
% % 
% %             [dt_sorted,idx] = sort(conv_data.dt);
% % 
% %             if isfield(conv_data,'iterations') && ~isempty(conv_data.iterations)
% %                 plot(ax1,dt_sorted,conv_data.iterations(idx),'b-o','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','b');
% %                 xlabel(ax1,'dt (time step)'); ylabel(ax1,'Number of iterations');
% %                 set(ax1,'XScale','log'); grid(ax1,'on');
% %             end
% % 
% %             if isfield(conv_data,'cpu_time') && ~isempty(conv_data.cpu_time)
% %                 plot(ax2,dt_sorted,conv_data.cpu_time(idx),'r-s','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','r');
% %                 xlabel(ax2,'dt (time step)'); ylabel(ax2,'CPU Time (s)');
% %                 set(ax2,'XScale','log'); grid(ax2,'on');
% %             end
% % 
% %             if isfield(conv_data,'conditioning') && ~isempty(conv_data.conditioning)
% %                 plot(ax3,dt_sorted,conv_data.conditioning(idx),'g-d','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','g');
% %                 xlabel(ax3,'dt (time step)'); ylabel(ax3,'Conditioning');
% %                 set(ax3,'XScale','log'); grid(ax3,'on');
% %             end
% % 
% %             drawnow;
% %         else
% %             text(ax1,0.5,0.5,'No temporal data available','HorizontalAlignment','center','FontSize',12,'Parent',ax1);
% %             text(ax2,0.5,0.5,'No temporal data available','HorizontalAlignment','center','FontSize',12,'Parent',ax2);
% %             text(ax3,0.5,0.5,'No temporal data available','HorizontalAlignment','center','FontSize',12,'Parent',ax3);
% %         end
% %     catch ME
% %         fprintf('Error in refresh_plots_temporal: %s\n',ME.message);
% %     end
% % end
% % 
% % % =======================================================================
% % % UTILITY FUNCTIONS
% % % =======================================================================
% % function s = dispOrd(val)
% % %DISPORD Format convergence order for display
% % %   Returns '-' for NaN,otherwise formatted number with 2 decimals.
% % 
% %     if isnan(val),s = '-'; else,s = sprintf('%.2f',val); end
% % end
% % 
% % function name = get_mode_name(val)
% % %GET_MODE_NAME Convert mode number to descriptive string
% % 
% %     switch val
% %         case 1,name = 'Spatial only';
% %         case 2,name = 'Temporal only';
% %         case 3,name = 'Both studies';
% %         otherwise,name = 'Unknown';
% %     end
% % end