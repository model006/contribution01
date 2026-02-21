function g=wepp(Theta)
%WEPP Compute the second derivative of function we(Theta)
%   Calculates wepp(Theta) = d²(we)/dTheta² where we(Theta) = 1 + e(Theta)
%
%   INPUT:
%       Theta : input variable (scalar or vector)
%
%   OUTPUT:
%       g     : second derivative values at Theta
%
%   FORMULA:
%       Since we(Theta) = 1 + e(Theta), its second derivative is simply
%       the second derivative of e(Theta):
%           wepp(Theta) = epp(Theta)
%
%   DEPENDENCIES:
%       Requires auxiliary function:
%           - epp(Theta) : second derivative of extraction function e(Theta)

g=epp(Theta);
end