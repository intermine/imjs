Fixture = require './lib/fixture'
{eventually, prepare, always} = require './lib/utils'
should = require 'should'
{bothTests} = require './lib/segregation'
{setupRecorder, stopRecorder} = require './lib/mock'
{setupBundle} = require './lib/mock'

bothTests() && describe 'Service', ->
# bothTests() && describe '__current', ->

  setupBundle 'who-am-i.1.json'
  # setupRecorder()

  @afterAll ->
    # stopRecorder 'dummy.json'

  @slow 5000

  {service} = new Fixture()
  
  describe '#whoami()', ->

    @beforeAll prepare service.whoami

    it 'should yield a user', eventually (user) ->
      should.exist user

    it 'should yield the representation of the test user', eventually (user) ->
      user.username.should.equal 'intermine-test-user'

  describe '#whoami(cb)', ->

    it 'should support the callback API', (done) ->
      service.whoami (err, user) ->
        done err if err?
        try
          user.username.should.equal 'intermine-test-user'
          done()
        catch e
          done e
      return

  describe '#fetchUser()', ->

    @beforeAll prepare service.fetchUser

    it 'should yield a user', eventually (user) ->
      should.exist user

    it 'should yield the representation of the test user', eventually (user) ->
      user.username.should.equal 'intermine-test-user'

