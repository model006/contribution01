function g=ell(u)
%ELL Compute the vertical permeability function ell(u)
%   Calculates ell(u) = kh(u)*(gz(u))^2
%
%   INPUT:
%       u : input vector (can be scalar or vector)
%
%   OUTPUT:
%       g : column vector containing ell(u) values
%
%   FORMULA:
%       ell(u) = kh(u)*(gz(u))^2
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - kh(u) : horizontal permeability function
%           - gz(u) : gravity function

g=kh(u).*gz(u).^2;
end