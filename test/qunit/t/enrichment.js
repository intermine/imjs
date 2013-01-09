(function () {
  'use strict';

  var list   = 'My-Favourite-Employees'
  var widget = 'contractor_enrichment'
  var get    = intermine.funcutils.get
  var curry  = intermine.funcutils.curry
  var eql    = intermine.funcutils.flip(equal)
  var invoke = intermine.funcutils.invoke

  module('Enrichment', window.TestCase)

  asyncTest('Gets a list of enrichment widgets', 1, function () {
    this.s.fetchWidgets().then(get('length')).done(ok).always(start)
  })

  asyncTest('Gets a specific widget', 1, function () {
    this.s.fetchWidgetMap().then(get(widget)).done(ok).always(start)
  })

  asyncTest('Service#enrichment', 3, function () {
    this.s.enrichment({list: list, widget: widget, maxp: 1})
        .done(ok)
        .done(_.compose(curry(eql, "Gets one result", 1),        get('length')))
        .done(_.compose(curry(eql, "And it's Vikram", 'Vikram'), get('identifier'), get(0)))
        .always(start)
  })

  asyncTest('List#enrichment', 3, function () {
    this.s.fetchList('My-Favourite-Employees')
        .then(invoke('enrichment', {widget: widget, maxp: 1}))
        .done(ok)
        .done(_.compose(curry(equal, 1), get('length')))
        .done(_.compose(curry(equal, 'Vikram'), get('identifier'), get(0)))
        .always(start)
  })

})()
