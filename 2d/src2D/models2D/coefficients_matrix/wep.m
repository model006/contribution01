function g=wep(Theta)
%WEP Compute the first derivative of function we(Theta)
%   Calculates wep(Theta) = d(we)/dTheta where we(Theta) = 1 + e(Theta)
%
%   INPUT:
%       Theta : input variable (scalar or vector)
%
%   OUTPUT:
%       g     : first derivative values at Theta
%
%   FORMULA:
%       Since we(Theta) = 1 + e(Theta), its first derivative is simply
%       the first derivative of e(Theta):
%           wep(Theta) = ep(Theta)
%
%   DEPENDENCIES:
%       Requires auxiliary function:
%           - ep(Theta) : first derivative of extraction function e(Theta)

g=ep(Theta);
end