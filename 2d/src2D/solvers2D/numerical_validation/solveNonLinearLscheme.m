function [u1,iterNL,kappa_hist,cond_diagnostic] = solveNonLinearLscheme( ...
    ell,L,p,t,k,ibcd,inodes,eps1,time,up)
%SOLVENONLINEARLSCHEME L-scheme nonlinear solver with preconditioned GMRES
%   Solves the nonlinear Richards equation in deformable porous media
%   using the L-scheme linearization with a preconditioned GMRES solver
%   for the linear systems.
%
%   INPUTS:
%       ell      : material parameter
%       L        : L-scheme parameter
%       p        : node coordinates matrix (np x 2)
%       t        : triangle connectivity matrix (nt x 3)
%       k        : time step size
%       ibcd     : indices of Dirichlet boundary nodes
%       inodes   : indices of interior (free) nodes
%       eps1     : nonlinear tolerance
%       time     : current time
%       up       : solution at previous time step
%
%   OUTPUTS:
%       u1              : solution at current time
%       iterNL          : number of nonlinear iterations
%       kappa_hist      : history of condition numbers
%       cond_diagnostic : structure with conditioning and GMRES diagnostics
%

%   DESCRIPTION:
%       This function implements the L-scheme linearization for the
%       Richards equation in deformable porous media. At each nonlinear
%       iteration, a linear system is solved using preconditioned GMRES.
%       The condition number of the preconditioned system is estimated
%       and stored.
%
%   See also: GMRES, ILU

np = size(p,1);

[ue,~,~] = uex(p(:,1),p(:,2),time);
ubcd = ue(ibcd);

M = kpde2dmass(p,t,1);

err = 1;iterNL = 0;IterMaxNL = 50000;
kappa_hist = zeros(1000,1);

u1 = up;
u  = u1;

% ============================================================
% GMRES / ILU settings (adjustable)
% ============================================================
tol_gmres   = 1e-6;
maxit_gmres = 300;    % number of iterations (per restart)
restart_gmres = 50;   % Krylov subspace dimension (restart)

opts_ilu.type    = 'ilutp';
opts_ilu.droptol = 1e-3;
opts_ilu.udiag   = 1;

% Preconditioner reuse option
reuseEvery = 3;  % recompute ILU every 3 iterations
Lilu = [];Uilu = [];
perm = [];

% GMRES diagnostics
gmres_iter_last   = NaN;
gmres_iter_sum    = 0;
gmres_calls       = 0;
gmres_relres_last = NaN;
gmres_flag_last   = NaN;

while (err > eps1 && iterNL < IterMaxNL)
    iterNL = iterNL+1;

    % --- L-scheme assembly ---
    Rp  = kpde2drgd(p,t,a0(u,t),a3(u,t));
    nux = a2(u,p,t);
    nuz = a4(u,p,t);
    D   = kpde2div(p,t,nux,nuz);

    fh = fex(p(:,1),p(:,2),time);
    b  = kpde2drhs(p,t,fh);
    b1 = kpde2drhs(p,t,a5(u,p,t));

    b = (1/k)*M*up+b+b1+L*M*u;
    A = (1/k)*M+L*M+(Rp+D);

    % --- Dirichlet boundary conditions ---
    ubcd_full = zeros(np,1);
    ubcd_full(ibcd) = ubcd;

    b = b - A*ubcd_full;
    b(ibcd)   = [];
    A(:,ibcd) = [];
    A(ibcd,:) = [];

    % --- Conditioning (optional) ---
    if iterNL == 1
        kappa = condest(A);
    else
        kappa = kappa_hist(iterNL-1);
    end
    if iterNL > numel(kappa_hist)
        kappa_hist = [kappa_hist;zeros(numel(kappa_hist),1)];
    end
    kappa_hist(iterNL) = kappa;

    % ============================================================
    % Linear solve: GMRES+ILU (with AMD permutation)
    % ============================================================
    if isempty(Lilu) || isempty(Uilu) || isempty(perm) || mod(iterNL-1,reuseEvery) == 0
        perm = amd(A);
        Ap   = A(perm,perm);
        bp   = b(perm);

        % ILU may fail -> fallback with adjusted droptol
        try
            [Lilu,Uilu] = ilu(sparse(Ap),opts_ilu);
        catch
            opts_ilu2 = opts_ilu;
            opts_ilu2.droptol = 1e-2;
            [Lilu,Uilu] = ilu(sparse(Ap),opts_ilu2);
        end
    else
        Ap = A(perm,perm);
        bp = b(perm);
    end

    x0 = zeros(size(bp));

    % GMRES returns iter = [outer inner]
    [xperm,flag,relres,iterGMRES] = gmres(Ap,bp,restart_gmres,tol_gmres,maxit_gmres,Lilu,Uilu,x0);

    % GMRES statistics
    gmres_calls       = gmres_calls+1;
    gmres_flag_last   = flag;
    gmres_relres_last = relres;

    if numel(iterGMRES) == 2
        it_used = iterGMRES(1)*restart_gmres+iterGMRES(2);
    else
        it_used = iterGMRES;
    end
    gmres_iter_last = it_used;
    gmres_iter_sum  = gmres_iter_sum+it_used;

    % Inverse permutation
    ui_perm = xperm;
    ui = zeros(size(b));
    ui(perm) = ui_perm;

    % If GMRES failed,fallback to direct solver (safety)
    if flag ~= 0
        ui = A \ b;
    end

    % --- Reconstruction ---
    u(inodes) = ui;

    % --- Relative L2(M) error ---
    du  = u - u1;
    err = sqrt((du'*M*du) / max((u1'*M*u1),1e-12));
    u1  = u;
end

kappa_hist = kappa_hist(1:iterNL);

cond_diagnostic.final_kappa = kappa_hist(end);
cond_diagnostic.max_kappa   = max(kappa_hist);
cond_diagnostic.mean_kappa  = mean(kappa_hist);

% GMRES diagnostics
cond_diagnostic.gmres_it_last   = gmres_iter_last;
cond_diagnostic.gmres_it_avg    = gmres_iter_sum / max(gmres_calls,1);
cond_diagnostic.gmres_relres    = gmres_relres_last;
cond_diagnostic.gmres_flag_last = gmres_flag_last;
cond_diagnostic.gmres_calls     = gmres_calls;

if iterNL >= IterMaxNL
    warning('Non-convergence after %d iterations (err=%e)',IterMaxNL,err);
end

end