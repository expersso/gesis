Gesis
=====

[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/gesis)](http://cran.r-project.org/package=gesis) [![](http://cranlogs.r-pkg.org/badges/grand-total/gesis)](http://cran.r-project.org/web/packages/gesis)

Introduction
------------

The [GESIS Data Catalogue](https://dbk.gesis.org/) offers a repository of approximately 5,000 datasets.

To install the package from github:

``` r
# install.packages("devtools")
devtools::install_github("expersso/gesis")
```

``` r
library(gesis)
```

A simple example
----------------

We start by listing all available groups of studies:

``` r
groups <- get_study_groups()
head(groups, 10)
```

    ##    group_no                                        value
    ## 1      0001 International Social Survey Programme (ISSP)
    ## 2      0002                     EB - Flash Eurobarometer
    ## 3      0003                               Travel Surveys
    ## 4      0004                            Time Budget Study
    ## 5      0005       EB - Central and Eastern Eurobarometer
    ## 6      0006       EB - Candidate Countries Eurobarometer
    ## 7      0007                                       ALLBUS
    ## 8      0008      EB - Standard and Special Eurobarometer
    ## 9      0009                  European Values Study (EVS)
    ## 10     0010                               Politbarometer

We see that the Eurobarometer has study group number 10. Let's looks at all available Eurobarometer waves:

``` r
eurobars <- get_datasets("0008")
head(eurobars)
```

    ##    doi                           title
    ## 1 0078 Attitudes towards Europe (1962)
    ## 2 0626 European Communities Study 1970
    ## 3 0627 European Communities Study 1971
    ## 4 0628 European Communities Study 1973
    ## 5 0986  Eurobarometer 2 (Oct-Nov 1974)
    ## 6 0987      Eurobarometer 3 (May 1975)

We would now like to download the first three studies. We first need to log in to the Gesis website and then pass the DOIs (unique data set identifiers) to `download_dataset`:

``` r
# username and password stored as environment 
# variables "GESIS_USER" and "GESIS_PASS"
gesis_session <- login()
```

``` r
if(!dir.exists("downloads")) dir.create("downloads")
download_dataset(s = gesis_session, doi = eurobars$doi[1:3], 
                 path = "downloads", filetype = ".dta")
```

    ## Downloading DOI: 0078

    ## Downloading DOI: 0626

    ## Downloading DOI: 0627

``` r
(files <- list.files("downloads", full.names = TRUE))
```

    ## [1] "downloads/ZA0078_v1-0-1.dta" "downloads/ZA0626_v1-0-1.dta"
    ## [3] "downloads/ZA0627_v1-0-1.dta"

We can also download the codebooks for the same studies:

``` r
download_codebook(eurobars$doi[1:3], path = "downloads")
```

    ## Downloading codebook for DOI: 0078

    ## Downloading codebook for DOI: 0626

    ## Downloading codebook for DOI: 0627

Using the `haven` package we can now read the data sets:

``` r
library(haven)
df <- read_dta(files[1])
dim(df)
```

    ## [1] 4774  175

Disclaimer: the `gesis` package is neither affiliated with, nor endorsed by, the Leibniz Institute for the Social Sciences. I have been unable to find any indication that programmatic access to the website is disallowed under its terms of use (indeed, its [guidelines](https://dbk.gesis.org/dbksearch/guidelines.asp) appear to encourage it). That said, I would discourage users from using the `gesis` package to put undue pressure on their servers by initiating unnecessary (or unnecessarily large) batch downloads.
