# Netflix movie prediction

## Introduction

This project was created for my course assistance systems in cooperation with [Forian Eder](https://github.com/FlorianEder). The dataset was released by netflix in relation to a competition for the best algorith to predict new movies for users. You can find the dataset [here](https://www.kaggle.com/netflix-inc/netflix-prize-data). 

Our approach simplified the idea by only predicting on one single outcome movie you choose manually.

If you want to try it out now, you can visit out [interactive demo](https://thdmoritzenderle.shinyapps.io/netflix_prediction/).

## Installation

Install the `shiny` package with the R console

```r
install.packages("shiny")
```

Download and run this GitHub repository

```r
shiny::runGitHub(repo = "THDMoritzEnderle/netflix_prediction", ref="main") 
```

## Usage

#### Choosing the right dataset

When using the local install, you will be prompted to select a dataset. This might help you choose, which one fits your needs best:

| dataset name    | size   | information                                                                                                                 |
| --------------- | ------ | --------------------------------------------------------------------------------------------------------------------------- |
| large data set  | 232 MB | By far the largest data set, containing  900 movies and 95k customers. Use this, if you have a high end CPU or lots of time |
| small data set  | 6 MB   | Smallest dataset containing 100 movies and 20k customers. Use this for testing without expecting excact results             |
| normal data set | 80 MB  | Best for the average user. Contains 530 movies and 47k users. Balance between accuracy and loading times                    |
| few movies      | 61 MB  | Only contains 90 movies but 231k customers. This results in very high accuracy but comes at the cost of the few movies.     |

#### What can you do?

To start off, select the movies you watched and would like to rate on the top left. The movie posters will appear right next to it. Rate the movies based on your liking. 

Below this input field, you can select your goal movie, this is the movie you want to know the prediction of.

When you selected all movies, press the submit button and the model will start training. This may take a while based on the dataset, your hardware and the amount of movies you selected.

When the training is done, you can see the prediction appear on the movie poster in the bottom left corner. The graph shows the influences of each movie.

## Further plans

As for now, this project will not be continued. Possible further development could include the prediction for all movies and thus creating a ranking between those.
