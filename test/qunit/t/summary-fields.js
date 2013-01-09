(function () {
  'use strict';

  var get      = intermine.funcutils.get
  var curry    = intermine.funcutils.curry
  var flip     = intermine.funcutils.flip
  var expected = [
    "Employee.name", "Employee.department.name", "Employee.department.manager.name",
    "Employee.department.company.name", "Employee.fullTime", "Employee.address.address"
  ]

  module('Summary Fields', window.TestCase)

  asyncTest('Service#fetchSummaryFields()', 1, function () {
    this.s.fetchSummaryFields().then(this.succeed, this.fail).always(start)
  })

  asyncTest('Service#fetchSummaryFields(cb)', 1, function () {
    this.s.fetchSummaryFields(function (sfs) {
      deepEqual(expected, sfs.Employee)
      start()
    })
  })

  asyncTest('Service#fetchSummaryFields().then(cb)', 1, function () {
    this.s.fetchSummaryFields()
        .then(get('Employee'))
        .then(curry(flip(deepEqual), 'Fields are ' + expected, expected))
        .always(start)
  })
})()

