# fmri_estoymation

Tools for exploring fMRI event-related designs and how well a GLM can recover
the betas: build the design matrix from stimulus timings, inspect regressors and
their collinearity, and (coming next) simulate noisy data and re-estimate.

The repository has two parts:

| Folder | What it is | Status |
|---|---|---|
| `estfmri/` | **estfmri toolbox**: plain MATLAB functions + a `uifigure` app. No AFNI, no GUIDE, runs on Windows. | Active (branch `develop`) |
| `estfmriTOY_V3_PubV_1/` | Original 2013–14 GUIDE tool (R. Martinez-Cancino, Maryland Neuroimaging Center). Calls AFNI `3dDeconvolve` through `unix()`. | Legacy, kept for reference |

## Requirements

- MATLAB R2020a or newer (tested on R2024a). No extra toolboxes.
- The legacy tool additionally needs Linux/macOS with AFNI on the `PATH`, and the
  Statistics, Communications, Image Processing and Deep Learning toolboxes.

## Tutorial

All snippets assume MATLAB's current folder is the repository root.

### 1. Open the app

```matlab
addpath('estfmri');
estfmri.app
```

Then choose **File > Open...** (Ctrl+O) and pick
`estfmriTOY_V3_PubV_1/ER_tutorial_config_file.mat` (the tutorial: 4 stimulus
classes, TR = 2 s, 210 volumes, 1 run). Timing files are found in the
`timings/` folder next to it.

- **Acquisition** (top left): repetition time, volumes per run, runs and
  baseline drift (the AFNI `-polort` order; *Auto* shows the order it picks).
- **Stimulus classes**: one row per class with its response model, **VIF** and
  **SE/σ** (see step 4); high and severe VIF cells are coloured. Double-click a
  name to rename it; **+ − ↑ ↓** add a class from a timing file, remove it or
  reorder.
- **Response model** (bottom left): the selected class's model (Block, Gamma,
  MION) with labelled parameters in seconds and a live preview of the curve.
- **Design tab** (right): choose a view from the list (stimuli, onsets, HRF
  shapes, regressors, design matrix, correlation, design quality). Options for
  the current view sit above the plot; **Pop out** opens it in its own window.
  In the correlation view, click a cell to compare that pair of regressors.
- **Status bar**: design summary, warning count (hover for the list) and save
  state. The title shows the file name, with `*` for unsaved changes.
- Every edit rebuilds the design matrix immediately.
- **File > Import timing files...** (Ctrl+I) starts a design from `.1D`
  files; **Save** (Ctrl+S) stores everything, onsets included, in one `.mat`;
  **Export report...** (Ctrl+E) writes the config, every view as PNG and a
  `summary.txt` with the metrics to a folder.

### 2. Same thing from a script

```matlab
addpath('estfmri');
s   = load('estfmriTOY_V3_PubV_1/ER_tutorial_config_file.mat');
cfg = estfmri.cfg_from_legacy_opts(s.opts, 'estfmriTOY_V3_PubV_1/timings');

[X, labels, info] = estfmri.design_matrix(cfg);   % 210 x 4, no AFNI needed

estfmri.plot_regressors(cfg, X, info, 'ShowStimuli', true);
estfmri.plot_correlation(X, labels, info);
```

`X` has the same column order as AFNI's `3dDeconvolve -x1D`: baseline columns
first, then one column per stimulus class (`info.nbase`, `info.nstim`).

### 3. Use your own timing files

Timing files use AFNI's `-stim_times` format: one file per stimulus class, one
row per run, onset times in seconds from the start of that run (`*` = no events
in that run).

```text
10 15.4 23.5 37.9
44.0 59.3 66.9
```

Build a `cfg` struct directly:

```matlab
cfg.TR       = 2;      % seconds
cfg.npts     = 210;    % volumes per run
cfg.num_runs = 1;
cfg.polort   = 'A';    % baseline: -1 (none), 'A' (auto) or a degree 0..5

on = estfmri.read_timings('estfmriTOY_V3_PubV_1/timings/S_cue.1D');
cfg.stims(1) = struct('name', 'cue',  'onsets', {on(1)}, 'hrf', 'BLOCK(0.75,1)');
on = estfmri.read_timings('estfmriTOY_V3_PubV_1/timings/S_pict.1D');
cfg.stims(2) = struct('name', 'pict', 'onsets', {on(1)}, 'hrf', 'GAM');

[X, labels, info] = estfmri.design_matrix(cfg);
estfmri.app(cfg);      % or open it in the app
```

`onsets` must hold one cell per run (`on(1:cfg.num_runs)`).

Response models (AFNI definitions):

| HRF string | Meaning | Checked against AFNI |
|---|---|---|
| `BLOCK(d,p)` | `d`-second block, peak scaled to `p` (`BLOCK(d)`: unscaled) | yes (max error 1e-5) |
| `GAM(p,q)`, `GAM` | gamma variate, peak 1 at `p·q` (default 8.6, 0.547) | not yet |
| `GAM(p,q,d)` | gamma convolved with a `d`-second block | not yet |
| `MION(d)`, `MIONN(d)` | MION contrast-agent response, and its negative | not yet |

### 4. Is the design any good?

```matlab
m = estfmri.design_metrics(X, info);
m.vif    % variance inflation per stimulus regressor (1 = independent; >5 high; >10 severe)
m.se     % SD of the estimated beta per unit noise SD
m.cond   % condition number of X
estfmri.plot_design_metrics(m, labels(info.nbase+1:end));
```

With white noise of standard deviation σ, each estimated beta will scatter
with standard deviation `σ * m.se(k)`. For the tutorial design every VIF is
about 1.8 (the cue and picture regressors correlate up to |r| = 0.62), so each
beta's variance is roughly doubled compared with an orthogonal design.

### 5. Run the tests

```matlab
addpath('estfmri');
results = runtests('estfmri/tests');
table(results)
```

The suite checks the native design matrix against the AFNI output stored in
the tutorial config, the plots, the metrics (including a Monte Carlo check of
the SE) and the app (run headless).

## Toolbox layout

```text
estfmri/
  +estfmri/            package: call as estfmri.<name>
    design_matrix.m    cfg -> X (baseline + convolved stimulus columns)
    hrf.m, parse_hrf.m, stim_regressor.m, baseline.m, read_timings.m
    cfg_from_legacy_opts.m   legacy *_config_file.mat -> cfg
    design_metrics.m   VIF, beta SE, efficiency, cond(X)
    plot_*.m           views; each accepts 'Parent' to draw into a panel
    app.m              uifigure front end
  examples/            demo_design_matrix.m, demo_design_views.m
  tests/               matlab.unittest function-based tests
```

## Roadmap

1. Native estimation and simulation (replacing `estimatex.m` and AFNI's fit):
   noisy signals at a given SNR, many iterations, full vs partial models.
2. Simulation views: beta histograms, noisy vs fitted signals, model error.
3. Simulation tab in the app, with interactive viewers.
4. Validate `GAM`, `MION` and the baseline polynomials against AFNI output.
