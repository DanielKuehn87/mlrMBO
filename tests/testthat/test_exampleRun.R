context("exampleRun")

test_that("renderExampleRunPlot produces list of ggplot2 objects", {
  library(ggplot2)

  n.iters = 1L

  doRun = function(obj.fn, predict.type, crit, learner = "regr.km") {
    if (!is.null(learner))
      learner = makeLearner(learner, predict.type = predict.type)
    control = makeMBOControl()
    control = setMBOControlTermination(control, iters = n.iters)
    control = setMBOControlInfill(control, crit = crit, opt = "focussearch", opt.focussearch.points = 10)

    run = exampleRun(obj.fn, learner = learner, control = control)
    return(renderExampleRunPlot(run, iter = 1L))
  }

  ### 1D NUMERIC

  obj.fn = smoof::makeSingleObjectiveFunction(
    fn = function(x, ...) { if (abs(x) <= 2) sum(x * x) else stop("trafo failed") },
    par.set = makeParamSet(
      makeNumericParam("x", lower = -20, upper = 20, trafo = function(x) x / 10)
    )
  )

  checkPlotList = function(plot.list) {
    expect_is(plot.list, "list")
    lapply(plot.list, function(pl) {
        # sometimes for example the 'se' plot is NA, if learner does not support standard error estimation
        if (!any(is.na(pl))) {
          expect_is(pl, "gg")
          expect_is(pl, "ggplot")
        }
    })
  }

  # without se
  plot.list = doRun(obj.fn, "response", "mean")
  checkPlotList(plot.list)

  # with se
  plot.list = doRun(obj.fn, "se", "ei")
  checkPlotList(plot.list)
  
  #default learner
  plot.list = doRun(obj.fn, "response", "ei", learner = NULL)
  checkPlotList(plot.list)


  ### 2d MIXED
  obj.fn = smoof::makeSingleObjectiveFunction(
    fn = function(x) {
      if (abs(x$x) > 3)
        stop("trafo failed")
      else if (x$foo == "a")
        sum(x$x^2)
      else if (x$foo == "b")
        sum(x$x^2) + 10
      else
        sum(x$x^2) - 10
    },
    par.set = makeParamSet(
      makeDiscreteParam("foo", values = letters[1:3]),
      makeNumericVectorParam("x", len = 1, lower = -20, upper = 30, trafo = function(x) x / 10)
    ),
    has.simple.signature = FALSE
  )

  plot.list = doRun(obj.fn, "se", "ei", "regr.randomForest")
  checkPlotList(plot.list)

  ### 2D NUMERIC (MULTIPOINT)
  obj.fun = smoof::makeSingleObjectiveFunction(
    fn = function(x) {
      if (any(abs(x) > 5)) stop("trafo failed") else sum(x^2)
    },
    par.set = makeParamSet(
      makeNumericVectorParam("x", len = 2L, lower = -50, upper = 50, trafo = function(x) x / 10)
    )
  )

  ctrl = makeMBOControl(propose.points = 3)
  ctrl = setMBOControlTermination(ctrl, iters = n.iters)
  ctrl = setMBOControlMultiPoint(ctrl,
    method = "multicrit",
    multicrit.objective = "ei.dist",
    multicrit.dist = "nearest.neighbor",
    multicrit.maxit = 200L
  )

  run = exampleRun(obj.fun, learner = default.kriging, control = ctrl, points.per.dim = 50L)

  plot.list = renderExampleRunPlot(run, iter = 1L)
  checkPlotList(plot.list)
})
