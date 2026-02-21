function g=a0(u,t)
%A0 Assemble element-wise coefficient for stiffness matrix
%   Computes the average of the product kh(u)·g1(u) over each triangle
%   for use in finite element assembly.
%
%   INPUTS:
%       u : solution values at nodes (np x 1) or current iteration
%       t : triangle connectivity matrix (nt x 3)
%
%   OUTPUT:
%       g : element-wise coefficient (nt x 1) where each entry is the
%           average of kh(u)·g1(u) over the three nodes of the triangle
%
%   FORMULA:
%       For each triangle T with nodes i,j,k:
%           g(T) = ( kh(u_i)·g1(u_i) + kh(u_j)·g1(u_j) + kh(u_k)·g1(u_k) ) / 3
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - kh(u) : horizontal permeability function
%           - g1(u) : scaling function

g0=kh(u).*g1(u);
g=(g0(t(:,1))+g0(t(:,2))+g0(t(:,3)))./3;
end