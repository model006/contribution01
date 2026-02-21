function fh = kpde2drhs(p,t,f)
%KPDE2DRHS Assemble right-hand side vector for 2D FEM problems
%   Computes the load vector fh by integrating the source term f over
%   each triangle element using nodal or element-wise values.
%
%   INPUTS:
%       p : node coordinates matrix (np x 2)
%       t : triangle connectivity matrix (nt x 3)
%       f : source term values - can be:
%           - column vector of length np (nodal values)
%           - column vector of length nt (element-wise constant values)
%           - scalar (constant over domain)
%
%   OUTPUT:
%       fh : assembled right-hand side vector (np x 1)
%
%   NUMERICAL METHOD:
%       - If f is given at nodes, averages to element centers
%       - Uses centroid approximation: integral_T (f * phi_i) dT
%         is approximated by (area/3) * f_elem
%       - Assembles contributions using sparse matrix for efficiency
%
%   INTEGRATION FORMULA:
%       For each triangle T with area A_T and element value f_T:
%           fh(i) = fh(i) + (A_T/3) * f_T for each node i of triangle T
%
%   ERROR CHECKING:
%       Verifies that f dimensions are compatible (np or nt)

np=size(p,1);
nt=size(t,1);

% 1. Evaluate f at triangle centroids
[m1,m2]=size(f);
if (m2>1)||(m1>1&&m1~=nt&&m1~=np)
    error('f must be a column vector of length np or nt');
end
if (m1==1)||(m1==nt)
    ff=f;
else
    ff=(f(t(:,1))+f(t(:,2))+f(t(:,3)))/3;
end

% 2. Compute triangle areas
it1=t(:,1);
it2=t(:,2);
it3=t(:,3);

x1=p(it1,1);
y1=p(it1,2);

x2=p(it2,1);
y2=p(it2,2);

x3=p(it3,1);
y3=p(it3,2);

aireT=0.5*abs((x2-x1).*(y3-y1)-(x3-x1).*(y2-y1));

% 3. Assemble right-hand side vector
ff=ff.*aireT/3;
fh=full(sparse(t(:,1),1,ff,np,1)+...
        sparse(t(:,2),1,ff,np,1)+...
        sparse(t(:,3),1,ff,np,1));