function [u1,iterNL,kappa_hist,cond_diagnostic] = solveNonLinearLscheme( ...
    ell,L,p,t,k,ibcd,inodes,eps1,time,up,test_id,test_cond)
%SOLVENONLINEARLSCHEME L-scheme nonlinear solver with preconditioned GMRES
%   Solves the nonlinear Richards equation using the L-scheme linearization
%   with a preconditioned GMRES solver for the linear systems.
%
%   INPUTS:
%       ell        : material parameter
%       L          : L-scheme parameter
%       p          : node coordinates matrix (np x 3)
%       t          : tetrahedron connectivity matrix (nt x 4)
%       k          : time step size
%       ibcd       : indices of Dirichlet boundary nodes
%       inodes     : indices of interior (free) nodes
%       eps1       : nonlinear tolerance
%       time       : current time
%       up         : solution at previous time step
%       test_id    : test case identifier for source term
%       test_cond  : test case identifier for boundary conditions
%
%   OUTPUTS:
%       u1              : solution at current time
%       iterNL          : number of nonlinear iterations
%       kappa_hist      : history of condition numbers (reduced system)
%       cond_diagnostic : structure with conditioning and GMRES diagnostics

%   DESCRIPTION:
%       This function implements the L-scheme linearization for the
%       Richards equation in deformable porous media. At each nonlinear
%       iteration, a linear system is solved using preconditioned GMRES.
%       The condition number of the preconditioned system is estimated
%       and stored.

np = size(p,1);

% =========================
% Dirichlet (as in YOUR code)
% =========================
u0 = up;

% (you call uex here but don't use ue,you force -5)
[ue,~,~,~] = uex(p(ibcd,1),p(ibcd,2),p(ibcd,3),time,test_cond); %#ok<ASGLU>
u0(ibcd) = -5;

ubcd = u0;   % full vector np x 1

% Mass matrix (constant)
M  = kpde3dmass(p,t,1);

% Initialization
u1 = up;
u  = up;
u(ibcd) = -5;

err = 1;
iterNL = 0;
IterMaxNL = 700;

kappa_hist = zeros(1000,1);

% ============================================================
% GMRES+preconditioner settings (as in YOUR GMRES code)
% ============================================================
tol_gmres   = 1e-6;

restart_req = 200;    % requested,automatically bounded
maxit_total = 2000;   % total GMRES iterations budget (approx)

% ILU (often better for non-symmetric)
opts_ilu.type    = 'ilutp';
opts_ilu.droptol = 1e-3;
opts_ilu.udiag   = 1;

% ICHOL fallback
opts_ichol.type     = 'ict';
opts_ichol.michol   = 'on';
opts_ichol.droptol  = 1e-5;
opts_ichol.diagcomp = 1e-5;

% Preconditioner reuse
reuseEvery = 3;
Lpre = []; Upre = [];
perm = [];

% GMRES diagnostics
gmres_iter_last   = NaN;
gmres_iter_sum    = 0;
gmres_calls       = 0;
gmres_relres_last = NaN;
gmres_flag_last   = NaN;

while (err > eps1 && iterNL < IterMaxNL)

    iterNL = iterNL+1;

    % ============================================================
    % L-scheme assembly (unchanged)
    % ============================================================
    Rp  = kpde3drgd(p,t,a0(u,t),a0(u,t),a3(u,t));
    nux = a2(u,p,t);
    nuz = a4(u,p,t);
    D   = kpde3div(p,t,nux,nux,nuz);

    fh      = fex(p(:,1),p(:,2),p(:,3),time,test_id,L);
    b       = kpde3drhs(p,t,fh);
    b1      = kpde3drhs(p,t,a5(u,p,t));
    b_vg_0  = kpde3drhs(p,t,theta_vg(up));
    b_vg_1  = kpde3drhs(p,t,theta_vg(u));

    b = k*b+k*b1+L*M*u+b_vg_0-b_vg_1;
    A = L*M+k*(Rp+D);

    % ============================================================
    % Dirichlet BC+reduction (logic unchanged)
    % ============================================================
    b = b-A*ubcd;

    b(ibcd)   = [];
    A(:,ibcd) = [];
    A(ibcd,:) = [];

    % ============================================================
    % Conditioning (as in your approach)
    % ============================================================
    if iterNL == 1
        kappa = condest(A);
    else
        kappa = kappa_hist(iterNL-1);
    end

    if iterNL > numel(kappa_hist)
        kappa_hist = [kappa_hist; zeros(numel(kappa_hist),1)]; %#ok<AGROW>
    end
    kappa_hist(iterNL) = kappa;

    % ============================================================
    % Linear solve: GMRES+preconditioner+AMD permutation
    % ============================================================
    if isempty(perm) || mod(iterNL-1,reuseEvery) == 0 || isempty(Lpre)
        perm = amd(A);
        Ap   = A(perm,perm);
        bp   = b(perm);

        % Preconditioner: ILU then ICHOL fallback
        Lpre = []; Upre = [];
        try
            [Lpre,Upre] = ilu(Ap,opts_ilu);
        catch
            try
                R = ichol(Ap,opts_ichol);
                Lpre = R;
                Upre = R';
            catch
                Lpre = [];
                Upre = [];
            end
        end
    else
        Ap = A(perm,perm);
        bp = b(perm);
    end

    nA = size(Ap,1);

    % restart must be <= nA
    restart   = min(restart_req,nA);
    max_outer = max(1,ceil(maxit_total/restart));
    x0        = zeros(size(bp));

    if ~isempty(Lpre)
        [xperm,flag,relres,itGM] = gmres(Ap,bp,restart,tol_gmres,max_outer,Lpre,Upre,x0);
    else
        [xperm,flag,relres,itGM] = gmres(Ap,bp,restart,tol_gmres,max_outer,[],[],x0);
    end

    % itGM = [outer inner] -> exact total
    if numel(itGM) == 2
        itTotal = (itGM(1)-1)*restart+itGM(2);
    else
        itTotal = itGM;
    end

    gmres_calls       = gmres_calls+1;
    gmres_iter_last   = itTotal;
    gmres_iter_sum    = gmres_iter_sum+itTotal;
    gmres_relres_last = relres;
    gmres_flag_last   = flag;

    % Inverse permutation
    ui = zeros(size(b));
    ui(perm) = xperm;

    % Safety if GMRES fails
    if flag ~= 0
        ui = A\b;   % direct fallback
    end

    % Reconstruction in u
    u(inodes) = ui;
    u(ibcd)   = -5;

    % ============================================================
    % Stopping criterion (M-weighted relative error)
    % ============================================================
    du  = u-u1;
    err = sqrt((du'*M*du)/max((u1'*M*u1),1e-12));
    u1  = u;

end

kappa_hist = kappa_hist(1:iterNL);

% ============================================================
% Output diagnostics
% ============================================================
cond_diagnostic.final_kappa = kappa_hist(end);
cond_diagnostic.max_kappa   = max(kappa_hist);
cond_diagnostic.mean_kappa  = mean(kappa_hist);

cond_diagnostic.gmres_it_last   = gmres_iter_last;
cond_diagnostic.gmres_it_avg    = gmres_iter_sum/max(gmres_calls,1);
cond_diagnostic.gmres_relres    = gmres_relres_last;
cond_diagnostic.gmres_flag_last = gmres_flag_last;
cond_diagnostic.gmres_calls     = gmres_calls;

if iterNL >= IterMaxNL
    warning('Non-convergence after %d iterations (err=%e)',IterMaxNL,err);
end

end

