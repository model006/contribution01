function fval = fex(x,z,t)
%FEX Source term for manufactured solution in Richards 3D
%   Computes the right-hand side source term f(x,z,t) for code verification
%   using the manufactured solution u(x,z) = -x·(x-1)·z·(z-1).
%
%   INPUTS:
%       x : x-coordinate(s) - can be scalar or vector
%       z : z-coordinate(s) - can be scalar or vector (same size as x)
%       t : time value (scalar) - included for interface compatibility
%
%   OUTPUT:
%       fval : Source term value(s) such that:
%              time_derivative - divergence_of_flux = f(x,z,t)
%
%   MATHEMATICAL FORMULATION:
%       The source term is obtained by inserting the manufactured solution
%       into the Richards equation and computing the residual:
%           f = -[g1(u)·(kh(u)·uxx + khp(u)·ux·ux) + 
%                 g2(u)·(ell(u)·uzz + ellp(u)·uz·uz + ellp(u)·uz)]
%
%       where:
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
%       with test_cond = 1 or 3.

% Manufactured solution: u(x,z) = -x(x-1)z(z-1)
u = -x.*(x-1).*z.*(z-1);
dut = 0*u;  % time derivative (zero for steady-state solution)

% First spatial derivatives
ux = -(2*x-1).*z.*(z-1);
uz = -x.*(x-1).*(2*z-1);

% Second spatial derivatives
uxx = -2.*z.*(z-1);
uzz = -2.*x.*(x-1);

% Ensure column vectors for consistent handling
u = u(:);   dut = dut(:);
ux = ux(:);  uz = uz(:);
uxx = uxx(:); uzz = uzz(:);

% Compute source term components
fxyval = g1(u).*(kh(u).*uxx + khp(u).*(ux.^2));
fz1val = g2(u).*(ell(u).*uzz + ellp(u).*(uz.^2));
fz2val = g2(u).*ellp(u).*uz;

% Assemble final source term (negative sign from equation formulation)
fval = -(fxyval + fz1val + fz2val);
end