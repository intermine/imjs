Fixture = require './lib/fixture'
{prepare, always, clear, eventually} = require './lib/utils'
{get, invoke} = Fixture.funcutils

testTags = ['js', 'testing', 'mocha', 'imjs', '__folder__:test']
namePrefix = 'temp-testing-list-operations-'

listOpTest = ({method, expectedMember, lists, size}) ->

  {service} = new Fixture()

  args =
    tags: [method].concat(testTags)
    name: namePrefix + method
    lists: lists

  clearList = clear service, args.name

  describe "a list created by #{ method }", ->

    describe 'using the promise api', ->

      gotInputs = args.lists.map service.fetchList

      @slow 400
      @afterAll always clearList
      @beforeAll prepare -> clearList().then -> service[method] args

      it "should have #{ size } members", eventually (list) ->
        list.size.should.equal size

      it "should be called #{ args.name }", eventually (list) ->
        list.name.should.equal args.name

      it "should contain #{ expectedMember }", eventually (list) ->
        list.contents().then (contents) ->
          (x.name for x in contents).should.containEql expectedMember

      it 'should have the test tags', eventually (list) ->
        list.hasTag(t).should.be.true for t in testTags

      it 'should be in the test folder', eventually (list) ->
        list.folders.should.containEql 'test'

    describe 'using the callback api', ->

      @slow 400
      @afterAll always clearList
      @beforeAll always clearList

      it 'should have the right size, name, and all the tags we specified', (done) ->
        service[method] args, (err, list) ->
          return done err if err?
          try
            list.size.should.equal size
            list.name.should.equal args.name
            list.hasTag(t).should.be.true for t in testTags
            done()
          catch e
            done e

describe 'List Operations', ->

  listOpTest
    method: 'intersect'
    expectedMember: 'David Brent'
    size: 2
    lists: ['My-Favourite-Employees', 'some favs-some unknowns-some umlauts']

  listOpTest
    method: 'union'
    expectedMember: 'David Brent'
    size: 6
    lists: ['My-Favourite-Employees', 'Umlaut holders']

  listOpTest
    method: 'merge'
    expectedMember: 'David Brent'
    size: 6
    lists: ['My-Favourite-Employees', 'Umlaut holders']

  listOpTest
    method: 'diff'
    expectedMember: 'Brenda'
    size: 4
    lists: ['The great unknowns', 'some favs-some unknowns-some umlauts']
 
