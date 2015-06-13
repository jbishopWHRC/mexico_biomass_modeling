library(RPostgreSQL)
library(randomForest)
con <- dbConnect(drv="PostgreSQL", host="pan.whrc.ad", user="jbishop", dbname="smddb")
query <- "SELECT z.folio, z.carbono_arboles_tpha, z.date_distance, z.measurement_date, o.id_vegetac AS veg_type_id, o.vegetacion AS veg_type, CASE WHEN o.vegetacion IN ('Bosque de abies', 'Bosque de ayarin', 'Bosque de cedro', 'Bosque de pino', 'Bosque de tascate') THEN 'CF' WHEN o.vegetacion IN ('Bosque de encino', 'Bosque de galerÝa') THEN 'BF' WHEN o.vegetacion IN ('Bosque de encino-pino', 'Bosque de pino-encino') THEN 'CBF' WHEN o.vegetacion = 'Manglar' THEN 'MG' WHEN o.vegetacion IN ('Bosque mesofilo de monta±a', 'Selva alta perennifolia', 'Selva alta subperennifolia', 'Selva baja perennifolia', 'Selva baja subperennifolia', 'Selva mediana subperennifolia') THEN 'THF' WHEN o.vegetacion IN ('Selva baja caducifolia', 'Selva baja espinosa', 'Selva baja subcaducifolia', 'Selva mediana caducifolia', 'Selva mediana subcaducifolia') THEN 'TDF' ELSE 'ERROR' END AS type_code, o.ecosistema AS ecosystem, AVG(s.num_pixels) AS num_pixels, AVG(s.num_masked_pixels) AS num_masked_pixels, AVG(s.elev_mean) AS elev_mean, AVG(s.slope_mean) AS slope_mean, AVG(s.vcf_mean) AS vcf_mean, AVG(hh_mean) AS hh_mean, AVG(hv_mean) AS hv_mean, AVG(lsmask_mean) AS lsmask_mean, MIN(lsmask_min) AS lsmask_min, MAX(lsmask_max) AS lsmask_max, COUNT(alos_id) AS num_images FROM (SELECT b.folio, SUM(b.carbono_arboles) / 0.1598925 AS carbono_arboles_tpha, y.date_distance, MIN(b.levantamiento_fecha_ejecucion) AS measurement_date  FROM (SELECT folio, CASE WHEN MIN(date_distance) + MAX(date_distance) = 0 THEN MIN(date_distance) WHEN MIN(date_distance) + MAX(date_distance) > 0 THEN MIN(date_distance) ELSE MAX(date_distance) END AS date_distance FROM (SELECT folio, days_from_alos AS date_distance, COUNT(sitio) AS plot_count FROM mexico_biomass_plots_filtered WHERE NOT carbono_arboles IS NULL AND NOT levantamiento_fecha_ejecucion IS NULL AND folio IN (SELECT folio FROM mexico_biomass_plots_old) AND NOT tipificacion IN ('Inaccesible (pendiente)', 'Inaccesible (social)', 'Vacio', 'Planeado') GROUP BY folio, days_from_alos HAVING COUNT(sitio) = 4 ORDER BY folio) AS x GROUP BY folio) AS y INNER JOIN mexico_biomass_plots_filtered b ON b.folio=y.folio AND b.days_from_alos=y.date_distance GROUP BY b.folio, y.date_distance) AS z INNER JOIN mexico_biomass_plots_old o ON z.folio=o.folio INNER JOIN mexico_biomass_plots_model_statistics s ON z.folio=s.folio GROUP BY z.folio, z.carbono_arboles_tpha, z.date_distance, z.measurement_date, o.id_vegetac, o.vegetacion, o.ecosistema;"
d <- dbGetQuery(con, query)

# Take a look at the relationships
plot(d$carbono_arboles_tpha, d$hv_mean)
plot(d$carbono_arboles_tpha, d$vcf_mean)

## Data Filtering
# Remove steep slopes
sub <- subset(d, slope_mean < 15) # degrees (or 15%)
# Remove layover/shadow
sub <- subset(sub, lsmask_mean = 0)

# Take a look at the relationships
plot(sub$carbono_arboles_tpha, sub$hv_mean)
plot(sub$carbono_arboles_tpha, sub$vcf_mean)


# Remove the outliers
# Create a vector to hold the folios that will be removed
f <- vector()
for (i in unique(sub$type_code)){
  s <- subset(sub, type_code == i)
  plot(s$carbono_arboles_tpha, s$hv_mean, main=i, pch=19, col='grey')
  m.hv <- lm(s$hv_mean ~ poly(s$carbono_arboles_tpha, 3))
  s$pred_hv_mean <- predict(m.hv, poly(s$carbono_arboles_tpha, 3))
  points(s$carbono_arboles_tpha, s$pred_hv_mean, col='red')
  s$residual_hv <- resid(m.hv)
  hv.std_dev <- sd(s$residual_hv)
  s$remove_hv <- ifelse(s$residual_hv > 2 * hv.std_dev, TRUE, FALSE)
  points(s$carbono_arboles_tpha[s$remove_hv != TRUE], s$hv_mean[s$remove_hv != TRUE], pch=21)
  plot(s$carbono_arboles_tpha, s$vcf_mean, main=i, pch=19, col='grey')
  m.vcf <- lm(s$vcf_mean ~ poly(s$carbono_arboles_tpha, 3))
  s$pred_vcf_mean <- predict(m.vcf, poly(s$carbono_arboles_tpha, 3))
  points(s$carbono_arboles_tpha, s$pred_vcf_mean, col='green')
  s$residual_vcf <- resid(m.vcf)
  vcf.std_dev <- sd(s$residual_vcf)
  s$remove_vcf <- ifelse(s$residual_vcf > 2 * vcf.std_dev, TRUE, FALSE)
  points(s$carbono_arboles_tpha[s$remove_vcf != TRUE], s$vcf_mean[s$remove_vcf != TRUE], pch=21)
  f <- c(f, s$folio[s$remove_hv == TRUE | s$remove_vcf == TRUE])
}

sub <- subset(sub, ! folio %in% f)

plot(sub$carbono_arboles_tpha, sub$hv_mean)
plot(sub$carbono_arboles_tpha, sub$vcf_mean)

# Split out testing and training

attach(sub)
#stack <- data.frame(hh_mean, hv_mean, vcf_mean, slope_mean, elev_mean)
stack <- data.frame(hh_mean, hv_mean, vcf_mean, elev_mean)
rf <- randomForest(carbono_arboles_tpha ~ ., data=stack, ntree=200)
detach()

save('rf', file='/mnt/t/testing/mexico/biomass/alos/biomass_modeling/workshop_data/workshop_model.RData')

varImpPlot(rf)



# Replace this wrong crap below with proper non-crap

sub$pbio <- rf$pred
sub$pbiomod <- predict(rf, stack)
cor.mod <- cor(sub$carbono_arboles_tpha,predict(rf,stack))
cor.test <- cor(sub$carbono_arboles_tpha,rf$pred)
rmse.mod <- sqrt(sum((sub$carbono_arboles_tpha-predict(rf,stack))^2)/length(sub$carbono_arboles_tpha))
rmse.test <- sqrt(sum((sub$carbono_arboles_tpha-rf$pred)^2)/length(sub$carbono_arboles_tpha))
oob.h.cor <- cor.test
oob.h.rmse <- rmse.test
