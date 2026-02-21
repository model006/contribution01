function run_2d_model()
%RUN_2D_MODEL Launch 2D simulation environment for Richards equation in deformable porous media
%   Navigates to the 2D directory and launches the parameter selection GUI.
%   Optional cleanup removes previous results to ensure fresh simulations.
%
%   -----------------------------------------------------------------------
%   USAGE:
%        run_2d_model
%
%   This function serves as the main entry point for 2D simulations,
%   providing access to:
%       - Parameter selection via choose_parameters GUI
%       - Automatic directory navigation
%       - Optional cleanup of previous results
%       - Direct execution of main.m if GUI not available
%
%   -----------------------------------------------------------------------
%   FEATURES:
%       - Automatic navigation to 2D directory
%       - Optional cleanup of old results (set DO_CLEANUP)
%       - Launches choose_parameters.m (preferred) or main.m as fallback
%       - Compatible with both physical and validation cases
%
%   -----------------------------------------------------------------------
%   CLEANUP OPTIONS:
%       Set DO_CLEANUP = true to remove:
%           - results_physical/, results_validation/, results/ folders
%           - All *_results_*.mat files in the 2D directory
%
%   -----------------------------------------------------------------------
%   DEPENDENCIES:
%       choose_parameters.m - Interactive parameter selection GUI
%       main.m              - Core simulation driver (fallback)
%
%   -----------------------------------------------------------------------
%   SEE ALSO:
%       choose_parameters, main, postprocess_2d, run_3d_model
%

    here = fileparts(mfilename('fullpath'));
    twoD = fullfile(here, '2D');

    if ~isfolder(twoD)
        error('2D folder not found at: %s', twoD);
    end

    cd(twoD);

    % ===================== Optional cleanup ======================
    DO_CLEANUP = true;   % set false to keep results between runs

    if DO_CLEANUP
        fprintf('Cleaning old 2D results...\n');
        
        % Remove result folders
        folders = {'results_physical', 'results_validation', 'results'};
        for i = 1:numel(folders)
            folder_path = fullfile(twoD, folders{i});
            if exist(folder_path, 'dir')
                rmdir(folder_path, 's');
                fprintf('  Removed: %s\n', folder_path);
            end
        end
        
        % Remove individual result files
        mats = dir(fullfile(twoD, '*_results_*.mat'));
        for k = 1:numel(mats)
            delete(fullfile(twoD, mats(k).name));
            fprintf('  Deleted: %s\n', mats(k).name);
        end
        
        fprintf('Cleanup completed.\n\n');
    end

    % ===================== Launch ================================
    if exist('choose_parameters.m','file')
        fprintf('Launching parameter selection GUI...\n');
        choose_parameters;
    elseif exist('main.m','file')
        fprintf('Parameter selection GUI not found. Running main directly...\n');
        main;
    else
        error('No launcher found in 2D folder.');
    end
end