(function () {
  'use strict';

  var curry  = intermine.funcutils.curry
  var get    = intermine.funcutils.get
  var flip   = intermine.funcutils.flip
  var invoke = intermine.funcutils.invoke
  var comp   = _.compose
  var eql    = flip(equal)
  var toName = get('name')
  var is4    = curry(eql, 'Size is correct', 4)
  var favs   = 'My-Favourite-Employees'

  module('Lists', window.TestCase)

  asyncTest('All lists - cb', 1, function () {
    this.s.fetchLists(function (ls) {
      ok(ls.length > 0)
      start()
    })
  })

  asyncTest('All lists - promises', 1, function () {
    this.s.fetchLists().then(get('length')).then(ok).always(start)
  })

  asyncTest('fetches a list - promises', 1, function () {
    this.s.fetchList('My-Favourite-Employees')
        .then(get('size'))
        .then(is4)
        .always(start)
  })

  asyncTest('fetches a list - cb', 1, function () {
    this.s.fetchList('My-Favourite-Employees', function (l) {
      is4(l.size)
      start()
    })
  })

  asyncTest('Can find lists containing an item', 2, function () {
    this.s.fetchListsContaining({publicId: 'Brenda', type: 'Employee'}, function (ls) {
      ok(ls.length, 'There are some results')
      ok(_.include(_.pluck(ls, 'name'), 'The great unknowns'))
      start()
    })
  })

  asyncTest('Can copy a list', 3, function () {
    var fetch = this.s.fetchLists
    $.when(fetch(), this.s.fetchList(favs)).then(function (was, orig) {
      var copy = orig.copy()
      copy.done(comp(is4, get('size')))
          .done(comp(curry(flip(notEqual), 'Name is not ' + favs, favs), get('name')))
          .then(curry(fetch, comp(curry(eql, 'Is new', was.length + 1), get('length'))))
          .done(function () { copy.done(invoke('del')) })
          .always(start)
    })
  })

  asyncTest('Can copy a list, specifying a name', 3, function () {
    var fetch = this.s.fetchLists
    var newName = 'temp-copy-of-' + favs

    $.when(fetch(), this.s.fetchList(favs)).then(function (was, orig) {
      var copy = orig.copy(newName);
      copy.done(comp(is4, get('size')))
          .done(comp(curry(flip(equal), 'Name is ' + newName, newName), get('name')))
          .then(curry(fetch, comp(curry(flip(equal), 'Is new', was.length + 1), get('length'))))
          .done(function () { copy.done(invoke('del')) })
          .always(start);
    })
  })

  asyncTest('Can rename a list', 2, function () {
    var newName    = 'temp-copy-of-' + favs
    var areTheSame = curry(eql, 'Names are in sync')
    var copy       = this.s.fetchList(favs).then(invoke('copy'))
    var isNow      = copy.then(invoke('rename', newName))

    isNow.done(curry(eql, 'Name is what we wanted', newName))
         .then(function () { return $.when(copy.then(toName), isNow).then(areTheSame) })
         .always(function () { copy.done(invoke('del')) }, start);
  })

})()
