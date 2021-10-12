library(tercen)
library(dplyr)
library(pgCheckInput)
library(multcomp)

# Set appropriate options
#options("tercen.serviceUri"="http://tercen:5400/api/v1/")
#options("tercen.workflowId"= "4133245f38c1411c543ef25ea3020c41")
#options("tercen.stepId"= "2b6d9fbf-25e4-4302-94eb-b9562a066aa5")
#options("tercen.username"= "admin")
#options("tercen.password"= "admin")

do.fit <- function(df, verbose = "off") {
  if (length(levels(df$unit)) > 1 ) {
    model <- try(lm(.y ~ treatment + unit, data = df), silent = TRUE)
  } else {
    model <- try(lm(.y ~ treatment, data = df), silent = TRUE)
  }
  model_error <- inherits(model, "try-error") 
  if (!model_error) {
    anova_result <- anova(model)
    p1           <- anova_result["Pr(>F)"][1,]
    p2           <- anova_result["Pr(>F)"][2,]
    
    result = data.frame(.ci = sort(unique(df$.ci)), .ri = df$.ri[1], 
                        pvalue.any = p1,
                        pvalue.unit = if(is.na(p2)) NaN else p2,
                        pvalue.treatment = NaN,
                        LogFC = NaN)
    
    # Dunnett test below, using the multcomp predefined Dunnett constrasts here.
    # Note: the order of levels as returned by (df$treatment) is all important here.
    # Treatment is coded as <ctrl..ci> with ctrl C if the condition is the ctl treatment and T otherwise,
    # this is to make sure that the first level is the ctl level. 
    # Each .ci is equivalent with a treatment level, test of treatment levels come out in the .ci order:
    # e.g. T.1 == C.3, T.2 == C.3, T.4 == C.3
    glht_result <- try(glht(model, mcp(treatment = "Dunnett")), silent = TRUE)
    model_error <- inherits(glht_result, "try-error")
    if (!model_error) {
      
      glht_summary  <- summary(glht_result, test = adjusted(type = "none"))
      # get the .ci from the test names
      glht_names   <- rownames(glht_result$linfct)  
      matches      <- regexpr("T.(?<ci>[[:digit:]]+)", glht_names, perl = TRUE)
      iIdx         <- attr(matches, "capture.start")
      fIdx         <- iIdx + attr(matches, "capture.length") -1  
      aMatched.ci  <- as.numeric(substr(glht_names, start = iIdx, stop = fIdx ) )
      
      for(j in 1:length(aMatched.ci)) {
        for (i in 1:dim(result)[1]) {
          if (aMatched.ci[j] == result$.ci[i]) {
            result$pvalue.treatment[i] <- glht_summary$test$pvalues[j]
            result$LogFC[i]            <- glht_summary$test$coefficients[j]
          }
        }
      }
      if(verbose == "on") {
        print("****")
        print(glht_result$linfct)
        print(anova(model))
        print(glht_summary)
      }
      result = data.frame(result,
                          pvalue.any_log 		   = with(result, -log10(pvalue.any)),
                          pvalue.unit_log 		 = with(result, -log10(pvalue.unit)),
                          pvalue.treatment_log = with(result, -log10(pvalue.treatment)))
    }
  }
  if (model_error) {
    result <- data.frame(.ci                  = sort(unique(df$.ci)), 
                         .ri                  = df$.ri[1], 
                         pvalue.any           = NaN,
                         pvalue.unit          = NaN,
                         pvalue.treatment     = NaN,
                         LogFC                = NaN,
                         pvalue.any_log       = NaN,
                         pvalue.unit_log      = NaN,
                         pvalue.treatment_log = NaN)
  }
  result
}

ctx = tercenCtx()

check(FactorPresent, ctx, groupingType = "cnames")
check(ExactNumberOfFactors, ctx, groupingType = "xAxis", nFactors = 1)

verbose <- ifelse(is.null(ctx$op.value("Verbose")), "off", ctx$op.value("Verbose"))

ctx %>% 
  dplyr::select(.ci, .ri, .y, .x) %>% 
  mutate(unit = as.factor(ctx$select(ctx$colors) %>% pull())) %>%
  mutate(controlFactor = ifelse(.x == "true", "C", "T")) %>%
  mutate(treatment = as.factor(paste(controlFactor, .ci, sep = "."))) %>%
  dplyr::select(-controlFactor) %>%
  group_by(.ri) %>%
  do(do.fit(., verbose)) %>%
  ctx$addNamespace() %>%
  ctx$save()
