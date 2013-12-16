covDir = '../../../build-cov'

if process.env.IMJS_COV
  {Service, Query, Model, utils} = require covDir + '/service'
else
  {Service, Query, Model, utils} = require '../../../'

args =
  root: process.env.TESTMODEL_URL ? 'localhost:8080/intermine-test'
  token: 'test-user-token'

legacy =
  root: process.env.LEGACY_URL ? 'localhost:8080/legacy-test'
  token: 'test-user-token'

console.log "Testing against #{ args.root }" if process.env.DEBUG

class Fixture

    constructor: ->
        [@service, @legacy] = [args, legacy].map Service.connect

        @allEmployees =
            select: ['*']
            from: 'Employee'

        @badQuery =
          select: ['name']
          from: 'Employee'
          where:
            id: 'foo'

        @olderEmployees =
            select: ['*']
            from: 'Employee'
            where:
                age:
                    gt: 50

        @youngerEmployees =
            select: ['*']
            from: 'Employee'
            where:
                age:
                    le: 50


Fixture.funcutils = utils
Fixture.utils = utils
Fixture.Query = Query
Fixture.Model = Model
Fixture.Service = Service

module.exports = Fixture
