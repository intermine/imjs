Fixture = require './lib/fixture'
{report, deferredTest} = require './lib/utils'

describe 'Counting', ->

    {service, olderEmployees, allEmployees} = new Fixture()

    it 'should work for all', (done) ->
        test = deferredTest (c) -> c.should.be.above(130).and.below(140)
        report done, service.count(allEmployees).then test


