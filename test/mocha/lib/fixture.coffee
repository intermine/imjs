lib = if process.env.IMJS_COV then 'build-cov' else 'build'

{Service, Query, Model} = require '../../../js/main.js'
funcutils = require "../../../#{ lib }/util"

args =
    root: process.env.TESTMODEL_URL ? 'localhost:8080/intermine-test'
    token: 'test-user-token'

class Fixture

    constructor: ->
        @service = new Service args

        @allEmployees =
            select: ['*']
            from: 'Employee'

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


Fixture.funcutils = funcutils
Fixture.Query = Query
Fixture.Model = Model

module.exports = Fixture
