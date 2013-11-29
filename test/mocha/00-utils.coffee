utils = require '../../build/util'
require 'should'

describe 'utils', ->

  describe 'isArray', ->

    {isArray} = utils

    it 'should agree that [] is an array', ->
      isArray([]).should.be.true

    it 'should agree that [1, 2, 3] is an array', ->
      isArray([1, 2, 3]).should.be.true

    it 'should deny that {} is an array', ->
      isArray({}).should.not.be.true

    it 'should deny that null is an array', ->
      isArray(null).should.not.be.true

  describe 'querystring', ->

    {querystring} = utils

    describe 'from pairs', ->

      it 'should make "foo=bar" from [["foo", "bar"]]', ->
        querystring([['foo', 'bar']]).should.eql "foo=bar"

      it 'should make "a=b&c=d" from [["a", "b"], ["c", "d"]]', ->
        querystring([["a", "b"], ["c", "d"]]).should.eql "a=b&c=d"

      it 'should make "a=1&a=2" from [["a", 1],["a",2]]', ->
        querystring([['a', 1],['a', 2]]).should.eql "a=1&a=2"

      it 'should make "key=some%20value" from [["key", "some value"]]', ->
        querystring([['key', 'some value']]).should.eql "key=some%20value"

    describe 'from object', ->

      it 'should make "foo=bar" from {"foo": "bar"}', ->
        querystring(foo: 'bar').should.eql "foo=bar"

      it 'should make "a=b&c=d" from {"a": "b", "c": "d"}', ->
        # This could be fragile, depending on the key iteration order.
        querystring(a: "b", c: "d").should.eql "a=b&c=d"

      it 'should make "a=1&a=2" from {"a": [1, 2]}', ->
        querystring(a: [1, 2]).should.eql "a=1&a=2"

      it 'should make "key=some%20value" from {"key": "some value"}', ->
        querystring(key: 'some value').should.eql "key=some%20value"

  describe 'curry', ->

    {curry} = utils

    add = (a, b) -> a + b
    plusTwo = curry add, 2
    getFour = curry add, 2, 2

    it 'can produce a partially applied function', ->
      plusTwo(2).should.eql 4

    it 'can partially apply all arguments', ->
      getFour().should.eql 4

  describe 'error', ->
    
    {error} = utils

    e = error "Sth. bad happened"

    it 'should be a failed promise', (done) ->
      shouldHaveFailed = (args...) -> done "Expected failure, got #{ args }"
      e.then shouldHaveFailed, (-> done())

  describe 'success', ->
     
    {success} = utils

    s = success "Sth. good happened"

    it 'should be a resolved promise', (done) ->
      s.then (-> done()), (-> done "Failed")

  describe 'fold', ->

    {fold} = utils
    add = (a, b) -> a + b
    sum = fold add

    describe 'the sum of an empty list with an initial state.', ->
      n = sum 0, []
      it 'should equal 0', ->
        n.should.eql 0

    describe 'the sum of a non-empty list with an initial state.', ->
      n = sum 100, [1, 2, 3]
      it 'should equal 106', ->
        n.should.eql 106

    describe 'the attempt to call sum with no arguments', -> 
      attempt = -> sum()
      it 'should throw and error', ->
        attempt.should.throw /null/

    describe 'the sum of a non-empty list', ->
      n = sum [1, 2, 3]
      it 'should equal 6', ->
        n.should.equal 6
      
    describe 'the sum of an empty list with no init', ->
      n = sum []
      it 'should be undefined', ->
        n.should.be.undefined

  describe 'take', ->

    {take} = utils

    describe 'take 2', ->
      takeTwo = take 2

      it 'should retrieve the first 2 items from an array', ->
        takeTwo([1, 2, 3]).should.eql [1, 2]

      it 'should retrieve as many items as possible', ->
        takeTwo([1]).should.eql [1]

      it 'should not alter the input', ->
        input = [1, 2, 3]
        firstTwo = takeTwo input
        firstTwo.should.not.equal input

  describe 'filter', ->

    {filter} = utils

    even = (n) -> n % 2 is 0
    evens = filter even

    describe 'the first 5 even numbers', ->
      xs = [1 .. 10]
      firstFive = evens xs
      it 'should contain 5 items', ->
        firstFive.should.have.lengthOf 5
      it 'should be [2, 4, 6, 8, 10]', ->
        firstFive.should.eql [2, 4, 6, 8, 10]

  describe 'uniqBy', ->

    {uniqBy} = utils

    describe 'using a hashable key', ->

      lengthOf = (x) -> x.length
      uniqByLength = uniqBy lengthOf
      input = ["foo", "bar", "quux"]

      it 'should get only one string of each length', ->
        uniqByLength(input).should.eql ['foo', 'quux']

    describe 'using a non-hashable-key', ->
      a = {}
      b = {}
      c = {}
      xs = [{key: a}, {key: a}, {key: b}, {key: b}, {key: b}, {key: c}]
      uniqByKey = uniqBy (x) -> x.key

      it 'should reduce the list to three items', ->
        uniqByKey(xs).should.have.lengthOf 3

      it 'should have unique keys', ->
        (x.key for x in uniqByKey(xs)).should.eql [a, b, c]

    describe 'calling uniqBy with both arguments', ->

      oneEvenOneOdd = uniqBy ((x) -> x % 2), [1 .. 10]

      it 'should work as it would if curried', ->
        oneEvenOneOdd.should.eql [1, 2]

