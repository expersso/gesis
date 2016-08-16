Gesis
=====

[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/gesis)](http://cran.r-project.org/package=gesis) [![](http://cranlogs.r-pkg.org/badges/grand-total/gesis)](http://cran.r-project.org/web/packages/gesis)

Introduction
------------

The [GESIS Data Catalogue](https://dbk.gesis.org/) offers a repository of approximately 5,000 datasets.

To install the package from github:

``` r
knitr::opts_chunk$set(eval = FALSE)
```

``` r
# install.packages("devtools")
devtools::install_github("expersso/gesis")
```

A simple example
----------------

We start by listing all available groups of studies:

``` r
groups <- get_study_groups()
head(groups, 10)
```

We see that the Eurobarometer has study group number 10. Let's looks at all available Eurobarometer waves:

``` r
eurobars <- get_datasets("0008")
head(eurobars)
```

We would now like to download the first three studies. We first need to log in to the Gesis website and then pass the DOIs (unique data set identifiers) to `download_dataset`:

``` r
# username and password stored as environment 
# variables "GESIS_USER" and "GESIS_PASS"
gesis_session <- login()
```

``` r
if(!dir.exists("downloads")) dir.create("downloads")
download_dataset(session = gesis_session, doi = eurobars$doi[1:3], 
                 path = "downloads", filetype = ".dta")

list.files("downloads")
```

We can also download the codebooks for the same studies:

``` r
download_codebook(gesis_session, eurobars$doi[1:3])
```

Using the `haven` package we can now read the data sets:

``` r
library(haven)
df <- read_dta("downloads/ZA0078.dta")
dim(df)
```

Disclaimer: the `gesis` package is neither affiliated with, nor endorsed by, the Leibniz Institute for the Social Sciences. I have been unable to find any indication that programmatic access to the website is disallowed under its terms of use (indeed, its [guidelines](https://dbk.gesis.org/dbksearch/guidelines.asp) appear to encourage it). That said, I would discourage users from using the `gesis` package to put undue pressure on their servers by initiating unnecessary (or unnecessarily large) batch downloads.
