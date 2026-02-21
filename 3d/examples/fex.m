function fval = fex(x,y,z,t,test_id)
%FEX Evaluate right-hand side source term for nonlinear anisotropic PDE
%   f = c(u)*u_t-[div_{xy}(g1(u)*kh(u)*grad_{xy}u)+
%                   div_z(g2(u)*ell(u)*grad_z u)+
%                   g2(u)*ell'(u)*u_z]
%
%   INPUTS
%       x,y,z,t : space-time coordinates (arrays, automatically flattened)
%       test_id : integer (1,2,3) selecting manufactured solution
%       L       : domain size (unused, kept for interface compatibility)
%
%   OUTPUT
%       fval    : column vector of source term values f(x,y,z,t)
%
%   DEPENDENCIES
%       Requires functions: c(u), g1(u), g2(u), kh(u), khp(u), ell(u), ellp(u)

if nargin < 5, test_id = 1; end

switch test_id    
    case 1
        % -------------------------------------------------------------
        % TEST 1: Time-dependent polynomial manufactured solution
        % u(x,y,z,t) = (1-t)*x*(1-x)*y^2*(1-y)^2*z^2*(1-z)^2
        % -------------------------------------------------------------
        
        % Solution and time derivative
        u   = -(1-t).*x.*(1-x).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;
        dut =  x.*(1-x).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;
        
        % First derivatives (exact)
        duex = -(1-t).*(1-2.*x).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;
        duey = -(1-t).*x.*(1-x).*2.*y.*(1-y).*(1-2.*y).*z.^2.*(1-z).^2;
        duez = -(1-t).*x.*(1-x).*y.^2.*(1-y).^2.*2.*z.*(1-z).*(1-2.*z);
        
        % Second derivatives (exact)
        d2y  = 2.*(1-y).^2-8.*y.*(1-y)+2.*y.^2;
        d2z  = 2.*(1-z).^2-8.*z.*(1-z)+2.*z.^2;
        
        dfxx = -(1-t).*(-2).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;
        dfyy = -(1-t).*x.*(1-x).*d2y.*z.^2.*(1-z).^2;
        dfzz = -(1-t).*x.*(1-x).*y.^2.*(1-y).^2.*d2z;
        
        % Flatten to column vectors
        u    = u(:);    dut  = dut(:);
        duex = duex(:); duey = duey(:); duez = duez(:);
        dfxx = dfxx(:); dfyy = dfyy(:); dfzz = dfzz(:);
        
        % Assemble source term: f = c(u)*u_t-(fxy+fz1+fz2)
        fxy = g1(u).*(kh(u).*(dfxx+dfyy)+khp(u).*(duex.^2+duey.^2));
        fz1 = g2(u).*(ell(u).*dfzz+ellp(u).*(duez.^2));
        fz2 = g2(u).*ellp(u).*duez;
        
        fval = c(u).*dut-(fxy+fz1+fz2);        
    case 2
        % -------------------------------------------------------------
        % TEST 2: Steady-state cubic manufactured solution
        % u(x,y,z,t) = x*y*z*(x-1)*(y-1)*(z-1)
        % -------------------------------------------------------------
        
        % Solution and time derivative (steady-state)
        u   = x.*y.*z.*(x-1.0).*(y-1.0).*(z-1.0);
        dut = x.*y.*z.*(x-1.0).*(y-1.0).*(z-1.0);
        
        % First derivatives (exact)
        duex = (2.*x-1.0).*y.*(y-1.0).*z.*(z-1.0);
        duey = x.*(x-1.0).*(2.*y-1.0).*z.*(z-1.0);
        duez = x.*(x-1.0).*y.*(y-1.0).*(2.*z-1.0);
        
        % Second derivatives (exact)
        dfxx = 2.0.*y.*z.*(y-1.0).*(z-1.0);
        dfyy = 2.0.*x.*z.*(x-1.0).*(z-1.0);
        dfzz = 2.0.*x.*y.*(x-1.0).*(y-1.0);
        
        % Flatten to column vectors
        u    = u(:);    dut  = dut(:);
        duex = duex(:); duey = duey(:); duez = duez(:);
        dfxx = dfxx(:); dfyy = dfyy(:); dfzz = dfzz(:);
        
        % Assemble source term
        fxy = g1(u).*(kh(u).*(dfxx+dfyy)+khp(u).*(duex.^2+duey.^2));
        fz1 = g2(u).*(ell(u).*dfzz+ellp(u).*(duez.^2));
        fz2 = g2(u).*ellp(u).*duez;
        
        fval = c(u,ell).*dut-(fxy+fz1+fz2);        
    case 3
        % -------------------------------------------------------------
        % TEST 3: Constant zero source term
        %         Used for homogeneous equilibrium verification
        % -------------------------------------------------------------
        fval = zeros(size(x(:)));        
    otherwise
        error('fex: invalid test_id (%d). Must be 1,2,3.', test_id);
        
end