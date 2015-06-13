#!/bin/bash
infile=$1
for i in $(cat $infile)
do
    /mnt/t/testing/mexico/biomass/alos/biomass_modeling/workshop_data/mexico_biomass_modeling/predict_carbon.sh $i
done