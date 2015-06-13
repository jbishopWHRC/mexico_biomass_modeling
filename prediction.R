# Libraries
library(randomForest)

#seg_csv <- '/mnt/t/testing/mexico/biomass/alos/biomass_modeling/workshop_data/210_630_20070623_FBD_ALPSRP075150630_41147/210_630_20070623_FBD_ALPSRP075150630_41147_s1_g15_gamma_dB_s0n_hhhvzratio_seg_7_0.1_0.9_predictors.csv'
#outlut_csv <- '/mnt/t/testing/mexico/biomass/alos/biomass_modeling/210_630_20070623_FBD_ALPSRP075150630_41147_carbon.csv'
#seg_raster <- '/mnt/t/testing/mexico/biomass/alos/biomass_modeling/workshop_data/210_630_20070623_FBD_ALPSRP075150630_41147/210_630_20070623_FBD_ALPSRP075150630_41147_s1_g15_gamma_dB_s0n_hhhvzratio_seg_7_0.1_0.9.tif'
#out_raster <- '/mnt/t/testing/mexico/biomass/alos/biomass_modeling/210_630_20070623_FBD_ALPSRP075150630_41147_carbon.tif'
 
# Get the parameters from the --args commandline (or R qsub script equivalent)
args <- commandArgs(trailingOnly=TRUE)
modelfile <- toString(args[1])
seg_csv   <- toString(args[2])
outlut_csv   <- toString(args[3])
seg_raster <- toString(args[4])
out_raster <- toString(args[5])

print(seg_csv)

# Load the model
load(modelfile) # model object is called "rf"

# Get the segment data as csv file
segs <- read.csv(seg_csv, as.is=TRUE, stringsAsFactors=FALSE)
# eliminate background 0
segs <- subset(segs, segs$segment_id != 0)

# Remove segments that have NA in the predictors
#badsegs <- unique(c(segs$segment_id[is.na(segs$hh_mean)], segs$segment_id[is.na(segs$hv_mean)], segs$segment_id[is.na(segs$vcf_mean)], segs$segment_id[is.na(segs$elev_mean)]))
#segs <- subset(segs, segs$segment_id %in% badsegs == FALSE)

# Get the model predictor names
#prednames <- names(rf$importance[,1])

# prepare the predictor stack 
#pred <- segs[prednames]
pred <- data.frame(as.numeric(segs$hh_mean), as.numeric(segs$hv_mean), as.numeric(segs$vcf_mean), as.numeric(segs$elev_mean))
names(pred) <- c('hh_mean', 'hv_mean', 'vcf_mean', 'elev_mean')

# Prediction
predicted_carbon <- predict(rf,pred)

out <- data.frame(segs$segment_id,round(predicted_carbon))
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
#is.na(img) <- img == 0
img[img == 0] <- NA
# Set the bad segments to NA
#is.na(img) <- img[badsegs]
#img[img %in% badsegs] <- NA
# Make a vector by replacing segment ids with the prediction
img.match <- as.numeric(out$pred[match(img, out[,1])])
# Set the no data value for the output
img.match[is.na(img.match) == TRUE] <- NAvalue(img.out) # Or some other value like -1
# Set the values of the output raster
img.out <- setValues(img.out, img.match)
# Write out the image
writeRaster(img.out, filename=out_raster, format="GTiff", dataType="Byte", overwrite=T)
