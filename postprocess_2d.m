function postprocess_2d()
%POSTPROCESS_2D Launch 2D visualization and convergence analysis
%   Navigates to the 2D results directory and initializes the batch
%   visualization tool for post-processing Richards equation simulations
%   in deformable porous media.
%
%   -----------------------------------------------------------------------
%   USAGE:
%        postprocess_2d
%
%   This function provides interactive access to:
%       a) Error convergence plots (L2, H1, L1, Linf)
%       b) CPU time and iteration analysis
%       c) L-value comparisons and conditioning
%       d) Publication-quality figure export
%
%   WORKFLOW:
%       1. Changes current directory to the 2D results folder
%       2. Displays a startup message
%       3. Calls batch_view_rules_bat() to launch the visualization interface
%
%   -----------------------------------------------------------------------
%   DEPENDENCIES:
%       batch_view_rules_bat.m - Main visualization driver
%
%   -----------------------------------------------------------------------
%   SEE ALSO:
%       batch_view_rules_bat, postprocess_3d, choose_parameters
%
%   -----------------------------------------------------------------------


    % Locate and navigate to 2D results directory
    here = fileparts(mfilename('fullpath'));
    target_dir = fullfile(here, '2D');
    
    try
        cd(target_dir);
        fprintf('\n=== 2D Post-Processing ===\n');
        fprintf('Launching visualization tools...\n\n');
        batch_view_rules_bat;
    catch ME
        error('Failed to initialize post-processing:\n%s', ME.message);
    end

end
