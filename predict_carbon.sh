#!/bin/bash

# This script takes an file and runs the carbon prediction
#
# AUTHOR: Jesse Bishop
# DATE: 2013-10-21
#
cd /mnt/t/testing/mexico/biomass/alos/biomass_modeling/workshop_data/mexico_biomass_modeling

if [ "$#" != "1" ]; then
    echo "USAGE ${0##*/} id"
    echo "EXAMPLE: ${0##*/} 12345"
    echo
    exit
fi

seg_csv=$1
segdir=$(dirname $seg_csv)

# Calculate some additional parameters
modelfile="workshop_model.RData"
outlut_csv=$(echo $seg_csv | sed 's/.csv/_carbon.csv/g')
seg_tif=$(echo $seg_csv | sed 's/_predictors.csv/.tif/g')
out_tif=$(echo $outlut_csv | sed 's/.csv/.tif/g')

# Predict 
/usr/bin/R --vanilla --slave --args $modelfile $seg_csv $outlut_csv $seg_tif $out_tif < prediction.R

