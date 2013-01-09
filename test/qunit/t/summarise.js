(function () {
  'use strict';

  var get     = intermine.funcutils.get
  var concatMap = intermine.funcutils.concatMap
  var invoke  = intermine.funcutils.invoke
  var curry   = intermine.funcutils.curry
  var eql     = intermine.funcutils.flip(equal)
  var sumCount  = concatMap(get('count'))

  module('Column Summaries', window.TestCase)

  asyncTest('Can summarise a path - callbacks', 2, function () {
    this.s.query(this.olderEmployees, function (q) {
      q.summarise('department.company.name', function (items) {
        equal(items.length, 6)
        equal(sumCount(items), 46)
        start()
      })
    })
  })

  asyncTest('Can summarise a path - promises', 2, function () {
    this.s.query(this.olderEmployees)
        .then(invoke('summarise', 'department.company.name'))
        .done(_.compose(curry(eql, 6),  get('length')))
        .done(_.compose(curry(eql, 46), sumCount))
        .always(start)
  })

  asyncTest('Can summarise a numeric path - promises', 5, function () {
    this.s.query(this.olderEmployees)
        .then(invoke('summarise', 'department.company.vatNumber'))
        .done(_.compose(curry(eql, 4),  get('length')))
        .done(_.compose(curry(eql, "903322"), get('max'), get(0)))
        .done(_.compose(curry(eql, "5678"),   get('min'), get(0)))
        .done(_.compose(curry(eql, "513018.217391304348"), get('average'), get(0)))
        .done(_.compose(curry(eql, "196298.36496709"), get('stdev'), get(0)))
        .always(start)
  })
})()
