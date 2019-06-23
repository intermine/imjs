Fixture = require './lib/fixture'
{eventually, prepare} = require './lib/utils'
{unitTests} = require './lib/segregation'
{recordResponses, setupTest} = require './lib/mock'
nock = require 'nock'
fs = require 'fs'

# To expand the '*' is handled by `imjs` library, therefore unit test (expandStar)

unitTests() && describe 'Query', ->
  # recordResponses 'dummy.txt', before, after
  # before ->
    # nock.recorder.rec
      # logging: (content) -> fs.appendFile 'record.txt', content, console.error
      # output_objects: true

  # after ->
    # nock.restore()
    # nockCallObjects = nock.recorder.play()
    # fs.writeFile 'dummy.txt', JSON.stringify(nockCallObjects), console.error

  describe 'expandStar', ->

    {service} = new Fixture()

    describe "#select(['*'])", ->
      @beforeEach prepare ->
        setupMock '/service/model?format=json'
        setupMock '/service/summaryfields?format=json'
        service.query root: 'Employee'

      it 'should expand stars to the summary fields', eventually (q) ->
        expected_views = [
          'Employee.name',
          'Employee.department.name',
          'Employee.department.manager.name',
          'Employee.department.company.name',
          'Employee.fullTime',
          'Employee.address.address'
        ]
        q.select ['*']
        q.views.should.eql expected_views

      it 'should expand double stars to all fields', eventually (q) ->
        expected_views = [
          'Employee.name',
          'Employee.department.name',
          'Employee.department.manager.name',
          'Employee.department.company.name',
          'Employee.fullTime',
          'Employee.address.address',
          'Employee.age',
          'Employee.end',
          'Employee.id'
        ]
        q.select ['**']
        q.views.sort().should.eql expected_views.sort()

      it 'should be able to expand paths ending in a star', eventually (q) ->
        expected_views = [ 'Employee.department.name' ]
        q.select ['department.*']
        q.views.should.eql expected_views


