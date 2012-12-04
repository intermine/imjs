{Deferred} = require 'underscore.deferred'
Fixture = require './lib/fixture'
{eventually} = require './lib/utils'
{invoke, get, flatMap} = Fixture.funcutils
sumCounts = flatMap get 'count'

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

        it 'should have a suitable max value', eventually (_, stats) ->
            stats.max.should.be.below 100

        it 'should have a suitable min value', eventually (_, stats) ->
            stats.min.should.be.above 49

        it 'should have a suitable total', eventually (buckets, stats) ->
            buckets.length.should.be.below stats.uniqueValues

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

        it 'should contain the company names as the bucket labels', eventually (items) ->
            (x.item for x in items).should.include 'Wernham-Hogg'

        it 'should have a suitable total', eventually (_, stats) ->
            stats.uniqueValues.should.equal 6
        
