function m = design_metrics(X, info)
%DESIGN_METRICS Design-quality numbers for the stimulus regressors of X.
%   m = estfmri.design_metrics(X, info)
%   X, info come from estfmri.design_matrix. For each stimulus regressor k
%   (columns info.nbase+1 : end) it returns:
%
%     m.vif(k)        Variance inflation factor = 1/(1 - R^2_k), where R^2_k
%                     is the (centred) R^2 of regressing column k on all
%                     other columns of X plus an intercept. 1 = independent
%                     of the rest; > 5 high; > 10 severe.
%     m.se(k)         Standard error of beta_k per unit noise SD:
%                     sqrt([(X'X)^-1]_kk). With white noise of SD sigma,
%                     SD(beta_k_hat) = sigma * m.se(k).
%     m.efficiency(k) 1 / m.se(k)^2  (inverse variance; larger is better).
%     m.max_abs_r(k)  Largest |r| with another stimulus regressor.
%
%   and for the whole design:
%     m.cond          Condition number of X (scale-dependent; Inf if rank
%                     deficient).
%     m.rank, m.ncols Rank and number of columns of X.
%     m.rank_deficient  true if some column is a linear combination of others
%                     (then se/efficiency are Inf/0 for affected betas).
%     m.level{k}      'ok' | 'high' (VIF > 5) | 'severe' (VIF > 10).
%     m.warnings      cellstr of human-readable warnings.

K = info.nstim;
P = size(X, 2);
cols = info.nbase + (1:K);
tol = max(size(X)) * eps(norm(X));

m.ncols = P;
m.rank = rank(X, tol);
m.rank_deficient = m.rank < P;
if m.rank_deficient
    m.cond = Inf;
else
    m.cond = cond(X);
end

% --- SE per unit noise (only meaningful for estimable betas) -------------
m.se = Inf(1, K);
if ~m.rank_deficient
    XtXi = inv(X' * X);
    m.se = sqrt(diag(XtXi(cols, cols)))';
else
    % beta_k is estimable iff e_k is in the row space of X
    N = null(X);
    for n = 1:K
        if all(abs(N(cols(n), :)) < 1e-8)
            % estimable: use the pseudo-inverse
            Xp = pinv(X);
            m.se(n) = norm(Xp(cols(n), :));
        end
    end
end
m.efficiency = 1 ./ m.se.^2;

% --- VIF ------------------------------------------------------------------
m.vif = zeros(1, K);
for n = 1:K
    k = cols(n);
    y = X(:, k);
    Z = X(:, setdiff(1:P, k));
    if ~any(all(abs(Z - Z(1, :)) < 1e-12, 1))   % no constant column yet
        Z = [Z, ones(size(X, 1), 1)]; %#ok<AGROW>
    end
    yc = y - mean(y);
    sst = yc' * yc;
    if sst == 0
        m.vif(n) = Inf;          % constant regressor: not identifiable
        continue;
    end
    b = lsqminnorm(Z, y);        % no warning when Z itself is collinear
    r = y - Z * b;
    r2 = 1 - (r' * r) / sst;
    if r2 >= 1 - 1e-12
        m.vif(n) = Inf;
    else
        m.vif(n) = 1 / (1 - r2);
    end
end

% --- correlations between stimulus regressors -------------------------------
if K > 1
    R = corrcoef(X(:, cols));
    R(1:K+1:end) = 0;
    m.max_abs_r = max(abs(R), [], 2)';
else
    m.max_abs_r = 0;
end

% --- levels and warnings ----------------------------------------------------
m.level = repmat({'ok'}, 1, K);
m.level(m.vif > 5) = {'high'};
m.level(m.vif > 10) = {'severe'};
m.warnings = {};
if m.rank_deficient
    m.warnings{end+1} = sprintf('X is rank deficient (rank %d of %d columns): some betas cannot be estimated.', ...
        m.rank, P);
end
end
