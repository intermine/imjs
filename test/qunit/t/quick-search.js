(function () {
  'use strict';

  var get    = intermine.funcutils.get
  var invoke = intermine.funcutils.invoke
  var fold   = intermine.funcutils.fold
  var AND    = intermine.funcutils.AND
  var curry  = intermine.funcutils.curry
  var flip   = intermine.funcutils.flip
  var eql    = flip(equal)
  var lengthOf = get('length')
  var is     = function (x) { return function (y) { return x === y } }
  
  function allAre(type) {
    return _.compose(fold(true, AND), curry(flip(_.all), is(type)), invoke('map', get('type')))
  }

  module('Quick Search', window.TestCase)

  asyncTest('get all cbs', 2, function () {
    this.s.search(function (results, facets) {
      ok(results.length >= 100, 'Expected lots of results, got ' + results.length)
      equal(5, facets.Category.Bank, 'There should be 5 banks')
      start()
    }).fail(start)
  })

  asyncTest('get all: promises', 2, function () {
    var manyResults = function (results) { ok(results.length >= 100, 'There are many results.') }
    var fiveBanks   = function (_, fs) { equal(5, fs.Category.Bank, 'There are five banks.') }
    this.s.search().done(manyResults, fiveBanks).always(start);
  });

  asyncTest('get david', 1, function () {
    this.s.search('david')
        .fail(this.fail)
        .done(_.compose(curry(flip(equal), 'Get David and his department', 2), lengthOf))
        .always(start)
  })

  asyncTest('get managers', 2, function () {
    this.s.search({facets: {Category: 'Manager'}})
        .fail(this.fail)
        .done(_.compose(curry(eql, 'There are 24 results', 24), lengthOf))
        .done(_.compose(curry(flip(ok), 'And they are all managers'), allAre('Manager')))
        .always(start)
  })

  asyncTest('limited', 2, function () {
    this.s.search({facets: {Category: 'Manager'}, size: 10})
        .done(_.compose(curry(eql, 'There are 10 results', 10), lengthOf))
        .done(_.compose(curry(flip(ok), 'And they are all managers'), allAre('Manager')))
        .always(start)
  })

})()
