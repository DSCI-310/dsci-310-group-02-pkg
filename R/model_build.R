#' KNN Model Building
#'
#' Build the KNN model using the most accurate K value
#'
#' @import kknn
#' @import recipes
#' @import rsample
#' @import tidymodels
#' @import tune
#' @import parsnip
#' @import workflows
#
#'
#' @param train_data The training data for the model
#' @param recipe The recipe for the data to build model
#' @param col The column name of the response variable
#'
#' @return A fitted KNN model using the most accurate K value
#' @export
#'
#' @examples
#' model_build(iris, recipes::recipe(Species ~., data = iris), "Species")
#'
model_build <- function(train_data, recipe, col){

  if(!is.data.frame(train_data)){
    stop("'train_data' must be a dataframe")
  }

  if(!is.list(recipe)){
    stop("'recipe' must be the recipe in list type")
  }

  if(!is.character(col)){
    stop("'col' must be the column name of the response variable in string type")
  }

  neighbors <- NULL

  vfold <- vfold_cv(train_data, v = 10, strata = all_of(col))
  knn_tune <- nearest_neighbor(
    weight_func = "rectangular", neighbors = tune()) %>%
    set_engine("kknn") %>%
    set_mode("classification")

  # Set up the workflow for the knn fold
  knn_results <- workflow() %>%
    add_recipe(recipe) %>%
    add_model(knn_tune) %>%
    tune_grid(resamples = vfold, grid = 20) %>%
    collect_metrics()

  # Find the most accurate K value
  .metric <- NULL
  accuracies <- knn_results %>%
    filter(.metric == "accuracy")

  accurate_k <- accuracies %>% filter(mean == max(mean)) %>% slice(1)
  k <- accurate_k %>% pull(neighbors)

  # Use the most accurate K value to then build the Classification Model
  spec <- nearest_neighbor(weight_func = "rectangular", neighbors = k) %>%
    set_engine("kknn") %>%
    set_mode("classification")

  final_model <- workflow() %>%
    add_recipe(recipe) %>%
    add_model(spec) %>%
    fit(train_data)

  return(final_model)
}
