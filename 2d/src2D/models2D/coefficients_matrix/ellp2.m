function g=ellp2(u)
%ELLP2 Compute the second derivative of vertical permeability function ell(u)
%   Calculates d²(ell)/du² where ell(u) = kh(u) * (gz(u))^2
%
%   INPUT:
%       u : input vector (can be scalar or vector)
%
%   OUTPUT:
%       g : column vector containing ell''(u) values
%
%   FORMULA:
%       Using repeated application of product and chain rules:
%           ell''(u) = kh''(u)*(gz(u))^2 
%                   +kh'(u)*(2*gz'(u)*gz(u))
%                   +2*kh'(u)*gz'(u)*gz(u)
%                   +2*kh(u)*gz''(u)*gz(u)
%                   +2*kh(u)*(gz'(u))^2
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - kh(u)   : horizontal permeability function
%           - khp(u)  : first derivative of kh(u)
%           - khpp(u) : second derivative of kh(u)
%           - gz(u)   : gravity function
%           - dgz(u)  : first derivative of gz(u)
%           - d2gz(u) : second derivative of gz(u)

g=khpp(u).*gz(u).^2+khp(u).*(2*dgz(u).*gz(u))+2.*khp(u).*dgz(u).*gz(u)+2*kh(u).*d2gz(u).*gz(u)+2*kh(u).*dgz(u).^2;
end