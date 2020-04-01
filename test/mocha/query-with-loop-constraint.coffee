{TESTMODEL} = require '../data/model'
Fixture = require './lib/fixture'
{Query, Model} = Fixture
{get} = Fixture.funcutils
{unitTests} = require './lib/segregation'

loopQueryXML = '<query model="testmodel"' +
' view="Department.manager.department.name Department.name" ' +
' longDescription="" sortOrder="Department.manager.department.name">' +
'<constraint path="Department.manager.department" ' +
'op="=" loopPath="Department"/></query>'

options =
  intermine:
    view: ["Department.name", "Department.manager.department.name"]
    constraints: [
      {path: "Department.manager.department", op: '=', loopPath: "Department"}
    ]

unitTests() && describe 'Query#loopPath', ->

  testmodel = new Model TESTMODEL.model

  describe 'new', ->

  describe 'toJSON', ->

    q = new Query options.intermine

    asStr = '{"constraintLogic":"","from":"Department",' +
      '"select":["manager.department.name" "name"],"orderBy":[],' +
      '"joins":[],"where":[{"path":"department.name","op":"=",' +
      '"value":"Sales*"},{"path":"age","op":">","value":"50"}]}'

    it 'should copy over loops', ->
      q.toJSON().should.eql
        from: 'Department'
        select: ['name', 'manager.department.name']
        orderBy: []
        constraintLogic: ''
        joins: []
        where: [
          {path: "manager.department", op: '=', loopPath: "Department"}
        ]
