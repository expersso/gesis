context("Main functionality")

if(!identical(Sys.getenv("GESIS_USER"), "")) {
    test_that("login works", {
      s <- login()
      expect_equal(class(s), "session")
    })
}
