function M=kpde2dmass(p,t,alfa)
%KPDE2DMASS Assemble mass matrix using P1 finite elements
%   Computes the consistent mass matrix M for the term (alpha * u, v)
%   using linear triangular elements with coefficient alpha.
%
%   INPUTS:
%       p    : node coordinates matrix (np x 2)
%       t    : triangle connectivity matrix (nt x 3)
%       alfa : coefficient alpha(x,y) - can be:
%              - scalar (constant over domain)
%              - column vector of length np (nodal values)
%              - column vector of length nt (element-wise constant)
%
%   OUTPUT:
%       M    : global mass matrix (np x np, sparse, symmetric positive definite)
%
%   NUMERICAL METHOD:
%       - Uses linear triangular elements (P1)
%       - Element mass matrix for triangle T with area A_T and constant alpha_T:
%           M_T(i,j) = (alpha_T * A_T / 12) * (1 + delta_ij)
%         where delta_ij is 1 when i=j and 0 otherwise
%       - Consistent mass formulation (not lumped)
%
%   ELEMENT FORMULA:
%       For each triangle T:
%           - Off-diagonal terms (i not equal to j): alpha_T * A_T / 12
%           - Diagonal terms (i equal to j): alpha_T * A_T / 6
%
%   INTEGRATION:
%       Uses exact integration for linear basis functions:
%           - Integral over T of phi_i * phi_j dOmega = A_T / 12 for i not equal to j
%           - Integral over T of phi_i * phi_i dOmega = A_T / 6
%
%   DEPENDENCIES:
%       Requires kpde2dgphi.m to compute triangle areas

np=size(p,1); nt=size(t,1); [m1,~]=size(alfa);

% Evaluate coefficient at element centers
if (m1==1||m1==nt)
    c=alfa;
else
    c=(alfa(t(:,1))+alfa(t(:,2))+alfa(t(:,3)))/3;
end

% Compute triangle areas and scale coefficients
ar=kpde2dgphi(p,t);
c=c.*ar/12;

% Initialize sparse mass matrix
M=sparse(np,np);

% Assemble off-diagonal contributions (i not equal to j)
for i=1:3
    for j=1:i-1
        M=M+sparse(t(:,i),t(:,j),c,np,np);
    end
end

% Symmetrize (add transpose)
M=M+M.';

% Assemble diagonal contributions (i equal to j)
for i=1:3
    M=M+sparse(t(:,i),t(:,i),2*c,np,np);
end