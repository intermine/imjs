(function (window) {
  'use strict';

  var setupError = null
  var root       = (window.location.host || "localhost") + ":8080/intermine-test"
  var Service    = window.intermine.Service

  window.TestCase = {
    setup: function () { throw setupError }
  }

  if (!window.jQuery) {
    setupError = new Error("jQuery is missing")
  } else if (!window.QUnit) {
    setupError = new Error("QUnit missing")
  } else if (!window.intermine) {
    setupError =  new Error("intermine is missing")
  } else if (!Service) {
    setupError = new Error("intermine.Service was not found")
  }

  if (setupError) {
    throw setupError
  }

  console.log("")
  console.log("Testing against " + root)

  window.TestCase = {
    setup: function () {
      this.succeed = function () {
        ok(true, "Test passed")
      }
      this.fail = function (err) {
        console.error("FAILURE", [].slice.call(arguments, 0)) 
        ok(false, err) 
      }
      this.s = new intermine.Service({
        root:  root,
        token: "test-user-token"
      })
      this.flymine = new intermine.Service({
        root: "http://www.flymine.org/query/service"
      })
      this.allEmployees = {
        select: ['*'],
        from: 'Employee'
      }
      this.olderEmployees = {
        select: ['*'],
        from: 'Employee',
        where: { age: {gt: 50} }
      }
      this.youngerEmployees = {
        select: ['*'],
        from: 'Employee',
        where: { age: {le: 50} }
      }
    }
  }

  try {
    var context = new window.TestCase.setup()
    context.s.fetchLists(function (ls) {
      _.each(ls, function (l) {
        if (l.hasTag('qunit')) {
          l.del()
        }
      })
    })
  } catch (e) {
    console.error("Caught an error")
    // ignore.
  }
})(window)

