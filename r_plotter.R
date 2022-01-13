create_plot <- function(goal_movie, parameter_movies, weights, png_title="plot.png"){
  # find longest parameter and short every parameter movie with more than 20 chars
  longest_parameter <- 0
  
  for (title in parameter_movies){
    l = nchar(title)
    if (l > 19){
      parameter_movies[match(title, parameter_movies)] <- paste0(substr(title, 1, 19), "...")
      l = 19
    }
    if (l > longest_parameter){
      longest_parameter <- l
    }
  }
  # short goal movie if longer than 20 chars
  if (nchar(goal_movie) > 15){
    goal_movie <- paste0(substr(goal_movie, 1, 15), "...") 
  }
  
  # short weights if their digit places are more than 5:
  for(weight in weights){
    weights[match(weight, weights)] <- round(weight, 4)
  }
  
  
  # create x and y coordinates for every parameter movie
  # and some text adjustments
  nn <- data.frame(matrix(nrow=0, ncol = 2))
  names(nn) <-c ("x","y")
  text_pos <- c()
  offset_vector <- c()
  for(val in 0:(length(parameter_movies)-1)){
    de <- data.frame(0, val*7+5)
    names(de) <- c("x","y")
    nn <- rbind(nn, de)
    text_pos <- c(text_pos,2)
    offset_vector <- c(offset_vector, 1.6)
  }
  
  # add the x and y coordinates of the goal movie tot the dataframe
  # also some text adjustments
  max_y <- (length(parameter_movies)-1)*7 + 10
  max_x <- sqrt(length(parameter_movies))
  goal_x <- 3
  goal_y <- max_y / 2
  goal <- data.frame(goal_x, goal_y)
  text_pos <- c(text_pos, 4)
  offset_vector <- c(offset_vector, 0.4)
  names(goal) <- c("x","y")
  nn <- rbind(nn, goal)
  
  len_goal_movie = nchar(goal_movie)
  
  min_x <- 0
  
  # use created data to create a plot of the nodes
  # also create a png
  png(filename=png_title,width=1200,height=1000, bg=NA)
  
  plot(nn,
       col = "#999999",
       xlab = " ",
       ylab = " ",
       pch = 19,
       cex = 7,
       lty = "solid",
       lwd =2,
       ylim = c(0,max_y),
       xlim = c(-1.4, 4),
       bty="n",
       axes = F,
       yaxt="n",
       xaxt="n"
  )
  # add some text with previously created text adjustments
  text(nn, labels=c(parameter_movies,goal_movie), cex=1.8, pos=text_pos, offset=offset_vector, col="white")
  
  # remove the y coordinate of the goal node since we don't need it anymore
  # and have it stored anyways as goal_y
  y_coords <- nn[2]
  y_coords <- y_coords[-nrow(y_coords),]
  
  # get min and max abs weight for line width
  max_weight <- abs(weights[1])
  min_weight <- abs(weights[1])
  for(weight in weights){
    abs_weight <- abs(weight)
    if(abs_weight > max_weight){
      max_weight <- abs_weight
    }else if(abs_weight < min_weight){
      min_weight <- abs_weight
    }
  }
  
  # create lines between nodes
  for(coord in y_coords){
    # color = gray if weight > 0 else red
    if(weights[match(coord,y_coords)] >= 0){
      color <- "#858585"
    }else{
      color <- "#e23128"
    }
    
    line_width = ((abs(weights[match(coord,y_coords)]) - min_weight)/max_weight)*8 + 1
    arrows(0.46+0.01*length(parameter_movies), coord, goal_x-0.06, goal_y, code=0, col=color, lwd = line_width)
    text(0.27+0.01*length(parameter_movies)^1/2, coord, labels= weights[match(coord,y_coords)], cex=1.8, col="white")
  }
  
  # save the image
  dev.off() 
}