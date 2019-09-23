#!/bin/bash

# LIP EMISSIONS SIMULATIONS, VARIABLE REPEAT TIME
# STEVE JONES 2017-9

N_HISTORY_START=1
N_HISTORIES=2
SAVE_FILES=1
SAVE_DIR=.
MANTLE_AREA_FLUX=4          # IN KM2/YR
STOP_TIME=5000              # IN YR
TIME_STEP=100               # IN YR
SILL_RECURRENCE_PERIOD=2    # IN YR
SILL_AREA_FILE=./sill_areas_3D_naip_over10km2.x
AZIMUTH_FILE=./azimuth_72.dat
RADIAL_VARIATION_FILE=./gaussian_pulse_zero_scaled_pcum.dat
TREC_FILE=

AWK=gawk

gmt gmtset MAP_FRAME_TYPE plain
gmt gmtset MAP_FRAME_PEN 0.5p,black
gmt gmtset MAP_TICK_LENGTH_PRIMARY 0.1c
gmt gmtset MAP_TICK_LENGTH_SECONDARY 0.05c
gmt gmtset MAP_LABEL_OFFSET 0.3c
gmt gmtset FONT_LABEL 12p
gmt gmtset FONT_ANNOT_PRIMARY 10p

# SILL SURFACE AREA DISTRIBUTION

DISTRIBUTION=LOGNORMAL
if [ "$DISTRIBUTION" == "NORMAL"  ]; then
#	gmtinfo $SILL_AREA_FILE
	gmt pshistogram $SILL_AREA_FILE -R1e-1/1e4/0/100 -JX -Ba1p:"Sill Surface Area (km@+2@+)":/a25f5g25:"Frequency (%)":n -W1 -Q -S -Z1 -Io > tmp.area.cum.freq.1
elif [ "$DISTRIBUTION" == "LOGNORMAL"  ]; then
	$AWK '{print log($1)}' $SILL_AREA_FILE > tmp.a
#	gmtinfo tmp.a
	gmt pshistogram tmp.a -R0/10/0/100 -Ba1p:"Sill Surface Area (km@+2@+)":/a25f5g25:"Frequency (%)":n -W0.1 -Q -S -Z1 -Io > tmp.area.cum.freq.1
fi

# LOOP FOR STOCHASTIC MODELS

echo
echo "Aiming to run $N_HISTORIES simulations"
date
N=$N_HISTORY_START
N_MAX=`echo "$N_HISTORY_START - 1 + $N_HISTORIES" | bc -l`

while [ $N -le $N_MAX ]; do
    echo -n "  Calculating simulation $N ... "

# LIST OF RANDOM NUMBERS TO TURN INTO SILL PROVINCE MODEL

    $AWK 'BEGIN{srand(); for (n=1; n<=15000; n++) { print rand(), rand(), rand(), rand(), rand(), rand(), rand(), rand(), rand() }}' > tmp.ran9

# MAKE MONOTONICALLY INCREASING LIST FROM SURFACE AREA CUMULATIVE PROBABILITY DISTRIBUTION

    $AWK 'BEGIN{print 0, 0; prev=0}{if ($2>prev){ print $1, $2/100; prev=$2}}' tmp.area.cum.freq.1 > tmp.sample1d.in

# GET SILL SURFACE AREA FROM FIRST RANDOM NUMBER APPLIED TO CUMULATIVE PROBABILITY DISTRIBUTION

    $AWK '{print $1}' tmp.ran9 > tmp.knot
    gmt sample1d tmp.sample1d.in -T1 -Ntmp.knot | \
    $AWK '{print $1}' > tmp.sample1d.out

# GET ASSOCIATED LAVA AREA FROM SIXTH RANDOM NUMBER APPLIED TO CUMULATIVE PROBABILITY DISTRIBUTION
# (THIS NO LONGER USED)

    $AWK '{print $6}' tmp.ran9 > tmp.knot
    gmt sample1d tmp.sample1d.in -T1 -Ntmp.knot | \
    $AWK '{print $1}' > tmp.sample1d.6.out

# COMBINE WITH OTHER PARAMETERS

    if [ "$DISTRIBUTION" == "NORMAL"  ]; then
        $AWK 'function erf(xx) {xsq=xx*xx; fopi=1.273239545; ca=0.140012; caxsq=ca*xsq; ce=exp(-xsq*(fopi+caxsq)/(1+caxsq)); cs=sqrt(1-ce); if ( xx >= 0) {return cs} else {return -cs}} BEGIN{ pi=3.141592654 } {getline A <"tmp.sample1d.out"; S=120+0.02568*sqrt(A*1e6/pi); W=0.005+$3*0.015; Z=0.5+$4*3; K=$5; dt=0; print A, S, W, Z, K, dt }'
				tmp.ran6 > sills.15000
    elif [ "$DISTRIBUTION" == "LOGNORMAL"  ]; then
        $AWK -f ./make_dimensions.awk tmp.ran9 > sills.15000
    fi

# DETERMINE TOTAL MASS AND TIMESCALE FOR EMISSION DECAY

    $AWK -f ./dim2mtp.awk -v fix_K=1 sills.15000 > sills.15000.mt
    $AWK '{ if ($2==0) print $4,$5,$6,$7,$8,$9,$10,$11}' sills.15000.mt > sills.15000.mt0
		
# CALCULATE EMISSIONS HISTORY FOR THE PROVINCE

    $AWK -f ./LIP_emission_model.awk -v time_stop=$STOP_TIME -v time_step=$TIME_STEP -v mantle_area_flux=$MANTLE_AREA_FLUX -v azimuth_file=$AZIMUTH_FILE -v radial_variation_file=$RADIAL_VARIATION_FILE -v t_rec_file=$TREC_FILE  sills.15000.mt > emissions.model

# SAVE FILES
	
if [ $SAVE_FILES -eq 1 ]; then
    cp emissions.model ${SAVE_DIR}/emissions.model.$N
    cp ???_emission_model.test ${SAVE_DIR}/sills.model.$N
fi
			
# END OF STOCHASTIC MODEL LOOP

    echo "finished"
let N=N+1
done

date
echo

