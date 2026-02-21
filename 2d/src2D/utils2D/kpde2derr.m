function [eL2,eH1]=kpde2derr(p,t,u,time)
%KPDE2DERR Compute L2 and H1 errors between exact and approximate solutions
%   Calculates the L2 and H1 error norms for a 2D finite element solution
%   using 13-point Gaussian quadrature on each triangle.
%
%   INPUTS:
%       p    : node coordinates matrix (np x 2)
%       t    : triangle connectivity matrix (nt x 3)
%       u    : approximate solution at nodes (np x 1)
%       time : current time for exact solution evaluation
%
%   OUTPUTS:
%       eL2 : L2 error norm (square root of integrated squared difference)
%       eH1 : H1 error norm (includes both function and gradient differences)
%
%   NUMERICAL METHOD:
%       - Uses 13-point Gaussian quadrature (degree 6) on reference triangle
%       - Quadrature points and weights are precomputed
%       - Error computed as:
%           L2 error = sqrt( (u_h - u_ex)^2 dOmega )
%           H1 error = sqrt( [(u_h - u_ex)^2 + |grad u_h - grad u_ex|^2] dOmega )
%
%   QUADRATURE:
%       Reference triangle coordinates (xg,yg) and weights (wg) are from
%       a 13-point rule that integrates polynomials up to degree 6 exactly.


xg=[0.0651301029022;0.8697397941956;0.0651301029022;0.3128654960049;
    0.6384441885698;0.0486903154253;0.6384441885698;0.3128654960049;
    0.0486903154253;0.2603459660790;0.4793080678419;0.2603459660790;
    0.3333333333333];
yg=[0.0651301029022;0.0651301029022;0.8697397941956;0.0486903154253;
    0.3128654960049;0.6384441885698;0.0486903154253;0.6384441885698;
    0.3128654960049;0.2603459660790;0.2603459660790;0.4793080678419;
    0.3333333333333];
wg=[0.0533472356088;0.0533472356088;0.0533472356088;0.0771137608903;
    0.0771137608903;0.0771137608903;0.0771137608903;0.0771137608903;
    0.0771137608903;0.1756152574332;0.1756152574332;0.1756152574332;
   -0.1495700444677]/2;

% 1. Triangle areas
it1=t(:,1); it2=t(:,2); it3=t(:,3);
x21=p(it2,1)-p(it1,1); y21=p(it2,2)-p(it1,2);
x32=p(it3,1)-p(it2,1); y32=p(it3,2)-p(it2,2);
x31=p(it3,1)-p(it1,1); y31=p(it3,2)-p(it1,2);
ar=x21.*y31-y21.*x31;

% 2. Basis function derivatives (constant per element)
phi1=[-y32./ar x32./ar];
phi2=[ y31./ar -x31./ar];
phi3=[-y21./ar x21./ar];

% 3. Derivatives of approximate solution on each triangle
dxuh=u(it1).*phi1(:,1)+u(it2).*phi2(:,1)+u(it3).*phi3(:,1);
dyuh=u(it1).*phi1(:,2)+u(it2).*phi2(:,2)+u(it3).*phi3(:,2);

% 4. Gaussian quadrature loop
nt=size(t,1);
errl=0; errh=0;
for i=1:nt
    it=t(i,1:3); ut=u(it); xt=p(it,1); yt=p(it,2);

    % Approximate solution at Gauss points (bilinear interpolation)
    uh=(1-xg-yg).*ut(1)+xg.*ut(2)+yg.*ut(3);

    % Physical coordinates of Gauss points
    x=(1-xg-yg).*xt(1)+xg.*xt(2)+yg.*xt(3);
    y=(1-xg-yg).*yt(1)+xg.*yt(2)+yg.*yt(3);

    % Exact solution and its derivatives at Gauss points
    [ue, dxue, dyue] = uex(x, y, time);

    % Error contributions
    ee1=ar(i)*wg.*(uh-ue).^2;
    ee2=ar(i)*wg.*(dxuh(i)-dxue).^2+ar(i)*wg.*(dyuh(i)-dyue).^2;

    errl=errl+sum(ee1);
    errh=errh+sum(ee1)+sum(ee2);
end

eL2=sqrt(errl); eH1=sqrt(errh);
end