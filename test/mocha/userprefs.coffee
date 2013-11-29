Fixture = require './lib/fixture'
{eventually, prepare, always} = require './lib/utils'
{invoke} = Fixture.funcutils
should = require 'should'

describe 'Service', ->

  {service} = new Fixture()

  describe '#manageUserPreferences', ->

    clearPref = always -> service.manageUserPreferences 'DELETE', {key: 'testpref'}

    describe 'promise api', ->

      @beforeEach clearPref
      @afterEach clearPref

      describe 'getting preferences', ->

        @beforeEach prepare -> service.manageUserPreferences 'GET'

        it 'should get an object, with no value for testpref', eventually (prefs) ->
          should.not.exist prefs.testpref

      describe 'setting pref', ->

        @beforeEach prepare -> service.manageUserPreferences 'POST', {testpref: 'foo'}

        it 'should find the prefs set correctly', eventually (prefs) ->
          prefs.testpref.should.equal 'foo'

    describe 'callback api', ->

      @beforeEach clearPref
      @afterEach clearPref

      describe 'getting preferences', ->

        it 'should get an object, with no value for testpref', (done) ->
          service.manageUserPreferences 'GET', null, (err, prefs) ->
            return done err if err?
            try
              should.not.exist prefs.testpref
              done()
            catch e
              done e

      describe 'setting pref', ->

        it 'should find the prefs set correctly', (done) ->
          service.manageUserPreferences 'POST', {testpref: 'foo'}, (err, prefs) ->
            return done err if err?
            try
              prefs.testpref.should.equal 'foo'
              done()
            catch e
              done e

describe 'User: single preference management', ->

  {service} = new Fixture()

  clearPref = invoke 'clearPreference', 'testpref'

  @afterEach always -> service.fetchUser().then clearPref

  singleTest = (setter) -> () ->
    @beforeEach prepare -> service.fetchUser().then setter

    it 'should have the right prefs set', eventually (prefs) ->
      prefs.should.have.property 'testpref'
      prefs.testpref.should.equal 'TestPrefVal'

  describe '#setPreference(key: val)', singleTest (user) ->
    user.setPreference(testpref: 'TestPrefVal')

  describe '#setPreference(key, val)', singleTest (user) ->
    user.setPreference('testpref', 'TestPrefVal')

  describe '#setPreference([[key, val]])', singleTest (user) ->
    user.setPreference [['testpref', 'TestPrefVal']]

  describe '#clearPreference(key)', ->

    @beforeEach prepare -> service.fetchUser().then clearPref

    it 'should have the right prefs set', eventually (prefs) ->
      prefs.should.not.have.property 'testpref'

describe 'User: preference management with callbacks', ->

  {service} = new Fixture()

  clearPref = invoke 'clearPreference', 'testpref'

  @afterEach always -> service.fetchUser().then clearPref

  checkPrefs = (done) -> (err, prefs) ->
    return done err if err?
    try
      prefs.should.have.property 'testpref'
      prefs.testpref.should.equal 'TestPrefVal'
      done()
    catch e
      done e

  describe '#setPreference(key: val)', (done) ->
    service.whoami (err, user) ->
      return done err if err?
      user.setPreference {testpref: 'TestPrefVal'}, checkPrefs done

  describe '#setPreference(key, val)', (done) ->
    service.whoami (err, user) ->
      return done err if err?
      user.setPreference 'testpref', 'TestPrefVal', checkPrefs done

  describe '#setPreference([[key, val]])', (done) ->
    service.whoami (err, user) ->
      return done err if err?
      user.setPreference [['testpref', 'TestPrefVal']], checkPrefs done

  describe '#clearPreference(key)', ->

    @beforeEach prepare -> service.fetchUser().then clearPref

    it 'should have the right prefs set', eventually (prefs) ->
      service.whoami (err, user) ->
        return done err if err?
        user.clearPreference 'testpref', (err, done) ->
          return err if err?
          try
            prefs.should.not.have.property 'testpref'
            done()
          catch e
            done e

describe 'User: multiple preference management', ->

  {service} = new Fixture()
  set = 'setPreferences'

  clearPrefs = (user) ->
    user.clearPreference('testpref-a').then -> user.clearPreference 'testpref-b'

  @afterEach always -> service.fetchUser().then clearPrefs

  multiTest = (setter) -> () ->
    @beforeEach prepare -> service.fetchUser().then setter

    it 'should have both preferences set', eventually (prefs) ->
      prefs.should.have.property 'testpref-a', 'VAL1'
      prefs.should.have.property 'testpref-b', 'VAL2'

  describe '#setPreferences({a: val1, b: val2})', multiTest invoke set,
      'testpref-a': 'VAL1'
      'testpref-b': 'VAL2'

  describe '#setPreferences([[a, val1], [b, val2]])', multiTest invoke set, [
    ['testpref-a', 'VAL1'],
    ['testpref-b', 'VAL2']
  ]


