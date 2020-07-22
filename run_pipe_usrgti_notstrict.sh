#!/bin/sh
# usage: run_pipe.sh PATH/TO/OBSID AorB

# syntax: run_pipe.sh INDIR
if [ $# != 2 ] ; then
    echo Syntax:  run_pipe_usrgti_notstrict.sh PATH_TO_OBSID AorB
    exit 1
fi

# Note, PATH_TO_OBSID is assumed to be relative to the current
# directory:

INDIR=$1
AB=$2

## Set up your local NuSTAR science environment here:
#if [ -z "$NUSTARSETUP" ]; then
#echo "Need to set the NUSTARSETUP environment variable!"
#exit
#fi
#source $NUSTARSETUP


# Assume that INDIR will be the complete path, and we only want the last bit
# for the stem inputs:

STEMINPUTS=nu`basename ${1}`
OUTDIR=$INDIR/event_cl

# Set the pfiles to point to $INDIR/PID_pfiles
# Assumes that INDIR is relative to the current directory
headas_locpfiles=${PWD}/${INDIR}/$$_pfiles

if [ ! -d $OUTDIR ]; then
#    echo $OUTDIR needs to be produced
    mkdir -m 750 $OUTDIR
#    chgrp nustar $OUTDIR
fi


# If you do NOT have a TLE file in yoru auxil directory, uncomment out the next line
# and add a line below:
# tlefile=$tlefile to both the echo'd nupipeline call and the one that actaully
# executes...
#tlefile=${CALDB_AUXIL}/NUSTAR_TLE_ARCHIVE.txt.2012305

# Here put the pointers to the alignments databases if you want to use something
# other than the CALDB alignments database. If you want to switch to the CALDB,
# comment out everything below.


logfile=$INDIR/{$$}_pipe.log

# Set the entry/exit stages here if you want to 
# change it from the default of 1 and 2, respectively.
# Only set EXISTAGE=3 if you actually know what you're doing and have
# added correct keywords for effective area, grprmf, vignetting, etc below.

ENTRYSTAGE=1
EXITSTAGE=2

GTISCREEN=yes
EVTSCREEN=yes
GRADEEXPR='DEFAULT'
STATUSEXPR='DEFAULT'
CREATEATTGTI=yes
CREATEINSTRGTI=yes
FPM=FPM${AB}
USRGTIFILE=$OUTDIR/../${STEMINPUTS}${AB}01_usrgti.fits


echo
echo Running pipeline...

echo nupipeline \
clobber=yes \
indir=$INDIR steminput=$STEMINPUTS \
outdir=$OUTDIR \
entrystage=$ENTRYSTAGE exitstage=$EXITSTAGE \
gtiscreen=$GTISCREEN \
usrgtifile=$USRGTIFILE \
evtscreen=$EVTSCREEN \
gradeexpr=$GRADEEXPR statusexp=$STATUSEXPR \
pntra=OBJECT pntdec=OBJECT \
instrument=$FPM \
createattgti=$CREATEATTGTI createinstrgti=$CREATEINSTRGTI  > $logfile 2>&1 

nupipeline \
clobber=yes \
indir=$INDIR steminput=$STEMINPUTS \
outdir=$OUTDIR \
entrystage=$ENTRYSTAGE exitstage=$EXITSTAGE \
gtiscreen=$GTISCREEN \
usrgtifile=$USRGTIFILE \
evtscreen=$EVTSCREEN \
pntra=OBJECT pntdec=OBJECT \
instrument=$FPM \
gradeexpr=$GRADEEXPR statusexp=$STATUSEXPR \
createattgti=$CREATEATTGTI createinstrgti=$CREATEINSTRGTI  >> $logfile 2>&1


