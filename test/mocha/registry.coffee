should = require 'should'
{shouldBeRejected} = require './lib/utils'

Fixture = require './lib/fixture'

{Registry} = Fixture

{unitTests, integrationTests, bothTests} = require './lib/segregation'

bothTests() && describe 'Registry', ->
# bothTests() && describe '__current', ->

  bothTests() && describe 'new Registry', ->
    registry = new Registry

    unitTests() && it 'should make a new registry adapter', ->
      should.exist registry
      registry.should.be.an.instanceOf Registry

    unitTests() && describe 'getFormat', ->
      {getFormat} = new Registry
      it 'should return format of query and default back to json', ->

        getFormat().should.equal 'json'
        getFormat('xml').should.equal 'xml'

    unitTests() && describe 'makePath', ->
      {makePath} = new Registry

      it 'should return complete path, assembling root url and query parameters', ->
        root = makePath '', {}
        root.should.equal 'http://registry.intermine.org/service/'
        (makePath 'outer/inner', {}).should.equal "#{root}outer/inner"
        (makePath 'outer/inner', {a: 2, b: 3}).should.equal "#{root}outer/inner?a=2&b=3"

    unitTests() && describe 'isEmpty', ->
      {isEmpty} = new Registry

      it 'should return true if an object is empty and has Object as prototype, false if not', ->
        (isEmpty {}).should.be.true
        (isEmpty {a: 1}).should.be.false

    unitTests() && describe 'isEmptyString', ->
      {isEmptyString} = new Registry

      it 'should return true if the string passed does not exist', ->
        (isEmptyString null).should.be.true
        (isEmptyString undefined).should.be.true

      it 'should return true if the string passed is completely blank', ->
        (isEmptyString "").should.be.true
        (isEmptyString "   ").should.be.true

      it 'should return false if the string is non empty', ->
        (isEmptyString "filler").should.be.false
        (isEmptyString "  filler  ").should.be.false

    bothTests() && describe 'fetchMines', ->
      @timeout 15000
      {fetchMines} = new Registry

      unitTests() && it 'should reject all values except dev, prod or all in type of \
        mine', (done) ->
        (shouldBeRejected fetchMines [], ['unexpect']) done
        return #To not return empty promise


      integrationTests() && it 'should fetch all mines given nothing in the query parameter', ->
        fetchMines [], []
          .then (mines) ->
            should.exist mines
            mines.should.have.properties statusCode: 200
            mines.should.have.property 'instances'

    bothTests() && describe 'fetchInstance', ->
      @timeout 15000
      registry = new Registry

      unitTests() && it 'should not allow \'id\', \'name\' or \'namespace\' to be null', (done) ->
        (shouldBeRejected registry.fetchInstance null) done
        return #To not return empty promise

      unitTests() && it 'should not allow \'id\', \'name\' or \'namespace\' to be an \
        empty string', (done) ->
        (shouldBeRejected registry.fetchInstance "   ") done
        return #To not return empty promise


      integrationTests() && it 'should fetch the information of an instance given its \
        namespace', ->
        registry.fetchInstance 'flymine'
          .then (mine) ->
            should.exist mine
            mine.should.have.properties statusCode: 200
            mine.should.have.property 'instance'

    bothTests() && describe 'fetchNamespace', ->
      @timeout 15000
      registry = new Registry

      unitTests() && it 'should not allow \'url\' to be null', (done) ->
        (shouldBeRejected registry.fetchNamespace null) done
        return #To not return empty promise

      unitTests() && it 'should not allow \'url\' to be an empty string', (done) ->
        (shouldBeRejected registry.fetchNamespace "   ") done
        return #To not return empty promise


      integrationTests() && it 'should fetch the namespace of the instance associated \
        with the given url', ->
        registry.fetchNamespace 'www.flymine.org'
          .then (namespace) ->
            should.exist namespace
            namespace.should.have.properties statusCode: 200
            namespace.should.have.property 'namespace'
