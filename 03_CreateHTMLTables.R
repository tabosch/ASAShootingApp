library(dplyr)
library(xtable)

playerxgoals <- readRDS('IgnoreList/xGoalsByPlayer.rds')
minutesPlayed <- readRDS('IgnoreList/MinutesByGameID.rds')
teamxgoals <- readRDS('IgnoreList/xGoalsByTeam.rds')
xgbygame <- readRDS('IgnoreList/xGoalsByTeam_byGame.rds')
keeperxgoals <- readRDS('IgnoreList/xGoalsByKeeper.rds')
conferences <- read.csv('teamsbyconferencebyseason.csv')
glossary <- read.csv('Glossary.csv')

playerpassing <- readRDS("IgnoreList/xPassingByPlayer.rds")
teampassing.offense <- readRDS("IgnoreList/xPassingByTeamOffense.rds")
teampassing.defense <- readRDS("IgnoreList/xPassingByTeamDefense.rds")

source('ShooterxGoalsFunction.R')
source('ShooterxGoalsFunction_perminute.R')
source('TeamxGoalsFunction.R')
source('KeeperxGoalsFunction.R')
source("PasserxPassesFunction.R")
source("TeamxPassesFunction.R")

# Player xGoals ####
dt_xgoals <- lapply(2011:max(playerxgoals$Season),
                    FUN = function(x){
                      dt_total <- shooterxgoals.func(playerxgoals,
                                                     date1 = as.Date('2000-01-01'),
                                                     date2 = as.Date('9999-12-31'),
                                                     season = x,
                                                     minfilter = 0,
                                                     shotfilter = 0,
                                                     keyfilter = 0,
                                                     byteams = F,
                                                     byseasons = T,
                                                     OtherShots = T,
                                                     FK = T,
                                                     PK = T) %>% 
                        select(-c(Dist, Dist.key)) %>%
                        mutate(`G+A` = Goals + Assts) %>%
                        rename(Sht = Shots,G = Goals, KP = KeyP, A = Assts) %>%
                        select(Player:xG, `G-xG`:`xG+xA`, xPlace)
                      
                      dt_per96 <- shooterxgoals_perminute(playerxgoals,
                                                          minutes_df = minutesPlayed,
                                                          date1 = as.Date('2000-01-01'),
                                                          date2 = as.Date('9999-12-31'),
                                                          season = x,
                                                          shotfilter = 0,
                                                          keyfilter = 0,
                                                          minfilter = 0,
                                                          byseasons = T,
                                                          byteams = F,
                                                          OtherShots = T,
                                                          FK = T,
                                                          PK = T) %>%
                        mutate(`G+A` = Goals + Assts) %>%
                        rename(Sht = Shots,G = Goals, KP = KeyP, A = Assts) %>%
                        select(Player:xG, `G-xG`:`xG+xA`, xPlace) 
                      
                      namesFL <- as.data.frame(do.call("rbind", strsplit(sub(" ", ";", dt_total$Player), ";"))) %>%
                        mutate_all(.funs = as.character)
                      names(namesFL) <- c("First", "Last")
                      namesFL <- namesFL %>%
                        mutate(First = ifelse(First == Last, "", First))
                      
                      if(x >= 2015){
                        output <- data.frame(namesFL, dt_total %>% 
                                               left_join(dt_per96 %>%
                                                           select(-Team),
                                                         by = c("Player", "Season", "Min"),
                                                         suffix = c("", "p96")) %>%
                                               ungroup() %>%
                                               select(-Player), check.names = F)
                        output <- xtable(output, 
                                         digits = c(0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 2, 2, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2))
                        write.table(print.xtable(output, 
                                                 type = "html",
                                                 include.rownames = F,
                                                 print.results = F), 
                                    file = paste0("C:/Users/Matthias.Kullowatz/Dropbox/ASA Blog Data/HTMLOutputs/Player_xGoals_", x, ".txt"),
                                    row.names = F,
                                    quote = F)
                      } else{
                        output <- data.frame(namesFL, dt_total %>%
                                               ungroup() %>%
                                               select(-Player, -Min), check.names = F)
                        
                        output <- xtable(output, 
                                         digits = c(0, 0, 0, 0, 0, 0, 0, 2, 0, 2, 2, 0, 0, 2, 2, 2, 2))
                        write.table(gsub("table border=1", 'table border=1 class = "sortable"',
                                         print.xtable(output, 
                                                      type = "html",
                                                      include.rownames = F,
                                                      print.results = F)),
                                    file = paste0("C:/Users/Matthias.Kullowatz/Dropbox/ASA Blog Data/HTMLOutputs/Player_xGoals_", x, ".txt"),
                                    row.names = F,
                                    quote = F)
                      }
                      
                    })


# Team xGoals ####
dt_xG_team <- lapply(2011:max(teamxgoals$Season),
                     FUN = function(x){
                       dt_total_bas <- teamxgoals.func(teamxgoals = teamxgoals,
                                                       date1 = as.Date('2000-01-01'),
                                                       date2 = as.Date('9999-12-31'),
                                                       season = x,
                                                       even = F,
                                                       pattern = 'All',
                                                       pergame = F,
                                                       advanced = F,
                                                       venue = c('Home', 'Away'),
                                                       byseasons = T,
                                                       plot = F) %>%
                         select(Team, GP = Games, ShtF, ShtA, GF, GA, GD, Pts)
                       
                       dt_total_adv <- teamxgoals.func(teamxgoals = teamxgoals,
                                                       date1 = as.Date('2000-01-01'),
                                                       date2 = as.Date('9999-12-31'),
                                                       season = x,
                                                       even = F,
                                                       pattern = 'All',
                                                       pergame = F,
                                                       advanced = T,
                                                       venue = c('Home', 'Away'),
                                                       byseasons = T,
                                                       plot = F) %>%
                         select(Team, xGF, xGA, xGD, TSR, PDO, Conf)
                       
                       dt_per96_bas <- teamxgoals.func(teamxgoals = teamxgoals,
                                                       date1 = as.Date('2000-01-01'),
                                                       date2 = as.Date('9999-12-31'),
                                                       season = x,
                                                       even = F,
                                                       pattern = 'All',
                                                       pergame = T,
                                                       advanced = F,
                                                       venue = c('Home', 'Away'),
                                                       byseasons = T,
                                                       plot = F) %>%
                         select(Team, ShtF, ShtA, GF, GA, GD)
                       
                       dt_per96_adv <- teamxgoals.func(teamxgoals = teamxgoals,
                                                       date1 = as.Date('2000-01-01'),
                                                       date2 = as.Date('9999-12-31'),
                                                       season = x,
                                                       even = F,
                                                       pattern = 'All',
                                                       pergame = T,
                                                       advanced = T,
                                                       venue = c('Home', 'Away'),
                                                       byseasons = T,
                                                       plot = F) %>%
                         select(Team, xGF, xGA, xGD)
                       
                       output <- dt_total_bas %>%
                         left_join(dt_total_adv, "Team") %>%
                         left_join(dt_per96_bas, "Team", suffix = c("", "/g")) %>%
                         left_join(dt_per96_adv, "Team", suffix = c("", "/g")) %>%
                         ungroup() %>%
                         mutate(`GD-xGD` = GD - xGD) %>%
                         select(Team:GD, xGF:xGD, `GD-xGD`, `ShtF/g`:`xGD/g`, Conf)
                       
                       output <- xtable(output, 
                                        digits = c(0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 0),
                                        align = rep("c", ncol(output) + 1))
                       write.table(gsub("table border=1", 'table border=1 class = "sortable"',
                                        print.xtable(output, 
                                                     type = "html",
                                                     include.rownames = F,
                                                     print.results = F)),
                                   file = paste0("C:/Users/Matthias.Kullowatz/Dropbox/ASA Blog Data/HTMLOutputs/Team_xGoals_", x, ".txt"),
                                   row.names = F,
                                   quote = F)
                     })

# Player xPassing ####

lapply(2015:max(playerpassing$year),
       FUN = function(x){
        all <- passer.xpasses(playerpassing,
                        minpasses = 0,
                        seasonfilter = x,
                        byteams = F,
                        byseasons = T,
                        third.filter = "All") %>%
          mutate(Per100 = Per100/100) %>%
          rename(`%` = PassPct, `Exp%` = xPassPct, `%Diff` = Per100)
        
        att <- passer.xpasses(playerpassing,
                              minpasses = 0,
                              seasonfilter = x,
                              byteams = F,
                              byseasons = T,
                              third.filter = "Att") %>%
          mutate(Per100 = Per100/100) %>%
          rename(`%` = PassPct, `Exp%` = xPassPct, `%Diff` = Per100)
        
        mid <- passer.xpasses(playerpassing,
                              minpasses = 0,
                              seasonfilter = x,
                              byteams = F,
                              byseasons = T,
                              third.filter = "Mid") %>%
          mutate(Per100 = Per100/100) %>%
          rename(`%` = PassPct, `Exp%` = xPassPct, `%Diff` = Per100)
        
        def <- passer.xpasses(playerpassing,
                              minpasses = 0,
                              seasonfilter = x,
                              byteams = F,
                              byseasons = T,
                              third.filter = "Def") %>%
          mutate(Per100 = Per100/100) %>%
          rename(`%` = PassPct, `Exp%` = xPassPct, `%Diff` = Per100)
        
        dt <- all %>%
          select(-c(Season, Score, Distance)) %>%
          full_join(def %>%
                      select(-c(Season, Team, Pos, Score, Distance)), 
                    by = c("Player"), 
                    suffix = c("_all", "_def")) %>%
          full_join(mid %>%
                      select(-c(Season, Team, Pos, Score, Distance)), 
                    by = c("Player")) %>%
          full_join(att %>%
                      select(-c(Season, Team, Pos, Score, Distance)), 
                    by = c("Player"), 
                    suffix = c("_mid", "_att"))
        dt <- dt %>%
          mutate_at(.vars = setdiff(names(dt), c("Player", "Team", "Pos")),
                    .funs = function(x) ifelse(is.na(x), 0, x))
        
        
        namesFL <- as.data.frame(do.call("rbind", strsplit(sub(" ", ";", dt$Player), ";")))
        names(namesFL) <- c("First", "Last")
        
        dt <- data.frame(namesFL, dt %>% select(-Player), check.names = F)
        
        output <- print.xtable(xtable(dt, 
                         digits = c(0, 0, 0, 0, 0, 0, 3, 3, 3, 2, 0, 3, 3, 3, 2, 0, 3, 3, 3, 2, 0, 3, 3, 3, 2),
                         align = rep("c", ncol(dt) + 1)),
                         type = "html",
                         include.rownames = F,
                         print.results = F)
        # replace column tags and include script
        write.table(gsub("_all|_def|_mid|_att", "",
                         gsub("<table border=1>", '<script>
$(document).ready(function() {
$("#myTable").tablesorter();
  });
</script>
<TABLE border=1 id="myTable" class="tablesorter"><thead>
<TR><TH colspan="4" class="sorter-false"></TH><TH colspan="5" class="sorter-false">All Passes</TH><TH colspan="5" class="sorter-false">Defensive Third</TH><TH colspan="5" class="sorter-false">Middle Third</TH><TH colspan="5" class="sorter-false">Attacking Third</TH></TR>
',
                         output)),
                    file = paste0("C:/Users/Matthias.Kullowatz/Dropbox/ASA Blog Data/HTMLOutputs/Player_xPasses_", x, ".txt"),
                    row.names = F,
                    quote = F)  
       })
  
# Keeper xGoals ####
# First	Last	Team	Mins	Saves	GA	SOG	xGA	GA-xGA	GA-xGAp96
lapply(2011:max(keeperxgoals$Season),
       FUN = function(x){
       dt <- keeperxgoals.func(keeperxgoals %>%
                             mutate(date = as.Date(date, format = '%m/%d/%Y')),
                           date1 = as.Date('2000-01-01'),
                           date2 = as.Date('9999-12-31'),
                           season = x,
                           shotfilter = 0,
                           byteams = F,
                           byseasons = T,
                           OtherShots = T,
                           FK = T,
                           PK = T) %>%
         select(-Season) %>%
         rename(SOG = Shots, GA = Goals, xGA = xG, `GA-xGA` = `G-xG`)
       
       output <- xtable(dt, 
                        digits = c(0, 0, 0, 0, 0, 0, 2, 1, 2, 2),
                        align = rep("c", ncol(dt) + 1))
       write.table(gsub("table border=1", 'table border=1 class = "sortable"',
                        print.xtable(output, 
                                     type = "html",
                                     include.rownames = F,
                                     print.results = F)),
                   file = paste0("C:/Users/Matthias.Kullowatz/Dropbox/ASA Blog Data/HTMLOutputs/Keeper_xGoals_", x, ".txt"),
                   row.names = F,
                   quote = F)
       
       })