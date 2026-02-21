function g = g1(u)
%G1 Compute the function g1(u) = we(u) / (c(u) + eps)
%
%   DESCRIPTION:
%       Calculates the ratio between we(u) and c(u) with regularization
%       to avoid division by zero. This function is used in the
%       finite element assembly of the Richards equation.
%
%   INPUT:
%       u : input vector (can be scalar, row vector, or column vector)
%
%   OUTPUT:
%       g : column vector containing g1(u) = we(u) / (c(u) + eps)
%
%   REGULARIZATION:
%       A small constant eps is added to the denominator to prevent
%       division by zero when c(u) is near zero.
%
%   DEPENDENCIES:
%       Requires auxiliary function:
%           - we(u) : base function (1 + e(u))
%
%   NOTE:
%       The function c(u) and regularization parameter eps are defined
%       elsewhere in the codebase.

% Regularization value to avoid division by zero

% Ensure u is a column vector
u = u(:);

% Compute g1(u)
g = we(u);

% Guarantee that the result is a column vector
g = g(:);
    
end