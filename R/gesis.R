#' Prepare connection to GESIS
#'
#' Set up options necessary for automatically downloading files from GESIS. Will
#' always be the first function run when using the \code{gesis} package. See
#' Workflow section below for further explanation.
#'
#' @section Workflow: The GESIS website (\url{http://www.gesis.org}) offers a
#'   large repository of datasets, mostly on public opinion surveys. However, it
#'   does not offer a standard API, which makes accessing these datasets in a
#'   programmatic and reproducible way difficult. The \code{gesis} package gets
#'   around this issue through the use of Selenium
#'   (\url{http://www.seleniumhq.org/}) and the \code{RSelenium} package.
#'   Selenium allows you to emulate a web browser session, wherein you log in to
#'   the GESIS website, browse to the dataset of interest, click to download
#'   that dataset, agree to accept the terms of use, and, ultimately, download
#'   the dataset. This whole process follows three steps: \enumerate{
#'   \item{Initiate a Selenium server (\code{setup_gesis})} \item{Log in to
#'   GESIS (\code{gesis_login})} \item{Download a specified dataset
#'   (\code{download_dataset})} \item{(optional) Manually closing the Selenium
#'   server (remDr$close(); remDr$closeServer())} }
#'
#' @param download_dir The directory (relative to your working directory) to
#'   which you will be downloading files from GESIS.
#' @param file_mime The MIME type of the file(s) you will be downloading (see
#'   details).
#'
#' @details Most GESIS datasets are .dta or .spss files, which are of MIME type
#'   "application/octet-stream". However, there are stray files stored as e.g.
#'   .zip, which are of a different type ("application/zip" in this case). If
#'   you notice your browser opening a download dialog and waiting for your
#'   manual input (clicking OK to download), then odds are the file is not a
#'   .dta/.spss file. You will then need to re-run the setup with a different
#'   \code{file_mime} argument.
#'
#' @return A Selenium remote driver.
#'
#' @examples
#' \dontrun{
#' gesis_remDr <- setup_gesis(download_dir = "downloads")
#' login_gesis(gesis_remDr, user = "myusername", pass = "mypassword")
#' download_dataset(gesis_remDr, doi = "5928")
#' }
#'
#' @export
setup_gesis <- function(download_dir = ".",
                        file_mime = "application/octet-stream") {

  # set firefox properties to not open download dialog
  fprof <- RSelenium::makeFirefoxProfile(list(
    browser.download.dir = paste0(getwd(), "/", download_dir),
    browser.download.folderList = 2L,
    browser.download.manager.showWhenStarting = FALSE,
    browser.helperApps.neverAsk.saveToDisk = file_mime))

  # Set up server as open initial window
  RSelenium::checkForServer()
  RSelenium::startServer()
  remDr <- RSelenium::remoteDriver(extraCapabilities = fprof)
  remDr$open()
  return(remDr)
}

#' Log in to GESIS
#'
#' Create connection with GESIS and log in.
#'
#' @param remDr The remote driver object created with \code{setup_gesis}.
#' @param user,pass Your GESIS user name and password.
#'
#' @return Nothing.
#'
#' @examples
#' \dontrun{
#' gesis_remDr <- setup_gesis(download_dir = "downloads")
#' login_gesis(gesis_remDr, user = "myusername", pass = "mypassword")
#' download_dataset(gesis_remDr, doi = "5928")
#' }
#'
#' @export
login_gesis <- function(remDr,
                        user = getOption("gesis_user"),
                        pass = getOption("gesis_pass")) {

  remDr$navigate("https://dbk.gesis.org/dbksearch/gdesc.asp")
  remDr$findElement(using = "id", value = "loginContainer")$clickElement()

  remDr$findElement(using = "name", "user")$sendKeysToElement(list(user))
  remDr$findElement(using = "name", "pass")$sendKeysToElement(list(pass))
  remDr$findElement(using = "id", "login")$clickElement()
}

#' Download dataset from GESIS
#'
#' Download dataset from GESIS identified by its Document Object Identifier (DOI) and filetype
#'
#' @param remDr Selenium remote driver created with \code{setup_gesis}.
#' @param doi The unique identifier for the dataset to be downloaded (see details).
#' @param filetype The filetype to be downloaded (usually only "dta" or "spss" available).
#'
#' @details Datasets reposited with GESIS are uniquely identified with a numberic identifier called a "DOI". This identifier appears both in the URL for a dataset's website, and on the website itself.
#'
#' @return Downloads a file.
#'
#' @examples
#' \dontrun{
#' gesis_remDr <- setup_gesis(download_dir = "downloads")
#' login_gesis(gesis_remDr, user = "myusername", pass = "mypassword")
#' download_dataset(gesis_remDr, doi = "5928")
#' }
#'
#' @export
download_dataset <- function(remDr, doi, filetype = "dta") {

  url <- paste0("https://dbk.gesis.org/dbksearch/SDesc2.asp?ll=10&notabs=1&no=",
                doi)

  remDr$navigate(url)

  # Click filename to download .dta file
  file_to_download <- sprintf("//a[contains(text(), '%s')]", filetype)
  remDr$findElement("xpath", file_to_download)$clickElement()

  # Input purpose and terms of use
  remDr$switchToWindow(remDr$getWindowHandles()[[1]][2])

  # Only check "accept terms of purpose" if unchecked
  try(if(remDr$findElement("name",
      "projectok")$getElementAttribute("checked")[[1]][1] != "true") {
      remDr$findElement("name", "projectok")$clickElement()
  }, silent = TRUE)

  remDr$findElement("xpath", "//option[@value='1']")$clickElement()
  remDr$findElement("xpath", "//input[@value='Download']")$clickElement()

  # Close Download window and switch back to first window
  remDr$closeWindow()
  remDr$switchToWindow(remDr$getWindowHandles()[[1]])
}

#' Browse dataset codebook
#'
#' Open a dataset's codebook in browser
#'
#' @param doi The dataset's DOI.
#' @param browseURL If FALSE, returns codebook's URL instead of opening in
#'   browser.
#' @param ... Additional arguments passed to \code{browseURL}.
#'
#' @examples
#' \dontrun{browse_codebook("5928")}
#'
#' @export
browse_codebook <- function(doi, browseURL = TRUE, ...) {

  if (!requireNamespace("xml2", quietly = TRUE)) {
      stop("xml2 package needed for this function to work. Please install it.",
           call. = FALSE)
  }

  if (!requireNamespace("rvest", quietly = TRUE)) {
      stop("rvest package needed for this function to work. Please install it.",
           call. = FALSE)
    }

  doi <- as.character(doi)
  base_url <- "https://dbk.gesis.org/dbksearch/"
  url <- paste0(base_url, "SDesc2.asp?ll=10&notabs=1&no=", doi)
  page <- xml2::read_html(url)
  codebook_link <- rvest::html_nodes(page,
                                     xpath = "//a[contains(text(), 'cdb.pdf')]")
  codebook_link_href <- paste0(base_url,
                               rvest::html_attr(codebook_link, "href"))

  if(browseURL) {
    browseURL(codebook_link_href, ...)
  } else {
    return(codebook_link_href)
  }
}
