(function () {
  'use strict';

  var Service = window.intermine.Service

  module("service root")

  asyncTest('Add default elements when missing', 1, function () {
    var service = new Service({root: "foo/bar"})
    equal(service.root, "http://foo/bar/service/")
    start()
  })

  asyncTest('Leaves URLs that look basically OK alone, but adds a final slash', 1, function () {
    var flymine = new Service({root: "http://www.flymine.org/query/service"})
    equal(flymine.root, "http://www.flymine.org/query/service/")
    start()
  })
})()
