# Tutorial data

An event-related design with four stimulus classes (`S_cue`, `S_pict`,
`T_cue`, `T_pict`), TR 2 s, 210 volumes, 1 run, `BLOCK` responses, no baseline.
Load it with `estfmri.tutorial()`.

| File | Content |
|---|---|
| `timings/*.1D` | AFNI `-stim_times` files, one per class (6 rows; the tutorial uses row 1) |
| `tutorial_cfg.mat` | the design as an estfmri `cfg` (open it in `estfmri.app`) |
| `ER_tutorial_config_file.mat` | the original estfmriTOY (2014) config, reduced to its design fields. `opts.X` is the design matrix AFNI `3dDeconvolve -nodata` produced; the tests use it as the reference for `estfmri.design_matrix`, and it exercises `estfmri.cfg_from_legacy_opts` |
