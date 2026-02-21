function g=dd(u,p,t)
%DD Assemble element-wise coefficient for dd terms
%   Computes a coefficient involving the vertical gradient of u and
%   the product of derivatives of scaling and permeability functions.
%
%   INPUTS:
%       u : solution values at nodes (np x 1) or current iteration
%       p : node coordinates matrix (np x 2)
%       t : triangle connectivity matrix (nt x 3)
%
%   OUTPUT:
%       g : element-wise coefficient (nt x 1) where:
%           g = c * du/dz
%           with c = average of dg2(u)·ellp(u) over triangle nodes
%
%   FORMULA:
%       For each triangle T with nodes i,j,k:
%           c = ( dg2(u_i)·ellp(u_i) 
%               + dg2(u_j)·ellp(u_j) 
%               + dg2(u_k)·ellp(u_k) ) / 3
%           du/dz = z-component of gradient of u on element T
%           g = c * du/dz
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - edp2dgrad.m : computes gradient of u on each triangle
%           - dg2(u)      : first derivative of scaling function g2
%           - ellp(u)     : derivative of vertical permeability function ell(u)

[~,dzu]=edp2dgrad(p,t,u);
g1=dg2(u).*ellp(u);
c=(g1(t(:,1))+g1(t(:,2))+g1(t(:,3)))/3;
g=c.*dzu;