function g=we(Theta)
%WE Compute the function we(Theta) = 1 + e(Theta)
%   Evaluates the base function we which combines a constant term
%   with the extraction function e(Theta).
%
%   INPUT:
%       Theta : input variable (scalar or vector)
%
%   OUTPUT:
%       g     : value(s) of we at Theta
%
%   FORMULA:
%       we(Theta) = 1 + e(Theta)
%
%   DEPENDENCIES:
%       Requires auxiliary function:
%           - e(Theta) : extraction function (void ratio)

g=1+e(Theta);
end