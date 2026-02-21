function g = dg2(u)
%DG2 Compute the first derivative of function g2(u)
%   Calculates dg2/du where g2(u) = g1(u)*gz(u)
%
%   INPUT:
%       u : input vector (can be scalar or vector)
%
%   OUTPUT:
%       g : column vector containing the first derivative dg2/du
%
%   FORMULA:
%       Using the product rule:
%           dg2/du = (dg1/du)*gz(u)+g1(u)*(dgz/du)
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - g1(u)  : base function
%           - dg1(u) : first derivative of g1
%           - gz(u)  : gravity function
%           - dgz(u) : first derivative of gz

g = dg1(u).*gz(u)+g1(u).*dgz(u);