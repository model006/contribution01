function [ue,duex_val,duey_val,duez_val] = uex(x,y,z,t,test_cond)
% UEX  Manufactured/benchmark solution and its spatial derivatives (3D).
%
% This function provides an analytical (or prescribed) field u_e(x,y,z,t)
% used for code verification (manufactured solutions) and for controlled
% test scenarios. Depending on test_cond, the function returns u_e and the
% exact partial derivatives (du/dx, du/dy, du/dz) when available.
%
% INPUTS
%   x,y,z     Spatial coordinates (arrays of same size).
%   t         Time (scalar).
%   test_cond Case selector:
%               1: Polynomial manufactured solution with time factor (1-t).
%               2: Polynomial manufactured solution (product form) with (1-t).
%               3: Prescribed smooth localized “bubble” (derivatives not exact -> set to zero).
%               4: Smooth localized “bubble” with analytic gradient inside the active region.
%
% OUTPUTS
%   ue        u_e evaluated at (x,y,z,t), returned as a column vector.
%   due*_val  Exact spatial derivatives (column vectors). If not available,
%             they are set to zero (case 3).
%
% NOTE
%   Cases (1)–(2) are intended for convergence studies (known exact gradients).
%   Cases (3)–(4) define localized fields with geometric masks to mimic
%   realistic heterogeneous configurations.
%
% -------------------------------------------------------------------------

if nargin < 5, test_cond = 1; end

switch test_cond

    case 1
        % Case 1: smooth polynomial field with separable time factor (1-t)
        time_factor = (1-t);
        ue = -(1-t)*x.*(1-x).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;

        % Exact derivatives
        duex_val = -time_factor.*(1-2*x).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;
        duey_val = -time_factor.*x.*(1-x).*2.*y.*(1-y).*(1-2*y).*z.^2.*(1-z).^2;
        duez_val = -time_factor.*x.*(1-x).*y.^2.*(1-y).^2.*2.*z.*(1-z).*(1-2*z);

    case 2
        % Case 2: polynomial manufactured solution with time factor (1-t)
        ue = -(1-t).*x.*y.*z.*(x-1).*(y-1).*(z-1);

        % Exact derivatives
        duex_val = -(1-t).*(2*x-1).*y.*(y-1).*z.*(z-1);
        duey_val = -(1-t).*x.*(x-1).*(2*y-1).*z.*(z-1);
        duez_val = -(1-t).*x.*(x-1).*y.*(y-1).*(2*z-1);

    case 3
        % Case 3: prescribed localized smooth field (masked bubble)
        % No exact derivatives used here -> returned as zeros.
        ur = -5;

        R0sq = 0.1;  % Radius squared controlling the support size
        r2 = (x-0.5).^2+(y-0.5).^2+(z-0.5).^2;

        denom = 1-exp(-R0sq);
        S = (1-exp(r2-R0sq))./denom;

        % Geometric mask (localized “door-like” region)
        mask = ((abs(y-0.5) > 0.09) | (z > 0.5)) & (r2 <= R0sq);
        S = S.*mask;

        u_ext    = ur;
        u_centre = -1;
        ue = ur+(u_centre-u_ext)*S;

        % Derivatives not defined/used for this prescribed field
        duex_val = zeros(size(ue));
        duey_val = zeros(size(ue));
        duez_val = zeros(size(ue));

    case 4
        % Case 4: localized smooth bubble with analytic gradient
        cx = 0.4; cy = 0.4; cz = 0.4;

        us = 1.26;     % interior value
        ur = 0.0000;   % exterior value
        R2 = 0.09;     % radius^2

        dx = x-cx;  dy = y-cy;  dz = z-cz;
        r2 = dx.^2+dy.^2+dz.^2;
        r  = sqrt(r2);

        % Masked region (geometry filter)
        mask = ((abs(x-cx) > 0.09) | (y > 0.5)) & (r <= 0.2);

        denom  = 1-exp(-R2);
        inside = (r2 < R2) & mask;

        % Field definition
        ue = ur.*ones(size(r2));
        ue(inside) = (us-ur).*(0.5-exp(r2(inside)-R2)./denom)+ur;

        % Gradient (only inside the active region)
        duex_val = zeros(size(r2));
        duey_val = zeros(size(r2));
        duez_val = zeros(size(r2));

        coef = -(us-ur).*exp(r2(inside)-R2)./denom;  % dU/dr2
        duex_val(inside) = 2.*coef.*dx(inside);
        duey_val(inside) = 2.*coef.*dy(inside);
        duez_val(inside) = 2.*coef.*dz(inside);

    otherwise
        error('uex: unknown test_cond (%d). Use 1, 2, 3 or 4.',test_cond);
end

% Return column vectors (consistent with FEM assembly conventions)
ue       = ue(:);
duex_val = duex_val(:);
duey_val = duey_val(:);
duez_val = duez_val(:);