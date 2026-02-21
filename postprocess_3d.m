function postprocess_3d()
%POSTPROCESS_3D Launch 3D visualization and convergence analysis
%   Navigates to the 3D results directory and initializes the batch
%   visualization tool for post-processing Richards equation simulations
%   in deformable porous media.
%
%   -----------------------------------------------------------------------
%   USAGE:
%        postprocess_3d
%
%   This function provides interactive access to:
%       a) Error convergence plots (L2, H1, L1, Linf norms)
%       b) CPU time and iteration analysis across mesh refinements
%       c) L-value comparisons and conditioning diagnostics
%       d) Publication-quality figure export for 3D results
%       e) Cross-section and isosurface visualization (physical case)
%
%   WORKFLOW:
%       1. Changes current directory to the 3D results folder
%       2. Displays a startup message with version info
%       3. Calls batch_view_rules_bat() to launch the visualization interface
%
%   -----------------------------------------------------------------------
%   DEPENDENCIES:
%       batch_view_rules_bat.m - Main visualization driver for 3D results
%
%   -----------------------------------------------------------------------
%   SEE ALSO:
%       batch_view_rules_bat, postprocess_2d, choose_parameters, run_3d_model
%


    % Locate and navigate to 3D directory
    here = fileparts(mfilename('fullpath'));
    target_dir = fullfile(here, '3D');
    
    try
        cd(target_dir);
        fprintf('\n=== 3D Post-Processing ===\n');
        fprintf('Launching visualization tools...\n');
        batch_view_rules_bat;
    catch ME
        error('Failed to initialize post-processing:\n%s', ME.message);
    end

end
