(function () {
  'use strict';

  var get    = intermine.funcutils.get
  var first  = get(0)
  var davidQ = { select: ['id'], from: 'Employee', where: {name: 'David Brent'} }
  var b1q    = { select: ['id'], from: 'Employee', where: {name: 'EmployeeB1'} }

  module('Find Objects', window.TestCase)

  asyncTest('Can find by id - cb', 5, function () {
    var self = this
    this.s.rows(davidQ).then(get(0)).then(get(0)).then(function (id) {
      self.s.findById('Employee', id, function (david) {
        equal(david.name,            'David Brent', 'name')
        equal(david.department.name, 'Sales',       'department.name')
        equal(david.age,             41,            'age')
        equal(david.fullTime,        false,         'fullTime')
        equal(david['class'],        'Manager',     'class')
      }).always(start)
    })
  })

  asyncTest('Can find by id - promises', 5, function () {
    var service = this.s, findEmp = _.bind(service.findById, service, 'Employee')
    this.s.rows(davidQ).then(first).then(first).then(findEmp)
        .then(function (david) {
          equal(david.name,            'David Brent', 'name')
          equal(david.department.name, 'Sales',       'department.name')
          equal(david.age,             41,            'age')
          equal(david.fullTime,        false,         'fullTime')
          equal(david['class'],        'Manager',     'class')
        }).always(start)
  })

  asyncTest('Can find emp B1', 5, function () {
    var service = this.s, findEmp = _.bind(service.findById, service, 'Employee')
    this.s.rows(b1q).then(first).then(first).then(findEmp)
        .then(function (empb1) {
          equal(empb1.name,            'EmployeeB1',   'name')
          equal(empb1.department.name, 'DepartmentB1', 'department.name')
          equal(empb1.age,             40,             'age')
          equal(empb1.fullTime,        true,           'fullTime')
          equal(empb1['class'],        'CEO',          'class')
        }).always(start)
  })

  asyncTest('Can find with a fuzzy search', 2, function () {
    this.s.find('Employee', 'David Brent').then(function (matches) {
      ok(matches.length, "There are some results")
      ok(
          _.find(matches, function (emp) { return 'David Brent' === emp.name }),
          "And one of them is David"
      )
    }).always(start)
  })

})()
