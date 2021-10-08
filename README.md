# ANOVA_Dunnett operator

##### Description

The `anova_dunnett` operator performs a statistical comparison of one control vs multiple treatment conditions.

##### Usage

Input projection|.
---|---
`row`    | represents the variables (e.g. genes, channels, markers)
`col`    | represents the observations (e.g. cells, samples, individuals) 
`y-axis` | measurement value
`x-axis` | treatment control factor
`colors` | represents the groups to compare

Input parameters|.
---|---
`Verbose` | Verbose

Output relations|.
---|---
`test_p0.treatment`            |	p value (from the ANOVA) for the probability that there is no difference between any of the treatments including control.
`test_p0.unit`                 |	p value (from ANOVA) for the probability that there is no difference between the experimental units (if applicable).
`test_p.Treatment.Control`     |	p-value (from Dunnett test) that there is no difference between the corresponding treatment condition and control. For the control condition p.Treatment.Control will be empty (NA).
`test_delta.Treatment.Control` |	Difference between mean signals of the corresponding treatment and control. For the control condition this value is empty (NA).
`test_logp values`             |	-log10(p) [significance values corresponding to the p-values above.

##### Details

Dunnett's test is a hypothesis (or significance) test for comparing data obtained under multiple treatment conditions against a single control. This is the case, for instance, when comparing the effect of treatment with compounds A, B, and C against the vehicle (DMSO) control. This case is sometimes approached by applying multiple separate t-test's between the control condition and the respective treatment conditions. However, Dunnett's test is a better alternative.
Dunnett's test is performed based on the results of a ANOVA model (post-hoc test). In this ANOVA model all treatment conditions (including the control) are modeled simultaneously. Unlike when performing multiple separate t-test's between control and treatment conditions, the ANOVA model results in a variance estimate that is based on the data for all treatment conditions. This global variance estimate is then used in subsequent testing between the individual treatment conditions and control, which makes the test a more powerful version of the t-test, compared to performing multiple separate t-test's.

#### Assumptions

The main assumption of the test is that the data in all treatment conditions is normally distributed with equal variances. For PamChip data after log transformation this is usually a reasonable assumption.

#### Multiple comparsions

For the Dunnett's test as well as fro the approach of applying multiple separate t-test it has to be taken into account that multiple comparisons are made. As a consequence, the probability of a false positive is actually larger than that suggested by the p-value resulting from the separate test's. It is common for implementations of Dunnett's test to return p-values that are corrected for this. However, in the case of PamChip data there is also multiple testing associated with the many peptides in the analysis. Therefore, in the Bionavigator implementation of Dunnett's test there is no multiple testing correction, the user should properly account for the effect of testing multiple conditions against control as well as of testing multiple peptides.

##### References

See [Dunnett's test on Wikipedia](https://en.wikipedia.org/wiki/Dunnett%27s_test).

##### See Also

[anova1](https://github.com/tercen/anova1_operator)
[anova2](https://github.com/tercen/anova2_operator)
