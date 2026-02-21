function D=kpde2div(p,t,alfa,beta)
%KPDE2DIV Assemble 2D advection matrix using P1 finite elements
%   Computes the global advection matrix D for the term ( (c dot grad)u, v )
%   where c = (alpha, beta) is the advection velocity field.
%
%   INPUTS:
%       p     : node coordinates matrix (np x 2)
%       t     : triangle connectivity matrix (nt x 3)
%       alfa  : x-component of advection coefficient - can be:
%               - scalar (constant over domain)
%               - column vector of length np (nodal values)
%               - column vector of length nt (element-wise constant)
%       beta  : y-component of advection coefficient (same format as alfa)
%
%   OUTPUT:
%       D     : global advection matrix (np x np, sparse)
%
%   NUMERICAL METHOD:
%       - Uses linear triangular elements (P1)
%       - Element advection matrix for triangle T with area A_T and
%         constant coefficients alpha_T, beta_T:
%           D_T(i,j) = (alpha_T/6)*(dphi_j/dx)*A_T + (beta_T/6)*(dphi_j/dy)*A_T
%       - Uses constant approximation of coefficients per element
%
%   BASIS FUNCTION DERIVATIVES:
%       For linear triangle with nodes (x1,y1), (x2,y2), (x3,y3):
%           dphi_1/dx = (y2 - y3)/(2*A_T)
%           dphi_1/dy = (x3 - x2)/(2*A_T)
%           (cyclic permutations for other nodes)
%
%   INTEGRATION:
%       Uses the formula:
%           Integral over T of (c dot grad phi_j)*phi_i dOmega 
%           = (alpha_T*dphi_j/dx + beta_T*dphi_j/dy)*A_T/3
%       with mass distribution among nodes (1/3 each)

np=size(p,1); nt=size(t,1); [m1,~]=size(alfa);

% Evaluate x-component coefficient at element centers
if (m1==1||m1==nt)
    c=alfa;
else
    c=(alfa(t(:,1))+alfa(t(:,2))+alfa(t(:,3)))/3;
end

[m2,~]=size(beta);
% Evaluate y-component coefficient at element centers
if (m2==1||m2==nt)
    d=beta;
else
    d=(beta(t(:,1))+beta(t(:,2))+beta(t(:,3)))/3;
end

% Compute triangle areas
it1=t(:,1);
it2=t(:,2);
it3=t(:,3);

x1=p(it1,1);
y1=p(it1,2);

x2=p(it2,1);
y2=p(it2,2);

x3=p(it3,1);
y3=p(it3,2);

c=c/6;
d=d/6;

% Basis function derivatives (constant per element)
xt=[(y2-y3) (y3-y1) (y1-y2)];
yt=[(x3-x2) (x1-x3) (x2-x1)];

% Assembly of advection matrix
D=sparse(np,np);
for i=1:3
    for j=1:3
        D=D+sparse(t(:,i),t(:,j),c.*xt(:,j)+d.*yt(:,j),np,np);
    end
end
end