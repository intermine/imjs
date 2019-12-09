{shouldFail, prepare, eventually} = require './lib/utils'
should     = require 'should'
{Model}    = Fixture = require './lib/fixture'
{unitTests} = require './lib/segregation'

{TESTMODEL} = require '../data/model'

unitTests() && describe 'Table', ->

  testmodel = new Model TESTMODEL.model

  Employee = testmodel.classes.Employee

  it 'should stringify correctly', ->
    expected =
      "[Table name=Employee, " +
      "fields=[fullTime,age,end,name,id,department,departmentThatRejectedMe,employmentPeriod," +
      "address,simpleObjects]]"

    Employee.toString().should.equal expected

  it 'should know about its parents', ->
    Employee.parents().should.containEql 'Employable'

  it 'should support the getDisplayName method', ->
    Employee.getDisplayName.should.not.throw()

unitTests() && describe 'Table with live model', ->

  testmodel = new Model TESTMODEL.model
  {service} = new Fixture
  testmodel.service = service # Inject the service here.

  {Broke} = testmodel.classes

  describe 'getDisplayName', ->

    @beforeAll prepare -> Broke.getDisplayName()

    it 'should support the getDisplayName method', ->
      Broke.getDisplayName.should.not.throw()

    it 'should return a display name', eventually (name) ->
      should.exist name
      name.should.eql 'Poor Person'
