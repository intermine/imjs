should     = require 'should'
{Model}    = require './lib/fixture'

{TESTMODEL} = require '../data/model'

describe 'Table', ->

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

