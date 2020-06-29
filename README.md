# COVID-19
Using published [data](https://data.gov.il/dataset/covid-19/resource/d337959a-020a-4ed3-84f7-fca182292308) from the Israeli Ministry of Health. I ran a prediction modelto the odds of having the Coronavirus according to key symptoms. The data contains ~15 observations of tests in Israel.
After the data wrangling and cleaning, Here's some (nice) mosaic plots to give us some insight about the data before we start the prediction analysis:

<a><img src="https://github.com/elior631/COVID-19/blob/master/Rplot-%20cough.png?raw=true" alt="Cough" width="500" height="300" /></a>

<a><img src="https://github.com/elior631/COVID-19/blob/master/Rplot-fever%20-mosaic.png?raw=true" alt="Fever" align="center" width="500" height="300" /></a>


We can see very nicely from both figures that as expected, the Fever is a good indication for the virus. Also, the Cough can be a good predictor. Probably the interaction of thetwo features can be used as a good predictor. However, let's give the algorithm to lead us to that conclusion.
I mainly used the Tidymodels package to proceed the algorithm with the 'Recipe coding'. Since our output will be binary (have Covid-19 or not) I'll use a logistic regression model. After a few tests I picked the Lasso regularization. Please see the predictive power of the model with AUC curve on the training set and the test set:

## Training set AUC curve
<a><img src="https://github.com/elior631/COVID-19/blob/master/Rplot-AUC-Training.png" alt="training" width="500" height="300" /></a>

## Test set AUC curve
<a><img src="https://github.com/elior631/COVID-19/blob/master/Rplot-AUC-Test.png" alt="test" width="500" height="300" /></a>


We can see that the curves are almost the same. Namely, the model is not overfitted, a very important issue we need to overcome.
The predictive power in the model is ~80% which I find not bad at all. If too many people want to be tested, a small questionnaire can help the policy maker to prioritizewho should be tested first.
Finally, as promised earlier, the last figure shows who are the most important predictors in the model: sore throat and shortness of breath. Not surprisingly, the second most important is the interaction of cough and fever as discussed:

## Feature importance

<a><img src="https://github.com/elior631/COVID-19/blob/master/Rplot-%20VIP-analysis.png" alt="VIP" width="500" height="300" /></a>


Thank you.
For additional questions, don't hesitate to contact me.
