{utils: {defer}} = require './fixture'

# Helper class to incapsulate the logic for tests on iteration
module.exports = class Counter
  n: 0
  total: 0

  constructor: (@expN, @expT, @resolve, @reject) ->

  count: (emp) =>
    @n = @n + 1
    @total = @total + emp.age

  check: () =>
    try
      @n.should.equal(@expN)
      @total.should.equal(@expT)
      @resolve()
    catch e
      @reject e

Counter.forOldEmployees = (done) ->
  {promise, resolve, reject} = defer()
  promise.then (-> done()), ((e) -> done e)
  new Counter 46, 2688, resolve, reject

