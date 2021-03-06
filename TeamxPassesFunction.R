# Aggregate team passing metrics for shiny app

# # Sample inputs ####
# library(dplyr)
# offense <- readRDS("IgnoreList/xPassingByTeamOffense.rds")
# defense <- readRDS("IgnoreList/xPassingByTeamDefense.rds")
# gamesplayed <- readRDS("IgnoreList/GamesPlayed_forTeamPassing.rds")
# season <- 2016:2017
# byseasons <- T
# third.filter <- c("Att")
# pergame = T

teampassing.func <- function(offense,
                             defense,
                             season,
                             byseasons,
                             third.filter,
                             pergame = F,
                             games_df = gamesplayed){
  
  if(!byseasons){
    games_df <- games_df %>%
      filter(year %in% season) %>%
      group_by(team) %>%
      summarize(Games = sum(Games)) %>%
      ungroup()
  }
  
  temp <- offense %>%
    left_join(defense, 
              by = c("year", "team" = "team.1", "third"), 
              suffix = c("f", "a")) %>%
    left_join(games_df,
              by = c("year", "team")[c(byseasons, T)]) %>%
    ungroup() %>%
    filter(year %in% season,
           third %in% third.filter) %>%
    group_by_(.dots = c("team", "year")[c(T, byseasons)]) %>%
    summarize(Games = Games[1],
              PassF = sum(Nf),
              PctF = sum(successesf)/PassF,
              xPctF = sum(expf)/PassF,
              ScoreF = (PctF - xPctF)*PassF,
              Per100F = ScoreF*100/PassF,
              VertF = sum(Vert.Distf)/sum(successesf),
              PassA = sum(Na),
              PctA = sum(successesa)/PassA,
              xPctA = sum(expa)/PassA,
              VertA = sum(Vert.Dista)/sum(successesa),
              ScoreA = (PctA - xPctA)*PassA,
              Per100A = ScoreA*100/PassA,
              ScoreDiff = ScoreF - ScoreA,
              VertDiff = VertF - VertA) %>%
    ungroup()
  
  if(byseasons){
    temp <- temp %>%
      rename("Season" = "year")
  }
  
  if(pergame){
    return(temp %>%
             mutate(`PassF/g` = PassF/Games,
                    `ScoreF/g` = ScoreF/Games,
                    `PassA/g` = PassA/Games,
                    `ScoreA/g` = ScoreA/Games,
                    `ScoreDiff/g` = ScoreDiff/Games) %>%
             select(-c(PassF, ScoreF, PassA, ScoreA, ScoreDiff))%>%
             select_(.dots = c("team", "Season"[byseasons], "Games", "`PassF/g`", 
                               "PctF", "xPctF", "`ScoreF/g`", "Per100F", 
                               "VertF", "`PassA/g`", "PctA", "xPctA", 
                               "`ScoreA/g`", "Per100A", "VertA", "`ScoreDiff/g`", "VertDiff")) %>%
             arrange(desc(`ScoreDiff/g`)) %>%
             rename("Team" = "team"))
    
  } else{
    return(temp %>%
             arrange(desc(ScoreDiff)) %>%
             rename("Team" = "team"))
  }
}

# # Function example
# library(dplyr)
# teampassing.func(offense = readRDS("IgnoreList/xPassingByTeamOffense.rds"),
#                  defense = readRDS("IgnoreList/xPassingByTeamDefense.rds"),
#                  season = 2017:2018,
#                  byseasons = T,
#                  third.filter = "Att",
#                  pergame = T,
#                  games_df = gamesplayed)
