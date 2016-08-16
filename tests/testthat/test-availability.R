context("Available datasets")

test_that("get_study_groups() works", {
    groups <- get_study_groups()
    expect_equal(class(groups), c("tbl_df", "tbl", "data.frame"))
    expect_gt(nrow(groups), 0)
})

test_that("get_datasets() works", {
    dfs <- get_datasets("0001")
    expect_equal(class(dfs), c("tbl_df", "tbl", "data.frame"))
    expect_gt(nrow(dfs), 0)
})
