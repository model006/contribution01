function g=ellp(u)
%ELLP Compute the first derivative of vertical permeability function ell(u)
%   Calculates d(ell)/du where ell(u) = kh(u)*(gz(u))^2
%
%   INPUT:
%       u : input vector (can be scalar or vector)
%
%   OUTPUT:
%       g : column vector containing ell'(u) values
%
%   FORMULA:
%       Using the product rule:
%           ell'(u) = kh'(u)*(gz(u))^2 + 2*kh(u)*gz'(u)*gz(u)
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - kh(u)  : horizontal permeability function
%           - khp(u) : first derivative of kh(u)
%           - gz(u)  : gravity function
%           - dgz(u) : first derivative of gz(u)

g=khp(u).*gz(u).*gz(u)+2.*kh(u).*dgz(u).*gz(u);
end