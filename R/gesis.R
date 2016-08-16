#' Log in to the Gesis website
#'
#' @param username Your Gesis username
#' @param password Your Gesis password
#'
#' @details
#' The username and password can also be stored as enviroenment variables
#' "GESIS_USER" and "GESIS_PASS" so as not to store these in plaintext in a
#' script.
#'
#' @return A session object
#' @export
#' @import rvest
#' @import xml2
#'
#' @examples
#' \dontrun{s <- login("my_gesis_username", "my_gesis_password")}
login <- function(username = "", password = "") {
    if(username == "") username <- Sys.getenv("GESIS_USER")
    if(password == "") password <- Sys.getenv("GESIS_PASS")

    if(any(username == "", password == "")) {
        stop("Please provide username and/or password.", call. = FALSE)
    }

    url <- "https://dbk.gesis.org/dbksearch/index.asp"
    s <- html_session(url)
    form <- html_form(s)[[1]]
    form <- set_values(form, user = username, pass = password)
    form$url <- ""
    suppressMessages(submit_form(s, form))
}

#' Download a Gesis data set
#'
#' @param s A session object created with login()
#' @param doi The unique identifier(s) for the data set(s)
#' @param path Directory to which to download the file
#' @param filetype The filetype to download (usually available: .dta/.por/.sav)
#' @param purpose The purpose for downloading the data. See details.
#' @param quiet Whether to output download message.
#'
#' @details Datasets reposited with GESIS are uniquely identified with a
#'   numberic identifier called a "DOI". This identifier appears both in the URL
#'   for a dataset's website, and on the website itself.
#'
#'   In addition to accepting the terms of use, you need to input a purpose for
#'   downloading a data set. The options are as follows:
#'
#' 1. for scientific research (incl. PhD)
#' 2. for reserach with commercial mandate
#' 3. for teaching as lecturer
#' 4. for my academic studies
#' 5. for my final exam (e.g. bachelor or master)
#' 6. for professional training and qualification
#'
#' @return Nothing
#' @export
#' @import rvest
#' @import xml2
#' @import httr
#'
#' @examples
#' \dontrun{s <- login("my_gesis_username", "my_gesis_password")
#' download_dataset(s, doi = "0078")}
download_dataset <- function(s, doi, path = ".", filetype = ".dta",
                             purpose = 1, quiet = FALSE) {
    for(d in doi) {

        url <- paste0("https://dbk.gesis.org/dbksearch/SDesc2.asp?db=E&no=", d)
        s <- jump_to(s, url)
        stop_for_status(s)

        s <- suppressMessages(
            follow_link(s, xpath = sprintf("//a[contains(text(), '%s')]", filetype))
        )
        stop_for_status(s)

        form <- html_form(s)[[2]]
        form <- set_values(form, zweck = 1, projectok = 1)
        form$url <- ""
        s <- suppressMessages(submit_form(s, form))
        stop_for_status(s)

        if(!quiet) message("Downloading DOI: ", d)
        filename <- gsub("^.*?\"|\"", "", s$response$headers$`content-disposition`)
        filename <- file.path(path, filename)
        writeBin(content(s$response, "raw"), filename)
    }
}

#' Download the codebook for a Gesis data set
#'
#' @param doi The unique identifier(s) for the data set(s)
#' @param path Directory to which to download the file
#' @param quiet Whether to output download message.
#'
#' @return Nothing
#' @export
#' @import rvest
#' @import xml2
#' @import httr
#'
#' @examples
#' download_codebook(doi = "0078")
download_codebook <- function(doi, path = ".", quiet = FALSE) {
    for(d in doi) {

        url <- paste0("https://dbk.gesis.org/dbksearch/SDesc2.asp?db=E&no=", d)
        page <- read_html(url)
        node <- html_nodes(page, xpath = "//a[contains(text(), '_cdb')]")
        node <- paste0("https://dbk.gesis.org/dbksearch/", html_attr(node, "href"))
        resp <- GET(node)

        if(!quiet) message("Downloading codebook for DOI: ", d)
        filename <- gsub("^.*?\"|\"", "", resp$headers$`content-disposition`)
        filename <- file.path(path, filename)
        writeBin(content(resp, "raw"), filename)
    }
}

#' Get a dataframe with all available groups of studies
#'
#' @return A dataframe
#' @export
#'
#' @import rvest
#' @import xml2
#'
#' @examples
#' groups <- get_study_groups()
#' head(groups)
get_study_groups <- function() {
    url <- "https://dbk.gesis.org/dbksearch/gdesc.asp"
    page <- read_html(url)

    group_no <- html_attr(html_nodes(page, xpath = "//input//parent::a//input"), "name")
    group_no <- gsub("TI", "", group_no)
    value <- html_attr(html_nodes(page, xpath = "//input//parent::a//input"), "value")

    df <- data.frame(group_no, value, stringsAsFactors = FALSE)
    class(df) <- c("tbl_df", "tbl", "data.frame")
    df
}

#' Get a dataframe of all individual data sets within a group of studies
#'
#' @param group_no The group number (usually obtained from get_study_groups())
#'
#' @return A dataframe
#' @export
#'
#' @import rvest
#' @import xml2
#'
#' @examples
#' # Get DOIs and titles for all Eurobarometer studies
#' eurobars <- get_datasets("0008")
#' head(eurobars)
get_datasets <- function(group_no) {
    url <- paste0("https://dbk.gesis.org/dbksearch/GDESC2.asp?db=e&no=", group_no)
    page <- read_html(url)

    nodes <- html_nodes(page, xpath = "//li//a[contains(@href, 'no=')]")
    text <- html_nodes(page, xpath = "//li//a[contains(@href, 'no=')]//parent::li")
    text <- html_text(text, TRUE)

    doi <- substr(text, 3, 6)
    title <- substr(text, 8, stop = 10000L)

    df <- data.frame(doi, title, stringsAsFactors = FALSE)
    class(df) <- c("tbl_df", "tbl", "data.frame")
    df
}
