Fixture = require './lib/fixture'
{always, prepare, eventually} = require './lib/utils'
should = require 'should'

describe 'Service#register', ->

  username = 'mr foo'
  password = 'pæssw0rd'

  {service} = new Fixture
  service.errorHandler = ->

  removeMrFoo = ->
    service.login(username, password)
            .then (fooService) ->
              p = fooService.getDeregistrationToken()
              p.then (token) -> fooService.deregister token.uuid

  @beforeAll always removeMrFoo

  describe 'registering a new user', ->

    @beforeAll prepare -> service.register username, password
    @afterAll always removeMrFoo

    it 'should be able to register a new user', eventually (s) ->
      s.fetchUser().then (user) -> user.username.should.eql username

  describe 'deregistering a user', ->

    @beforeAll prepare -> service.register username, password
    @afterAll always removeMrFoo

    it 'should be able to deregister a user', eventually (s) ->
      accessToken = s.token
      tokP = s.getDeregistrationToken()
      checkTokenAndDeregister = (token) ->
        token.secondsRemaining.should.be.above 0
        s.deregister token.uuid

      tokP.then(checkTokenAndDeregister)
          .then(-> s.fetchUser())
          .then(
            (-> throw new Error "Token is still valid" ),
            ((err) -> err.should.match new RegExp accessToken ))
