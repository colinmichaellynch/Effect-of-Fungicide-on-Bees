#Clear workspace
rm(list = ls())

#Load libraries 
library(ggplot2)
library(lme4)
library(car)
library(regclass)
library(piecewiseSEM)
library(ggpubr)
library(survival)
library(ranger)
library(dplyr)
library(ggfortify)
library(coxme)

setwd("~/Nicole Desjardins")
dataForaging = read.csv("FN combined data - All data.csv")

### Data preprocessing: get it in a form readable by R ###

#clean treatment
dataForaging$Treatment[dataForaging$Treatment=="pristine "] = "pristine"

#Remove times which are greater than 60 minutes to ensure we can compare across runs

dataForaging$Time[dataForaging$Time > 60] = NA

#Create a variable that says whether the bee returned or not. 1 = returned, 0 = not returned 
dataForaging$Returned[is.na(dataForaging$Time)==0] = "1"
dataForaging$Returned[is.na(dataForaging$Time)] = "0"
dataForaging$Returned = as.numeric(dataForaging$Returned)

### Test if 2021 data is significantly different than 2022 data ###

#tests for both returned and flight time 
modelRun1 = glm(Returned~Treatment * Temperature * Run, data=dataForaging, family=binomial)
modelRun2 = coxph(Surv(Time) ~ Treatment * Temperature * Run, data = dataForaging)

#This anova tests whether the fixed effects of the glmm above are significant or not
car::Anova(modelRun1, type=2)
car::Anova(modelRun2, type=2)

###The main effect of Run is significant for both types of data, so we can exclude the 2021 data. Reprocess data here ### 
dataForaging = read.csv("FN combined data - All data.csv")
dataForaging$Treatment[dataForaging$Treatment=="pristine "] = "pristine"
dataForaging$Treatment[dataForaging$Treatment=="pristine"] = "Pristine" #rename for plots 
dataForaging$Treatment[dataForaging$Treatment=="control"] = "Control"
dataForaging = subset(dataForaging, Run != "Oct21")
dataForaging$Returned[is.na(dataForaging$Time)==0] = "1"
dataForaging$Returned[is.na(dataForaging$Time)] = "0"
dataForaging$Returned = as.numeric(dataForaging$Returned)

#get names of hives for random effect
dataForaging$Hive = substr(dataForaging$ID, start = 1, stop = 2)
dataForaging$Hive = gsub("H", "A", dataForaging$Hive)

### test if pristine had an effect on the probability of returning ###

#initial model with just the main effects of treatment and release distance. I use this as the standard to compare future models to
model1 = glmer(Returned~Treatment + Temperature + (1|Hive), data=dataForaging, family=binomial)

#This anova tests whether the fixed effects of the glmm above are significant or not
car::Anova(model1, type=2)
rsquared(model1)
summary(model1)
vif(model1)
plot(model1) #residual plot
qqnorm(residuals(model1)) #qqplot 

#model with interaction 
model2 = glmer(Returned~Treatment * Temperature + (1|Hive), data=dataForaging, family=binomial)

#This anova tests whether the fixed effects of the glmm above are significant or not
car::Anova(model2, type=2)
rsquared(model2)
summary(model2)
vif(model2)
plot(model2) #residual plot
qqnorm(residuals(model2)) #qqplot 

AIC(model1, model2)
BIC(model1, model2)

### Use survival analysis to test for what affected the bee's time to return ###

cox1 <- coxme(Surv(Time) ~ Treatment + Temperature + (1 | Hive), data = dataForaging)
summary(cox1)

km_trt_fit <- survfit(Surv(Time) ~ Treatment, data=dataForaging)
autoplot(km_trt_fit)

cox2 <- coxme(Surv(Time) ~ Treatment * Temperature + (1 | Hive), data = dataForaging)
summary(cox2)

AIC(cox1, cox2)
BIC(cox1, cox2)

dataPristine = subset(dataForaging, Treatment == "Pristine")
mean(dataPristine$Time, na.rm=TRUE)

dataControl = subset(dataForaging, Treatment == "Control")
mean(dataControl$Time, na.rm=TRUE)

### exploratory plots ###

#Convert 'flight time' to a biniary variable. For every bee, turn minutes before return to 0's and minutes at and after return to 1's. The binary matrix contains the binary vector for all bees 
maxTime = max(dataForaging$Time, na.rm=TRUE)
binaryMatrix = matrix(, nrow = nrow(dataForaging), ncol = maxTime)

for(i in 1:nrow(dataForaging)){
  time = dataForaging$Time[i]
  for(j in 1:maxTime){
    if(is.na(time)){
      binaryMatrix[i,j] = 0
    } else {
      if(j < time){
        binaryMatrix[i,j] = 0
      } else {
        binaryMatrix[i,j] = 1
      }
    }
  }
}

#Separate bees in binary matrix to those that are a part of different experimental conditions. The means of the binary matrix (by column) is the proportion of bees that had returned to the hive at that particular minute 

control= dataForaging$Treatment == "Control" 
treatment = dataForaging$Treatment == "Pristine" 

controlMat = colMeans(binaryMatrix[control,])
treatmentMat = colMeans(binaryMatrix[treatment,])

dataGraph = data.frame(Percentage = c(controlMat, treatmentMat)*100, Time = 1:maxTime, Treatment = c(rep("Control", maxTime), rep("Pristine", maxTime)))

#Graph showing percentage of returned bees over time 

p1 = ggplot(dataGraph, aes(x = Time, y = Percentage, color = Treatment)) + geom_line(size = 1.5) + theme_bw() + xlab("Time (Minutes)") + ylab("% Bees Returned") + theme(text = element_text(size=14)) + scale_color_brewer(palette = "Paired") + ylim(0, 50) + xlim(0, maxTime-1) + ggtitle("A")+ theme(aspect.ratio=1)

p2 = ggplot(dataForaging, aes(x=Temperature, y= Returned, color = Treatment)) + geom_smooth(method = "glm", method.args = list(family = "binomial"), se = FALSE, size = 1.5) + geom_jitter(height = 0.1,size=2) + theme_bw() + theme(text = element_text(size=14)) + scale_color_brewer(palette = "Paired") + ggtitle("B") + theme(aspect.ratio=1) + xlab("Temperature (C)") + scale_y_continuous(breaks=c(0, 1)) 

p3 = ggplot(dataForaging, aes(x=Temperature, y= Time, color = Treatment)) + geom_point(size=2) + geom_smooth(method='lm', size = 1.5, se = FALSE)+ theme_bw() + theme(text = element_text(size=14)) + scale_color_brewer(palette = "Paired") + ggtitle("C") + theme(aspect.ratio=1) + xlab("Temperature (C)") + ylab("Time to Return (Minutes)")

ggarrange(p1, p2, p3, nrow = 1, ncol = 3,  common.legend = TRUE)

### Only analyze 2021 data ###

dataForaging = read.csv("FN combined data - All data.csv")
dataForaging$Treatment[dataForaging$Treatment=="pristine "] = "pristine"
dataForaging$Treatment[dataForaging$Treatment=="pristine"] = "Pristine"
dataForaging$Treatment[dataForaging$Treatment=="control"] = "Control"
dataForaging = subset(dataForaging, Run == "Oct21")
dataForaging$Returned[is.na(dataForaging$Time)==0] = "1"
dataForaging$Returned[is.na(dataForaging$Time)] = "0"
dataForaging$Returned = as.numeric(dataForaging$Returned)
dataForaging$Time[dataForaging$Time > 60] = NA

model1 = glm(Returned~Treatment + Temperature, data=dataForaging, family=binomial)

#This anova tests whether the fixed effects of the glmm above are significant or not
car::Anova(model1, type=2)
rsquared(model1)
summary(model1)
vif(model1)
plot(model1) #residual plot
qqnorm(residuals(model1)) #qqplot 

#model with interaction 
model2 = glm(Returned~Treatment * Temperature, data=dataForaging, family=binomial)

#This anova tests whether the fixed effects of the glmm above are significant or not
car::Anova(model2, type=2)
rsquared(model2)
summary(model2)
vif(model2)
plot(model2) #residual plot
qqnorm(residuals(model2)) #qqplot 

AIC(model1, model2)
BIC(model1, model2)

### Use survival analysis to test for what affected the bee's time to return ###

cox1 <- coxph(Surv(Time) ~ Treatment + Temperature, data = dataForaging)
summary(cox1)

km_trt_fit <- survfit(Surv(Time) ~ Treatment, data=dataForaging)
autoplot(km_trt_fit)

cox2 <- coxph(Surv(Time) ~ Treatment * Temperature, data = dataForaging)
summary(cox2)

AIC(cox1, cox2)
BIC(cox1, cox2)

### exploratory plots ###

#Convert 'flight time' to a biniary variable. For every bee, turn minutes before return to 0's and minutes at and after return to 1's. The binary matrix contains the binary vector for all bees 
maxTime = 60
binaryMatrix = matrix(, nrow = nrow(dataForaging), ncol = maxTime)

for(i in 1:nrow(dataForaging)){
  time = dataForaging$Time[i]
  for(j in 1:maxTime){
    if(is.na(time)){
      binaryMatrix[i,j] = 0
    } else {
      if(j < time){
        binaryMatrix[i,j] = 0
      } else {
        binaryMatrix[i,j] = 1
      }
    }
  }
}

#Separate bees in binary matrix to those that are a part of different experimental conditions. The means of the binary matrix (by column) is the proportion of bees that had returned to the hive at that particular minute 

control= dataForaging$Treatment == "Control" 
treatment = dataForaging$Treatment == "Pristine" 

controlMat = colMeans(binaryMatrix[control,])
treatmentMat = colMeans(binaryMatrix[treatment,])

dataGraph = data.frame(Percentage = c(controlMat, treatmentMat)*100, Time = 1:maxTime, Treatment = c(rep("Control", maxTime), rep("Pristine", maxTime)))

#Graph showing percentage of returned bees over time 

p1 = ggplot(dataGraph, aes(x = Time, y = Percentage, color = Treatment)) + geom_line(size = 1.5) + theme_bw() + xlab("Time (Minutes)") + ylab("% Bees Returned") + theme(text = element_text(size=14)) + scale_color_brewer(palette = "Paired") + ylim(0, 60) + xlim(0, maxTime-1) + ggtitle("A")+ theme(aspect.ratio=1)

p2 = ggplot(dataForaging, aes(x=Temperature, y= Returned, color = Treatment)) + geom_smooth(method = "glm", method.args = list(family = "binomial"), se = FALSE, size = 1.5) + geom_jitter(height = 0.1,size=2) + theme_bw() + theme(text = element_text(size=14)) + scale_color_brewer(palette = "Paired") + ggtitle("B") + theme(aspect.ratio=1) + xlab("Temperature (C)") + scale_y_continuous(breaks=c(0, 1)) 

p3 = ggplot(dataForaging, aes(x=Temperature, y= Time, color = Treatment)) + geom_point(size=2) + geom_smooth(method='lm', size = 1.5, se = FALSE)+ theme_bw() + theme(text = element_text(size=14)) + scale_color_brewer(palette = "Paired") + ggtitle("C") + theme(aspect.ratio=1) + xlab("Temperature (C)") + ylab("Time to Return (Minutes)")

ggarrange(p1, p2, p3, nrow = 1, ncol = 3,  common.legend = TRUE)
