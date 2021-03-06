data("cdnow")
data("apparelTrans")
data("apparelStaticCov")

context("Inputchecks - clvfitted - predict")
expect_silent(clv.cdnow <- clvdata(cdnow, date.format = "ymd", time.unit = "w", estimation.split = 37))
expect_silent(pnbd.cdnow <- pnbd(clv.cdnow, verbose = FALSE))

expect_silent(clv.apparel <- clvdata(apparelTrans, date.format = "ymd", time.unit = "w",
                                    estimation.split = 40))
expect_silent(clv.apparel.static <- SetStaticCovariates(clv.data = clv.apparel,
                                                        data.cov.life = apparelStaticCov, data.cov.trans = apparelStaticCov,
                                                        names.cov.life = "Gender",
                                                        names.cov.trans = "Gender"))
expect_silent(p.apparel.static <- pnbd(clv.apparel.static, verbose=FALSE))

test_that("Fails if discount factor out of [0,1)", {
  expect_error(predict(pnbd.cdnow, continuous.discount.factor = -0.01))
  expect_error(predict(pnbd.cdnow, continuous.discount.factor = -0.4))
  expect_error(predict(pnbd.cdnow, continuous.discount.factor = -4))

  # expect_error(predict(pnbd.cdnow, continuous.discount.factor = 0))
  expect_error(predict(pnbd.cdnow, continuous.discount.factor = 1))

  expect_error(predict(pnbd.cdnow, continuous.discount.factor = 1.01))
  expect_error(predict(pnbd.cdnow, continuous.discount.factor = 1.4))
  expect_error(predict(pnbd.cdnow, continuous.discount.factor = 10))
})


l.std.args <- list(pnbd.cdnow, prediction.end=6)
.fct.helper.inputchecks.single.logical(fct = predict, l.std.args = l.std.args,
                                       name.param = "predict.spending", null.allowed=TRUE)



test_that("Fails if no prediction.end and no holdout period", {
  expect_error(predict(pnbd(clvdata(cdnow, time.unit = "w", date.format = "ymd"), verbose = FALSE)),
               regexp = "if there is no holdout")
})


test_that("Fails if prediction.end before fitting end", {
  # (different with holdout?)

  # Negative number
  expect_error(predict(pnbd.cdnow, prediction.end = -1), regexp = "after the end of the estimation")
  expect_error(predict(pnbd.cdnow, prediction.end = -10), regexp = "after the end of the estimation")
  expect_error(predict(pnbd.cdnow, prediction.end = -5), regexp = "after the end of the estimation")
  # zero
  expect_error(predict(pnbd.cdnow, prediction.end = 0), regexp = "after the end of the estimation")

  # Date before
  expect_error(predict(pnbd.cdnow, prediction.end = pnbd.cdnow@clv.data@clv.time@timepoint.estimation.end - lubridate::days(1)), regexp = "after the end of the estimation")
  expect_error(predict(pnbd.cdnow, prediction.end = pnbd.cdnow@clv.data@clv.time@timepoint.estimation.end - lubridate::days(10)), regexp = "after the end of the estimation")
  # Date on
  expect_error(predict(pnbd.cdnow, prediction.end = pnbd.cdnow@clv.data@clv.time@timepoint.estimation.end), regexp = "after the end of the estimation")
})


# **TODO: Prediction end as not date/numeric/char (= same tests as for plot)
test_that("Fails if newdata not a clv.data object", {
  expect_error(predict(pnbd.cdnow, newdata = NA_character_), regexp = "needs to be a clv data object")
  expect_error(predict(pnbd.cdnow, newdata = character()), regexp = "needs to be a clv data object")
  expect_error(predict(pnbd.cdnow, newdata = cdnow), regexp = "needs to be a clv data object")
  expect_error(predict(pnbd.cdnow, newdata = unlist(cdnow)), regexp = "needs to be a clv data object")
})


test_that("Fails if newdata is of wrong clv.data", {
  skip_on_cran()
  # predicting nocov model with staticcov data
  dt.cdnow.cov <- data.table(Id=unique(cdnow$Id), Gender=c("F", rep(c("M", "F"), 2357/2)))
  clv.cdnow.static <- SetStaticCovariates(clv.data=clv.cdnow, data.cov.life = dt.cdnow.cov, data.cov.trans = dt.cdnow.cov,
                                          names.cov.life = "Gender", names.cov.trans = "Gender")
  expect_error(predict(pnbd.cdnow, newdata = clv.cdnow.static), regexp = "of class clv.data")

  # predicting staticcov model with nocov data
  expect_error(predict(pnbd(clv.cdnow.static, verbose = FALSE),
                       newdata=clv.cdnow), regexp ="of class clv.data.static.covariates")
})

test_that("Fails if newdata has not the same covariates", {
  apparelDemographics.additional <- data.table::copy(apparelStaticCov)
  apparelDemographics.additional[, Haircolor := c(rep(c(1,2), .N/2))]

  # Other covs
  expect_silent(clv.apparel.static.other <- SetStaticCovariates(clv.data = clv.apparel,
                                                          data.cov.life = apparelDemographics.additional,
                                                          data.cov.trans = apparelDemographics.additional,
                                                          names.cov.life = "Haircolor",
                                                          names.cov.trans = "Haircolor"))
  expect_error(predict(p.apparel.static, newdata = clv.apparel.static.other),
               regexp = "used for fitting are present in the")

  # More covs
  expect_silent(clv.apparel.static.more <- SetStaticCovariates(clv.data = clv.apparel,
                                                               data.cov.life = apparelDemographics.additional,
                                                               data.cov.trans = apparelDemographics.additional,
                                                               names.cov.life = c("Gender","Haircolor"),
                                                               names.cov.trans = c("Gender","Haircolor")))

  expect_error(predict(p.apparel.static, newdata = clv.apparel.static.more),
               regexp = "used for fitting are present in the")
})

