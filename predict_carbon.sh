#!/bin/bash

# This script takes an file and runs the carbon prediction
#
# AUTHOR: Jesse Bishop
# DATE: 2013-10-21
#

if [ "$#" != "2" ]; then
    echo "USAGE ${0##*/} id code_directory"
    echo "EXAMPLE: ${0##*/} 12345 /mnt/t/code/project_repo"
    echo
    exit
fi

seg_csv=$1
codedir=$2
segdir=$(dirname $seg_csv)
cd $codedir

# Calculate some additional parameters
modelfile="workshop_model.RData"
outlut_csv=$(echo $seg_csv | sed 's/.csv/_carbon.csv/g')
seg_tif=$(echo $seg_csv | sed 's/_predictors.csv/.tif/g')
out_tif=$(echo $outlut_csv | sed 's/.csv/.tif/g')

# Predict 
/usr/bin/R --vanilla --slave --args $modelfile $seg_csv $outlut_csv $seg_tif $out_tif < prediction.R

