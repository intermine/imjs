{Query, Model} = Fixture = require './lib/fixture'
{eventually, prepare} = require './lib/utils'
{TESTMODEL} = require './data/model'

describe 'Query#select', ->

  q = null
  
  @beforeEach ->
    q = new Query
      model: new Model TESTMODEL.model
      root: 'Employee'
      select: ['name', 'department.manager.name']
      where:
        'department.manager': {isa: 'CEO'}

  it 'should have a type constraint on the department manager', ->
    [{path, type}] = q.constraints
    path.should.eql 'Employee.department.manager'
    type.should.eql 'CEO'

  it 'means that we can resolve paths correctly', ->
    {name} = q.getType 'department.manager'
    name.should.eql 'CEO'

  it 'doesn\'t stop working when we make the constraint irrelevant', ->
    q.select ['name', 'age']
    {name} = q.getType 'department.manager'
    name.should.eql 'CEO'

  it 'doesn\'t emit irrelevant type constraints in XML', ->
    xml = q.select(['name', 'age']).toXML()
    xml.should.not.match /CEO/

  it 'should emit the type constraint again once it becomes relevant', ->
    xml = q.select(['name', 'age']).select(['name', 'department.manager.age']).toXML()
    xml.should.match /CEO/

