Fixture = require './lib/fixture'
{always, prepare, eventually} = require './lib/utils'
should = require 'should'

describe 'Service#register', ->

  username = 'mr foo'
  password = 'pæssw0rd'

  {service} = new Fixture
  service.errorHandler = -> # Suppress pointless error messages.

  removeMrFoo = -> service.login(username, password).then (fooService) ->
    p = fooService.getDeregistrationToken()
    p.then (token) -> fooService.deregister token.uuid

  @beforeAll always removeMrFoo

  describe 'registering a new user', ->

    @afterAll always removeMrFoo
    @beforeAll prepare -> service.register username, password

    it 'should create a user', eventually (s) ->
      s.fetchUser().then (user) -> user.username.should.eql username

    it 'should be reversible', eventually (s) ->
      accessToken = s.token
      pattern = new RegExp accessToken
      tokP = s.getDeregistrationToken()
      checkTokenAndDeregister = (token) ->
        token.secondsRemaining.should.be.above 0
        s.deregister token.uuid

      tokP.then checkTokenAndDeregister
          .then -> s.fetchUser()
          .then (-> throw new Error "Token is still valid"), (err) -> err.should.match pattern

