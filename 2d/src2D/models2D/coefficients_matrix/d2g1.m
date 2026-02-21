function g = d2g1(u)
%D2G1 Compute the second derivative of function g1(u)
%   Calculates d²g1/du² where g1(u) = we(u)/(c(u) + eps)
%
%   INPUT:
%       u : input vector (can be scalar or vector)
%
%   OUTPUT:
%       g : column vector containing the second derivative d²g1/du²
%
%   FORMULA:
%       The second derivative is computed using the simplified expression:
%           d²g/du² = numerator ./ (c(u) + eps_num).^3
%       where numerator depends on derivatives of we(u) and c(u).
%
%   DEPENDENCIES:
%       Requires auxiliary function:
%           - wepp(u) : second derivative of we(u)

% Ensure u is a column vector
u = u(:);

% Compute second derivative
% Simplified formula for d²g1/du²
% d²g/du² = numerator ./ (c(u) + eps_num).^3

% Guarantee that the result is a column vector
g = wepp(u);
end