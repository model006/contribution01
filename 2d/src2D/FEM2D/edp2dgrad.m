function [dxu,dyu]=edp2dgrad(p,t,u)
%EDP2DGRAD Compute gradient of a piecewise linear function on a 2D triangular mesh
%   Calculates the x and y components of the gradient of a function u
%   defined at nodes, using linear finite element approximation.
%
%   INPUTS:
%       p  : node coordinates matrix (np x 2)
%       t  : triangle connectivity matrix (nt x 3)
%       u  : nodal values of the function (np x 1)
%
%   OUTPUTS:
%       dxu : x-component of gradient (du/dx) at each triangle (nt x 1)
%       dyu : y-component of gradient (du/dy) at each triangle (nt x 1)
%
%   NUMERICAL METHOD:
%       For each triangle T with nodes i,j,k and nodal values ui,uj,uk:
%           du/dx = ui·(dphi_i/dx) + uj·(dphi_j/dx) + uk·(dphi_k/dx)
%           du/dy = ui·(dphi_i/dy) + uj·(dphi_j/dy) + uk·(dphi_k/dy)
%       where dphi/dx, dphi/dy are the basis function derivatives
%       (constant per element).
%
%   BASIS FUNCTION DERIVATIVES:
%       For triangle with area A_T:
%           dphi_1/dx = (y2 - y3)/(2*A_T)
%           dphi_1/dy = (x3 - x2)/(2*A_T)
%           (cyclic permutations for other nodes)
%
%   OUTPUT FORMAT:
%       Returns gradient components as column vectors of length nt,
%       each entry corresponding to one triangle element.

% Triangle node indices
it1=t(:,1);
it2=t(:,2);
it3=t(:,3);

% Edge vectors
x21=p(t(:,2),1)-p(t(:,1),1); y21=p(t(:,2),2)-p(t(:,1),2);
x32=p(t(:,3),1)-p(t(:,2),1); y32=p(t(:,3),2)-p(t(:,2),2);
x31=p(t(:,3),1)-p(t(:,1),1); y31=p(t(:,3),2)-p(t(:,1),2);

% Triangle areas (signed, 2*area)
ar=x21.*y31-y21.*x31;

% Basis function derivatives (scaled by 1/area)
phi1=[-y32./ar x32./ar];
phi2=[ y31./ar -x31./ar];
phi3=[-y21./ar x21./ar];

% Compute gradient components
dxu=(u(it1).*phi1(:,1)+u(it2).*phi2(:,1)+u(it3).*phi3(:,1));
dyu=(u(it1).*phi1(:,2)+u(it2).*phi2(:,2)+u(it3).*phi3(:,2));
end