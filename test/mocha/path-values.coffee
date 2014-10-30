Fixture              = require './lib/fixture'
{cleanSlate, prepare, always, clear, eventually, shouldFail} = require './lib/utils'
{prepare, eventually, always} = require './lib/utils'
should               = require 'should'

workerNames = 'Department.employees.name'
workingBosses = 'Department.employees': 'CEO'

describe 'Service', ->

  {service} = new Fixture()

  describe '#pathValues()', ->

    it 'should fail', shouldFail service.pathValues

  describe '#values()', ->

    it 'should fail', shouldFail service.values

  describe '#pathValues("Foo.bar")', ->

    it 'should fail', shouldFail -> service.pathValues 'Foo.bar'

  describe '#pathValues("Company.name")', ->

    @beforeAll prepare -> service.pathValues 'Company.name'

    it 'should get a list of seven values', eventually (values) ->
      values.length.should.equal 7

    it 'should include Wernham-Hogg', eventually (values) ->
      (v.value for v in values).should.containEql 'Wernham-Hogg'

  describe '#pathValues("Company.name", cb)', ->
     
    it 'should find WH in amongst the 7 companies', (done) ->
      service.pathValues "Company.name", (err, values) ->
        return done err if err?
        try
          values.length.should.equal 7
          (v.value for v in values).should.containEql 'Wernham-Hogg'
          done()
        catch e
          done e

  describe '#pathValues(Path("Company.name"))', ->

    @beforeAll prepare -> service.fetchModel().then (m) ->
      service.pathValues m.makePath 'Company.name'

    it 'should get a list of seven values', eventually (values) ->
      values.length.should.equal 7

    it 'should include Wernham-Hogg', eventually (values) ->
      (v.value for v in values).should.containEql 'Wernham-Hogg'

  describe '#pathValues("Department.employees.name")', ->

    @beforeAll prepare -> service.pathValues workerNames

    it 'should get a list of 132 values', eventually (values) ->
      values.length.should.equal 132
      
    it 'should include David-Brent', eventually (values) ->
      (v.value for v in values).should.containEql 'David Brent'

  describe '#pathValues("Department.employees.name")', ->

    @beforeAll prepare -> service.fetchModel().then (m) ->
      service.pathValues m.makePath 'Department.employees.name'

    it 'should get a list of 132 values', eventually (values) ->
      
    it 'should include David-Brent', eventually (values) ->
      (v.value for v in values).should.containEql 'David Brent'

  describe '#pathValues("Department.employees.name", {"Department.employees": "CEO"})', ->

    @beforeAll prepare -> service.pathValues workerNames, workingBosses

    it 'should get a list of six values', eventually (values) ->
      values.length.should.equal 6
    
    it 'should not include David-Brent', eventually (values) ->
      (v.value for v in values).should.not.containEql 'David Brent'

    it "should include B'wah Hah Hah", eventually (values) ->
      (v.value for v in values).should.containEql "Charles Miner"

  describe '#pathValues("Department.employees.name", {"Department.employees": "CEO"}, cb)', ->

    it 'should find 6 CEOs, including Charles Miner', (done) ->
      service.pathValues workerNames, workingBosses, (e, vs) ->
        return done e if e?
        try
          vs.length.should.equal 6
          names = (v.value for v in vs)
          names.should.not.containEql 'David Brent'
          names.should.containEql "Charles Miner"
          done()
        catch err
          done err

  describe '#pathValues(Path("Department.employees.name", {"Department.employees": "CEO"}))', ->

    @beforeAll prepare -> service.fetchModel().then (m) ->
      service.pathValues m.makePath workerNames, workingBosses

    it 'should get a list of six values', eventually (values) ->
      values.length.should.equal 6
    
    it 'should not include David-Brent', eventually (values) ->
      (v.value for v in values).should.not.containEql 'David Brent'

    it "should include B'wah Hah Hah", eventually (values) ->
      (v.value for v in values).should.containEql "Charles Miner"

  describe '#values("Department.employees.name", {"Department.employees": "CEO"})', ->

    @beforeAll prepare -> service.values workerNames, workingBosses

    it 'should get a list of six values', eventually (values) ->
      values.length.should.equal 6
    
    it 'should not include David-Brent', eventually (values) ->
      values.should.not.containEql 'David Brent'

    it "should include B'wah Hah Hah", eventually (values) ->
      values.should.containEql "Charles Miner"

  describe '#values(Path("Department.employees.name", {"Department.employees": "CEO"}))', ->

    @beforeAll prepare -> service.fetchModel().then (m) ->
      service.values m.makePath workerNames, workingBosses

    it 'should get a list of six values', eventually (values) ->
      values.length.should.equal 6
    
    it 'should not include David-Brent', eventually (values) ->
      values.should.not.containEql 'David Brent'

    it "should include B'wah Hah Hah", eventually (values) ->
      values.should.containEql "Charles Miner"

