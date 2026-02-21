function g=a2(u,p,t)
%A2 Assemble element-wise coefficient for advection/dispersion terms
%   Computes a coefficient involving the gradient of u and derivatives
%   of permeability and scaling functions for finite element assembly.
%
%   INPUTS:
%       u : solution values at nodes (np x 1) or current iteration
%       p : node coordinates matrix (np x 2)
%       t : triangle connectivity matrix (nt x 3)
%
%   OUTPUT:
%       g : element-wise coefficient (nt x 1) where:
%           g = c * ( (du/dx)^2 + eps1 )
%           with c = average of kh(u)·dg1(u) over triangle nodes
%
%   FORMULA:
%       For each triangle T with nodes i,j,k:
%           c = ( kh(u_i)·dg1(u_i) + kh(u_j)·dg1(u_j) + kh(u_k)·dg1(u_k) ) / 3
%           du/dx = x-component of gradient of u on element T
%           g = c * ( (du/dx)^2 + eps1 )
%
%   REGULARIZATION:
%       eps1 = 1e-8 is added to avoid division by zero or negative values
%       in subsequent computations.
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - edp2dgrad.m : computes gradient of u on each triangle
%           - kh(u)       : horizontal permeability function
%           - dg1(u)      : derivative of scaling function g1

eps1=1e-8;
[dxu,~]=edp2dgrad(p,t,u);
g00=kh(u).*dg1(u);
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3)))/3;
g=c.*(dxu.^2+eps1);
end