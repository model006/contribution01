function [ar,g]=kpde2dgphi(p,t)
%KPDE2DGPHI Compute triangle areas and basis function gradients for P1 elements
%   Calculates the area of each triangle and optionally the gradients of
%   the linear basis functions for use in finite element assembly.
%
%   INPUTS:
%       p : node coordinates matrix (np x 2)
%       t : triangle connectivity matrix (nt x 3)
%
%   OUTPUTS:
%       ar : triangle areas (nt x 1)
%       g  : cell array of gradients for each basis function (optional)
%            g{1}, g{2}, g{3} are matrices of size nt x 2 containing
%            [dphi/dx, dphi/dy] for each node of the triangle
%
%   AREA COMPUTATION:
%       For triangle with vertices (x1,y1), (x2,y2), (x3,y3):
%           area = 0.5 * | (x2-x1)*(y3-y1) - (x3-x1)*(y2-y1) |
%
%   GRADIENT COMPUTATION:
%       For linear basis functions, gradients are constant per element:
%           phi_1 = 1 - xi - eta  (reference element)
%           phi_2 = xi
%           phi_3 = eta
%       Physical gradients are computed using the inverse Jacobian:
%           dphi_i/dx = (y_j - y_k) / (2*area)
%           dphi_i/dy = (x_k - x_j) / (2*area)
%       where (j,k) are the other two nodes.
%
%   USAGE:
%       ar = kpde2dgphi(p,t);                 % areas only
%       [ar,g] = kpde2dgphi(p,t);             % areas and gradients

% Edge vectors (differences between node coordinates)
x21=p(t(:,2),1)-p(t(:,1),1); y21=p(t(:,2),2)-p(t(:,1),2);
x32=p(t(:,3),1)-p(t(:,2),1); y32=p(t(:,3),2)-p(t(:,2),2);
x31=p(t(:,3),1)-p(t(:,1),1); y31=p(t(:,3),2)-p(t(:,1),2);

% Triangle areas (signed, then absolute value taken elsewhere if needed)
ar=(x21.*y31-y21.*x31)/2;

if (nargout==1), return; end

% Gradients of basis functions (constant per element)
% Each gradient is stored as [dphi/dx, dphi/dy] scaled by 1/(2*area)
g={.5*[-y32./ar x32./ar] .5*[y31./ar -x31./ar] .5*[-y21./ar x21./ar]};
end