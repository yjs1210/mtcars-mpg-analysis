library(gridExtra)
library(ggplot2)
##Explore description of mtcars data
##We identify am column is the one we are looking for and one is MANUAL not zero... 
?mtcars 

##Exploring Data, plotting mpg vs automatic or manual transmission
boxplot(mpg~am, data=mtcars, main = "Car Mileage by Transmission", xlab = "0 = automatic, 1 = manual", ylab= "Miles Per Gallon")

##We see that manual cleary has a lot more miles per gallon in the picture. We will test significance using a linear model


##first fitting just mpg vs transmission as a factor, we will later add more values
fit <- lm(mpg~factor(am), mtcars)

##Using factor automatic as a base we see that manual's slope coefficient is clearly statistically significant with a very low p value
summary(fit)

##I do not know a lot about cars but we might be leaving bias into our coefficient by not fitting other variables that may be relevant
##first i will fit all the variables 
fit.all <- lm(mpg~+disp+hp+drat+wt+qsec+factor(vs)+factor(am)+factor(gear)+factor(carb)+factor(cyl), mtcars)
summary(fit.all)

##Looks like horsepower and weight are closest to being significant, we will try out one variable at a time to try to remove bias from the transmission regressor as much as possible without overfitting
##We will employ nested model testing
fit.hp <- lm(mpg~hp+factor(am),mtcars)
summary(fit.hp)

##Anova shows that including hp might be statistically significant. 
anova(fit,fit.hp)


##We add weight
fit.hp.wt <- lm(mpg~hp+wt+factor(am),mtcars)
anova(fit.hp,fit.hp.wt)


p1<-ggplot(data=mtcars, aes(x=wt, y=mpg, color=am)) +
  geom_line()+
  geom_point()
p2<-ggplot(data=mtcars, aes(x=hp, y=mpg, color=am)) +
  geom_line()+
  geom_point()
grid.arrange(p1, p2, nrow = 1)

##We add displacement
fit.hp.wt.disp <- lm(mpg~hp+wt+disp+factor(am),mtcars)
anova(fit,fit.hp,fit.hp.wt,fit.hp.wt.disp)

##displacement p-value suggests it might not be significant, we will try everything to make sure we are not excluding any significant variables
fit.hp.wt.drat <- lm(mpg~hp+wt+drat+factor(am),mtcars)
anova(fit,fit.hp,fit.hp.wt,fit.hp.wt.drat)

fit.hp.wt.qsec <- lm(mpg~hp+wt+qsec+factor(am),mtcars)
anova(fit,fit.hp,fit.hp.wt,fit.hp.wt.qsec)

fit.hp.wt.vs <- lm(mpg~hp+wt+factor(vs)+factor(am),mtcars)
anova(fit,fit.hp,fit.hp.wt,fit.hp.wt.vs)

fit.hp.wt.gear <- lm(mpg~hp+wt+factor(gear)+factor(am),mtcars)
anova(fit,fit.hp,fit.hp.wt,fit.hp.wt.gear)

fit.hp.wt.carb <- lm(mpg~hp+wt+factor(carb)+factor(am),mtcars)
anova(fit,fit.hp,fit.hp.wt,fit.hp.wt.carb)


##We check that adding any of these other variables are statistically significant so our final model is
fit.hp.wt <- lm(mpg~hp+wt+factor(am),mtcars)
summary(fit.hp.wt)
par(mfrow=c(2,2)) 


plot(fit.hp.wt)
##doing diagnostics
##looks likew we might have some outliers, chrysler, toyota and fiat. However, overall the residuals show no signifcant pattern
##Looking at residuals again, looks like we have a right skewed plot, as in we have outliers that are giving very high mpg 
##than our model would suggest. We confirm this in a normal Q-Q plot which shows chracteristics of a right-skewness
##Looking at cook's distance, we don't see any points that are very hgigh in leverage
## Overall, we have a fairly good fit although there is some concerns of right skewness. However, given we have a small data
## This is to be expected


## We test for outliers to follow up on the concern
## Looks like maserati bora might have a relatively strong potential for leverage, we test dfbetas
hatvalues(fit.hp.wt)[order(-hatvalues(fit.hp.wt))]

##getting max of dfbetas for hp, looks like maserati bora has a fairly high dfbetas value at .58
dfbetas(fit.hp.wt)[,2][which.max(abs(dfbetas(fit.hp.wt)[,2]))]


##getting max of dfbetas for wt, looks like chrysler imperail has a fairly high dfbetas value at .58
dfbetas(fit.hp.wt)[,3][which.max(abs(dfbetas(fit.hp.wt)[,3]))]


##getting max of dfbetas for transmission, looks like chrysler imperial has a fairly high dfbetas value at .58
dfbetas(fit.hp.wt)[,4][which.max(abs(dfbetas(fit.hp.wt)[,4]))]


##it might be helpful to get rid of the outlier's we identified and fit a new model, Chrysler Imperial, Maserati Bora
## to be more careful we will also remove Fiat 128 and Toyota Corolla
drop.outliers<- c('Chrysler Imperial','Maserati Bora','Fiat 128' ,'Toyota Corolla')
mtcars2 <- mtcars[ !(rownames(mtcars) %in% drop.outliers), ]

##interestingly our new fit suggests that am is no longer significant, it might have been that one of those outliers were 
##exercising heavy leverage by having a high mpg as manual vehicles, we check this
fit.hp.wt2 <- lm(mpg~hp+wt+factor(am),mtcars2)
mtcars[rownames(mtcars) %in% drop.outliers,]
## we see that 3 of the outliers we dropped were manual cars, it is very possible that fiat and corrolla were making 
## am variable significant by themselves. Maserati Bora's mpg however is very small so but it has a very high horsepower
## and weight, which reduces the mpg, so it might be a case that it has a good mpg for its kind

boxplot(mpg~am, data=mtcars2, main = "Car Mileage by Transmission", xlab = "0 = automatic, 1 = manual", ylab= "Miles Per Gallon")
## we try fitting just am, and it is significant
fit.am2 <- lm(mpg~factor(am),mtcars2)
summary(fit.am2)

## we add hp
fit.am.hp2 <- lm(mpg~ hp + factor(am) ,mtcars2)
summary(fit.am.hp2)

## we add wt, and it is no longer significant. 
fit.am.wt2 <- lm(mpg~ hp + wt+factor(am) ,mtcars2)
summary(fit.am.wt2)


##This analysis suggests that while AM initially seemed significant as part of 3 variables that can explain a lot of the mpg.
##Taking out outliers that had very high leverages show that these points may have skewewd our model quiet a bit, 3 of which having manual transmissions
##2 of them had very high mpg, while the third had low mpg but had high weight and horsepower, which can reduce the mpg.
##So it may have had a RELATIVELY high mpg given that we removed the linear effects of weight and horsepower
##after removing these outliers, we see that AM may no longer be significant while the other two variables were. 
##therefore, we conclude that there is no strong evidence to suggest transmission is statistically significant in explaining 
##mpg after having removed the linear effects of weigth and horsepower
## on the other hand there is a strong reason to beleive that weight and horsepower have strong correlation


