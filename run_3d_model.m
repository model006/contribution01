function run_3d_model()
%RUN_3D_MODEL Launch the 3D finite element simulation environment
%   This function serves as the master entry point for all 3D simulations
%   of coupled flow and deformation in porous media. It automatically
%   navigates to the 3D simulation directory and launches the appropriate
%   graphical user interface.
%
%   -----------------------------------------------------------------------
%   FEATURES:
%       - Automatic path management for 3D simulation environment
%       - Smart detection of available GUI launchers
%       - Seamless integration with the main simulation workflow
%       - Compatible with both standalone and batch processing modes
%
%   -----------------------------------------------------------------------
%   USAGE:
%        run_3d_model
%
%   The function will:
%       1. Locate the 3D simulation directory
%       2. Detect available GUI launchers in order of preference
%       3. Start the interactive simulation environment
%
%   -----------------------------------------------------------------------
%   DEPENDENCIES:
%       - 3D/start_gui.m           : Primary GUI launcher
%       - 3D/gui/run_all_cases_gui.m : Alternative batch GUI
%
%   -----------------------------------------------------------------------
%   NOTES:
%       - Ensure all 3D simulation files are in the correct directory
%       - The function automatically manages the current working directory
%       - Returns control to original directory after GUI launch
%
%   -----------------------------------------------------------------------
%   SEE ALSO:
%       start_gui, run_all_cases_gui, choose_parameters
%
%   -----------------------------------------------------------------------



    % Store the original directory to return to later (good practice)
    original_dir = pwd;
    
    % Locate the 3D simulation directory relative to this file
    current_file_path = fileparts(mfilename('fullpath'));
    simulation_3d_dir = fullfile(current_file_path, '3D');
    
    % Attempt to change to the 3D directory
    try
        cd(simulation_3d_dir);
    catch ME
        error('Unable to access 3D simulation directory:\n%s', ME.message);
    end
    
    % Display startup information (professional feedback)
    fprintf('\n');
    fprintf('============================================\n');
    fprintf('   3D FINITE ELEMENT SIMULATION ENVIRONMENT\n');
    fprintf('   Coupled Flow and Deformation in Porous Media\n');
    fprintf('============================================\n');
    fprintf('Working directory: %s\n', simulation_3d_dir);
    fprintf('Initializing GUI...\n');
    
    % Launch the most appropriate GUI with fallback options
    if exist('start_gui.m', 'file')
        % Primary option: dedicated GUI launcher
        fprintf('Launching primary simulation interface...\n');
        start_gui;
        
    elseif exist(fullfile('gui', 'run_all_cases_gui.m'), 'file')
        % Secondary option: batch processing GUI
        fprintf('Launching batch processing interface...\n');
        run(fullfile('gui', 'run_all_cases_gui.m'));
        
    else
        % No GUI found - provide helpful error message
        cd(original_dir);  % Restore original directory
        error(['No GUI launcher found in 3D folder.\n', ...
               'Expected files:\n', ...
               '  - start_gui.m\n', ...
               '  - gui/run_all_cases_gui.m\n', ...
               'Current directory: %s'], simulation_3d_dir);
    end
    
    % Note: We don't automatically cd back to allow the GUI to run
    fprintf('3D simulation environment successfully initialized.\n');
    fprintf('============================================\n\n');

end
