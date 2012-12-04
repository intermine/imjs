Fixture = require './lib/fixture'
{invoke, get, flatMap} = Fixture.funcutils
sumCounts = flatMap get 'count'

eventually = (test) -> (done) ->
    @promise.then(test).fail(done).done -> done()

describe 'Query', ->

    describe 'summary of numeric path', ->

        {service, olderEmployees} = new Fixture()

        @beforeEach (done) ->
            @promise = service.query(olderEmployees)
                .then(invoke 'summarise', 'age')
                .fail(done)
                .done -> done()

        it 'should have fewer than 21 buckets', eventually (buckets) ->
            buckets.length.should.be.below 21

        it 'should include all the results of the query', eventually (buckets) ->
            sumCounts(buckets).should.equal 46

        it.skip 'should have a suitable max value', eventually (_, stats) ->
            stats.max.should.be.below 100

        it.skip 'should have a suitable min value', eventually (_, stats) ->
            stats.min.should.be.above 49

    describe 'summary of string path', ->

        {service, olderEmployees} = new Fixture()

        @beforeEach (done) ->
            @promise = service.query(olderEmployees)
                .then(invoke 'summarise', 'department.company.name')
                .fail(done)
                .done -> done()

        it 'should have fewer than 21 buckets', eventually (items) ->
            items.length.should.equal 6

        it 'should include all the results of the query', eventually (items) ->
            sumCounts(items).should.equal 46

        it.skip 'should have a suitable total', eventually (_, stats) ->
            stats.total.should.equal 46

        
