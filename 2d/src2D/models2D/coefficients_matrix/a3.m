function g=a3(u,t)
%A3 Assemble element-wise coefficient for vertical diffusion terms
%   Computes the average of kh(u)·(gz(u)^2)·g2(u) over each triangle
%   for use in finite element assembly.
%
%   INPUTS:
%       u : solution values at nodes (np x 1) or current iteration
%       t : triangle connectivity matrix (nt x 3)
%
%   OUTPUT:
%       g : element-wise coefficient (nt x 1) where each entry is the
%           average of kh(u)·(gz(u)^2)·g2(u) over the three nodes of the triangle
%
%   FORMULA:
%       For each triangle T with nodes i,j,k:
%           g(T) = ( kh(u_i)·(gz(u_i)^2)·g2(u_i) 
%                  + kh(u_j)·(gz(u_j)^2)·g2(u_j) 
%                  + kh(u_k)·(gz(u_k)^2)·g2(u_k) ) / 3
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - kh(u)  : horizontal permeability function
%           - gz(u)  : gravity-related function
%           - g2(u)  : scaling function

g00=kh(u).*(gz(u).^2).*g2(u);
g=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3)))/3;
end