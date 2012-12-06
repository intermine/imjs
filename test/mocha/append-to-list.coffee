{prepare, eventually, always, clear, report} = require './lib/utils'
$ = require 'underscore.deferred'
once = $.when
{Deferred} = $
Fixture = require './lib/fixture'

describe 'Query#appendToList', ->

    {service, olderEmployees, youngerEmployees} = new Fixture()
    name = 'temp-olders-append-to-list-target'
    tags = ['js', 'node', 'testing', 'mocha', 'append-to-list']
    clearList = clear service, name

    @slow 400
    
    @afterAll always clearList

    describe 'target: List', ->

        @beforeAll prepare -> clearList().then -> once(
                service.count(youngerEmployees),
                service.count(olderEmployees),
                service.query(youngerEmployees),
                service.query(olderEmployees).then((q) -> q.saveAsList {name, tags})
            ).then (yc, oc, yq, ol) -> Deferred ->
                yq.appendToList(ol).fail(@reject).done (al) => @resolve(yc, oc, ol, al)

        it 'should actually add items to the list', eventually (yc, oc, list) ->
            list.size.should.be.above oc

        it 'should in fact add all the youngsters', eventually (yc, oc, list) ->
            list.size.should.equal yc + oc

        it 'should keep the input and output lists in sync', eventually (_..., orig, appended) ->
            orig.size.should.equal appended.size

    describe 'target: String', ->

        @beforeAll prepare -> clearList().then -> once(
                service.count(youngerEmployees),
                service.count(olderEmployees),
                service.query(youngerEmployees),
                service.query(olderEmployees).then((q) -> q.saveAsList {name, tags})
            ).then (yc, oc, yq, ol) -> Deferred ->
                yq.appendToList(name).fail(@reject).done (al) => @resolve(yc, oc, ol, al)

        it 'should actually add items to the list', eventually (yc, oc, _, list) ->
            list.size.should.be.above oc

        it 'should in fact add all the youngsters', eventually (yc, oc, _, list) ->
            list.size.should.equal yc + oc

        it 'should not have kept the input and output lists in sync', eventually (yc, oc, orig, appended) ->
            orig.size.should.equal oc
            appended.size.should.equal orig.size + yc

