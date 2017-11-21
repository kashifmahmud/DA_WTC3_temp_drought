# Script to process leaf litter data
litterfall = read.csv("raw_data/WTC_TEMP_CM_LEAFLITTER_20130913-20140528_L1.csv")
litterfall$startDate = as.Date(litterfall$startDate)
litterfall$collectionDate = as.Date(litterfall$collectionDate)
litterfall$Date <- (litterfall$startDate + ((litterfall$collectionDate - litterfall$startDate) / 2))
litterfall = subset(litterfall, Date > as.Date("2014-02-18") & Date <= as.Date("2014-05-27"))

# convert to data.table in place
litterfall = setDT(litterfall)
# dcast and do individual sums
litterfall.cast = dcast.data.table(litterfall, chamber ~ Date, value.var = 'litter', fun.aggregate = sum)

# cumsum to estimate dummy litter pool
litterfall.cum <- litterfall.cast[, as.list(cumsum(unlist(.SD))), by = chamber]
# # no cumsum to estimate litter flush
# litterfall.cum = litterfall.cast

litterfall.cum.melt <- melt(litterfall.cum, id.vars = "chamber")
litterfall.cum.melt = merge(litterfall.cum.melt, unique(treeMass[,c("chamber","T_treatment")]), all=TRUE)
litterfall.cum.melt$chamber_type = as.factor( ifelse(litterfall.cum.melt$chamber %in% drought.chamb, "drought", "watered") )
names(litterfall.cum.melt)[2:3] = c("Date","litter")
litterfall.cum.melt$Date = as.Date(litterfall.cum.melt$Date)
litterfall.cum.melt = summaryBy(litter ~ Date+T_treatment+chamber_type, data=litterfall.cum.melt, FUN=c(mean,standard.error))
names(litterfall.cum.melt)[4:5] = c("litter","litter_SE")

litterfall.cum.deduct = subset(litterfall.cum.melt, Date %in% as.Date("2014-02-25"))
names(litterfall.cum.deduct)[4:5] = c("litter_deduct","litter_deduct_SE")
litterfall.cum.deduct[,c(4:5)] = litterfall.cum.deduct[,c(4:5)]/2
litterfall.cum.melt = merge(litterfall.cum.melt, litterfall.cum.deduct[,c("T_treatment","chamber_type","litter_deduct","litter_deduct_SE")], by=c("T_treatment","chamber_type"), all=TRUE)
litterfall.cum.melt$litter = litterfall.cum.melt$litter - litterfall.cum.melt$litter_deduct
litterfall.cum.melt$litter_SE = litterfall.cum.melt$litter_SE - litterfall.cum.melt$litter_deduct_SE
litterfall.cum.melt = litterfall.cum.melt[,-c(6:7)]


litterfall.initial = data.frame(Date = rep(as.Date("2014-02-18"), 4),
                                T_treatment = rep(unique(data$T_treatment), each=2),
                                chamber_type = rep(unique(data$chamber_type), 2),
                                litter = rep(0.1,4),
                                litter_SE = rep(0.01,4))
litterfall.cum.melt = rbind(litterfall.initial, litterfall.cum.melt)
litterfall.cum.melt$litter = litterfall.cum.melt$litter * c1 # unit conversion from gDM to gC
litterfall.cum.melt$litter_SE = litterfall.cum.melt$litter_SE * c1 # unit conversion from gDM to gC
