{TESTMODEL} = require './data/model'
Fixture = require './lib/fixture'
{Query, Model} = Fixture
{get} = Fixture.funcutils

options =
  intermine:
    view: ["Employee.name", "Employee.age", "Employee.department.name"]
    constraints: [
      {path: "Employee.department.name", op: '=', value: "Sales*"},
      {path: "Employee.age", op: ">", value: "50"}
    ]
  sqlish:
    from: "Employee"
    select: ["name", "age", "department.name"]
    where:
      'department.name': 'Sales*'
      'age': {gt: 50}

describe 'Query', ->

  testmodel = new Model TESTMODEL.model

  describe 'new', ->

    it 'should make a new query', ->
      q = new Query()
      q.should.be.an.instanceOf Query

    it 'should set the root based on the "root" option', ->
      q = new Query root: 'Gene'
      q.root.should.equal 'Gene'

    it 'should set the root based on the "from" option', ->
      q = new Query from: 'Gene'
      q.root.should.equal 'Gene'
  
  for k, v of options then do (k, v) ->

    describe "handles #{ k } options", ->

      q = new Query v

      it 'can interpret views', ->
        q.views.should.eql options.intermine.view

      it 'can derive root', ->
        q.root.should.eql('Employee')

      it 'can interpret constraints', ->
        cs = q.constraints
        cs.should.have.lengthOf(2)
        cs.map(get 'op').should.eql(['=', '>'])
        cs.map(get 'path').should.eql(['Employee.department.name', 'Employee.age'])

  describe 'Query syntaxes', ->

    qtrad = new Query options.intermine
    qsqlish = new Query options.sqlish

    it 'should be synonymous', -> qtrad.toXML().should.equal(qsqlish.toXML())

  describe 'addToSelect(path)', ->

    q = new Query from: 'Employee', select: ['name', 'age']
    q.model = testmodel

    it 'should add views to the select list', ->
      q.addToSelect('fullTime')
      q.isInView( 'Employee.fullTime').should.be.true

  describe 'removeFromSelect(path)', ->

    q = new Query from: 'Employee', select: ['name', 'age', 'fullTime']
    q.model = testmodel

    it 'should remove views to the select list', ->
      removals = changes = 0
      q.on 'remove:view', -> removals++
      q.bind 'change:views', -> changes++

      q.removeFromSelect('Employee.age')
      q.isInView('Employee.fullTime').should.be.true
      q.isInView('fullTime').should.be.true
      q.isInView('age').should.not.be.true
      q.isInView('Employee.age').should.not.be.true

      q.removeFromSelect('fullTime')
      q.isInView('Employee.name').should.be.true
      q.isInView('name').should.be.true
      q.isInView('fullTime').should.not.be.true
      q.isInView('Employee.fullTime').should.not.be.true

      removals.should.equal 2
      changes.should.equal 2

  describe '#addToSelect(path)', ->

    q = new Query from: 'Employee', select: ['name', 'age', 'fullTime']
    q.model = testmodel

    it 'should throw errors if there are duplicate views', ->
      (-> q.addToSelect 'Employee.name').should.throw(/already/)

    it 'should not have added more views', ->
      q.views.length.should.equal 3

  describe '#clone()', ->

    orig = new Query from: 'Employee', select: ['name']

    it 'should produce unconnected clones', ->
      clone = orig.clone()
      clone.addToSelect 'age'
      orig.views.should.have.lengthOf 1
      clone.views.should.have.lengthOf 2

    it 'cloning should not include events by default', ->
      y = n = 0
      orig.on 'test:event', -> y++
      clone = orig.clone()
      clone.on 'test:event', -> n++
      orig.trigger 'test:event'
      y.should.equal 1
      n.should.equal 0


