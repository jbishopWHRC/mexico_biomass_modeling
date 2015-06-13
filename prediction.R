# Libraries
library(randomForest)

#seg_csv <- '/mnt/t/testing/mexico/biomass/alos/biomass_modeling/workshop_data/168_380_20080901_FBD_ALPSRP138740380_183304/168_380_20080901_FBD_ALPSRP138740380_183304_s1_g15_gamma_dB_s0n_hhhvzratio_seg_7_0.1_0.9_predictors.csv'
#outlut_csv <- '/mnt/t/testing/mexico/biomass/alos/biomass_modeling/168_380_20080901_FBD_ALPSRP138740380_183304_carbon.csv'
#seg_raster <- '/mnt/t/testing/mexico/biomass/alos/biomass_modeling/workshop_data/168_380_20080901_FBD_ALPSRP138740380_183304/168_380_20080901_FBD_ALPSRP138740380_183304_s1_g15_gamma_dB_s0n_hhhvzratio_seg_7_0.1_0.9.tif'
#out_raster <- '/mnt/t/testing/mexico/biomass/alos/biomass_modeling/168_380_20080901_FBD_ALPSRP138740380_183304_carbon.tif'
  
  
# Get the parameters from the --args commandline (or R qsub script equivalent)
args <- commandArgs(trailingOnly=TRUE)
modelfile <- toString(args[1])
seg_csv   <- toString(args[2])
outlut_csv   <- toString(args[3])
seg_raster <- toString(args[4])
out_raster <- toString(args[5])

# Load the model
load(modelfile) # model object is called "rf"

# Get the segment data as csv file
segs <- read.csv(seg_csv, as.is=TRUE)
# eliminate background 0
segs <- subset(segs, segs$segment_id != 0)

# Get the model predictor names
prednames <- names(rf$importance[,1])

# prepare the predictor stack 
pred <- segs[prednames]

# Prediction
predicted_carbon <- predict(rf,pred)

out <- data.frame(segs$segment_id,predicted_carbon)
names(out) <- c("segid","pred")
options(scipen=10)
write.csv(out,file=outlut_csv,row.names=FALSE,quote=FALSE)

######################
# Write Output Image #
######################
# Load the raster package here to avoid overloading the predict function from stats
require(raster)
# Load the output segment raster 
img.out <- raster(seg_raster)
# Get the values as a vector
img <- getValues(img.out)
# Set the boundary segment to NA
is.na(img) <- img == 0
# Make a vector by replacing segment ids with the prediction
img.match <- as.numeric(out$pred[match(img, out[,1])])
# Set the no data value for the output
img.match[is.na(img.match) == TRUE] <- NAvalue(img.out) # Or some other value like -1
# Set the values of the output raster
img.out <- setValues(img.out, img.match)
# Write out the image
writeRaster(img.out, filename=out_raster, format="GTiff", dataType="FLT4S", overwrite=T)
