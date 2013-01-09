(function () {
  'use strict';

  var invoke = intermine.funcutils.invoke
  var curry  = intermine.funcutils.curry
  var flip   = intermine.funcutils.flip
  var get    = intermine.funcutils.get
  var eql    = flip(equal)
  var args   = {name: 'temp-olders-saved-as-a-list', tags: ['js', 'qunit', 'testing']}

  module('Save As List', window.TestCase)

  asyncTest('Save a query as a list', 2, function () {
    this.s.query(this.olderEmployees)
        .then(invoke('saveAsList', args))
        .done(_.compose(curry(eql, 'Name is correct', args.name), get('name')))
        .done(_.compose(curry(eql, 'Size is correct', 46), get('size')))
        .done(invoke('del'))
        .always(start)
  })

})()
