from jkpy.StimSim import *
from pprint import pprint
# prepare files, working directory...
base='/home/nucleus/WORK/fMRI_simulator_estimator/scripts/simfmritool/estfmriTOY_V2.3_beta/Luiz_class_ER_1'
outdir=os.path.join(base,'stimsim_Luiz_Class_ER_t2_10')
shutil.rmtree(outdir, True)
os.mkdir(outdir)

# define broad experiment structure
p_exp       = Part('experiment',  'run')
p_run       = Part('run',       'trial')
p_trial     = Part('trial',       'cue','isi_1','pict','isi_2',        types=('T', 'S'))

N=50.0
dtrial=np.array([25,25])/N

# define event-specific settings (durations, timings, numbers, etc)
config=Config()
config['run']          = dict(N=6, pre=10,post=10)

config['trial']        = dict(N=N, dist = dtrial)

config['cue']          = dict(dur=0.75,model='BLOCK(0.75,1)')

# config['isi_1']        = dict(dur=Pretty(3,4,8,group=0))
config['isi_1']        = dict(dur=Pretty(4,5,10,group=0))

config['pict']         = dict(dur=0.5,model='BLOCK(0.5,1)')

# config['isi_2']        = dict(dur=Pretty(3,4,8,group=0))
config['isi_2']        = dict(dur=Pretty(4,5,10,group=1))

# run the simulation
best=simulate([p_exp,p_run,p_trial],config
             ,folder=outdir
             ,iterations=1000
             ,tr=2
             ,all_contrast_pairs=True
             ,metric = "0.33*((T.pict+S.pict)+(T.pict-S.pict))+0.33*((T.cue+S.cue)+(T.cue-S.cue))+0.33*((T.cue+T.pict)-(S.cue-S.pict))"
             ,fix_run_lengths=True
             ,nthreads=16)