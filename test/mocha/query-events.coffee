{Query} = require './lib/fixture'
should = require 'should'

describe 'Query#on', ->

  q = new Query
  events = 0
  specific = 0
  q.on 'all', (name, n) -> events += n
  q.on 'foo', (n) -> specific += n

  describe 'when events are triggered', ->
    q.trigger 'foo', 1
    q.trigger 'bar', 1
    q.trigger 'foo', 2

    it 'should notify generally interested handlers', ->
      events.should.equal 4

    it 'should also notify handlers with more specific interests', ->
      specific.should.equal 3

describe 'Query#on', ->

  q = new Query
  events = 0
  q.on 'all', -> events++

  describe 'when events are emitted', ->
    q.emit 'foo'
    q.emit 'bar'

    it 'should respond to events', ->
      events.should.equal 2

describe 'Query#bind', ->

  q = new Query
  events = 0
  q.bind 'all', -> events++

  describe 'when events are emitted', ->
    q.trigger 'foo'
    q.emit 'bar'

    it 'should respond to events', ->
      events.should.equal 2

describe 'Query#off', ->

  q = new Query
  events = 0
  q.on 'all', -> events++

  describe 'when events are emitted', ->
    q.trigger 'foo'
    q.off()
    q.emit 'bar'

    it 'should respond to events', ->
      events.should.equal 1

describe 'Query#off', ->

  q = new Query
  foos = 0
  bars = 0
  q.on 'foo', -> foos++
  q.on 'bar', -> bars++

  describe 'when events are emitted', ->
    q.trigger 'foo'
    q.trigger 'bar'
    q.off 'foo'
    q.emit 'foo'
    q.emit 'bar'

    it 'should respond to events', ->
      foos.should.equal 1
      bars.should.equal 2

describe 'Query#unbind', ->

  q = new Query
  events = 0
  q.on 'all', -> events++

  describe 'when events are emitted', ->
    q.trigger 'foo'
    q.unbind()
    q.emit 'bar'

    it 'should respond to events', ->
      events.should.equal 1

