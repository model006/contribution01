function g = d2gz(u)
%D2GZ Compute the second derivative of the flow gravity function
%   Calculates g''(u) where g(u) = (1+er)/we(u) is the gravity function.
%
%   INPUT:
%       u : input vector (can be scalar or vector)
%
%   OUTPUT:
%       g : value(s) of the second derivative g''(u)
%
%   FORMULA:
%       The second derivative is given by:
%           g''(u) = -(1+er) * ( we(u)*epp(u) - 2*(ep(u))^2 ) / ( we(u)^3 + eps1 )
%
%       where:
%           we(u)  : base function
%           wep(u) : first derivative of we
%           wepp(u): second derivative of we (used in numerator)
%           epp(u) : second derivative of e(u)
%           ep(u)  : first derivative of e(u)
%
%   REGULARIZATION:
%       eps1 = 1e-8 is added in denominator to avoid division by zero.
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - we(u)   : base function
%           - wep(u)  : first derivative of we
%           - wepp(u) : second derivative of we
%           - ep(u)   : first derivative of e(u)
%           - epp(u)  : second derivative of e(u)
%
%   NOTE:
%       er - constant entrainment ratio (defined elsewhere)

eps1 = 1e-8;
g = -(1).*(we(u).*wepp(u)-2*(wep(u)).^2 )./( we(u)+eps1).^3;