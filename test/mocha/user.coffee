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

    describe 'create a token using the callback api', ->

      @afterAll always revokeAll
      @beforeAll always revokeAll

      it 'should be able to use the callback api', (done) ->
        service.fetchUser (err, user) ->
          return done err if err?
          user.createToken (err, dayToken) ->
            return done err if err?
            try
              should.exist dayToken
            catch e
              return done e
            user.createToken 'once', (err, singleUseToken) ->
              return done err if err?
              try
                should.exist singleUseToken
                singleUseToken.should.not.equal dayToken
              catch e
                return done e
              user.createToken 'perm', 'some message', (err, permToken) ->
                return done err if err?
                try
                  should.exist permToken
                  permToken.should.not.equal singleUseToken
                  permToken.should.not.equal dayToken
                  permToken.should.not.equal service.token
                  done()
                catch e
                  done e

    describe 'create a couple of tokens', ->

      @afterAll always revokeAll
      @beforeAll always revokeAll
      @beforeAll prepare -> userPromise.then (user) ->
        parallel(user.createToken('perm', 'A'), user.createToken('perm', 'B')).then ->
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
        ta = user.createToken 'perm', 'revoke one'
        tb = user.createToken 'perm', 'revoke one'
        parallel(ta, tb).then( ([tokenA]) -> user.revokeToken tokenA )
          .then -> user.fetchCurrentTokens()

      it 'should have created multiple tokens, and revoked one', eventually (tokens) ->
        tokens.should.have.lengthOf 1
