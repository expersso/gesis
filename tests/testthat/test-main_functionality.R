context("Main functionality")

test_that("login works", {
  s <- login()
  expect_equal(class(s), "session")
})
