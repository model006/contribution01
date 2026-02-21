function [eL1,eLinf] = kpde2derrL1Linfty(p,t,uh,t_eval)
%KPDE2DERRL1LINFTY Compute L1 and Linfinity error norms
%   Calculates L1 and Linfinity error norms between finite element solution
%   and exact solution for 2D problems.
%
%   INPUTS:
%       p      : node coordinates matrix (np x 2)
%       t      : triangle connectivity matrix (nt x 3)
%       uh     : approximate solution at nodes (np x 1)
%       t_eval : time at which to evaluate exact solution
%
%   OUTPUTS:
%       eL1   : L1 error norm (integrated absolute difference)
%       eLinf : Linfinity error norm (maximum absolute difference)

[u_exact,~,~] = uex(p(:,1),p(:,2),t_eval);
err = abs(uh-u_exact);

% L1 error (integrated absolute difference)
eL1 = sum(kpde2drhs(p,t,err));

% Linfinity error (maximum absolute difference)
eLinf = max(err);