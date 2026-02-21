function g = d2g2(u)
%D2G2 Compute the second derivative of function g2(u)
%   Calculates d²g2/du² where g2(u) = g1(u) * gz(u)
%
%   INPUT:
%       u : input vector (can be scalar or vector)
%
%   OUTPUT:
%       g : column vector containing the second derivative d²g2/du²
%
%   FORMULA:
%       Using the product rule for second derivative:
%           d²g2/du² = (d²g1/du²) * gz(u) 
%                    + 2 * (dg1/du) * (dgz/du) 
%                    + g1(u) * (d²gz/du²)
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - g1(u)   : base function
%           - dg1(u)  : first derivative of g1
%           - d2g1(u) : second derivative of g1
%           - gz(u)   : gravity function
%           - dgz(u)  : first derivative of gz
%           - d2gz(u) : second derivative of gz

g = d2g1(u).*gz(u) + 2*dg1(u).*dgz(u) + g1(u).*d2gz(u);