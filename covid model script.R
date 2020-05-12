if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,   # for data wrangling and visualization
  tidymodels,  # for data modeling
  vip,         # for variable importance
  here,        # for referencing files and folders
  readxl,      # for reading xlsx files
  ggmosaic,
  glmnet,
  knitr
  )
set.seed(1203)
covid_raw <- 
  here("data.csv") %>% 
  read_csv()


#Replace all NULL values with NA’s
is.na(covid_raw[,-1]) <- covid_raw[,-1] == "NULL"

covid <- covid_raw %>%
  select(-test_date, -test_indication) %>% 
  filter(corona_result != "אחר") %>% 
  drop_na() %>%
  mutate(
    corona_result = if_else(corona_result == "שלילי", "negative", "positive"),
    gender = if_else(gender == "זכר", "male", "female")
  ) %>% 
  mutate_all(as_factor)


write.csv(
  covid,
  file = here("06-classification/data","covid_proc.csv"),
  row.names = FALSE
)
# summary stat before analysis. relation of having  COVID and Fever
 covid %>%
   ggplot() + 
   geom_mosaic(aes(x = product(corona_result,fever),
                fill = corona_result)) +
  labs( x = "Fever",
        y = "Result",
        fill = ""
        )

 # summary stat before analysis. relation of having  COVID and cough   
 covid %>%
   ggplot() + 
   geom_mosaic(aes(x = product(corona_result,cough),
                   fill = corona_result)) +
   labs(x = "cough",
        y = "Result",
        fill = ""
   )
 
#split
covid_split <- covid %>% initial_split(prop = 0.5)
covid_train <- covid_split %>% training()
covid_test <- covid_split %>% testing()

covid_folds <- covid_train %>% vfold_cv(v = 5, strata = corona_result)

#BUILD THE MODEL

## tune() its because we will define later the best Lambda, mixture is because we want Lasso regularization
logit_model <- 
  logistic_reg() %>%
  set_engine("glmnet") %>% 
  set_mode("classification") %>%
  set_args(penalty = tune(), mixture = 1)

# on_hot pic all the variable.
covid_rec <- 
  recipe(corona_result ~ ., data = covid_train) %>% 
  step_dummy(all_nominal(), -corona_result, one_hot = TRUE) %>% 
  step_interact(~ all_predictors():all_predictors()) %>%
  step_normalize(all_predictors()) %>% # because we are in Lasso, we need to dp minus average and devide by sd.
  step_zv(all_predictors())  # "zero variance" if there is a fix parameter such as male or feamale - drop them. its important since we're using interactions, we'll always get zero, so we avoid what ew don't need

# lets see how the data looks. juice - do it on the trainig set
covid_rec %>%
  prep() %>%
  juice()

# Create the workflow - join the recepie and the model
logit_wfl <- 
  workflow() %>% 
  add_recipe(covid_rec) %>% 
  add_model(logit_model)
#model properties
logit_wfl

# tuning the model

roc_only <- metric_set(roc_auc)

logit_result <- 
  logit_wfl %>% 
  tune_grid(
    resamples = covid_folds,
    control = control_grid(save_pred = TRUE),
    metrics = roc_only
  )
# plot Cross Validation results - the AUC as a function of the lambda 
logit_result %>% 
  collect_metrics() %>% 
  ggplot(aes(x = penalty, y = mean)) + 
  geom_point() + 
  geom_line() + 
  ylab("Area under the ROC Curve") +
  scale_x_log10(labels = scales::label_number())

# show best results:
logit_result %>% 
  show_best(metric = "roc_auc", n = 10)

# set best Lambda
select_best(
  metric = "roc_auc"
)


lambda_1se <- logit_result %>% 
  select_by_one_std_err(
    metric = "roc_auc",
    desc(penalty)
  ) %>% 
  select(penalty)

# Last fit on the test set
## final workflow

logit_wfl_final <- 
  logit_wfl %>%
  finalize_workflow(lambda_1se)

#Last fit on the test set
logit_last_fit <- 
  logit_wfl_final %>% 
  last_fit(covid_split)
 
# ROC AUC on  traint set
logit_wfl_final %>%
  fit(data = covid_train) %>% 
  predict(new_data = covid_train, type = "prob") %>% 
  roc_curve(covid_train$corona_result, .pred_negative) %>% 
  autoplot() +
  labs(title = "Training set AUC")

# ROC AUC on  test set

logit_last_fit %>% 
  collect_predictions() %>% 
  roc_curve(corona_result, .pred_negative) %>% 
  autoplot() +
  labs(title = "Test set AUC")

logit_last_fit %>% 
  collect_metrics() %>% 
  filter(.metric == "roc_auc")
# the accuaricy of the model on the test set

# Variables important
logit_last_fit %>% 
  pluck(".workflow", 1) %>%   
  pull_workflow_fit() %>% 
  vip(num_features = 10,geom = c("col", "point", "boxplot", "violin"), color = "yellow", fill = "lightgreen", alpha = 0.7 )

