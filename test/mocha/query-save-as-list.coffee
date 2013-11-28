{prepare, eventually, always, clear, report} = require './lib/utils'
should = require 'should'
Promise = require 'promise'
Fixture = require './lib/fixture'
{set} = Fixture.funcutils

tags = ['js', 'node', 'testing', 'mocha', 'save-as-list']
makeTheList = (s, name, opts) -> prepare -> clear(s, name)().then ->
  Promise.all [s.query(opts).then((q) -> q.saveAsList {name, tags}), s.count(opts)]

describe 'Query#saveAsList', ->

  {service, olderEmployees, youngerEmployees} = new Fixture()

  @slow 400

  describe 'saving older employees', ->
    name = 'temp-olders-from-query'
    
    @afterAll always clear service, name

    @beforeAll makeTheList service, name, olderEmployees

    it 'should exist', eventually ([list]) ->
      should.exist list

    it "should be called '#{ name }'", eventually ([list]) ->
      list.name.should.equal name

    it 'should contain as many members as the count suggests', eventually ([list, count]) ->
      list.size.should.equal count

    it "should be marked for death", eventually ([list]) ->
      list.hasTag(t).should.be.true for t in tags

  describe 'saving younger employees', ->
    name = 'temp-youngers-from-query'
    
    @afterAll always clear service, name

    @beforeAll makeTheList service, name, youngerEmployees

    it 'should exist', eventually (list) ->
      should.exist list

    it "should be called '#{ name }'", eventually ([list]) ->
      list.name.should.equal name

    it 'should contain as many members as the count suggests', eventually ([list, count]) ->
      list.size.should.equal count

    it "should be marked for death", eventually ([list]) ->
      list.hasTag(t).should.be.true for t in tags
