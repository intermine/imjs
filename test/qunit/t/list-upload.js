(function () {
  'use strict';

  var invoke  = intermine.funcutils.invoke
  var flip    = intermine.funcutils.flip
  var get     = intermine.funcutils.get
  var curry   = intermine.funcutils.curry
  var content = "Anne, Brenda, Carol, David*"
  var names   = ['Anne', 'Brenda', 'Charles Miner', 'David*']
  var description = 'A temporary list uploaded with imjs in the qunit tests'
  var tags = ['js', 'temp', 'qunit']
  var args = { name: "temp-uploaded-list", type: "Employee", tags: tags, description: description }

  function clear(service, name) {
    return function () {
      return new jQuery.Deferred(function () {
        service.fetchList(name).then(invoke('del')).always(this.resolve)
      }).promise()
    }
  }

  module('List Upload', window.TestCase)

  asyncTest('Can upload a list - string content', 4, function () {
    var firstly  = function (then) { clear(this.s, args.name).then(then) }
    var cleanup  = _.compose(start, firstly)
    var hasTag   = _.compose(curry(flip(ok), 'Has tag'), invoke('hasTag', 'js'))
    var upload   = curry(this.s.createList, args, content)
    var hasRight = function (prop, value) {
      return _.compose(curry(flip(equal), 'Has right ' + prop, value), get(prop))
    }

    firstly(upload).done(
      hasRight('size', 3),
      hasRight('name', args.name),
      hasRight('description', args.description),
      hasTag
    ).always(cleanup)
  })

  asyncTest('Can upload a list - list content', 2, function () {
    var firstly  = function (then) { clear(this.s, args.name).then(then) }
    var cleanup = _.compose(start, firstly)
    var has3Members = _.compose(curry(flip(equal), 'Has correct size', 3), get('size'))
    var hasCharles  = invoke('contents', _.compose(
      curry(flip(ok), 'Includes Charles'),
      curry(flip(_.include), 'Charles Miner'), 
      invoke('map', get('name'))
    ))
    var upload  = curry(this.s.createList, args, names)

    firstly(upload).done(
      has3Members,
      hasCharles
    ).always(cleanup)
  })
})()
