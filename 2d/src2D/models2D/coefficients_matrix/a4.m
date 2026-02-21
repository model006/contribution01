function g=a4(u,p,t)
%A4 Assemble element-wise coefficient for vertical advection terms
%   Computes a coefficient involving the vertical gradient of u and
%   derivatives of permeability and scaling functions.
%
%   INPUTS:
%       u : solution values at nodes (np x 1) or current iteration
%       p : node coordinates matrix (np x 2)
%       t : triangle connectivity matrix (nt x 3)
%
%   OUTPUT:
%       g : element-wise coefficient (nt x 1) where:
%           g = c * ( du/dz + eps1 )
%           with c = average of kh(u)·(gz(u)^2)·dg2(u) over triangle nodes
%
%   FORMULA:
%       For each triangle T with nodes i,j,k:
%           c = ( kh(u_i)·(gz(u_i)^2)·dg2(u_i) 
%               + kh(u_j)·(gz(u_j)^2)·dg2(u_j) 
%               + kh(u_k)·(gz(u_k)^2)·dg2(u_k) ) / 3
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
%           - kh(u)       : horizontal permeability function
%           - gz(u)       : gravity-related function
%           - dg2(u)      : derivative of scaling function g2

eps1=1e-8;
[~,dzu]=edp2dgrad(p,t,u);
g00=kh(u).*(gz(u).^2).*dg2(u);
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3)))/3;
g=c.*(dzu+eps1);
end