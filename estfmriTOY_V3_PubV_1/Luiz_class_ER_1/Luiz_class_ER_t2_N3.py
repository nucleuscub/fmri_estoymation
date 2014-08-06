from jkpy.StimSim import *
from pprint import pprint
# prepare files, working directory...
base='/home/nucleus/WORK/fMRI_simulator_estimator/scripts/simfmritool/estfmriTOY_V2.3_beta/Luiz_class_ER_1'
outdir=os.path.join(base,'stimsim_Luiz_Class_ER_t2_N3')
shutil.rmtree(outdir, True)
os.mkdir(outdir)

# define broad experiment structure
p_exp       = Part('experiment',  'run')
p_run       = Part('run',       'trial')
p_trial     = Part('trial',       'cue','isi_1','pict','isi_2',        types=('T', 'S', 'N'))

N=75.0
dtrial=np.array([25,25,25])/N

# define event-specific settings (durations, timings, numbers, etc)
config=Config()
config['run']          = dict(N=6, pre=10,post=10)

config['trial']        = dict(N=N, dist = dtrial)

config['cue']          = dict(dur=0.75,model='BLOCK(0.75,1)')

# config['isi_1']        = dict(dur=Pretty(3,4,8,group=0))
config['isi_1']        = dict(dur=2)

config['pict']         = dict(dur=0.5,model='BLOCK(0.5,1)')

# config['isi_2']        = dict(dur=Pretty(3,4,8,group=0))
config['isi_2']        = dict(dur=2)

# Metrics
TSpict  = "(T.pict+S.pict)+(T.pict-S.pict)"
TNpict  = "(T.pict+N.pict)+(T.pict-N.pict)"
SNpict  = "(S.pict+N.pict)+(S.pict-N.pict)"

TSNpict = "0.33*(" + TSpict + "+" + TNpict + "+" + SNpict + ")"

TScue   = "(T.cue+S.cue)+(T.cue-S.cue)"
TNcue   = "(T.cue+N.cue)+(T.cue-N.cue)"
SNcue   = "(S.cue+N.cue)+(S.cue-N.cue)"

TSNcue  = "0.33*(" + TScue + "+" + TNcue + "+" + SNcue + ")"


TStotal  =  "(T.cue+T.pict)-(S.cue-T.pict)"
TNtotal  =  "(T.cue+T.pict)-(N.cue-N.pict)"
SNtotal  =  "(S.cue+S.pict)-(N.cue-N.pict)"

TSNtotal =  "0.33*(" + TStotal + "+" + TNtotal + "+" + SNtotal + ")"

mymetric = TSNpict + "+" + TSNcue + "+" + TSNtotal


# run the simulation
best=simulate([p_exp,p_run,p_trial],config
             ,folder=outdir
             ,iterations=100
             ,tr=2
             ,all_contrast_pairs=True
             ,metric = mymetric
             ,fix_run_lengths=True
             ,nthreads=16)