
(function () {
  'use strict';

  var get = intermine.funcutils.get
  var invoke = intermine.funcutils.invoke
  var flatMap = intermine.funcutils.flatMap
  var q = {select: ['age'], from: 'Employee', where: {age: {gt: 50}}}
  
  function checkRecords(records) {
    equal(records.length, 46)
    equal(flatMap(get('age'))(records), 2688)
  }

  module('Results Records', window.TestCase)

  asyncTest('Can fetch records - cb', 2, function () {
    this.s.query(q, function (query) {
      query.records(_.compose(start, checkRecords))
    })
  })

  asyncTest('Can fetch records - promise', 2, function () {
    this.s.query(q).then(invoke('records')).then(checkRecords).always(start)
  })

  asyncTest('Can lift opts to records', 2, function () {
    this.s.records(q).then(checkRecords).always(start)
  })

  asyncTest('Can iterate over records', 2, function () {
    var self = this
    var n = 0
    var total = 0
    var count = function (emp) {
      n++
      total += emp.age
    }

    function checkTotals() {
      equal(n, 46)
      equal(total, 2688)
      start()
    }

    this.s.query(q, function (query) {
      query.eachRecord([count, self.fail, checkTotals])
    })
  })
})()
