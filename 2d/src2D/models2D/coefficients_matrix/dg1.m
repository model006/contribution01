function g = dg1(u)
%DG1 Compute the first derivative of function g1(u)
%   Calculates dg1/du where g1(u) = we(u)/(c(u) + eps)
%
%   INPUT:
%       u : input vector (can be scalar or vector)
%
%   OUTPUT:
%       g : column vector containing the first derivative dg1/du
%
%   FORMULA:
%       The first derivative is given by:
%           dg1/du = ( wep(u)*(c(u)+eps_num) - cp(u)*we(u) ) / (c(u)+eps_num)^2
%
%   DEPENDENCIES:
%       Requires auxiliary function:
%           - wep(u) : first derivative of we(u)

% Ensure u is a column vector
u = u(:);

% Compute first derivative according to formula:
% dg1/du = ( wep(u)*(c(u)+eps_num) - cp(u)*we(u) ) / (c(u)+eps_num)^2

g = wep(u);

% Guarantee that the result is a column vector
g = g(:);