Fixture = require './lib/fixture'
{eventually, prepare, after} = require './lib/utils'
{get, invoke} = Fixture.funcutils
should = require 'should'

describe 'User#getToken', ->

  {service} = new Fixture

  userPromise = service.fetchUser()

  describe 'A day token', ->

    @beforeAll prepare -> after userPromise, userPromise.then invoke 'getToken'

    it 'should not be the same as the permanent token', eventually ([_, token]) ->
      token.should.not.equal service.token

    it 'should still function as one though', eventually ([user, token]) ->
      service.connectAs(token)
             .fetchUser()
             .then (user2) ->
               user2.username.should.equal user.username

