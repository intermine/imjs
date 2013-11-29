{prepare, eventually, always, clear, report} = require './lib/utils'
Fixture = require './lib/fixture'
Promise = require 'promise'

{invoke} = Fixture.funcutils

describe 'Query#appendToList', ->

  {service, olderEmployees, youngerEmployees} = new Fixture()
  name = 'temp-olders-append-to-list-target'
  tags = ['js', 'node', 'testing', 'mocha', 'append-to-list']
  clearList = clear service, name

  @slow 400
  @timeout 10000
  
  @afterAll always clearList

  describe 'target: List', ->

    @beforeAll prepare -> clearList().then -> Promise.all([
      service.count(youngerEmployees),
      service.count(olderEmployees),
      service.query(youngerEmployees),
      service.query(olderEmployees).then(invoke 'saveAsList', {name, tags})
    ]).then ([yc, oc, yq, target]) ->
      yq.appendToList(target).then (newState) -> [yc, oc, target, newState]

    it 'should actually add items to the list', eventually ([_, oc, orig]) ->
      orig.size.should.be.above oc

    it 'should in fact add all the youngsters', eventually ([yc, oc, orig]) ->
      orig.size.should.equal yc + oc

    it 'should keep the input and output lists in sync', eventually ([_..., orig, appended]) ->
      orig.size.should.equal appended.size

  describe 'target: String', ->

    @beforeAll prepare -> clearList().then -> Promise.all([
      service.count(youngerEmployees),
      service.count(olderEmployees),
      service.query(youngerEmployees),
      service.query(olderEmployees).then((q) -> q.saveAsList {name, tags})
    ]).then ([yc, oc, yq, ol]) -> yq.appendToList(ol.name).then (al) -> [yc, oc, ol, al]

    it 'should have appropriate values to start with -yc', eventually ([yc]) ->
      yc.should.equal 85

    it 'should have appropriate values to start with -oc', eventually ([_, oc]) ->
      oc.should.equal 46

    it 'should have appropriate values to start with -oc', eventually ([_, __, ol]) ->
      ol.size.should.equal 46

    it 'should actually add items to the list', eventually ([yc, oc, _, list]) ->
      list.size.should.be.above oc

    it 'should in fact add all the youngsters', eventually ([yc, oc, _, list]) ->
      list.size.should.equal yc + oc

    it 'input and output lists should not be in sync', eventually ([yc, oc, orig, appended]) ->
      orig.size.should.equal oc
      appended.size.should.equal orig.size + yc

