es = require 'event-stream'
reduce = require 'stream-reduce'

Fixture              = require './lib/fixture'
Counter              = require './lib/stream-utils'

{prepare, eventually, always, shouldBeRejected} = require './lib/utils'
should               = require 'should'

{invoke, defer} = Fixture.utils

SLOW = 200

describe 'Service#eachRecord', ->

  @slow SLOW

  {olderEmployees, service} = new Fixture()

  query =
    select: ['age']
    from: 'Employee'
    where: olderEmployees.where

  describe 'Params', ->

    it 'can yield each employee, using params', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      service.eachRecord query, {}, count, reject, check

    it 'can yield each employee, without needing a page, using params', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      service.eachRecord query, count, reject, check

    it 'can yield a stream of employees, using params', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      test = (stream) ->
        stream.on 'data', count
        stream.on 'end', check
        stream.on 'error', reject
      service.eachRecord(query).then test, done

    it 'can make use of pipes', (done) ->
      check = (total) ->
        try
          total.should.eql 2688
          done()
        catch e
          done e

      p = service.eachRecord(query).then (streamOfEmployees) ->
        streamOfEmployees.pipe reduce ((total, emp) -> total + emp.age), 0
        .on 'data', check
        .on 'error', done
      p.then null, done

  describe 'Query', ->

    it 'can yield each employee, all parameters', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      test = (q) -> service.eachRecord q, {}, count, reject, check
      service.query(query).then test, done

    it 'can yield each employee, without needing a page', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      testQuery = (q) -> service.eachRecord q, count, reject, check
      service.query(query).then testQuery, done

    it 'can yield a stream of employees, no callbacks', (done) ->
      {reject, check, count} = Counter.forOldEmployees done
      testStream = (stream) ->
        stream.on 'data', count
        stream.on 'end', check
        stream.on 'error', reject
      testQuery = (q) -> service.eachRecord(q).then testStream, reject
      service.query(query).then testQuery, reject

describe 'Query#eachRecord', ->

  {olderEmployees, service} = new Fixture()

  query =
    select: ['Employee.age']
    where: olderEmployees.where

  @beforeAll prepare -> service.query(query).then(invoke 'eachRecord')

  it 'promises to return a stream over the employees', eventually (stream) ->
    {promise, resolve, reject} = defer()
    n = sum = 0
    stream.on 'error', reject
    stream.on 'data', (e) ->
      n++
      sum += e.age
    stream.on 'end', ->
      try
        n.should.equal 46
        sum.should.equal 2688
        resolve()
      catch e
        reject e


