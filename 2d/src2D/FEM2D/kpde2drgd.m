function R=kpde2drgd(p,t,nu1,nu2)
%KPDE2DRGD Assemble 2D stiffness matrix for anisotropic diffusion
%   Computes the global stiffness matrix R for the term
%   -div( nu * grad u ) where nu = [nu1 0; 0 nu2] is a diagonal
%   diffusion tensor.
%
%   INPUTS:
%       p   : node coordinates matrix (np x 2)
%       t   : triangle connectivity matrix (nt x 3)
%       nu1 : diffusion coefficient in x-direction - can be:
%             - column vector of length np (nodal values)
%             - column vector of length nt (element-wise constant)
%             - scalar (constant over domain)
%       nu2 : diffusion coefficient in y-direction (same format as nu1)
%
%   OUTPUT:
%       R   : global stiffness matrix (np x np, sparse)
%
%   NUMERICAL METHOD:
%       - Uses linear triangular elements (P1)
%       - Constant or averaged coefficients per element
%       - Piecewise constant gradient approximation
%       - Sparse assembly for efficiency
%
%   ELEMENT STIFFNESS FORMULA:
%       For each triangle T with area A_T and coefficients nu1_T, nu2_T:
%           K_T(i,j) = (nu1_T * dphi_i/dx * dphi_j/dx 
%                     + nu2_T * dphi_i/dy * dphi_j/dy) * A_T
%       where phi_i are linear basis functions.
%
%   BASIS FUNCTION DERIVATIVES:
%       Derivatives of basis functions are constant per element:
%           dphi_i/dx = (y_j - y_k) / (2 * A_T)
%           dphi_i/dy = (x_k - x_j) / (2 * A_T)
%       where (j,k) are the other two nodes.

np=size(p,1);
nt=size(t,1);

% Evaluate coefficients at element centers
[m1,~]=size(nu1);
if (m1==1|m1==nt)
    c=nu1;
else
    c=(nu1(t(:,1))+nu1(t(:,2))+nu1(t(:,3)))/3;
end

[m11,~]=size(nu2);
if (m11==1|m11==nt)
    c1=nu2;
else
    c1=(nu2(t(:,1))+nu2(t(:,2))+nu2(t(:,3)))/3;
end

% Compute triangle areas
it1=t(:,1); it2=t(:,2); it3=t(:,3);
x1=p(it1,1); y1=p(it1,2);
x2=p(it2,1); y2=p(it2,2);
x3=p(it3,1); y3=p(it3,2);

aireT=((x2-x1).*(y3-y1)-(x3-x1).*(y2-y1))/2;

% Scale coefficients by area (prefactor for derivative products)
c=0.25.*c./aireT;
c1=0.25.*c1./aireT;

% Basis function derivatives (constant per element)
% xt(:,i) = dphi_i/dx, yt(:,i) = dphi_i/dy
xt=[(y2-y3) (y3-y1) (y1-y2)];
yt=[(x3-x2) (x1-x3) (x2-x1)];

% Initialize sparse stiffness matrix
R=sparse(np,np);

% Assemble off-diagonal contributions (i greater than j)
for i=1:3
    for j=1:i-1
        R=R+sparse(t(:,i),t(:,j),c.*xt(:,i).*xt(:,j)+c1.*yt(:,i).*yt(:,j),np,np);
    end
end

% Symmetrize (add transpose)
R=R+R.';

% Assemble diagonal contributions (i equal to j)
for i=1:3
    R=R+sparse(t(:,i),t(:,i),c.*xt(:,i).^2+c1.*yt(:,i).^2,np,np);
end
end