function g=a5(u,p,t)
%A5 Assemble element-wise coefficient for additional vertical terms
%   Computes a coefficient involving the vertical gradient of u and
%   the derivative of the vertical permeability function.
%
%   INPUTS:
%       u : solution values at nodes (np x 1) or current iteration
%       p : node coordinates matrix (np x 2)
%       t : triangle connectivity matrix (nt x 3)
%
%   OUTPUT:
%       g : element-wise coefficient (nt x 1) where:
%           g = c * ( du/dz + eps1 )
%           with c = average of g2(u)·ellp(u) over triangle nodes
%
%   FORMULA:
%       For each triangle T with nodes i,j,k:
%           c = ( g2(u_i)·ellp(u_i) 
%               + g2(u_j)·ellp(u_j) 
%               + g2(u_k)·ellp(u_k) ) / 3
%           du/dz = z-component of gradient of u on element T
%           g = c * ( du/dz + eps1 )
%
%   REGULARIZATION:
%       eps1 = 1e-8 is added inside parentheses to avoid issues with
%       zero or near-zero values in subsequent divisions.
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - edp2dgrad.m : computes gradient of u on each triangle
%           - g2(u)       : scaling function
%           - ellp(u)     : derivative of vertical permeability function ell(u)

eps1=1e-8;
[~,dzu]=edp2dgrad(p,t,u);
g00=g2(u).*ellp(u);
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3)))/3;
g=c.*(dzu+eps1);
end