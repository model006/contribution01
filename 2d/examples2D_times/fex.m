function fval = fex(x,z,t)
%FEX Source term for time-dependent manufactured solution in Richards 3D
%   Computes the right-hand side source term f(x,z,t) corresponding to the
%   time-dependent manufactured solution u(x,z,t)=-exp(-2t)·x·(x-1)·z·(z-1)
%   for code verification.
%
%   INPUTS:
%       x : x-coordinate(s) - can be scalar or vector
%       z : z-coordinate(s) - can be scalar or vector (same size as x)
%       t : time value (scalar)
%
%   OUTPUT:
%       fval : Source term value(s) satisfying the Richards equation:
%              ∂u/∂t - divergence_of_flux = f(x,z,t)
%
%   MATHEMATICAL FORMULATION:
%       The source term is obtained by inserting the manufactured solution
%       into the Richards equation and computing the residual:
%           f = dut - [g1(u)·(kh(u)·uxx+khp(u)·ux·ux) + 
%                      g2(u)·(ell(u)·uzz+ellp(u)·uz·uz+ellp(u)·uz)]
%
%       where:
%           dut      : time derivative ∂u/∂t = 2·exp(-2t)·x·(x-1)·z·(z-1)
%           ux, uz   : first spatial derivatives
%           uxx, uzz : second spatial derivatives
%           kh, ell  : permeability functions
%           khp, ellp: derivatives of permeability functions
%           g1, g2   : scaling functions
%
%   DEPENDENCIES:
%       Requires auxiliary functions:
%           - g1(u), g2(u)    : scaling functions
%           - kh(u), khp(u)    : horizontal permeability and derivative
%           - ell(u), ellp(u)  : vertical permeability and derivative
%
%   USAGE:
%       Used in method of manufactured solutions (MMS) verification
%       for time-dependent problems with test_cond = 1 or 3.

% Manufactured solution: u(x,z,t) = -exp(-2t)·x·(x-1)·z·(z-1)
u=-exp(-2*t).*x.*(x-1).*z.*(z-1);
dut=2*exp(-2*t).*x.*(x-1).*z.*(z-1);  % time derivative

% First spatial derivatives
ux=-exp(-2*t).*(2*x-1).*z.*(z-1);
uz=-exp(-2*t).*x.*(x-1).*(2*z-1);

% Second spatial derivatives
uxx=-2*exp(-2*t).*z.*(z-1);
uzz=-2*exp(-2*t).*x.*(x-1);

% Ensure column vectors for consistent handling
u=u(:);   dut=dut(:);
ux=ux(:); uz=uz(:);
uxx=uxx(:); uzz=uzz(:);

% Compute flux divergence components
fxyval=g1(u).*(kh(u).*uxx+khp(u).*(ux.^2));
fz1val=g2(u).*(ell(u).*uzz+ellp(u).*(uz.^2));
fz2val=g2(u).*ellp(u).*uz;

% Assemble source term: time derivative minus flux divergence
fval=dut-(fxyval+fz1val+fz2val);