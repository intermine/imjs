Fixture              = require './lib/fixture'
{needs, prepare, eventually, always} = require './lib/utils'
should               = require 'should'
Promise              = require 'promise'
{invoke} = Fixture.funcutils

once = Promise.all

atV = needs 12

describe 'Query', ->

  describe 'getExportURI', ->

    {service} = new Fixture()
    companies = select: ['Company.name']


    describe 'default format, no options', ->

      @beforeAll prepare -> service.query(companies).then invoke 'getExportURI'

      it 'should yield a URL', eventually (url) ->
        should.exist url

      it 'should look about right', eventually (url) ->
        url.should.eql service.root +
          'query/results?query=' +
          '%3Cquery%20model%3D%22testmodel%22%20view%3D%22Company.name%22%20%3E%3C%2Fquery%3E' +
          '&format=tab&token=' + service.token

    describe 'tab format, no options', ->

      @beforeAll prepare ->
        service.query(companies).then invoke 'getExportURI', 'tab'

      it 'should yield a URL', eventually (url) ->
        should.exist url

      it 'should look about right', eventually (url) ->
        url.should.eql service.root +
          'query/results?query=' +
          '%3Cquery%20model%3D%22testmodel%22%20view%3D%22Company.name%22%20%3E%3C%2Fquery%3E' +
          '&format=tab&token=' + service.token

    describe 'csv format, no options', ->

      @beforeAll prepare ->
        service.query(companies).then invoke 'getExportURI', 'csv'

      it 'should yield a URL', eventually (url) ->
        should.exist url

      it 'should look about right', eventually (url) ->
        url.should.eql service.root +
          'query/results?query=' +
          '%3Cquery%20model%3D%22testmodel%22%20view%3D%22Company.name%22%20%3E%3C%2Fquery%3E' +
          '&format=csv&token=' + service.token

    describe 'tab format, with options', ->

      @beforeAll prepare ->
        service.query(companies).then invoke 'getExportURI', 'tab', columnheaders: true

      it 'should yield a URL', eventually (url) ->
        should.exist url

      it 'should look about right', eventually (url) ->
        url.should.eql service.root +
          'query/results?columnheaders=true&query=' +
          '%3Cquery%20model%3D%22testmodel%22%20view%3D%22Company.name%22%20%3E%3C%2Fquery%3E' +
          '&format=tab&token=' + service.token

    describe 'gff3 format, no options', ->

      @beforeAll prepare ->
        service.query(companies).then invoke 'getExportURI', 'gff3'

      it 'should yield a URL', eventually (url) ->
        should.exist url

      it 'should look about right', eventually (url) ->
        url.should.eql service.root +
          'query/results/gff3?query=' +
          '%3Cquery%20model%3D%22testmodel%22%20%3E%3C%2Fquery%3E' +
          '&format=text&token=' + service.token

    describe 'fasta format, no options', ->

      @beforeAll prepare ->
        service.query(companies).then invoke 'getExportURI', 'fasta'

      it 'should yield a URL', eventually (url) ->
        should.exist url

      it 'should look about right', eventually (url) ->
        url.should.eql service.root +
          'query/results/fasta?query=' +
          '%3Cquery%20model%3D%22testmodel%22%20%3E%3C%2Fquery%3E' +
          '&format=text&token=' + service.token

    describe 'gff3 format, view options', ->

      @beforeAll prepare ->
        service.query(companies).then invoke 'getExportURI', 'gff3', view: ['id', 'name']

      it 'should yield a URL', eventually (url) ->
        should.exist url

      it 'should look about right', eventually (url) ->
        url.should.eql service.root +
          'query/results/gff3?query=' +
          '%3Cquery%20model%3D%22testmodel%22%20%3E%3C%2Fquery%3E' +
          '&format=text' +
          '&view=Company.id&view=Company.name' +
          '&token=' + service.token

