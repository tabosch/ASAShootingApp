# File to create pass models for shiny app

library(dplyr)
library(gbm)
library(stringr)
teamnames <- read.csv('TeamNameLinks.csv', stringsAsFactors = F) %>%
  select(-one_of("X"))

#load in the requisite data
passes <- bind_rows(lapply(paste0("IgnoreList/", grep('raw passes', list.files("IgnoreList/"), value = T)),
                           function(x) read.csv(x, stringsAsFactors = F))) %>%
  mutate(date = as.Date(date, format = "%m/%d/%Y"),
         year = as.numeric(format(date, "%Y"))) %>%
  mutate(passer = str_replace_all(passer, 
                                  c('Kazaishvili' = 'Qazaishvili', 
                                    'Jorge Villafaña' = 'Jorge Villafana',
                                    "Antonio Mlinar Dalamea" = "Antonio Mlinar Delamea")),
         passer = ifelse(row_number() %in% grep("Boniek", passer), "Oscar Boniek Garcia", passer)) %>%
  select(-one_of("X"))

vertical.lineups <- read.csv('IgnoreList/vertical starting lineups.csv', stringsAsFactors = FALSE) %>%
  select(-one_of("X"))
jy.starting.lineups <- read.csv('IgnoreList/Starting Lineups editedJY.csv', stringsAsFactors = FALSE) %>%
  select(-one_of("X"))


#########################################################

# Now get passing ratio numbers for each team
#passes <- data.frame(read.csv('raw passes.csv'))
#passPercFor <- group_by(passes, team) %>%
#   summarize(finalThirdPer = sum((x > 66.7 | endX > 66.7) & success == 1)/sum(success == 1))

#passPercAgainst <- group_by(passes, team.1) %>%
#    summarize(finalThirdAPer = sum((x > 66.7 | endX > 66.7) & success == 1)/sum(success == 1))


#write.csv(passPerc, 'passing_percentages.csv')x


# Create key1
vertical.lineups$Key1 <- paste(vertical.lineups$formation, vertical.lineups$position, sep = "")

# Create key2
vertical.lineups$Key2 <- paste(vertical.lineups$gameID, vertical.lineups$players, sep = "")

# Create key2 for passes df
passes$Key2 <- paste(passes$gameID, passes$passer, sep = "")

# Merge lineups with their proper positions
merged.lineups <- vertical.lineups %>%
  left_join(jy.starting.lineups, by = c("Key1" = "Key")) %>%
  filter(!duplicated(Key2))

# Merge lineups with positions
merged.passes <- left_join(passes, 
                           merged.lineups %>%
                             select(-c(team, gameID)), 
                           by = "Key2")

merged.passes <- merged.passes %>%
  left_join(teamnames, by = c('team' = 'FullName')) %>%
  left_join(teamnames, by = c('team.1' = 'FullName'), suffix = c("_0", "_1")) %>%
  left_join(teamnames, by = c("hteam" = "FullName")) %>%
  left_join(teamnames, by = c("ateam" = "FullName"), suffix = c("_h", "_a")) %>%
  mutate(team = Abbr_0,
         team.1 = Abbr_1,
         hteam = Abbr_h,
         ateam = Abbr_a) %>%
  select(-c(Abbr_0, Abbr_1, Abbr_h, Abbr_a))

# Engineer features ####

# Fill NA positions
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

merged.passes <- merged.passes %>%
  group_by(passer) %>%
  mutate(Position = ifelse(is.na(Position) | Position == "S", na.omit(c(Mode(Position[Position != "S"]), "S"))[1], Position)) %>%
  ungroup() %>%
  mutate(Position.model = factor(ifelse(Position == "G", "GK", "Field")))

merged.passes <- merged.passes %>%
  mutate(endX = endX*115/100,
         x = x*115/100,
         endY = endY*80/100,
         y = y*80/100,
         distance = sqrt((endX - x)^2 + (endY - y)^2),
         angle = atan((endY - y)/(endX - x)) + pi*ifelse(endX < x & endY < y, -1, ifelse(endX < x & endY > y, 1, 0)),
         year = as.numeric(as.character(year)),
         playerdiff = ifelse(team == hteam, hplayers - aplayers, aplayers - hplayers),
         minute.temp = unlist(sapply(strsplit(time, ":"), function(x) as.numeric(x[1]))),
         second.temp = unlist(sapply(strsplit(time, ":"), function(x) as.numeric(x[2]))),
         minute = minute.temp + second.temp/60) %>%
  mutate_at(.vars = names(merged.passes)[sapply(merged.passes, class) == "character"],
            .funs = factor) %>%
  group_by(gameID, half) %>%
  arrange(minute) %>%
  mutate(first.pass = ifelse(row_number() == 1, 1, 
                             ifelse(hscore != lag(hscore) | ascore != lag(ascore), 1, 0)),
         second.pass = ifelse(first.pass == 1, 0, 
                              ifelse(row_number() == 2, 1, 
                                     ifelse(team == lag(team) & (hscore != lag(hscore, 2) | ascore != lag(ascore, 2)), 1, 0)))) %>%
  select(-c(minute.temp, second.temp)) %>%
  ungroup()

# Build terminal x,y prediction model ####

# With censored obs
# library(gbm)
# surv.obj <- Surv(time = merged.passes$distance, 
#                  event = merged.passes$success)
# set.seed(23)
# surv.gbm <- gbm(surv.obj ~ home + x + y + angle + Position + 
#                   freekick + headpass + longball + throwin + throughball + 
#                   hplayers + aplayers + year,
#                 data = merged.passes,
#                 distribution = "coxph",
#                 n.trees = 1000,
#                 interaction.depth = 4,
#                 shrinkage = 0.01,
#                 n.minobsinnode = 20, 
#                 train.fraction = 0.7)
# 
# plot(surv.gbm$valid.error)
# min(surv.gbm$valid.error)
# which.min(surv.gbm$valid.error)
# summary(surv.gbm, plotit = F)

# With only successful passes
# library(gbm)
# set.seed(23)
# distance.gbm <- gbm(distance ~ x + y + angle + Position + 
#                   freekick + headpass + longball + throwin + throughball,
#                 data = merged.passes %>%
#                   filter(success == 1),
#                 distribution = "gaussian",
#                 n.trees = 200,
#                 interaction.depth = 5,
#                 shrinkage = 0.05,
#                 n.minobsinnode = 10, 
#                 train.fraction = 1)
# 
# merged.passes[["distance.pred"]] <- predict(distance.gbm, merged.passes, n.trees = 200)
# merged.passes <- merged.passes %>%
#   mutate(max.dist = 200, # placeholder for maximum distance the ball could travel in bounds; need some tricky geometry
#     distance.adj = ifelse(success == 1, distance,
#                            pmin(max.dist, distance.pred)))

# Build pass success model
# Include first pass of the half indicator!
library(gbm)
# set.seed(17)
# success.gbm.distance <- gbm(success ~ home + playerdiff + x + y + angle + Position.model + 
#                               freekick + headpass + longball + throwin + throughball + 
#                               cross + corner + playerdiff + distance + first.pass + second.pass,
#                             data = merged.passes,
#                             distribution = "bernoulli",
#                             n.trees = 1000,
#                             interaction.depth = 5,
#                             shrinkage = 0.1,
#                             n.minobsinnode = 20, 
#                             train.fraction = 1,
#                             keep.data = F)

set.seed(21)
success.gbm <- gbm(success ~ home + playerdiff + x + y + angle + Position.model + 
                     freekick + headpass + longball + throwin + throughball + 
                     cross + corner + playerdiff + first.pass + second.pass,
                   data = merged.passes %>%
                     filter(year < 2018),
                   distribution = "bernoulli",
                   n.trees = 1000,
                   interaction.depth = 5,
                   shrinkage = 0.1,
                   n.minobsinnode = 20, 
                   train.fraction = 1,
                   keep.data = F)

set.seed(13)
success.gbm.16 <- gbm(success ~ home + playerdiff + x + y + angle + Position.model + 
                     freekick + headpass + longball + throwin + throughball + 
                     cross + corner + playerdiff + first.pass + second.pass,
                   data = merged.passes %>%
                     filter(year < 2017),
                   distribution = "bernoulli",
                   n.trees = 1000,
                   interaction.depth = 5,
                   shrinkage = 0.1,
                   n.minobsinnode = 20, 
                   train.fraction = 1,
                   keep.data = F)

saveRDS(success.gbm, "IgnoreList/xPassModel.rds")
saveRDS(success.gbm.16, "IgnoreList/xPassModel_2016.rds")
# saveRDS(success.gbm.distance, "IgnoreList/xPassModel_withDistance.rds")

#merged.passes[["success.pred.distance"]] <- predict(success.gbm.distance, merged.passes, type = "response", n.trees = 1000)
merged.passes[["success.pred"]] <- predict(success.gbm, merged.passes, type = "response", n.trees = 1000)
merged.passes[["success.pred.16"]] <- predict(success.gbm.16, merged.passes, type = "response", n.trees = 1000)

merged.passes <- merged.passes %>%
  select(-c(eventID, hteam, ateam, final, hplayers, aplayers, 
            teamEventId, Key2, position, Formation, Player, players,
            Key1))

# saveRDS(merged.passes, "IgnoreList/AllPassingData.rds")



