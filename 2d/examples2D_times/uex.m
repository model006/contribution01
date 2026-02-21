function [ue, duex_val, duez_val] = uex(xs,zs,ts)
%UEX Exact time-dependent solution for Richards 3D test cases
%   Computes the exact solution and its spatial derivatives for a
%   manufactured solution used in code verification and convergence studies.
%
%   INPUTS:
%       xs : x-coordinate(s) - can be scalar or vector
%       zs : z-coordinate(s) - can be scalar or vector (same size as xs)
%       ts : time value (scalar)
%
%   OUTPUTS:
%       ue        : Exact solution value u(x,z,t) = -exp(-2t)·x·(x-1)·z·(z-1)
%       duex_val  : Partial derivative ∂u/∂x = -exp(-2t)·(2x-1)·z·(z-1)
%       duez_val  : Partial derivative ∂u/∂z = -exp(-2t)·x·(x-1)·(2z-1)
%
%   MATHEMATICAL FORM:
%       u(x,z,t) = -exp(-2t)·x(x-1)·z(z-1)
%       This function satisfies homogeneous Dirichlet boundary conditions
%       on all boundaries (u=0 at x=0, x=1, z=0, z=1) and decays
%       exponentially in time.
%
%   USAGE:
%       This exact solution is typically used with test_cond = 1 or 3
%       for method of manufactured solutions (MMS) verification with
%       time-dependent problems.

ue = -exp(-2*ts).*xs.*(xs-1).*zs.*(zs-1);
duex_val = -exp(-2*ts).*(2*xs-1).*zs.*(zs-1);
duez_val = -exp(-2*ts).*xs.*(xs-1).*(2*zs-1);


