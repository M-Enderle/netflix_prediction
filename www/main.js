var movies_error = true;
var selection_error = true;


function select_star(img) {

    var elements = $(img).nextAll("img");

    var rating = elements.length + 1;
    var movie = $(img).parent().parent().parent().attr("id")
    // eval(movie + " = " + rating);
    Shiny.setInputValue(movie, rating);
    
    elements.each(function(index){
        $(this).css('filter', 'saturate(100%)');
    });
    
    elements = $(img).prevAll("img");
    elements.each(function(index){
        $(this).css('filter', 'saturate(0%)');
    });

    $(img).css('filter', 'saturate(100%)');
}


const element = document.querySelector("#movie_wall");
element.addEventListener('wheel', (event) => {
  event.preventDefault();

  element.scrollBy({
    left: event.deltaY < 0 ? -30 : 30,
  });
});


document.getElementById("button-wrapper").addEventListener("mouseleave", function( event ) {
  document.getElementById("error-message").style.visibility = "hidden";
  document.getElementById("error-message").style.opacity = 0;
}, false);


document.getElementById("button-wrapper").addEventListener("mouseenter", function( event ) {
  if($("#submit").prop("disabled")){
    document.getElementById("error-message").style.visibility = "visible";
    document.getElementById("error-message").style.opacity = 1;
  }
}, false);


function update_button_status() {
  if(!movies_error && !selection_error){
    $("#submit").prop("disabled",false);
  } else {
    let error_message = "";
    if(movies_error && selection_error){
      error_message = "Please select at least 2 movies you'd like to rate and one goal movie";
    } else if (movies_error) {
      error_message = "Please select at least 2 movies you'd like to rate";
    } else {
      error_message = "Please select a goal movie";
    }
    
    console.log(error_message)
    $("#error-message").text(error_message);
    
    $("#submit").prop("disabled",true);
  }
}


var movies_exists = setInterval(function() {
  if ($('#parameter_movies-selectized').length == 1) {
    $("#submit").prop("disabled",true)
    $('#parameter_movies-selectized').parent().on('DOMSubtreeModified', function(){
      if($("#parameter_movies-selectized").prevAll("div").length > 1){
        movies_error = false;
      } else {
    	  movies_error = true;
      }
      update_button_status();
    });
      clearInterval(movies_exists);
   }
}, 100);


var selection_exists = setInterval(function() {
  if ($('#selected_goal_movie-selectized').length == 1) {
    $('#selected_goal_movie-selectized').parent().on('DOMSubtreeModified', function(){
      if($("#selected_goal_movie-selectized").prev("div").length == 1){
        selection_error = false;
      } else {
    	  selection_error = true;
      }
      update_button_status();
    });
      clearInterval(selection_exists);
   }
}, 100);


