% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/preciseTAD.R
\name{preciseTAD}
\alias{preciseTAD}
\title{Precise TAD boundary prediction at base-level resolution using density-based
spatial clustering and partitioning techniques}
\usage{
preciseTAD(
  genomicElements.GR,
  featureType = "distance",
  CHR,
  chromCoords = NULL,
  tadModel,
  threshold = 1,
  verbose = TRUE,
  parallel = NULL,
  DBSCAN_params = list(30000, 100),
  slope = 5000,
  genome = "hg19",
  BaseProbs = FALSE,
  savetobed = FALSE
)
}
\arguments{
\item{genomicElements.GR}{\code{GRangesList} object containing GRanges from
each ChIP-seq BED file that was used to train a predictive model (can be
obtained using the \code{\link{bedToGRangesList}}). Required.}

\item{featureType}{Controls how the feature space is constructed (one of
either "binary", "oc", "op", "signal, or "distance" (log2- transformed).
Default and recommended: "distance".}

\item{CHR}{Controls which chromosome to predict boundaries on at base-level
resolution, e.g., CHR22. Required.}

\item{chromCoords}{List containing the starting bp coordinate and ending bp
coordinate that defines the region of the linear genome to make predictions
on. If chromCoords is not specified, then predictions will be made on the
entire chromosome. Default is NULL.}

\item{tadModel}{Model object used to obtain predicted probabilities at
base-level resolution (examples include \code{gbm}, \code{glmnet},
\code{svm}, \code{glm}, etc). For a random forest model, can be obtained
using \code{preciseTAD::randomForest}). Required.}

\item{threshold}{Bases with predicted probabilities that are greater
than or equal to this value are labeled as potential TAD boundaries. Values
in the range of .95-1.0 are suggested. Default is 1. To explore how
selection of the `threshold` parameter affects the results, it is recommended
to rerun the function with a different threshold, e.g., 0.99, and compare the
results of Normalized Enrichment test (see `DBSCAN_params` and the 
`preciseTADparams` slot).}

\item{verbose}{Option to print progress. Default is TRUE.}

\item{parallel}{Option to parallelise the process for obtaining predicted
probabilities. Must be number to indicate the number of cores to use in
parallel. Default is NULL.}

\item{DBSCAN_params}{Parameters passed to \code{\link{dbscan}} in list form
containing 1) eps and 2) MinPts. If a vector of different values is passed to
either or both eps and MinPts, then each combination of these parameters is
evaluated to maximize normalized enrichment (NE) is the provided genomic 
annotations. Normalized Enrichment is calculated as the number of genomic 
annotations that overlap with flanked predicted boundary points (see the slope 
parameter) divided by the total number of predicted boundaries, averaged for 
all genomic annotations. Parameters yielding  maximum NE score are automatically 
selected for the final prediction. It is advisable to explore results 
of the NE test, available in the `preciseTADparams` slot of the returned 
object (NEmean - mean normalized enrichment, larger the better; k - number 
of PTBRs), to, potentially, find eps and MinPts parameters providing 
the number of PTBRs and the NE score better agreeing with the number
of boundaries used for training. Default: list(30000, 100). Required.}

\item{slope}{Controls how much to flank the predicted TAD boundary points for
calculating normalized enrichment. Default: 5000 bases. Required.}

\item{genome}{version of the human genome assembly. Used to filter out
bases overlapping centromeric regions. Accepted values - hg19 or 
hg38. Default: hg19}

\item{BaseProbs}{Option to include the vector of probabilities for each 
base-level coordinate. Recommended to be used only when chromCoords is 
specified. Default: FALSE}

\item{savetobed}{If true, preciseTAD regions (PTBRs) and preciseTAD points
(PTBPs) will be saved as BED-like files into the current folder 
(as.data.frame(GRanges)). File name convention: 
<PTBRs/PTBPs>_<threshold>_<MinPts>_<eps>.bed, e.g., PTBR_1_3_30000.bed. 
If multiple DBSCAN_params are specified, each result will
be saved in its own file. Default: FALSE}
}
\value{
A list containing 4 elements including:
1) data frame with average (and standard deviation) normalized enrichment 
(NE) values for each combination of t and eps (only if multiple values are 
provided for at least paramenter; all subsequent summaries are applied to 
optimal combination of (t, eps)),
2) the genomic coordinates spanning each preciseTAD predicted region (PTBR),
3) the genomic coordinates of preciseTAD predicted boundaries points (PTBP),
4) a named list including summary statistics of the following:
PTBRWidth - PTBR width, PTBRCoverage - the proportion of bases within a PTBR
with probabilities that equal to or exceed the threshold (t=1 by default),
DistanceBetweenPTBR - the genomic distance between the end of the previous
PTBR and the start of the subsequent PTBR, NumSubRegions - the number of
the subregions in each PTBR cluster, SubRegionWidth - the width of
the subregion forming each PTBR, DistBetweenSubRegions -
the genomic distance between the end of the previous PTBR-specific subregion
and the start of the subsequent PTBR-specific subregion, NormilizedEnrichment
- the normalized enrichment of the genomic annotations used in the model 
around flanked PTBPs, and BaseProbs - a numeric vector of probabilities for 
each corresponding base coordinate.
}
\description{
Precise TAD boundary prediction at base-level resolution using density-based
spatial clustering and partitioning techniques
}
\examples{
# Read in ARROWHEAD-called TADs at 5kb
data(arrowhead_gm12878_5kb)

# Extract unique boundaries
bounds.GR <- extractBoundaries(domains.mat = arrowhead_gm12878_5kb,
                               filter = FALSE,
                               CHR = c("CHR21", "CHR22"),
                               resolution = 5000)

# Read in GRangesList of 26 TFBS and filter to include only CTCF, RAD21,
#SMC3, and ZNF143
data(tfbsList)

tfbsList_filt <- tfbsList[which(names(tfbsList) \%in\%
                                                 c("Gm12878-Ctcf-Broad",
                                                   "Gm12878-Rad21-Haib",
                                                   "Gm12878-Smc3-Sydh",
                                                   "Gm12878-Znf143-Sydh"))]

# Create the binned data matrix for CHR1 (training) and CHR22 (testing)
# using 5 kb binning, distance-type predictors from 4 TFBS from
# the GM12878 cell line, and random under-sampling
set.seed(123)
tadData <- createTADdata(bounds.GR = bounds.GR,
                         resolution = 5000,
                         genomicElements.GR = tfbsList_filt,
                         featureType = "distance",
                         resampling = "rus",
                         trainCHR = "CHR21",
                         predictCHR = "CHR22")

# Perform random forest using TADrandomForest by tuning mtry over 10 values
# using 3-fold CV
set.seed(123)
tadModel <- TADrandomForest(trainData = tadData[[1]],
                            testData = tadData[[2]],
                            tuneParams = list(mtry = 2,
                                            ntree = 500,
                                            nodesize = 1),
                            cvFolds = 3,
                            cvMetric = "Accuracy",
                            verbose = TRUE,
                            model = TRUE,
                            importances = TRUE,
                            impMeasure = "MDA",
                            performances = TRUE)

# Apply preciseTAD on a specific 2mb section of CHR22:17000000-18000000
set.seed(123)
pt <- preciseTAD(genomicElements.GR = tfbsList_filt,
                 featureType = "distance",
                 CHR = "CHR22",
                 chromCoords = list(17000000, 18000000),
                 tadModel = tadModel[[1]],
                 threshold = 1.0,
                 verbose = TRUE,
                 parallel = NULL,
                 DBSCAN_params = list(c(1000, 10000, 30000), c(10, 100, 1000)),
                 slope = 5000,
                 genome = "hg19",
                 BaseProbs = FALSE,
                 savetobed = FALSE)
}
