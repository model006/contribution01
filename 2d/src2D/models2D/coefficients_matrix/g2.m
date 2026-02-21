function g = g2(u)
%G2 Compute the product of functions g1(u) and gz(u)
%   Evaluates g2(u) = g1(u) * gz(u) pointwise for input u.
%
%   INPUT:
%       u : input vector (can be scalar or vector)
%
%   OUTPUT:
%       g : value(s) of the product g1(u) .* gz(u)
%
%   FORMULA:
%       g2(u) = g1(u) * gz(u)
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - g1(u) : base function
%           - gz(u) : gravity function

g = g1(u).*gz(u);
end