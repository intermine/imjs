Fixture = require './lib/fixture'
{parallel, eventually, always, prepare, after} = require './lib/utils'
{get, invoke} = Fixture.funcutils
should = require 'should'

MSG = 'some message'

start = new Date().getTime()

describe 'User#getToken', ->

  {service} = new Fixture

  userPromise = service.fetchUser()

  describe 'A day token', ->

    @beforeAll prepare -> after userPromise, userPromise.then invoke 'createToken'

    it 'should not be the same as the permanent token', eventually ([_, token]) ->
      token.should.not.equal service.token

    it 'should still function as one though', eventually ([user, token]) ->
      service.connectAs(token)
             .fetchUser()
             .then (user2) ->
               user2.username.should.equal user.username

  describe 'Permanent tokens', ->

    revokeAll = -> userPromise.then (user) -> user.revokeAllTokens()

    describe 'create a token', ->

      @afterAll always revokeAll
      @beforeAll always revokeAll
      @beforeAll prepare -> userPromise.then (user) ->
        user.createToken('perm', MSG).then -> user.fetchCurrentTokens()

      it 'should have created a token', eventually (tokens) ->
        tokens.should.have.lengthOf 1

      it 'should have the right message', eventually ([token]) ->
        token.message.should.equal MSG

      it 'should have a good date', eventually ([token]) ->
        should.exist token.dateCreated
        d = new Date token.dateCreated
        unless isNaN d.getTime() # issue with phantomjs
          d.getTime().should.be.above start

    describe 'create a couple of tokens', ->

      @afterAll always revokeAll
      @beforeAll always revokeAll
      @beforeAll prepare -> userPromise.then (user) ->
        parallel(user.createToken('perm'), user.createToken('perm')).then ->
          user.fetchCurrentTokens()

      it 'should have created multiple tokens', eventually (tokens) ->
        tokens.should.have.lengthOf 2

    describe 'revoke all tokens', ->

      @beforeAll always revokeAll
      @afterAll always revokeAll
      @beforeAll prepare -> userPromise.then (user) ->
        user.createToken('perm', MSG).then -> user.fetchCurrentTokens()

      it 'should be able to delete these tokens', eventually (tokens) ->
        userPromise.then (user) ->
          user.revokeAllTokens()
              .then(-> user.fetchCurrentTokens())
              .then (afterDeletion) -> afterDeletion.should.have.lengthOf 0

    describe 'revoke one token', ->

      @afterAll always revokeAll
      @beforeAll always revokeAll
      @beforeAll prepare -> userPromise.then (user) ->
        parallel(user.createToken('perm'), user.createToken('perm'))
          .then( ([tokenA]) -> user.revokeToken tokenA )
          .then -> user.fetchCurrentTokens()

      it 'should have created multiple tokens, and revoked one', eventually (tokens) ->
        tokens.should.have.lengthOf 1
