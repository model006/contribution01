function g=beta(u,p,t)
%BETA Assemble element-wise coefficient for beta terms
%   Computes a coefficient involving the vertical gradient of u and
%   the product of vertical permeability and derivative of scaling function.
%
%   INPUTS:
%       u : solution values at nodes (np x 1) or current iteration
%       p : node coordinates matrix (np x 2)
%       t : triangle connectivity matrix (nt x 3)
%
%   OUTPUT:
%       g : element-wise coefficient (nt x 1) where:
%           g = c * ( du/dz + eps )
%           with c = average of ell(u)·dg2(u) over triangle nodes
%
%   FORMULA:
%       For each triangle T with nodes i,j,k:
%           c = ( ell(u_i)·dg2(u_i) 
%               + ell(u_j)·dg2(u_j) 
%               + ell(u_k)·dg2(u_k) ) / 3
%           du/dz = z-component of gradient of u on element T
%           g = c * ( du/dz + eps )
%
%   REGULARIZATION:
%       eps (MATLAB built-in) is added inside parentheses to avoid issues
%       with zero or near-zero values in subsequent divisions.
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - edp2dgrad.m : computes gradient of u on each triangle
%           - ell(u)      : vertical permeability function
%           - dg2(u)      : derivative of scaling function g2

[dzu,~]=edp2dgrad(p,t,u);
g00=ell(u).*dg2(u);
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3)))/3;
g=c.*(dzu+eps);
end