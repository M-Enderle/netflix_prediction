
# install all necessary packages
list_of_packages <- c("devtools", "shiny", "reticulate", "ANN2", "shinycssloaders", "shinyjs", "tidyverse")
new_packages <- list_of_packages[!(list_of_packages %in% installed.packages()[, "Package"])]
if(length(new_packages)){
  install.packages(new_packages)
}

# load all necessary packages
lapply(list_of_packages, library, character.only = TRUE)

py_install(c("tmdbv3api", "Pillow"), pip=TRUE)
install_github("AnalytixWare/ShinySky")

source("r_plotter.R")
source_python('./utils.py')

# ask for data set
to_select <- list("large dataset (slower, but more accurate)", 
                  "small dataset (faster, but less accurate)", 
                  "normal dataset", 
                  "few movies (only 90 Movies, but very high accuracy)")


dataset_selection <- dlgList(to_select, title="Select a dataset")$res

if(length(dataset_selection) == 0){
  stop("Please choose one of the datasets!")
}

dataset_selection <- case_when(
  dataset_selection == to_select[1] ~ "dataset_large.csv",
  dataset_selection == to_select[2] ~ "dataset_small.csv",
  dataset_selection == to_select[3] ~ "dataset.csv",
  dataset_selection == to_select[4] ~ "few_movies_lots_of_customers.csv"
)

# check if the data set exists, if not download it
if(!file.exists(dataset_selection)){
  url <- case_when(
    dataset_selection == "dataset_large.csv"                ~ "https://cloud.enderle-solutions.de/index.php/s/iDJFyPrrW3GS4yQ/download/dataset_large.csv",
    dataset_selection == "dataset_small.csv"                ~ "https://cloud.enderle-solutions.de/index.php/s/T3YajZXGR8EGPj6/download/dataset_small.csv",
    dataset_selection == "dataset.csv"                      ~ "https://cloud.enderle-solutions.de/index.php/s/N6k4L3kNYdx6s8p/download/dataset.csv",
    dataset_selection == "few_movies_lots_of_customers.csv" ~ "https://cloud.enderle-solutions.de/index.php/s/wtHXZJ6pDgtxZTg/download/few_movies_lots_of_customers.csv"
  )
  download.file(url, dataset_selection)
}

# open dataset
print("opening dataset....")
whole_dataset <- read.csv(dataset_selection, header=TRUE, sep=";", fill=TRUE)

# shuffle the data set in case its sorted
dataset <- whole_dataset[sample(nrow(whole_dataset)),]

# declare some global variables
old_parameter_movies <- c()
old_goal_movie <- ""
model <- NULL
all_movies_with_whitespaces <- gsub("\\."," ", gsub("_", " ", c(colnames(dataset))))
movies_without_inputs <- all_movies_with_whitespaces
active_posters <- c()

# Define UI for application
ui <- shinyUI(
  fluidPage(
    
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    ),
    
    # left panel
    sidebarPanel(id="navigation",
                 # netflix logo
                 htmlOutput("logo"),
                 
                 # parameter movies input
                 selectizeInput(
                   inputId = 'parameter_movies',
                   label = 'movies to rate',
                   choices = sample(all_movies_with_whitespaces),
                   selected = NULL,
                   multiple = TRUE,
                   options = list(create = FALSE, maxOptions = 10)
                 ),
                 
                 # goal movies input
                 selectizeInput(
                   inputId = 'selected_goal_movie',
                   label = 'movie to predict',
                   choice = c('Choose a File Name' = '', sample(unique(all_movies_with_whitespaces))),
                   selected = NULL,
                   multiple = FALSE,
                   options = list(create = FALSE)
                 ),
                 
                 # submit button (and warning if needed)
                 div(
                   id="button_container",
                   div(class="center", id="button-wrapper", actionButton("submit","submit")),
                   div(id="error-message", "Please select at least 2 movies you'd like to rate and one goal movie")
                 ),
                 
                 # goal movie poster
                 div(class="center", div(id="goal-movie", uiOutput("goal"), textOutput("prediction")))
    ),
    
    mainPanel(
      # parameter movies posters and stars to rate
      wellPanel(id="movie_wall"),
      
      # error of neural network
      textOutput("error"),
      
      # plot
      div(shinycssloaders::withSpinner(
        imageOutput("graph"),
        type=3,
        color.background = "#1e1e1e",
        color = "#e50914"
      )
      )
    ),
    
    tags$script(src="main.js")
  )
)

# Define server logic
server <- function(input, output, session) {
  # netflix logo
  output$logo<-renderText({c('<img src="',"https://i.ibb.co/YjHHrcr/logo.png",'">')})
  
  # a transparent picture to make the loading animation work
  output$graph <- renderImage({
    list(src = "./www/transparent.png",
         contentType = "image/png",
         alt = "Waiting for Plot")
  }, deleteFile = FALSE)
  
  
  observeEvent(input$parameter_movies, {
    # render the selected parameter movie posters
    if(length(active_posters) > 0){
      for (i in 1:length(active_posters)) {
        poster <- active_posters[i]
        if(!(is.na(poster) || poster == '')){
          if(!(poster %in% input$parameter_movies)){
            idx <- active_posters %>% match(x = poster)
            active_posters <<- active_posters[-idx] 
            removeUI(
              selector = paste0("#",str_replace_all(poster, " ", "_"))
            )
            runjs(paste0("document.getElementById('",str_replace_all(poster, " ", "_"),"').remove()"));
          }
        }
      }
    }
    # and their ratings
    for (i in 1:length(input$parameter_movies)) {
      movie <- input$parameter_movies[i]
      if(!movie %in% active_posters){
        active_posters <<- c(active_posters, movie)
        insertUI("#movie_wall", "afterBegin", 
                 div(class="movie", name=movie, id=str_replace_all(movie, " ", "_"),
                     h3(str_trunc(movie, 20, "right")),
                     div(class="poster", style=paste0("background-image: url(",get_poster(movie),")")),
                     div(class="center",
                         div(class="stars",
                             img(src="Gold_Star.svg", onclick="select_star(this)", class="star"),
                             img(src="Gold_Star.svg", onclick="select_star(this)", class="star"),
                             img(src="Gold_Star.svg", onclick="select_star(this)", class="star"),
                             img(src="Gold_Star.svg", onclick="select_star(this)", class="star"),
                             img(src="Gold_Star.svg", onclick="select_star(this)", class="star")
                         )
                     )
                 )
        )
      }
    }
  })
  
  # render the goal movie poster
  output$goal <- renderUI({
    if (input$selected_goal_movie != ""){
      tags$img(src = get_poster(input$selected_goal_movie))
    }
  })
  
  # update goal selection bar every time a parameter movie gets selected or unselected
  observeEvent(input$parameter_movies, {
    before <- movies_without_inputs
    after <-  all_movies_with_whitespaces[-c(match(c(input$parameter_movies),all_movies_with_whitespaces))]
    if(before != "" && after != ""){
      if (!identical(before,after)){
        updateSelectizeInput(session, "selected_goal_movie", choices = after, selected = input$selected_goal_movie, server = TRUE)
      }
    }
  })
  
  # remove prediction, error and plot if goal movie changes
  observeEvent(input$selected_goal_movie, {
    output$prediction <- runjs('$("#prediction").css({"display": "none"})')
    output$error <- runjs('$("#error").css({"display": "none"})')
    output$graph <- renderImage({
      list(src = "./www/transparent.png",
           contentType = "image/png",
           alt = "Waiting for Plot")
    }, deleteFile = FALSE)
    
  })
  
  # submit button
  submit_movies <- observeEvent(input$submit, {
    prognose()
  })
  
  prognose <- reactive({
    
    # transform parameter movie and goal movies into their equal dataset form (without whitespaces)
    parameter_movies <- colnames(dataset[match(c(input$parameter_movies), all_movies_with_whitespaces)])
    goal_movie <- colnames(dataset[match(input$selected_goal_movie, all_movies_with_whitespaces)])
    
    # check whether parameter movies or goal movies have changed
    # if they haven't we don't have to recreate the model again
    if((length(parameter_movies) != length(old_parameter_movies)) || (sort(parameter_movies) != sort(old_parameter_movies)) || (goal_movie != old_goal_movie)){
      # prepare for next check
      old_parameter_movies <<- parameter_movies
      old_goal_movie <<- goal_movie
      
      # if everything somehow goes wrong there's a backup gif :)
      output$graph <- renderImage({
        list(src = "./loading.gif",
             contentType = 'image/gif',
             alt = "Waiting for Plot")
      }, deleteFile = FALSE)
      
      # split the dataset into train and test datasets (ratio 0.9)
      amount_rows <- nrow(dataset)
      split <- as.integer(0.9*amount_rows)
      train <- dataset[1:split,]
      test <- dataset[(split+1):amount_rows,]
      
      # add the goal_movie and remove all bad entries
      # bad entries:
      # -> the goal movie column is 0
      # -> every column is 0
      train <- train[, c(goal_movie,parameter_movies)]
      train <- train[train[,1] != 0, ]
      train <- train[apply(train[,-1], 1, function(x) !all(x==0)),]
      
      test <- test[, c(goal_movie, parameter_movies)]
      test <- test[apply(test[,-1], 1, function(x) !all(x==0)),]
      test <- test[test[,1] != 0, ]
      
      # add for every parameter movie a column with whether they have watched the movie (1) or not (0) 
      for(column in parameter_movies){
        renamed <- paste0(column,"_watched")
        parameter_movies <- c(parameter_movies, renamed)
        watched <- c(ifelse(train[,column] > 0, 1, 0))
        train[,renamed] <- watched
        
        watched <- c(ifelse(test[,column] > 0, 1, 0))
        test[,renamed] <- watched
      }
      
      # create formula
      form_parameter_movies <- paste(parameter_movies, collapse=" + ")
      form <- paste(c(goal_movie,form_parameter_movies), collapse=" ~ ")
      print(paste("formula: ", form))
      formula <- as.formula(form)
      
      # create X and Y of train dataset
      X_train <- train[, parameter_movies]
      Y_train <- train[, goal_movie]
      
      print(paste0("epochs: ", as.integer(max(c(12, 75 - length(parameter_movies) * length(parameter_movies) * 0.2)))))
      # create the neuralnetwork (epochs change based on how many parameters there are)
      model <<- neuralnetwork(X = X_train,
                              y = Y_train,
                              hidden.layers = c(),
                              regression=TRUE,
                              loss.type="absolute",
                              learn.rates=1e-04,
                              n.epochs = as.integer(max(c(12, 75 - length(parameter_movies) * length(parameter_movies) * 0.2))))
      
      # create X and Y of test dataset
      X_test <- subset(test, select=parameter_movies)
      Y_test <- test[, goal_movie]
      
      # create a matrix to predict with the test dataset
      X_matrix <- model.matrix(formula, test)[,2:(length(parameter_movies)+1)]
      prediction <- predict(model,X_matrix)$predictions
      
      # frame the results of the prediction
      results <- data.frame(actual = subset(test, select=goal_movie), 
                            prediction = round(predict(model,X_matrix)$predictions,1), 
                            abs_error = abs(prediction-Y_test), error = prediction-Y_test)
      colnames(results)<- c("actual","prediction","abs_error", "error")
      cat(paste0("\nerror: ", mean(results$abs_error), "\n"))
      error <- mean(results$abs_error)
      
      # show the error 
      output$error <- renderText({paste0("Test error: ", error)})
      
    }
    # store the user ratings
    user_rating <- c(replicate(length(input$parameter_movies), 0))
    
    for (i in 1:length(input$parameter_movies)) {
      movie <- input$parameter_movies[i]
      replaced <- str_replace_all(movie, " ", "_")
      rating <- eval(parse(text = paste0("input$",replaced)))
      
      if(!is.integer(rating)){
        rating <- 0
      }
      
      index <- match(movie, input$parameter_movies) 
      user_rating[i] <- rating / 5
    }
    
    # append whether the user rated a movie or not
    watched <- c(ifelse(user_rating > 0, 1, 0))
    user_rating <- c(user_rating, watched)
    
    # predict with user ratings
    prediction <- predict(model, as.data.frame(t(user_rating)))
    
    # create the plot
    create_plot(goal_movie, input$parameter_movies, c(model$Rcpp_ANN$getParams()$weights[[1]]))
    crop_image()
    
    # show the plot
    output$graph <- renderImage({
      list(src = "./plot.png",
           contentType = "image/png",
           alt = "Waiting for Plot")
    }, deleteFile = T)
    
    # show the result
    percentage <- as.integer(sum(prediction$predictions*100))
    output$prediction <- renderText({paste0(percentage, "%")})
    
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
