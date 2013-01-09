(function () {
  'use strict';

  module("Service-version", window.TestCase)

  var checkVersion = function (v) {
    ok(v > 0, "version is not a positive number: " + v)
    equal(v + 0, v, "version acts like a number")
  }

  asyncTest('version - cb', 2, function () {
    this.s.fetchVersion(function (v) {
      checkVersion(v)
      start()
    })
  })

  asyncTest('version - promises', 2, function () {
    this.s
        .fetchVersion()
        .then(checkVersion)
        .always(start)
  })
})()
