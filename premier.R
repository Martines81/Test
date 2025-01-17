library(prioritizr)
library(data.table)
library(raster,rgdal)



{#On enleve les parcelles qui ont ete deja exploite des prix, il faut l enlever plus loin de la couche raster
  nvllExpl <- c()
  exploit <- c()#Les parcelles deja exploitees
  for (i in 1:nbCol){
    for(j in 1:nbCol){
      if (abs(j-5)+i <= 4){
        exploit <- c(exploit,0)
      }else{exploit <- c(exploit,1)}
    }
  }
}

{
  parcellesExploitees <- raster(ncol=10, nrow=10,xmn=0, xmx=1, ymn=0, ymx=1,crs=as.character(NA))
  
  values(parcellesExploitees) <- exploit
  plot(parcellesExploitees,main = "les parcelles non exploitees")
  
  nouvellesParcelles <- raster(ncol=10, nrow=10,xmn=0, xmx=1, ymn=0, ymx=1,crs=as.character(NA))
  
  listSol <- c()
  listExploitee <- c()
  listParcellesAn <- c()
  listAnnee <- c()
}



for (k in 1:5){  
  {
    nbCol <- 10
    listId <- c()
    listVal <- c()
    listIn <- c()
    listOut <- c()
  }
  
  for (i in 1:nbCol){
    for(j in 1:nbCol){
      ID <- toString(i+(j-1)*nbCol)
      listId <- c(listId, ID)
      listVal <- c(listVal,5 + i + abs(j-5))
      if (i == 1 & j == 5) {
        listIn <- c(listIn,TRUE)
      }
      else{
        listIn <- c(listIn,FALSE)
      }
      if (runif(1,0,1)<= 0.2){
        listOut <- c(listOut,TRUE)
      }else{
        listOut <- c(listOut,FALSE)
      }
    }
  }
  
  
  listVal <- listVal * exploit
  
  
  
  cost <- raster(ncol=10, nrow=10,xmn=0, xmx=1, ymn=0, ymx=1,crs=as.character(NA))
  
  values(cost) <- listVal
  
  
  lockIn <- raster(ncol=10, nrow=10,xmn=0, xmx=1, ymn=0, ymx=1,crs=as.character(NA))
  
  values(lockIn) <- listIn
  
  
  lockOut <- raster(ncol=10, nrow=10,xmn=0, xmx=1, ymn=0, ymx=1,crs=as.character(NA))
  
  values(lockOut) <- listOut*exploit
  
  
  
  r <- raster(ncol=10, nrow=10,xmn=0, xmx=1, ymn=0, ymx=1,crs=as.character(NA))
  
  
  vals <- c()
  for (i in 1:nbCol){
    for (j in 1:nbCol){
      if (j <= 5){
        if (i <= 5){
          vals <- c(vals,rnorm(1))#modifier le point de depart
        }else{
          vals <- c(vals,rnorm(1,10))
        }
      }else{
        if (i <= 5){
          vals <- c(vals,rnorm(1,20))
        }else{
          vals <- c(vals,rnorm(1,30))
        }
      }
    }
  }
  vals <- vals * exploit  
  
  values(r) <- vals
  
  r3 <- r
  contraint <- stack(r,r,r3)
  
  
  
  plot(cost, main="x les couts")
  
  plot(r, main="r les effectifs de conservations")
  
  plot(lockIn, main="lockIn")
  
  plot(lockOut, main="lockOut")
  
  
  p1 <- problem(cost, features = contraint) %>%
    add_min_set_objective() %>%
    add_relative_targets(0.15) %>%
    add_binary_decisions() %>%
    add_contiguity_constraints()  %>%
    add_locked_in_constraints(lockIn)%>%
    add_locked_out_constraints(lockOut)%>%
    add_gurobi_solver(gap=0)%>%add_boundary_penalties(penalty = 15, edge_factor = 0.5)
  
  s1 <- solve(p1)
  
  plot(s1,main = "voici la solution")
  
  
  print(attr(s1, "objective"))
  
  print(attr(s1, "runtime"))
  
  print(attr(s1, "status"))
  
  
  #on actualise les parcelles exploitees
  for (i in 1:(nbCol*nbCol)){
    nvllExpl[i] <- exploit[i] + s1@data@values[i]-1
    if (nvllExpl[i] <= 0){nvllExpl[i] <- 0}
  }
  values(nouvellesParcelles) <- nvllExpl
  plot(nouvellesParcelles,main = "les nouvelles parcelles")
  
  
  
  
  
  #on on regarde quelles sont les nouvelles parcelles exploitees
  for (i in 1:(nbCol*nbCol)){
    exploit[i] <- exploit[i] - s1@data@values[i]
    if (exploit[i] <= 0){exploit[i] <- 0}
  }
  values(parcellesExploitees) <- exploit
  plot(parcellesExploitees,main = "les parcelles non exploitees")
  
  listSol <- stack(s1,listSol)
  listParcellesAn <- stack( nouvellesParcelles,listParcellesAn)
  listExploitee <- stack(parcellesExploitees,listExploitee)
  listAnnee <- c(listAnnee, toString(6-k))
}
#idee pour integrer plusieurs rotation  juste plusieurs couches

spplot(listSol,main="la liste des solution selon les annees",names.attr=listAnnee)
spplot(listParcellesAn, main="la liste des parcelles exploitee cette annee",names.attr=listAnnee)
spplot(listExploitee, main="la liste des parcelles qui n'ont pas encore ete exploitees",names.attr=listAnnee)

