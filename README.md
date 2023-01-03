# Effect-of-Fungicide-on-Bees
Performed Survival Analysis on Bee Foraging Experiment to Estimate the Effect of Fungicide on Behavior

## Table of Contents

* Data
* Script

## Background

The use of fungicides is widespread within the US agricultural industry, and yet its ecological effects are not well studied. My collaborator Nicole Desjardins wanted determine the effect of fungicide on an important pollinator the European Honey Bee by exposing some colonies to the fungicide Pristine and then allowing them to forage for food. She then tracked which bees came back to the hive, when they came back, and she also recorded ecological factors such as temperature at the time of arrival. She compared these results to a control group which did not recieve pristine. I was recruited to determine if Pristine did in fact have an effect on bees and determine which other factors may have contributed to the bee's arrival time. 

## Methods

* Clean data to correct for data entry errors

* Performed a multiple logistic regression between the binary reponse variable (whether or not a bee returned to the hive before 3 hours elapsed) and the predictor variables tempertature and the fungicide treatment. 

* Performed a Cox proportinal hazards regression (survival analysis) between the continuous response variable (time it took for a bee to return to the hive) and the predictor variables tempertature and the fungicide treatment. 

* For both types of models I Tested for the presence of an interaction between the predictor variables by comparing AIC/BIC of models with and without an interaction. 

## Results

* What affected a bee's probability of returning
  - The model without an interaction had the lowest AIC/BIC value
  - All effects were significant
  - Having pristine lowers the probability of returning to the nest as does higher temperatures. This latter effect is exagerated by the presence of Pristine. 

* What affected a bee's time to return to the nest
  - The model with an interaction had the lowest AIC/BIC value
  - All effects were significant except for the main effect of temperature
  - Having pristine increases the time it takes for bees to return to the hive. Temperature alone has no effect, but higher temperatures results in longer foraging times for bees with pristine and shorter times without pristine. 
  
  

* Ultimately, Pristine increases the foraging time for bees, decreasing the probability that they return to the nest. This effect is stonger at higher temperatures. This interactions warns us that the effects of fungicide on our pollinators could get worse with global warming and we should limit or more tightly control their use. 


