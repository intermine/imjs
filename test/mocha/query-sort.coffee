{Query, Model} = Fixture = require './lib/fixture'
{eventually, prepare} = require './lib/utils'
{TESTMODEL} = require '../data/model'
{unitTests} = require './lib/segregation'

unitTests() && describe 'Query#select', ->

  m = new Model TESTMODEL.model
  q = null
  
  @beforeEach ->
    q = new Query
      model: m
      root: 'Employee'
      select: ['name', 'department.name']
      orderBy: ['department.name', 'age']

  it 'should initially have the right sort order', ->
    [{path, direction}] = q.sortOrder
    path.should.eql 'Employee.department.name'
    direction.should.eql 'ASC'
    q.sortOrder.length.should.eql 2

  it 'should update the sort order when changing the select list', ->
    q.select ['name', 'address.address']
    [{path, direction}] = q.sortOrder
    path.should.eql 'Employee.age'
    direction.should.eql 'ASC'
    q.sortOrder.length.should.eql 1

  it 'should also update the sort order when changing the select list when cloned', ->
    p = q.clone()

    [{path, direction}] = p.sortOrder
    path.should.eql 'Employee.department.name'
    direction.should.eql 'ASC'
    p.sortOrder.length.should.eql 2

    p.select ['name', 'address.address']

    [{path, direction}] = q.sortOrder
    path.should.eql 'Employee.department.name'
    direction.should.eql 'ASC'
    q.sortOrder.length.should.eql 2

    [{path, direction}] = p.sortOrder
    path.should.eql 'Employee.age'
    direction.should.eql 'ASC'
    p.sortOrder.length.should.eql 1

unitTests() && describe 'Query#orderBy events', ->

  m = new Model TESTMODEL.model
  q = null
  
  @beforeEach ->
    q = new Query
      model: m
      root: 'Employee'
      select: ['name', 'department.name']
      orderBy: ['department.name', 'age']

  it 'should be able to silence sort events', ->
    evts = change: 0, changeOrder: 0
    opts = events: []
    q.on 'change:sortorder', -> evts.changeOrder++
    q.on 'change', -> evts.change++

    q.orderBy ['name'], opts
    evts.change.should.eql 1
    evts.changeOrder.should.eql 1
    opts.events.should.have.lengthOf 0

unitTests() && describe 'Query#orderBy silently', ->

  m = new Model TESTMODEL.model
  q = null
  
  @beforeEach ->
    q = new Query
      model: m
      root: 'Employee'
      select: ['name', 'department.name']
      orderBy: ['department.name', 'age']

  it 'should be able to silence sort events', ->
    evts = 0
    opts = silent: true
    q.on 'change:sortorder', -> evts++
    q.orderBy ['name'], opts
    evts.should.eql 0
    opts.events.should.eql ['change', 'change:sortorder']

