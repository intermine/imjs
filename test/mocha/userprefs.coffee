Fixture = require './lib/fixture'
{eventually, prepare, always} = require './lib/utils'
{invoke} = Fixture.funcutils

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


