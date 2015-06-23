{Service, utils} = require './lib/fixture'
{shouldFail, prepare, eventually} = require './lib/utils'
{parallel, invoke, get} = utils
should = require 'should'

countRecords = (gff3) ->
  (l for l in gff3.split(/\n/) when l.length and not /^#/.test(l.trim())).length

describe 'GFF3 Queries', ->

  @timeout 10000

  # TODO: ideally this should point at a more stable mine.
  service = new Service root: 'www.flymine.org/query'

  describe 'implicitly constrained', ->

    opts =
      from: 'Gene'
      select: ['symbol', 'pathways.name']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']

    @beforeAll prepare -> service.query(opts).then (q) ->
      parallel [q.summarise('symbol').then(({stats}) -> stats), q.getGFF3()]

    it 'should find only two genes, due to the pathways', eventually ([stats, gff3]) ->
      stats.uniqueValues.should.equal 2

    it 'should find only two gff3 record, due to the pathways', eventually ([stats, gff3]) ->
      countRecords(gff3).should.equal 2

    describe 'callback api', ->

      it 'should work, just like promises do, but be more verbose', (done) ->
        service.query opts, (err, query) ->
          return done err if err?
          query.getGFF3 (err, gff3) ->
            return done err if err?
            try
              countRecords(gff3).should.equal 2
              done()
            catch e
              done e


  describe 'outer joined', ->
    opts =
      from: 'Gene'
      select: ['symbol', 'pathways.name']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']
      joins: ['pathways']

    @beforeAll prepare -> service.query(opts).then (q) ->
      parallel q.summarise('symbol').then(({stats}) -> stats), q.getGFF3()

    it 'should find 5 genes', eventually ([stats, gff3]) ->
      stats.uniqueValues.should.equal 5

    it 'should find 5 gff3 records', eventually ([stats, gff3]) ->
      countRecords(gff3).should.equal 5

  describe 'unconstrained', ->
    opts =
      from: 'Gene'
      select: ['symbol']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']

    @beforeAll prepare -> service.query(opts).then (q) ->
      parallel q.summarise('symbol').then(({stats}) -> stats), q.getGFF3()

    it 'should find all genes', eventually ([stats, gff3]) ->
      stats.uniqueValues.should.equal 5

    it 'should find 5 gff3 records', eventually ([stats, gff3]) ->
      countRecords(gff3).should.equal 5

  describe 'with extra attributes', ->
    opts =
      from: 'Gene'
      select: ['symbol']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']

    @beforeAll prepare ->
      beta = new Service root: 'www.flymine.org/query'
      qp = beta.query(opts)
      statsp = qp.then (q) -> q.summarise('symbol').then ({stats}) -> stats
      gff3p = qp.then (q) -> q.getGFF3 view: ['organism.name', 'length']
      parallel statsp, gff3p

    it 'should find all genes', eventually ([stats, gff3]) ->
      stats.uniqueValues.should.equal 5

    it 'should find 5 gff3 records', eventually ([stats, gff3]) ->
      countRecords(gff3).should.equal 5

    it 'the records should have the extra attributes', eventually ([stats, gff3]) ->
      for line in gff3.split("\n") when line.length and not /^#/.test line
        col9 = line.split(/\t/)[8]
        col9.should.match /organism.name/
        col9.should.match /length/

  describe 'with exons', ->
    opts =
      from: 'Gene'
      select: ['symbol', 'exons.symbol']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']
      joins: ['exons']

    @beforeAll prepare -> service.query(opts).then (q) ->
      parallel q.summarise('symbol').then(({stats}) -> stats), q.getGFF3()

    it 'should find all genes', eventually ([stats, gff3]) ->
      stats.uniqueValues.should.equal 5

    it 'should find more than 5 gff3 records', eventually ([stats, gff3]) ->
      countRecords(gff3).should.be.above 5

  describe 'export paths', ->
    opts =
      from: 'Gene'
      select: ['symbol', 'pathways.identifier']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']
    exons = 'exons.id'

    @beforeAll prepare -> service.query(opts).then (q) ->
      parallel q.summarise(exons).then(get 'stats'), q.getGFF3(export: [exons])

    it 'should find more than 5 gff3 records', eventually ([stats, gff3]) ->
      countRecords(gff3).should.equal stats.uniqueValues

  describe 'export nodes', ->
    opts =
      from: 'Gene'
      select: ['symbol', 'pathways.identifier']
      where:
        symbol: ['eve', 'zen', 'bib', 'r', 'h']
    exons = 'exons'

    @beforeAll prepare -> service.query(opts).then (q) ->
      parallel q.summarise('exons.id').then(get 'stats'), q.getGFF3(export: [exons])

    it 'should find more than 5 gff3 records', eventually ([stats, gff3]) ->
      countRecords(gff3).should.equal stats.uniqueValues

  describe 'bad request', ->

    service = new Service root: 'www.flymine.org/query', errorHandler: ->

    opts =
      from: 'Organism'
      select: ['name']
      where:
        taxonId: 7227

    it 'should fail', shouldFail -> service.query(opts).then invoke 'getGFF3'

    it 'should supply an error message to callbacks', (done) ->
      service.query opts, (err, query) ->
        return done err if err?
        query.getGFF3 (err, gff3) ->
          return done new Error("Expected failure, got: #{ gff3 }") if gff3
          try
            err.message.trim().should.startWith "Query does not pass XML validation."
            done()
          catch e
            done e